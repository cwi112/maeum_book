# 스토어 제출 스크립트: TestFlight에서 확인한 버전으로 App Store 심사 제출 · Google Play 업로드를 한다.
#
#   사용법: .\scripts\submit-store.ps1 1.2.1                    # iOS만 (Google Play 준비 전 기본값)
#           .\scripts\submit-store.ps1 1.2.1 -Platform all      # iOS + Android
#           .\scripts\submit-store.ps1 1.2.1 -Platform android
#
# 하는 일: release.ps1이 남긴 v<버전> 태그(= TestFlight로 확인한 바로 그 코드)로 Codemagic 빌드를 시작하고,
#          끝날 때까지 기다려 성공 · 실패를 알려 준다. (Codemagic 토큰 필요: scripts/lib/Codemagic.ps1 맨 위 설명)
#   - iOS (ios-appstore): App Store 심사 제출. 통과해도 자동 출시 안 함 → App Store Connect에서 "이 버전 출시"
#   - Android (android-play): Google Play 내부 테스트 트랙에 초안 → Play Console에서 프로덕션으로 승격 · 출시
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [ValidateSet('ios', 'android', 'all')][string]$Platform = 'ios'
)
$ErrorActionPreference = 'Stop'

if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "버전은 1.2.3 형식으로 입력하세요. 입력값: $Version" }
$tag = "v$Version"

Set-Location (Split-Path $PSScriptRoot -Parent)
. "$PSScriptRoot/lib/Codemagic.ps1"
$codemagic = Get-CodemagicConfig

git fetch --tags -q
if (-not (git tag -l $tag)) {
    throw "$tag 태그가 없습니다. 먼저 .\scripts\release.ps1 $Version 으로 배포해 TestFlight에서 확인하세요."
}

$workflows = switch ($Platform) {
    'ios' { @('ios-appstore') }
    'android' { @('android-play') }
    default { @('ios-appstore', 'android-play') }
}

Write-Host "스토어 제출 시작: $tag"
$builds = @(foreach ($workflow in $workflows) { Start-CodemagicBuild $codemagic $workflow $tag })
Write-Host '  끝날 때까지 기다립니다. (Ctrl+C로 그만 기다려도 빌드는 계속됨)'
$ok = Wait-CodemagicBuilds $codemagic $builds

Write-Host ''
if (-not $ok) { throw '실패한 빌드가 있습니다. 위 링크에서 로그를 확인하세요.' }
Write-Host '다음 할 일'
if ($workflows -contains 'ios-appstore') {
    Write-Host '  iOS    : 심사 대기(보통 1~2일) → 통과 메일 → App Store Connect에서 "이 버전 출시"'
}
if ($workflows -contains 'android-play') {
    Write-Host '  Android: Play Console → 테스트 및 출시 → 내부 테스트의 초안 확인 → 프로덕션으로 승격 → 검토 후 출시'
}
