-- 장부 표 · 컬럼 설명 (Supabase 대시보드의 Table Editor · Database › Tables · API Docs에 보이는 설명)
--
-- 표를 만든 SQL(20261126010000_ledger_tables.sql)의 `--` 주석은 DB에 저장되지 않아서, 설명은 COMMENT로 따로 단다.
-- 여러 번 실행해도 같은 결과다. (설명을 덮어씀)
--
-- 적용: Supabase 대시보드 → SQL Editor → New query → 이 파일 내용 붙여 넣기 → Run

-- ── 경조사 종류 ─────────────────────────
comment on table public.event_types is '경조사 종류 (결혼 · 조의 · 돌잔치 …). 사람마다 따로 갖고, 직접 추가 · 이름 변경 · 삭제할 수 있다';
comment on column public.event_types.user_id is '주인 (auth.users.id). 비워 두면 로그인한 사람으로 채워짐. 계정을 지우면 함께 지워짐';
comment on column public.event_types.id is '종류 번호. 기본 종류는 1~7 고정(7 = 기타), 직접 만든 종류는 앱이 만든 큰 임의의 수';
comment on column public.event_types.name is '종류 이름 (1~10자, 한 사람 안에서 중복 불가)';
comment on column public.event_types.sort_order is '보여주는 순서 (작을수록 앞)';
comment on column public.event_types.is_protected is '지울 수 없는 종류인지 (기타 = true). 다른 종류를 지우면 그 기록이 기타로 옮겨짐';

-- ── 행사 ───────────────────────────────
comment on table public.events is '내가 연 행사 (우리 결혼식 · 첫째 돌잔치 …). 받은 기록이 행사별로 묶인다';
comment on column public.events.user_id is '주인 (auth.users.id)';
comment on column public.events.id is '행사 번호 (앱이 만든 큰 임의의 수, 여러 기기에서 겹치지 않음)';
comment on column public.events.title is '행사 이름 (1~30자)';
comment on column public.events.event_type_id is '경조사 종류 (event_types.id)';
comment on column public.events.date is '행사 날짜 (UTC로 저장. 한국 시간보다 9시간 이르게 보임)';
comment on column public.events.memo is '메모 (선택)';
comment on column public.events.created_at is '처음 만든 시각';

-- ── 기록 ───────────────────────────────
comment on table public.ledger_entries is '보낸 마음 · 받은 마음 기록 한 건 (축의금 · 부조금 등). 엑셀 내보내기 열과 같은 구성';
comment on column public.ledger_entries.user_id is '주인 (auth.users.id)';
comment on column public.ledger_entries.id is '기록 번호 (앱이 만든 큰 임의의 수, 여러 기기에서 겹치지 않음)';
comment on column public.ledger_entries.direction is '보냄 · 받음 (sent = 보낸 마음, received = 받은 마음)';
comment on column public.ledger_entries.event_type_id is '경조사 종류 (event_types.id)';
comment on column public.ledger_entries.event_id is '받은 기록이 속한 행사 (events.id). 보낸 기록은 비어 있음. 행사를 지우면 함께 지워짐';
comment on column public.ledger_entries.person_name is '상대방 이름 (1~50자)';
comment on column public.ledger_entries.amount is '금액 (원, 0 이상)';
comment on column public.ledger_entries.date is '주고받은 날짜 (UTC로 저장. 한국 시간보다 9시간 이르게 보임)';
comment on column public.ledger_entries.relation is '관계 (선택): family 가족 · relative 친척 · friend 친구 · work 직장 · acquaintance 지인 · other 기타';
comment on column public.ledger_entries.memo is '메모 (선택)';
comment on column public.ledger_entries.created_at is '처음 저장한 시각';
comment on column public.ledger_entries.updated_at is '마지막으로 고친 시각';
