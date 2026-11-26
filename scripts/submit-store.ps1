# 스토어 제출 스크립트: TestFlight에서 확인한 버전으로 App Store 심사 제출 · Google Play 업로드를 시작한다.
#
#   사용법: .\scripts\submit-store.ps1 1.2.1                    # iOS만 (Google Play 준비 전 기본값)
#           .\scripts\submit-store.ps1 1.2.1 -Platform all      # iOS + Android
#           .\scripts\submit-store.ps1 1.2.1 -Platform android
#
# 하는 일: v<버전> 태그와 같은 커밋에 store 태그를 달아 push한다. → Codemagic이 태그를 보고 빌드 · 제출
#   store-v1.2.1          → iOS + Android
#   store-ios-v1.2.1      → iOS만
#   store-android-v1.2.1  → Android만
#   - iOS: App Store 심사 제출 (통과해도 자동 출시 안 함. App Store Connect에서 "이 버전 출시")
#   - Android: Google Play 내부 테스트 트랙에 초안 (Play Console에서 프로덕션으로 승격 · 출시)
#
# release.ps1과 똑같이 "태그 push"로 시작하므로 Codemagic 토큰 같은 따로 준비할 것이 없다.
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [ValidateSet('ios', 'android', 'all')][string]$Platform = 'ios'
)
$ErrorActionPreference = 'Stop'

function Assert-LastExit([string]$what) {
    if ($LASTEXITCODE -ne 0) { throw "$what 실패 (exit $LASTEXITCODE)" }
}

if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "버전은 1.2.3 형식으로 입력하세요. 입력값: $Version" }
$releaseTag = "v$Version"
$storeTag = switch ($Platform) {
    'ios' { "store-ios-v$Version" }
    'android' { "store-android-v$Version" }
    default { "store-v$Version" }
}

Set-Location (Split-Path $PSScriptRoot -Parent)
git fetch --tags -q; Assert-LastExit '태그 가져오기'
if (-not (git tag -l $releaseTag)) {
    throw "$releaseTag 태그가 없습니다. 먼저 .\scripts\release.ps1 $Version 으로 배포해 TestFlight에서 확인하세요."
}
if (git tag -l $storeTag) {
    throw "$storeTag 태그가 이미 있습니다. 이미 제출한 버전입니다. 다시 하려면 Codemagic 화면에서 그 빌드를 다시 실행하세요."
}

# TestFlight로 확인한 바로 그 커밋에 store 태그를 단다.
$commit = git rev-list -n 1 $releaseTag; Assert-LastExit '커밋 찾기'
git tag -a $storeTag $commit -m "스토어 제출 $releaseTag ($Platform)"; Assert-LastExit '태그 생성'
git push origin $storeTag; Assert-LastExit '태그 push'

Write-Host ""
Write-Host "스토어 제출 시작: $storeTag ($releaseTag 와 같은 코드)"
Write-Host '  진행 상황: https://codemagic.io/apps'
if ($Platform -ne 'android') {
    Write-Host '  iOS    : 빌드 성공 → 심사 대기(보통 1~2일) → 통과 메일 → App Store Connect에서 "이 버전 출시"'
}
if ($Platform -ne 'ios') {
    Write-Host '  Android: Play Console → 테스트 및 출시 → 내부 테스트의 초안 확인 → 프로덕션으로 승격 → 검토 후 출시'
}
