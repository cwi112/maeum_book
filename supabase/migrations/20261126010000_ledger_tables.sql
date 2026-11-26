-- 회원 장부 표 (서버 DB가 원본). 기기에는 계정별 사본만 둔다.
--
-- 구조는 앱의 로컬 DB(Drift)와 같다: 경조사 종류(event_types) · 행사(events) · 기록(ledger_entries)
-- - 기본키가 (user_id, id): 사람마다 id 공간이 따로라서, 기본 종류 id 1~7을 모든 사람이 똑같이 쓴다.
-- - id는 앱이 만든다. (기본 종류 1~7, 나머지는 큰 임의의 수 → 여러 기기에서 만들어도 겹치지 않음)
-- - user_id는 비워 두면 로그인한 사람(auth.uid())으로 채워진다.
-- - 계정을 지우면(auth.users 삭제) 그 사람의 장부도 모두 지워진다. (on delete cascade)
--
-- 보안(RLS): 로그인한 본인 행만 읽고 · 쓰고 · 지울 수 있다. 비로그인(anon)은 아무것도 못 한다.
--
-- 적용: Supabase 대시보드 → SQL Editor → New query → 이 파일 내용 붙여 넣기 → Run (한 번만)

-- ── 경조사 종류 ─────────────────────────
create table public.event_types (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id bigint not null,
  name text not null check (char_length(name) between 1 and 10),
  sort_order integer not null default 0,
  is_protected boolean not null default false,
  primary key (user_id, id),
  unique (user_id, name)
);

-- ── 행사 (내가 연 경조사) ──────────────────
create table public.events (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id bigint not null,
  title text not null check (char_length(title) between 1 and 30),
  event_type_id bigint not null,
  date timestamptz not null,
  memo text,
  created_at timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id, event_type_id) references public.event_types (user_id, id)
);

-- ── 기록 (보낸 · 받은 마음) ────────────────
create table public.ledger_entries (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id bigint not null,
  direction text not null check (direction in ('sent', 'received')),
  event_type_id bigint not null,
  event_id bigint,
  person_name text not null check (char_length(person_name) between 1 and 50),
  amount bigint not null check (amount >= 0),
  date timestamptz not null,
  relation text,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id, event_type_id) references public.event_types (user_id, id),
  -- 행사를 지우면 안의 받은 기록도 지운다 (앱의 로컬 DB와 같은 규칙)
  foreign key (user_id, event_id) references public.events (user_id, id) on delete cascade
);

create index ledger_entries_user_direction_date on public.ledger_entries (user_id, direction, date desc);

-- ── 권한: 로그인한 사용자만 표를 쓸 수 있게 (anon은 권한 없음) ──
grant select, insert, update, delete on public.event_types, public.events, public.ledger_entries to authenticated;

-- ── RLS: 본인 행만 ──────────────────────
alter table public.event_types enable row level security;
alter table public.events enable row level security;
alter table public.ledger_entries enable row level security;

create policy "본인 종류만" on public.event_types
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "본인 행사만" on public.events
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "본인 기록만" on public.ledger_entries
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
