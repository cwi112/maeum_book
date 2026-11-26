# 스토어 제출 스크립트: 이미 배포한 버전(v 태그)으로 App Store 심사 제출 · Google Play 업로드를 시작한다.
#
#   사용법: .\scripts\submit-store.ps1 1.2.1              # iOS + Android
#           .\scripts\submit-store.ps1 1.2.1 -Platform ios
#           .\scripts\submit-store.ps1 1.2.1 -Platform android
#
# 흐름: release.ps1로 TestFlight에서 확인한 버전 → 이 스크립트 → Codemagic이 같은 태그로 빌드해서
#   - iOS: App Store 심사 제출 (통과해도 자동 출시 안 함. App Store Connect에서 "이 버전 출시")
#   - Android: Google Play 내부 테스트 트랙에 초안 (Play Console에서 프로덕션으로 승격 · 출시)
#
# 처음 한 번 (docs/STORE_RELEASE.md):
#   Codemagic → User settings → Integrations → Codemagic API → 토큰 복사
#   Codemagic 앱 화면 주소 https://codemagic.io/app/<앱 ID> 에서 앱 ID 복사
#   PowerShell에서 (내 PC 사용자 환경 변수로 저장. 저장소에는 올리지 않는다)
#     [Environment]::SetEnvironmentVariable('CODEMAGIC_TOKEN', '<토큰>', 'User')
#     [Environment]::SetEnvironmentVariable('CODEMAGIC_APP_ID', '<앱 ID>', 'User')
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [ValidateSet('all', 'ios', 'android')][string]$Platform = 'all'
)
$ErrorActionPreference = 'Stop'

if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "버전은 1.2.3 형식으로 입력하세요. 입력값: $Version" }
$tag = "v$Version"

$token = [Environment]::GetEnvironmentVariable('CODEMAGIC_TOKEN', 'User')
$appId = [Environment]::GetEnvironmentVariable('CODEMAGIC_APP_ID', 'User')
if (-not $token -or -not $appId) {
    throw 'CODEMAGIC_TOKEN · CODEMAGIC_APP_ID 환경 변수가 없습니다. 스크립트 맨 위 설명대로 한 번 설정하세요.'
}

Set-Location (Split-Path $PSScriptRoot -Parent)
git fetch --tags -q
if (-not (git tag -l $tag)) { throw "$tag 태그가 없습니다. 먼저 .\scripts\release.ps1 $Version 으로 배포(TestFlight)하세요." }

$workflows = switch ($Platform) {
    'ios' { @('ios-appstore') }
    'android' { @('android-play') }
    default { @('ios-appstore', 'android-play') }
}

foreach ($workflow in $workflows) {
    $body = @{ appId = $appId; workflowId = $workflow; tag = $tag } | ConvertTo-Json
    $response = Invoke-RestMethod -Method Post -Uri 'https://api.codemagic.io/builds' `
        -Headers @{ 'x-auth-token' = $token } -ContentType 'application/json' -Body $body
    Write-Host "$workflow 시작: https://codemagic.io/app/$appId/build/$($response.buildId)"
}

Write-Host ''
Write-Host '다음 할 일'
if ($workflows -contains 'ios-appstore') {
    Write-Host '  iOS    : 빌드 성공 → 심사 대기(보통 1~2일) → 통과 메일 → App Store Connect에서 "이 버전 출시"'
}
if ($workflows -contains 'android-play') {
    Write-Host '  Android: Play Console → 테스트 및 출시 → 내부 테스트의 초안 확인 → 프로덕션으로 승격 → 검토 후 출시'
}
