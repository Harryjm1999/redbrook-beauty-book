create or replace function public.admin_delete_user(_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.has_role(auth.uid(), 'admin') then
    raise exception 'Not authorised';
  end if;

  if _user_id = auth.uid() then
    raise exception 'You cannot remove your own account here';
  end if;

  if public.has_role(_user_id, 'admin') then
    raise exception 'Admin accounts cannot be removed';
  end if;

  delete from auth.users where id = _user_id;
end;
$$;

revoke execute on function public.admin_delete_user(uuid) from public;
revoke execute on function public.admin_delete_user(uuid) from anon;
grant execute on function public.admin_delete_user(uuid) to authenticated;