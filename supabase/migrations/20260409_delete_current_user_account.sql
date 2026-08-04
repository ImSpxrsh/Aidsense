-- Secure self-service account deletion for AidSense.
-- This removes both auth.users row and related profile row for the current user.

create or replace function public.delete_current_user_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
begin
  v_uid := auth.uid();

  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  delete from public.profiles where uid = v_uid;
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_current_user_account() from public;
grant execute on function public.delete_current_user_account() to authenticated;
