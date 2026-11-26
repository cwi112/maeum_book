# 새 버전 배포 스크립트
#   사용법: .\scripts\release.ps1 1.0.1
#
# 하는 일:
#   1. main 최신화 → release/v<버전> 브랜치에서 pubspec.yaml 버전을 <버전>+<빌드번호+1>로 올림
#      app_version.json의 latestVersion도 <버전>으로 올림 (앱의 업데이트 확인용)
#   2. PR 생성 → CI 통과 확인 → 병합
#   3. main에 v<버전> 태그 push (배포 기록용)
#   4. Codemagic API로 ios-testflight 빌드 시작 → 끝날 때까지 기다려 성공 · 실패를 알려 줌
#      (Codemagic 토큰 필요: scripts/lib/Codemagic.ps1 맨 위 설명)
param(
    [Parameter(Mandatory = $true)][string]$Version
)
$ErrorActionPreference = 'Stop'

function Assert-LastExit([string]$what) {
    if ($LASTEXITCODE -ne 0) { throw "$what 실패 (exit $LASTEXITCODE)" }
}

if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "버전은 1.2.3 형식으로 입력하세요. 입력값: $Version" }
$tag = "v$Version"

Set-Location (Split-Path $PSScriptRoot -Parent)

. "$PSScriptRoot/lib/Codemagic.ps1"
# 토큰이 없으면 아무것도 바꾸기 전에 여기서 멈춘다.
$codemagic = Get-CodemagicConfig

if (git status --porcelain) { throw "커밋하지 않은 변경이 있습니다. 먼저 정리하세요." }

# TestFlight 문구(release_notes.json) 검사: Apple은 이모지와 < > 를 거부한다(문구 등록만 409로 실패).
$notesPath = Join-Path (Get-Location) 'release_notes.json'
if (Test-Path $notesPath) {
    $notes = [IO.File]::ReadAllText($notesPath)
    $null = $notes | ConvertFrom-Json  # JSON 형식이 깨졌으면 여기서 멈춤
    $bad = [regex]::Matches($notes, '[\uD800-\uDBFF][\uDC00-\uDFFF]|[☀-➿]|[<>]') | ForEach-Object { $_.Value } | Select-Object -Unique
    if ($bad) { throw "release_notes.json에 TestFlight가 거부하는 문자가 있습니다: $($bad -join ' ')  (이모지 · < > 를 빼 주세요)" }
}

git checkout main; Assert-LastExit 'main 체크아웃'
git pull --ff-only; Assert-LastExit 'main 최신화'
git fetch --tags -q; Assert-LastExit '태그 가져오기'
if (git tag -l $tag) { throw "$tag 태그가 이미 있습니다. 다른 버전 번호를 쓰세요." }

# pubspec.yaml 버전 올리기 (빌드 번호는 항상 +1: TestFlight·Android 모두 이전보다 커야 업데이트됨)
$pubspecPath = Join-Path (Get-Location) 'pubspec.yaml'
$pubspec = [IO.File]::ReadAllText($pubspecPath)
$m = [regex]::Match($pubspec, '(?m)^version:[ \t]*(\d+\.\d+\.\d+)\+(\d+)[ \t]*(?=\r?$)')
if (-not $m.Success) { throw "pubspec.yaml에서 version: x.y.z+n 줄을 찾지 못했습니다." }
$oldVersion = $m.Groups[1].Value
$build = [int]$m.Groups[2].Value + 1
$newLine = "version: $Version+$build"
$pubspec = $pubspec.Remove($m.Index, $m.Length).Insert($m.Index, $newLine)
[IO.File]::WriteAllText($pubspecPath, $pubspec, (New-Object System.Text.UTF8Encoding $false))
Write-Host "버전: $oldVersion+$($build - 1) → $Version+$build"

# 앱의 "설정 > 앱 정보"가 읽는 최신 버전 정보도 함께 올린다. (main에 병합되면 앱이 새 버전을 알게 됨)
$versionJsonPath = Join-Path (Get-Location) 'app_version.json'
$versionJson = [IO.File]::ReadAllText($versionJsonPath)
$versionJson = [regex]::Replace($versionJson, '"latestVersion"\s*:\s*"[^"]*"', "`"latestVersion`": `"$Version`"")
[IO.File]::WriteAllText($versionJsonPath, $versionJson, (New-Object System.Text.UTF8Encoding $false))

$branch = "release/$tag"
git checkout -b $branch; Assert-LastExit '브랜치 생성'
git commit -am "릴리스 $tag ($Version+$build)"; Assert-LastExit '커밋'
git push -u origin $branch; Assert-LastExit 'push'

gh pr create --base main --head $branch --title "릴리스 $tag" --body "pubspec 버전을 $Version+$build 로 올립니다. 병합 후 $tag 태그로 Android(GitHub Release)·iOS(TestFlight) 배포가 시작됩니다."
Assert-LastExit 'PR 생성'

Write-Host 'CI 결과를 기다립니다...'
# CI(.github/workflows/ci.yml)가 없는 저장소면 체크가 생기지 않으므로 1분 기다려 보고 건너뛴다.
$hasChecks = $false
for ($i = 0; $i -lt 6; $i++) {
    Start-Sleep -Seconds 10
    $count = (gh pr view $branch --json statusCheckRollup -q '.statusCheckRollup | length')
    if ([int]$count -gt 0) { $hasChecks = $true; break }
}
if ($hasChecks) {
    gh pr checks $branch --watch --fail-fast; Assert-LastExit 'CI'
} else {
    Write-Warning 'CI 체크가 없어 기다리지 않고 진행합니다.'
}

gh pr merge $branch --merge --delete-branch; Assert-LastExit 'PR 병합'
git checkout main; Assert-LastExit 'main 체크아웃'
git pull --ff-only; Assert-LastExit 'main 최신화'

git tag -a $tag -m "릴리스 $tag"; Assert-LastExit '태그 생성'
git push origin $tag; Assert-LastExit '태그 push'

# Codemagic에 iOS 빌드(TestFlight)를 시작하고 끝날 때까지 기다린다. (토큰은 맨 위에서 확인함)
Write-Host ""
Write-Host "배포 시작: $tag ($Version+$build)"
$started = Start-CodemagicBuild $codemagic 'ios-testflight' $tag
Write-Host '  빌드가 끝날 때까지 기다립니다. (보통 15~25분, Ctrl+C로 그만 기다려도 빌드는 계속됨)'
if (Wait-CodemagicBuilds $codemagic @($started)) {
    Write-Host ""
    Write-Host "TestFlight 업로드 완료: Apple 처리 후 5~30분 안에 TestFlight 앱에 $Version ($build) 가 올라옵니다."
    Write-Host "확인이 끝나면 스토어 제출: .\scripts\submit-store.ps1 $Version"
} else {
    throw "iOS 빌드가 실패했습니다. 위 링크에서 로그를 확인하세요. (태그 $tag 는 이미 올라가 있으니 고친 뒤 새 버전으로 배포)"
}
