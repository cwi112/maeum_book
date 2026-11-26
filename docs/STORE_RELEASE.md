# 스토어 출시 가이드

한 번 설정해 두면 이후 업데이트는 **명령 두 줄**로 끝난다.

```powershell
.\scripts\release.ps1 1.3.0        # 1) TestFlight로 배포 → 테스터 확인
.\scripts\submit-store.ps1 1.3.0   # 2) 확인한 버전을 App Store 심사 제출 (Google Play 준비 후엔 -Platform all)
```

```
release.ps1 ──▶ v1.3.0 태그 ──▶ (API) Codemagic ios-testflight ──▶ 끝날 때까지 기다려 결과 표시 ──▶ TestFlight
                                      │ 같은 태그(같은 코드)
submit-store.ps1 ──▶ (API) Codemagic ios-appstore ──▶ 결과 표시 ──▶ App Store 심사 ──▶ 통과 ──▶ [이 버전 출시] (사람)
                 └─▶ (-Platform all) android-play ──▶ 결과 표시 ──▶ Play 내부 테스트 초안 ──▶ [프로덕션 승격] (사람)
```

두 스크립트 모두 **Codemagic API 토큰**으로 빌드를 시작하고, **끝날 때까지 기다려 성공 · 실패를 터미널에 알려 준다.**
Codemagic 사이트에 들어가 확인할 필요가 없고, 실패하면 로그 링크가 바로 나온다.

### Codemagic 토큰 (PC마다 첫 배포 때 한 번)
따로 준비할 것은 없다. 이 PC에 토큰이 없으면 스크립트가 **그 자리에서 물어보고** 이 PC에 저장한다.
- 토큰: Codemagic → Settings 또는 Account settings → **Codemagic API** / **API token** → Show → 복사
- 앱 ID: Codemagic → Applications → maeum_book을 연 뒤 주소 `https://codemagic.io/app/<앱 ID>/...`의 24자리
- 토큰은 Codemagic에서 언제든 다시 볼 수 있으니 따로 보관하지 않아도 된다. 유출이 걱정되면 Codemagic에서 새로 발급한다.
- 붙여 넣은 값은 **배포를 시작하기 전에** 맞는지 확인한다. 틀리면 아무것도 바꾸지 않고 멈추며, 다시 실행하면 새로 묻는다.
- 저장 위치: 이 PC의 사용자 환경 변수 `CODEMAGIC_TOKEN` · `CODEMAGIC_APP_ID` (저장소 · 채팅에는 올리지 않는다)

**마지막 출시 버튼은 일부러 사람이 누르게 했다.** 심사를 통과해도 바로 모든 사용자에게 나가지 않는다.

---

## 최소 지원 버전

| | 최소 | 이유 |
|---|---|---|
| iOS | **15.0** | 사진 선택(image_picker)이 15.0 이상 필요. 아이폰 6s · SE(1세대) 이후 모든 기종이 iOS 15를 지원 |
| Android | **7.0 (SDK 24)** | 카카오 로그인 SDK · 사진 선택이 24 이상 필요. `android/app/build.gradle.kts`에 고정 |

---

## 처음 한 번: App Store (iOS)

### 1. App Store Connect 앱 정보 (웹에서 직접)
| 칸 | 넣을 것 |
|---|---|
| 이름 · 부제 · 설명 · 키워드 · 프로모션 텍스트 | `docs/STORE_LISTING.md` |
| 스크린샷 | `store_assets/ios_iphone_6.9` (6.9형), `ios_iphone_6.5` (6.5형), `ios_ipad_13` (13형 iPad) — 01 ~ 06 순서대로 |
| 개인정보 처리방침 URL | `https://github.com/cwi112/maeum_book/blob/main/docs/PRIVACY_POLICY.md` (먼저 문서의 [ ] 두 곳을 채운다) |
| 지원 URL | `https://github.com/cwi112/maeum_book` 또는 문의용 페이지 |
| 카테고리 | 금융 (보조: 라이프스타일) |
| 연령 등급 | 모든 질문 "없음" → 4+ |
| 가격 | 무료 |
| 저작권 | `2026 <이름>` |

### 2. 앱 개인정보 (App Privacy) 설문
| 질문 | 답 |
|---|---|
| 데이터 수집 여부 | 예 |
| 연락처 정보 › 이름 · 이메일 | 수집함 · 앱 기능 · 사용자와 연결됨 · 추적 안 함 |
| 사용자 콘텐츠 › 사진 · 기타 사용자 콘텐츠 | 수집함 · 앱 기능 · 사용자와 연결됨 · 추적 안 함 |
| 식별자 › 사용자 ID | 수집함 · 앱 기능 · 사용자와 연결됨 · 추적 안 함 |
| 추적(Tracking) | 하지 않음 |

### 3. 심사 정보 (App Review Information)
- 로그인 필요 여부: **아니요** (로그인 없이 시작하기로 모든 기능 사용 가능)
- 메모 예시:
  ```
  로그인 없이 시작하기로 모든 기록 기능을 확인할 수 있습니다.
  설정 › 샘플 데이터로 둘러보기를 누르면 예시 기록 · 통계 · 엑셀 내보내기를 바로 볼 수 있습니다.
  카카오 · Apple 로그인은 여러 기기 간 장부 동기화용이며, 설정 › 계정 › 탈퇴하기에서 계정과 데이터를 삭제할 수 있습니다.
  ```

### 4. 첫 제출은 웹에서 직접
첫 버전은 위 항목이 다 채워져야 제출된다. App Store Connect → iOS 앱 → 버전 → 빌드 선택(TestFlight에서 확인한 빌드) → 심사에 제출.
**두 번째 업데이트부터 `submit-store.ps1`을 쓴다.**

### 5. Codemagic 변수 하나 (빌드 번호 자동)
`codemagic.yaml`의 `# vars:` · `#   APP_STORE_APPLE_ID:` 두 줄의 `#`을 지우고 App Store Connect → 앱 정보 → **Apple ID**(숫자)를 넣는다. **빈칸("")으로 두면 Codemagic이 설정 파일 전체를 거부한다.**
비워 둬도 동작하지만, 채워 두면 TestFlight와 스토어 제출이 같은 버전을 빌드해도 번호가 겹치지 않는다.

---

## 처음 한 번: Google Play (Android)

1. **Play Console 개발자 계정** (1회 $25) → 앱 만들기 (`com.maeumbook.maeum_book`)
2. **스토어 등록정보**: `docs/STORE_LISTING.md`의 Google Play 칸, 그래픽 이미지 `store_assets/android_feature_graphic.png`, 휴대전화 스크린샷 `store_assets/android_phone/`
3. **앱 콘텐츠**: 개인정보처리방침 URL(위와 같음), 광고 없음, 데이터 보안 설문(위 App Privacy와 같은 내용 + "전송 중 암호화됨" · "삭제 요청 가능"), 콘텐츠 등급 설문, 타깃 연령 18세 이상
4. **업로드 키를 Codemagic에**: Codemagic → Code signing identities → Android keystores → `C:\Users\dnjsd\keys\maeum_book`의 키 파일 · 비밀번호 · 별칭, 이름 **maeum_book_upload**
5. **첫 AAB는 직접 업로드**: Google Play는 API로 올리기 전에 한 번은 웹에서 올려야 한다.
   - `.\scripts\submit-store.ps1 <버전> -Platform android`로 빌드하면 업로드 단계만 실패하고 AAB 파일은 Codemagic 결과물로 남는다 → 내려받아 Play Console → 내부 테스트 → 새 버전에 올린다.
6. **서비스 계정 (자동 업로드용)**: Google Cloud → 서비스 계정 만들기 → JSON 키 → Play Console → 사용자 및 권한 → 그 계정 초대(출시 권한) → Codemagic → 환경 변수 그룹 **google_play**에 `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` = JSON 내용 (Secure 체크)

**두 번째 업데이트부터 `submit-store.ps1`이 내부 테스트 트랙에 초안으로 올린다.** Play Console에서 프로덕션으로 승격해 출시한다.

---


## 출시 전 마지막 점검

- [ ] 서버: Supabase 무료 프로젝트 일시 정지 대책 (`docs/SERVER_CAPACITY.md` 3번) — 실제 사용자가 생기면 Pro 권장
- [ ] 개인정보 처리방침의 [ ] 두 곳 채우기 (서버 리전 · 문의 이메일)
- [ ] 카카오 개발자 콘솔: 앱 상태 "운영" 전환, 개인정보 동의 항목 검수(이메일을 받는다면)
- [ ] Apple: Sign in with Apple 기능이 App ID에 켜져 있는지 (이미 TestFlight에서 동작 중)
- [ ] TestFlight에서 회원 · 비회원 각각 기록 · 사진 · 엑셀 · 로그아웃 · 탈퇴 한 번씩
