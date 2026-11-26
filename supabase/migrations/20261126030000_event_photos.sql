-- 행사 사진 (화환 · 꽃). 기획안: docs/EVENT_PHOTO_PLAN.md
--
-- 1) 표 event_photos: 사진 정보 (보낸 분 · 메모). 사진 파일은 아래 Storage 버킷에 따로 둔다.
-- 2) Storage 버킷 event-photos (비공개): 파일 위치 = <사용자 id>/<사진 id>.jpg , <사진 id>_thumb.jpg
--
-- 보안
-- - 표: 로그인한 본인 행만 (다른 장부 표와 같은 규칙)
-- - 파일: 폴더 첫 칸이 내 사용자 id인 파일만 읽기 · 올리기 · 지우기. 공개 링크 없음
-- - 파일 크기 5MB까지, JPEG만 (앱이 1600px로 줄여서 장당 약 0.3 ~ 0.4MB)
--
-- 주의: 계정을 지워도 Storage 파일은 자동으로 지워지지 않는다. 앱이 탈퇴 직전에 Storage API로 먼저 지운다.
--       (Supabase 문서: Storage 파일은 SQL로 지우면 안 되고 Storage API로 지워야 함)
--
-- 적용: Supabase 대시보드 → SQL Editor → New query → 이 파일 내용 붙여 넣기 → Run (한 번만)

-- ── 표 ───────────────────────────────────
create table public.event_photos (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id bigint not null,
  event_id bigint not null,
  entry_id bigint,
  sender_name text check (sender_name is null or char_length(sender_name) <= 50),
  memo text check (memo is null or char_length(memo) <= 200),
  created_at timestamptz not null default now(),
  primary key (user_id, id),
  -- 행사를 지우면 사진 정보도 지운다 (앱의 로컬 DB와 같은 규칙)
  foreign key (user_id, event_id) references public.events (user_id, id) on delete cascade,
  -- 연결한 받은 기록을 지우면 연결만 푼다 (사진은 남김)
  foreign key (user_id, entry_id) references public.ledger_entries (user_id, id) on delete set null (entry_id)
);

create index event_photos_user_event on public.event_photos (user_id, event_id);

comment on table public.event_photos is '행사 사진(화환 · 꽃) 정보. 파일은 Storage 버킷 event-photos의 <user_id>/<id>.jpg';
comment on column public.event_photos.user_id is '주인 (로그인한 사용자). 비워 두면 auth.uid()';
comment on column public.event_photos.id is '사진 번호 (앱이 만든 큰 임의의 수). 파일 이름도 이 번호';
comment on column public.event_photos.event_id is '어느 행사 사진인지 (events.id)';
comment on column public.event_photos.entry_id is '보낸 분을 받은 기록에서 골랐으면 그 기록 (ledger_entries.id)';
comment on column public.event_photos.sender_name is '보낸 분 (리본에 적힌 이름 등)';
comment on column public.event_photos.memo is '메모 (예: 쌀화환 20kg)';
comment on column public.event_photos.created_at is '추가한 시각';

grant select, insert, update, delete on public.event_photos to authenticated;

alter table public.event_photos enable row level security;

create policy "본인 사진만" on public.event_photos
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- ── Storage 버킷 ──────────────────────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('event-photos', 'event-photos', false, 5242880, array['image/jpeg'])
on conflict (id) do nothing;

-- 폴더 첫 칸(<사용자 id>)이 내 id인 파일만
create policy "본인 사진 파일 읽기" on storage.objects
  for select to authenticated
  using (bucket_id = 'event-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "본인 사진 파일 올리기" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'event-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "본인 사진 파일 바꾸기" on storage.objects
  for update to authenticated
  using (bucket_id = 'event-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "본인 사진 파일 지우기" on storage.objects
  for delete to authenticated
  using (bucket_id = 'event-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
