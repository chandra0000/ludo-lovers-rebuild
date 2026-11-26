begin;
create table public.match_reactions (
 match_id uuid references public.matches(id), player_id uuid references auth.users(id),
 phrase text not null check(phrase in ('Good luck!','Nice move!','Good game!','👏','❤️','🎲')),
 sent_at timestamptz not null, primary key(match_id,player_id)
);
alter table public.match_reactions enable row level security;
revoke all on public.match_reactions from public, anon, authenticated;
grant select on public.match_reactions to authenticated;
create policy read_reactions on public.match_reactions for select to authenticated using(ludo_private.member(match_id));
create function public.send_reaction(p_match uuid,p_phrase text) returns boolean
language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.match_players p join public.matches m on p.match_id=m.id where p.match_id=p_match and p.player_id=auth.uid() and p.active and not p.bot and m.status='playing') then raise exception 'Not a participant'; end if;
 insert into public.match_reactions as r values(p_match,auth.uid(),p_phrase,clock_timestamp())
 on conflict(match_id,player_id) do update set phrase=excluded.phrase,sent_at=excluded.sent_at
 where r.sent_at <= clock_timestamp()-interval '2 seconds';
 return found;
end $$;
revoke all on function public.send_reaction(uuid,text) from public,anon;
grant execute on function public.send_reaction(uuid,text) to authenticated;
alter publication supabase_realtime add table public.match_reactions;
commit;