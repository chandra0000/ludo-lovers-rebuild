begin;
create schema if not exists ludo_private;
revoke all on schema ludo_private from public, anon, authenticated;

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references auth.users,
  mode text not null check(mode in ('classic','quick')),
  capacity smallint not null check(capacity in (2,4)),
  private_room boolean not null,
  fee integer not null check(fee in (0,10,50,100)),
  status text not null default 'waiting' check(status in ('waiting','playing','finished','cancelled')),
  sequence_number bigint not null default 0,
  snapshot jsonb, deadline timestamptz, winner smallint,
  pot integer not null default 0 check(pot >= 0),
  created_at timestamptz not null default now()
);
create table public.match_players (
  match_id uuid references public.matches on delete cascade,
  seat smallint check(seat between 0 and 3), player_id uuid references auth.users,
  ready boolean not null default false, bot boolean not null default false,
  timeouts int not null default 0, active boolean not null default true,
  primary key(match_id,seat), unique(match_id,player_id),
  check(bot or player_id is not null)
);
create unique index one_live_room on public.match_players(player_id) where active;
create index waiting_rooms on public.matches(mode,capacity,fee,created_at) where status='waiting' and not private_room;
create table public.player_wallets (
  player_id uuid primary key references auth.users,
  coins bigint not null default 0 check(coins>=0)
);
create table public.match_events (
  match_id uuid references public.matches, sequence_number bigint not null,
  command_id uuid not null, actor_key text not null, action text not null, payload jsonb not null,
  primary key(match_id,sequence_number), unique(match_id,command_id)
);
create table ludo_private.invites(code text primary key, match_id uuid unique references public.matches);
create table ludo_private.join_attempts(player_id uuid primary key, since timestamptz not null, attempts int not null);
create function ludo_private.member(mid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.match_players where match_id=mid and player_id=(select auth.uid()))
$$;
revoke all on function ludo_private.member(uuid) from public;
grant usage on schema ludo_private to authenticated;
grant execute on function ludo_private.member(uuid) to authenticated;
alter table public.matches enable row level security;
alter table public.match_players enable row level security;
alter table public.match_events enable row level security;
alter table public.player_wallets enable row level security;
revoke all on public.matches,public.match_players,public.match_events,public.player_wallets from public,anon,authenticated;
grant select on public.matches,public.match_players,public.match_events,public.player_wallets to authenticated;
grant select on public.matches,public.match_players,public.match_events to service_role;
create policy read_room on public.matches for select to authenticated using(ludo_private.member(id));
create policy read_seats on public.match_players for select to authenticated using(ludo_private.member(match_id));
create policy read_events on public.match_events for select to authenticated using(ludo_private.member(match_id));
create policy own_wallet on public.player_wallets for select to authenticated using(player_id=(select auth.uid()));

create function public.create_or_join_match(p_mode text,p_capacity int,p_tier text,p_private boolean,p_code text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); m public.matches; seat_count int; price int; code text; tries int;
begin
 if uid is null then raise exception 'Sign in required'; end if;
 if p_mode is null or p_mode not in ('classic','quick') or p_capacity is null or p_capacity not in (2,4) or p_private is null then raise exception 'Invalid configuration'; end if;
 price:=case p_tier when 'bronze' then 10 when 'silver' then 50 when 'gold' then 100 end;
 if price is null then raise exception 'Unknown tier'; end if;
 if p_private then price:=0; end if;
 perform pg_advisory_xact_lock(hashtextextended(uid::text,0));
 select r.* into m from public.matches r join public.match_players s on s.match_id=r.id where s.player_id=uid and s.active;
 if found then
   select i.code into code from ludo_private.invites i where i.match_id=m.id and m.host_id=uid;
   return jsonb_build_object('match_id',m.id,'code',code);
 end if;
 if p_code is not null then
   if not p_private then raise exception 'Invalid configuration'; end if;
   insert into ludo_private.join_attempts as a values(uid,now(),1)
   on conflict(player_id) do update set attempts=case when a.since < now()-interval '1 minute' then 1 else a.attempts+1 end,since=case when a.since < now()-interval '1 minute' then now() else a.since end returning attempts into tries;
   if tries>8 then return jsonb_build_object('error','Try again later'); end if;
   select r.* into m from public.matches r join ludo_private.invites i on i.match_id=r.id where i.code=upper(trim(p_code)) and r.status='waiting' for update of r;
   if not found then return jsonb_build_object('error','Room unavailable'); end if;
 elsif not p_private then
   perform pg_advisory_xact_lock(hashtextextended(p_mode||':'||p_capacity||':'||price,1));
   select * into m from public.matches where status='waiting' and not private_room and mode=p_mode and capacity=p_capacity and fee=price order by created_at limit 1 for update;
 end if;
 if m.id is null then
   insert into public.matches(host_id,mode,capacity,private_room,fee) values(uid,p_mode,p_capacity,p_private,price) returning * into m;
   if p_private then
     loop
       code:=upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
       insert into ludo_private.invites values(code,m.id) on conflict(code) do nothing;
       exit when found;
     end loop;
   end if;
 end if;
 select count(*) into seat_count from public.match_players where match_id=m.id;
 if seat_count>=m.capacity then return jsonb_build_object('error','Room unavailable'); end if;
 if m.fee>0 then
   update public.player_wallets set coins=coins-m.fee where player_id=uid and coins>=m.fee;
   if not found then raise exception 'Insufficient coins'; end if;
 end if;
 insert into public.match_players(match_id,seat,player_id,ready) values(m.id,seat_count,uid,not m.private_room);
 update public.matches set pot=pot+m.fee,status=case when not private_room and seat_count+1=capacity then 'playing' else status end,
 deadline=case when not private_room and seat_count+1=capacity then now()+interval '15 seconds' else deadline end where id=m.id;
 return jsonb_build_object('match_id',m.id,'code',code);
end $$;

create function public.room_action(p_match uuid,p_action text,p_ready boolean default true) returns void
language plpgsql security definer set search_path='' as $$
declare m public.matches; uid uuid:=auth.uid(); n int;
begin
 select * into strict m from public.matches where id=p_match and ludo_private.member(id) for update;
 if m.status <> 'waiting' then raise exception 'Room already closed'; end if;
 if p_action='ready' and m.private_room then
   update public.match_players set ready=p_ready where match_id=m.id and player_id=uid; return;
 end if;
 if p_action='cancel' and (not m.private_room or uid=m.host_id) then
   update public.player_wallets w set coins=w.coins+m.fee from public.match_players s where s.match_id=m.id and s.player_id=w.player_id;
   update public.match_players set active=false where match_id=m.id;
   update public.matches set status='cancelled',pot=0 where id=m.id; return;
 end if;
 if uid<>m.host_id then raise exception 'Host required'; end if;
 select count(*) into n from public.match_players where match_id=m.id;
 if p_action='backfill' and not m.private_room and now()>=m.created_at+interval '11 seconds' then
   insert into public.match_players(match_id,seat,bot,ready) select m.id,i,true,true from generate_series(n,m.capacity-1) i;
 elsif p_action<>'start' or not m.private_room or n<>m.capacity or exists(select 1 from public.match_players where match_id=m.id and not ready) then raise exception 'Room is not ready';
 end if;
 update public.matches set status='playing',deadline=now()+interval '15 seconds' where id=m.id;
end $$;

revoke all on function public.create_or_join_match(text,int,text,boolean,text), public.room_action(uuid,text,boolean) from public,anon;
grant execute on function public.create_or_join_match(text,int,text,boolean,text),public.room_action(uuid,text,boolean) to authenticated;
alter publication supabase_realtime add table public.matches,public.match_events,public.match_players;
commit;
