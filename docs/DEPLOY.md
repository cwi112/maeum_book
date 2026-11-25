# 배포 파이프라인

> 현재 상태: iOS(Codemagic → TestFlight) 사용 중. CI와 Android 릴리스(GitHub Actions)는 준비 중 — 워크플로 파일을 올리려면 `gh auth refresh -h github.com -s workflow`로 gh 권한을 먼저 추가해야 한다.

```
feature 브랜치 ──PR──▶ CI(분석·테스트) ──통과──▶ main 병합
                                                   │
                           .\scripts\release.ps1 1.0.1
                                                   │
                  pubspec 버전 올림 → PR → CI → 병합 → 태그 v1.0.1 push
                                                   │
                 ┌─────────────────────────────────┴──────────────────────────────┐
                 ▼                                                                ▼
   GitHub Actions (release-android.yml)                        Codemagic (codemagic.yaml)
   테스트 → 서명된 APK → GitHub Release                         테스트 → IPA → TestFlight
                 ▼                                                                ▼
   폰에서 Releases 페이지의 APK를 받아 설치                      iPhone TestFlight 앱에서 업데이트
```

| 단계 | 언제 | 어디서 | 설정 파일 |
|---|---|---|---|
| CI | PR 생성·수정, main push | GitHub Actions | `.github/workflows/ci.yml` |
| Android 배포 | `v*` 태그 push | GitHub Actions | `.github/workflows/release-android.yml` |
| iOS 배포 | `v*` 태그 push (수동 실행도 가능) | Codemagic | `codemagic.yaml` |

## 새 버전 배포하기

main에 원하는 변경이 모두 병합된 상태에서:

```powershell
.\scripts\release.ps1 1.0.1
```

- 버전 규칙: `주.부.수` — 버그 수정은 마지막 자리(1.0.**1**), 기능 추가는 가운데(1.**1**.0), 큰 개편은 앞자리(**2**.0.0)
- 빌드 번호(`pubspec.yaml`의 `+` 뒤 숫자)는 스크립트가 매번 자동으로 1씩 올린다. 손으로 고치지 않는다.
  Android·iOS 모두 빌드 번호가 이전보다 커야 업데이트로 인식된다.
- 배포가 끝나면
  - Android: GitHub 저장소 → **Releases** → 해당 버전의 `maeum_book-v1.0.1.apk`
  - iOS: Codemagic 빌드 성공 후 5~30분 뒤 TestFlight 앱에 새 빌드

### 실패했을 때

- **CI 실패**: 스크립트가 멈춘다. 고친 뒤 `release/v1.0.1` 브랜치에 push → CI 통과 확인 → 병합 → 태그를 직접 push
  (`git tag -a v1.0.1 -m "릴리스 v1.0.1"; git push origin v1.0.1`)
- **태그를 push했는데 Codemagic 빌드가 안 생김**: 웹훅이 없는 것. 아래 iOS 설정 8번을 한 뒤, 이미 올린 태그는 수동 실행한다.
- **Android/iOS 빌드만 실패**: 원인을 고쳐 main에 병합하고 **새 버전**(예: 1.0.2)으로 다시 배포한다.
  같은 태그를 지우고 다시 쓰지 않는다.

## 처음 한 번만 하는 설정

### Android 서명 키

- 키 위치: `C:\Users\dnjsd\keys\maeum_book\` (`upload-keystore.jks`, `key.properties`) — **저장소 밖, 반드시 별도 백업**
  키를 잃어버리면 같은 앱으로 업데이트를 낼 수 없다(삭제 후 재설치만 가능).
- 로컬 빌드: `android/key.properties`(깃 제외)가 이 키를 가리킨다. 없으면 디버그 키로 서명된다.
- GitHub Secrets (저장소 Settings → Secrets and variables → Actions):

  | 이름 | 값 |
  |---|---|
  | `ANDROID_KEYSTORE_BASE64` | `upload-keystore.jks`를 base64로 바꾼 문자열 |
  | `ANDROID_KEYSTORE_PASSWORD` | `key.properties`의 `storePassword` |
  | `ANDROID_KEY_ALIAS` | `upload` |

  PowerShell에서 한 번에 등록:

  ```powershell
  $dir = "C:\Users\dnjsd\keys\maeum_book"
  $props = Get-Content "$dir\key.properties" | ConvertFrom-StringData
  [Convert]::ToBase64String([IO.File]::ReadAllBytes("$dir\upload-keystore.jks")) | gh secret set ANDROID_KEYSTORE_BASE64
  $props.storePassword | gh secret set ANDROID_KEYSTORE_PASSWORD
  "upload" | gh secret set ANDROID_KEY_ALIAS
  ```

### iOS (Codemagic)

1. Apple Developer: Identifiers에 번들 ID `com.maeumbook.maeumBook` 등록
2. App Store Connect: 신규 앱 생성, 사용자 및 액세스 → 통합 → App Store Connect API → 팀 키 생성(App Manager)
3. Codemagic: GitHub로 가입 → 저장소 추가 → Personal Account → Settings → Integrations → Developer Portal에
   키 이름 **`maeum_book_asc`** 로 Issuer ID / Key ID / `.p8` 등록
4. 배포 인증서: Codemagic → Code signing identities → **iOS certificates** → Generate certificate
   (API 키 `maeum_book_asc`, 종류 **Apple Distribution**). 인증서 파일·비밀번호는 키 폴더에 백업
5. 프로비저닝 프로파일: Apple Developer → Profiles → + → Distribution **App Store Connect** →
   App ID `com.maeumbook.maeumBook` → 4번 인증서 선택 → 이름 `MaeumBook AppStore` → Generate
6. Codemagic → Code signing identities → **iOS provisioning profiles** → Fetch profiles →
   `MaeumBook AppStore` 선택, reference name `maeum_appstore`로 저장
7. App Store Connect → TestFlight → 내부 테스트 그룹을 만들고 본인을 테스터로 추가
8. Codemagic → 앱 `maeum_book` → 설정(톱니바퀴) → **Webhooks** → **Update webhook**
   → GitHub 저장소 Settings → Webhooks에 `api.codemagic.io/hooks/...`가 생긴다.
   이게 없으면 태그를 push해도 Codemagic이 알지 못해 빌드가 자동으로 시작되지 않는다.
   (확인: `gh api repos/cwi112/maeum_book/hooks --jq '.[].config.url'`)
   웹훅이 없을 때 이미 push한 태그는 Codemagic → Start new build → **Build tag**에서 태그를 골라 수동 실행한다.

`codemagic.yaml`의 `ios_signing`은 6번에서 가져온 프로파일을 번들 ID·배포 종류로 찾아 쓴다.
4~6번을 빠뜨리면 빌드가 `No matching profiles found for bundle identifier ...`로 실패한다.
인증서는 1년마다 만료되므로, 만료되면 4~6번을 다시 한다.
