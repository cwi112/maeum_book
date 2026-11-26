-- 회원 탈퇴: 로그인한 본인 계정을 지운다.
--
-- 앱(publishable key)에서는 계정 삭제 권한이 없어서, 이 함수가 대신 지운다.
-- security definer = 함수를 만든 관리자 권한으로 실행. 대신 auth.uid()(지금 로그인한 사람)만 지우므로 남의 계정은 건드릴 수 없다.
-- 나중에 장부 표를 만들 때 user_id에 "on delete cascade"를 걸어 두면 계정을 지울 때 서버의 장부도 함께 지워진다.
--
-- 적용: Supabase 대시보드 → SQL Editor → New query → 이 파일 내용 붙여 넣기 → Run

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception '로그인이 필요해요';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

-- 로그인한 사용자(authenticated)만 실행할 수 있게 한다.
revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
