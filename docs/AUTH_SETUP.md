# 로그인 · 서버 준비 (Supabase + 카카오 + Apple)

코드를 짜기 전에 **사람이 웹 콘솔에서 해야 하는 설정**을 순서대로 정리한 문서입니다. (2026-11 기준 각 서비스 공식 문서 확인)
위에서부터 순서대로 진행하면 됩니다. 콘솔 화면 이름이 문서와 조금 다르면 캡처를 보내 주세요.

## 0. 전체 그림

```
[앱] ─ 카카오톡/카카오계정 로그인 (카카오 SDK) ─▶ ID 토큰 ─┐
[앱] ─ Apple 로그인 (iOS 기본 창) ──────────────▶ ID 토큰 ─┼─▶ Supabase Auth ─▶ 사용자 계정 + 장부 DB
                                                           ┘
```

- 앱은 카카오 · Apple에서 **ID 토큰**(로그인했다는 증명서)을 받아 Supabase에 넘깁니다. Supabase가 진짜인지 확인하고 계정을 만들어 줍니다.
- 그래서 **카카오 로그인 → OpenID Connect(ID 토큰 발급)를 꼭 켜야** 합니다.
- 장부 데이터는 지금처럼 기기 DB에 먼저 저장하고, 로그인하면 Supabase와 동기화합니다. (인터넷이 없어도 앱은 그대로 동작)

이 프로젝트의 고정값 (콘솔에 그대로 붙여 넣으면 됩니다)

| 항목 | 값 |
| --- | --- |
| iOS 번들 ID | `com.maeumbook.maeumBook` |
| Android 패키지명 | `com.maeumbook.maeum_book` |
| Android 키 해시 (디버그 — 에뮬레이터 · Android Studio 실행) | `eEshaL66REAMUc6WtTK+hPtSSa0=` |
| Android 키 해시 (릴리스 — GitHub Releases APK) | `50+binnwET5uzV6tIQJctV+CcHE=` |

> 키 해시는 서명 키(`~/.android/debug.keystore`, `C:\Users\dnjsd\keys\maeum_book\upload-keystore.jks`)에서 계산한 값입니다. 다른 PC에서 디버그 빌드를 하면 디버그 키 해시가 달라지므로 그 PC 값도 추가해야 합니다.

---

## 1. Supabase 프로젝트 만들기

1. https://supabase.com 접속 → **Start your project** → GitHub 계정(cwi112)으로 로그인
2. 처음이면 **Organization** 만들기: 이름 자유(예: `cwi112`), Type `Personal`, Plan **Free**
3. **New project**
   - Project name: `maeum_book`
   - Database Password: **Generate a password** → 비밀번호 관리 앱 등에 저장 (앱에는 쓰지 않음, 분실 시 재설정 가능)
   - Region: **Northeast Asia (Seoul)**
   - **Create new project** → 1~2분 기다리기
4. 앱에 넣을 값 확인: 왼쪽 아래 **Project Settings**(톱니) →
   - **Data API**(또는 General): **Project URL** `https://<프로젝트ID>.supabase.co`
   - **API Keys**: **Publishable key** (`sb_publishable_...`로 시작)
   - 두 값은 앱 안에 들어가는 **공개용 값**이라 저에게 알려 주셔도 됩니다.
   - ⚠️ **secret key**(`sb_secret_...`)와 `service_role` 키는 절대 앱 · 채팅 · 저장소에 넣지 않습니다.
5. 카카오 설정에 쓸 **Callback URL** 복사: 왼쪽 **Authentication** → **Sign In / Providers** → **Kakao** 펼치기 → `Callback URL (for OAuth)` 값
   - 형식: `https://<프로젝트ID>.supabase.co/auth/v1/callback`
   - 아직 Kakao를 켜지 말고 창만 닫습니다. (3번에서 켬)

> 무료 플랜: DB 500MB, 월 활성 사용자 5만 명까지. **7일 동안 요청이 없으면 프로젝트가 일시 정지**되고, 대시보드에서 Restore를 누르면 다시 켜집니다.

---

## 2. 카카오 디벨로퍼스

### 2-1. 로그인 · 앱 만들기
1. https://developers.kakao.com → 오른쪽 위 **로그인** (카카오계정)
2. 처음이면 개발자 등록 약관 동의
3. 위 메뉴 **앱** → **앱 생성**(＋)
   - 앱 아이콘: `assets/icon/app_icon.png` 업로드 (로그인 동의 화면에 보임)
   - 앱 이름: `마음장부`
   - 회사명: 개인이면 본인 이름
   - 카테고리: `라이프스타일` (가까운 것 선택)
   - 앱 대표 도메인을 요구하면: `https://<프로젝트ID>.supabase.co`
   - **저장**

### 2-2. 플랫폼 키 · 플랫폼 등록
앱을 고른 뒤 **[앱] > [플랫폼 키]**

1. **네이티브 앱 키** 클릭 → 플랫폼 정보 입력
   - **iOS 번들 ID**: `com.maeumbook.maeumBook`
   - **Android 패키지명**: `com.maeumbook.maeum_book`
   - **키 해시**: 위 표의 디버그 · 릴리스 키 해시 **두 개 모두** 등록 (한 줄에 하나)
   - 저장
   - 📌 **네이티브 앱 키** 값을 메모 → 앱에 들어가는 공개용 값이라 저에게 알려 주셔도 됩니다.
2. **REST API 키** 클릭
   - **카카오 로그인 리다이렉트 URI**: 1-5에서 복사한 Supabase Callback URL 붙여 넣기 → 저장
   - **클라이언트 시크릿**: 상태가 **사용함**인지 확인하고 **코드** 값을 복사 (3번에서 Supabase에만 넣음)
   - 📌 **REST API 키** 값과 **클라이언트 시크릿 코드**를 메모. 시크릿은 **Supabase 대시보드에만** 넣고 앱 · 채팅에는 쓰지 않습니다.

> 번들 ID · 패키지명 · 키 해시가 하나라도 틀리면 로그인할 때 `invalid android_key_hash or ios_bundle_id` 오류가 납니다.

### 2-3. 카카오 로그인 켜기
1. **[카카오 로그인] > [사용 설정]** → 상태 **ON** (꺼져 있으면 `KOE004` 오류)
2. **[카카오 로그인] > [OpenID Connect]** → 상태 **ON**
   - 이걸 켜야 ID 토큰이 나오고, Supabase가 로그인을 받아 줄 수 있습니다. **꼭 켜기**

### 2-4. 동의항목 (로그인할 때 사용자에게 받을 정보)
**[카카오 로그인] > [동의항목]**

| 항목 | 설정 | 이유 |
| --- | --- | --- |
| 닉네임 (`profile_nickname`) | **필수 동의** | 설정 화면에 이름 표시 |
| 프로필 사진 (`profile_image`) | 선택 동의 (또는 사용 안 함) | 필요 없으면 받지 않는 게 심사 · 개인정보 측면에서 유리 |
| 카카오계정(이메일) (`account_email`) | **지금은 설정하지 않음** | 이메일은 **비즈 앱**만 받을 수 있음 |

- 이메일이 꼭 필요해지면: **[앱] > [일반] > [비즈니스 정보]**에서 **개인 개발자 비즈 앱** 전환 (사업자번호 없이 본인 인증으로 가능) 후 이메일 동의항목을 켭니다. 지금 앱에는 이메일이 필요 없으므로 건너뜁니다.
- **[동의 화면 미리보기]**로 사용자에게 어떻게 보이는지 확인할 수 있습니다.

---

## 3. Supabase에 카카오 연결

**Authentication → Sign In / Providers → Kakao**

| 칸 | 넣을 값 |
| --- | --- |
| Enable Sign in with Kakao | **ON** |
| Kakao Client ID (REST API Key) | 2-2의 **REST API 키** |
| Kakao Client Secret | 2-2의 **클라이언트 시크릿 코드** |
| Allow users without an email | **ON** (이메일을 받지 않으므로 꼭 켜기) |

**Save**

> 앱(카카오 SDK)으로 로그인하면 ID 토큰이 **네이티브 앱 키** 앞으로 발급됩니다. Supabase는 토큰의 발급 대상이 Client ID 칸에 있는지 확인하므로,
> Client ID 칸에는 **`REST API 키,네이티브 앱 키`** 순서로 쉼표로 이어 두 값을 넣습니다. (앞의 REST API 키는 웹 로그인용)
> 로그인할 때 `Unacceptable audience` 같은 오류가 나면 이 칸을 확인합니다.

## 3-1. 회원 탈퇴 함수 만들기 (SQL 한 번 실행)

앱의 "회원 탈퇴"가 쓰는 DB 함수입니다. 로그인한 본인 계정만 지울 수 있습니다.

1. Supabase 대시보드 왼쪽 **SQL Editor** → **New query**
2. 저장소의 [`supabase/migrations/20261126000000_delete_my_account.sql`](../supabase/migrations/20261126000000_delete_my_account.sql) 내용을 전부 붙여 넣기
3. **Run** → `Success. No rows returned`가 나오면 완료

---

## 4. Apple 로그인

App Store 심사 규정(4.8): 카카오 같은 소셜 로그인을 넣으면 **Apple 로그인도 함께 제공**해야 합니다. (iOS 앱만 해당. Android에서는 Apple 버튼을 숨깁니다.)
앱 안의 기본 Apple 로그인 창(네이티브)만 쓰므로 **Services ID · 키(.p8) · 시크릿은 만들 필요가 없습니다.**

### 4-1. App ID에 기능 켜기
1. https://developer.apple.com/account → **Certificates, Identifiers & Profiles** → **Identifiers**
2. `com.maeumbook.maeumBook` 클릭
3. **Capabilities** 목록에서 **Sign In with Apple** 체크 → 옆 **Edit**가 있으면 눌러 **Enable as a primary App ID** 선택 (Server-to-Server Notification Endpoint는 비워 둠)
4. 오른쪽 위 **Save** → **Confirm**

### 4-2. 프로비저닝 프로파일 다시 만들기 (기능을 켜면 기존 프로파일이 무효가 됨)
1. 같은 화면 왼쪽 **Profiles** → 기존 App Store 프로파일(마음장부)이 **Invalid**로 보이면 클릭 → **Edit** → **Save** → 새 프로파일 생성 완료
2. **Codemagic** → Personal Account(또는 Team) **Settings** → **Code signing identities** → **iOS provisioning profiles**
   - 예전 마음장부 프로파일 **삭제** → **Fetch profiles** → 새 프로파일 체크 → **Download selected**
3. 이걸 빼먹으면 다음 TestFlight 빌드가 서명 오류로 실패합니다. (`docs/DEPLOY.md` 5~6번과 같은 작업)

> Xcode 프로젝트 쪽 설정(Runner.entitlements에 Sign in with Apple 추가)은 Mac이 없어도 파일로 넣을 수 있어서, 구현할 때 코드와 함께 처리합니다.

### 4-3. Supabase에 Apple 연결
**Authentication → Sign In / Providers → Apple**

| 칸 | 넣을 값 |
| --- | --- |
| Enable Sign in with Apple | **ON** |
| Client IDs | `com.maeumbook.maeumBook` |
| Secret Key (for OAuth) | **비워 둠** (웹 로그인을 안 쓰므로 필요 없음) |

**Save**

> Apple은 이름을 **처음 로그인할 때 한 번만** 줍니다. 앱에서 받자마자 Supabase 사용자 정보에 저장하도록 구현합니다.

---

## 5. 다 끝나면 저에게 알려 줄 값

| 값 | 어디서 | 공개 여부 |
| --- | --- | --- |
| Supabase **Project URL** | 1-4 | 앱에 들어가는 공개 값 → 알려 줘도 됨 |
| Supabase **Publishable key** | 1-4 | 공개 값 → 알려 줘도 됨 |
| 카카오 **네이티브 앱 키** | 2-2 | 공개 값 → 알려 줘도 됨 |
| 카카오 REST API 키 · **클라이언트 시크릿** | 2-2 | ❌ Supabase 대시보드에만 입력, 채팅에 쓰지 않기 |
| Supabase DB 비밀번호 · secret key | 1-3, 1-4 | ❌ 어디에도 공유하지 않기 |

공개 값 3개는 `lib/core/define/app_env.dart`에 넣었습니다. 앱 파일 안에 그대로 들어가는 값이고(카카오 키는 AndroidManifest · Info.plist에도 들어가야 함), 데이터는 RLS · 카카오 플랫폼 등록(번들 ID · 키 해시)이 지키므로 저장소에 두어도 됩니다.

## 왜 Apple은 콜백 URL · Secret Key가 없어도 되나

| | 웹 로그인 (OAuth) | 앱 안 로그인 (네이티브, 이 앱) |
| --- | --- | --- |
| 흐름 | 브라우저에서 Apple 로그인 → Apple이 **콜백 URL**(Supabase)로 결과를 보냄 → Supabase가 **Secret Key**로 Apple 서버와 토큰 교환 | iOS 기본 로그인 창 → **ID 토큰을 앱이 바로 받음** → 앱이 Supabase에 전달 → Supabase는 Apple 공개키로 서명만 확인 |
| 콜백 URL | 필요 | 돌아올 주소가 없으므로 필요 없음 |
| Secret Key | 필요 (.p8로 만든 값, **6개월마다 갱신**) | 서버끼리 교환을 안 하므로 필요 없음 |

Android에서 Apple 로그인을 하려면 웹 로그인 방식이 필요해서 Android에서는 Apple 버튼을 숨겼습니다. (Android는 카카오로 충분하고, Apple 로그인 의무는 iOS 앱에만 해당)

## 6. 구현할 때 같이 챙길 것 (참고)

- **회원 탈퇴**: 앱에서 계정을 만들 수 있으면 앱 안에서 계정 삭제도 할 수 있어야 합니다. (App Store 규정 5.1.1(v))
- **개인정보처리방침 URL**: 로그인으로 개인정보를 받으면 App Store Connect에 필요합니다. (GitHub Pages 등으로 간단히 만들 예정)
- **로그인 없이 쓰기**: 지금처럼 로그인 없이도 쓸 수 있게 두고, 로그인은 "백업 · 다른 기기에서 보기"용 선택 기능으로 둡니다.

## 7. 자동 로그인 · 만료 · 오류 처리 (구현 내용)

**자동 로그인**: 로그인 정보(세션)는 기기에 저장되고 앱을 켜면 그대로 불러옵니다. 접속 토큰(1시간)은 Supabase가 만료 전에 자동으로 새로 받고, 인터넷이 없으면 로그인 상태를 유지한 채 나중에 다시 시도합니다.

**다시 로그인 안내** (`AuthSessionWatcher`, 앱 전체를 감쌈) — 사용자가 직접 하지 않은 로그아웃이 생기면 어느 화면에서든 "로그인이 만료됐어요" 토스트 + [다시 로그인] 버튼:

| 상황 | 감지 |
| --- | --- |
| 오래 안 써서 갱신 토큰이 만료 · 다른 기기에서 탈퇴 · 서버에서 계정 삭제 | Supabase 갱신 거절 (`SignOutReason.sessionExpired`) |
| 저장된 로그인 정보가 손상됨 | `SignOutReason.sessionMissing` |
| 아이폰 설정에서 "Apple로 로그인" 사용 중단 | 앱을 켤 때 · 다시 열 때 Apple 자격 상태 확인 → 로그아웃 |
| 탈퇴 등 서버 작업 중 토큰 만료 | 오류를 `sessionExpired`로 바꿔 같은 안내 |

로그인하지 않아도 앱은 쓸 수 있으므로 강제로 로그인 화면으로 보내지 않습니다.

**오류 분류** (`AuthFailureType`, 모든 예외를 여기로 변환 → 문구 하나씩)

| 종류 | 예 | 사용자에게 |
| --- | --- | --- |
| 취소 | 카카오톡 · 카카오계정 · Apple 창 닫기, 동의 화면 취소 | 아무것도 안 띄움 |
| 네트워크 | 인터넷 없음, 20초 응답 없음 | 인터넷 연결을 확인하고 다시 시도해 주세요 |
| 만료 | 위 표 | 다시 로그인 안내 |
| 설정 문제 | KOE 오류(키 해시 · 번들 ID), OpenID Connect 꺼짐, Supabase Client ID 불일치 | 로그인 설정에 문제가 있어요 (개발자 확인 필요, 로그에 원인 출력) |
| 로그인 방법 꺼짐 · 요청 과다 · 이용 제한 · 기기 미지원 | Supabase 오류 코드 | 각각 안내 |

그 밖에: 카카오톡 로그인이 안 되면(카카오톡 로그아웃 상태 등) 카카오계정 로그인으로 자동 전환(취소는 제외), 로그인 버튼 연타 방지, 로그아웃은 인터넷이 없어도 기기에서는 항상 완료, 닉네임 저장 · 카카오 연결 끊기 실패는 로그인 · 탈퇴 결과에 영향 없음.

## 8. 로그인 버튼 규격

| | 카카오 (디자인 가이드) | Apple (HIG) |
| --- | --- | --- |
| 배경 · 글자 | #FEE500 · 검정 85% | 검정 · 흰색 (sign_in_with_apple 패키지가 Apple 로고 · 서체로 그림) |
| 문구 | 카카오 로그인 | Apple로 로그인 |
| 서체 | OS 기본 서체 (앱 글꼴 미사용) | 시스템 서체 |
| 크기 | 높이 52, 모서리 12, 꽉 찬 너비 | 카카오와 똑같이 (Apple: 다른 로그인 버튼보다 작거나 덜 눈에 띄면 안 됨) |
| 심볼 | 말풍선 (직접 그림, 공식 리소스 이미지로 교체 가능) | Apple 로고 |
