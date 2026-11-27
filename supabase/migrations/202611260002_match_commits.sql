begin;
create function public.commit_ludo_turn(p_match uuid,p_expected bigint,p_id uuid,p_actor text,p_action text,p_seat int,p_timeout boolean,p_next jsonb,p_events jsonb,p_winner int)
returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.matches; receipt public.match_events; s public.match_players; payee uuid;
begin
 select * into strict m from public.matches where id=p_match for update;
 select * into receipt from public.match_events where match_id=m.id and command_id=p_id;
 if found then
   if receipt.actor_key<>p_actor or receipt.action<>p_action then raise exception 'Command conflict'; end if;
   return jsonb_build_object('sequence_number',receipt.sequence_number,'events',receipt.payload);
 end if;
 if m.status<>'playing' or m.sequence_number<>p_expected then raise exception 'Refresh snapshot'; end if;
 select * into strict s from public.match_players where match_id=m.id and seat=p_seat;
 if p_timeout then
   if not s.bot and clock_timestamp()<m.deadline then raise exception 'Turn is active'; end if;
   update public.match_players set timeouts=timeouts+1,bot=bot or timeouts+1>=3 where match_id=m.id and seat=p_seat;
 else
   if s.bot or s.player_id::text is distinct from p_actor or clock_timestamp()>=m.deadline then raise exception 'Turn unavailable'; end if;
   update public.match_players set timeouts=0 where match_id=m.id and seat=p_seat;
 end if;
 if p_winner is not null then
   select player_id into strict payee from public.match_players where match_id=m.id and seat=p_winner;
   if payee is not null then
     insert into public.player_wallets as w values(payee,m.pot) on conflict(player_id) do update set coins=w.coins+excluded.coins;
   else
     -- Synthetic seats contribute no stake. Refund human stakes on a bot win.
     update public.player_wallets w set coins=w.coins+m.fee from public.match_players p where p.match_id=m.id and w.player_id=p.player_id;
   end if;
   update public.match_players set active=false where match_id=m.id;
 end if;
 update public.matches set snapshot=p_next,sequence_number=p_expected+1,winner=p_winner,
 status=case when p_winner is null then 'playing' else 'finished' end,
 deadline=case when p_winner is null then clock_timestamp()+interval '15 seconds' end where id=m.id;
 insert into public.match_events values(m.id,p_expected+1,p_id,p_actor,p_action,p_events);
 return jsonb_build_object('sequence_number',p_expected+1,'events',p_events);
end $$;
revoke all on function public.commit_ludo_turn(uuid,bigint,uuid,text,text,int,boolean,jsonb,jsonb,int) from public,anon,authenticated;
grant execute on function public.commit_ludo_turn(uuid,bigint,uuid,text,text,int,boolean,jsonb,jsonb,int) to service_role;
commit;
