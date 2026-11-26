# Codemagic REST API 도우미 (release.ps1 · submit-store.ps1이 함께 쓴다)
#
# 토큰으로 빌드를 시작하고, 끝날 때까지 기다려 결과(성공 · 실패)를 터미널에 알려 준다.
# → Codemagic 사이트에 들어가 확인하지 않아도 된다.
#
# 토큰이 이 PC에 없으면 처음 배포할 때 스크립트가 물어보고 저장한다. (PC가 바뀌어도 붙여 넣기 한 번)
# 직접 등록하려면 (내 PC 사용자 환경 변수. 저장소 · 채팅에는 올리지 않는다):
#   1. Codemagic → Settings 또는 Account settings → "Codemagic API" / "API token" → Show → 토큰 복사
#   2. Codemagic 앱 화면 주소 https://codemagic.io/app/<앱 ID> 에서 앱 ID 복사
#   3. PowerShell:
#        [Environment]::SetEnvironmentVariable('CODEMAGIC_TOKEN', '<토큰>', 'User')
#        [Environment]::SetEnvironmentVariable('CODEMAGIC_APP_ID', '<앱 ID>', 'User')
#      (새 PowerShell 창부터 적용)
#
# API: https://codemagic.io/api/v3 (헤더 x-auth-token)
#   빌드 시작  POST /apps/{app_id}/builds   { workflow_id, tag }  → data.id
#   빌드 상태  GET  /builds/{build_id}                            → data.status

$script:CodemagicApi = 'https://codemagic.io/api/v3'
$script:CodemagicDone = @('finished', 'failed', 'canceled', 'timeout', 'skipped')

# 토큰 · 앱 ID를 읽는다. 이 PC에 없으면 그 자리에서 물어보고 저장한다. (PC가 바뀌어도 첫 배포 때 붙여 넣기 한 번)
# 토큰은 Codemagic에서 언제든 다시 볼 수 있으니 따로 보관하지 않아도 된다.
function Get-CodemagicConfig {
    $token = [Environment]::GetEnvironmentVariable('CODEMAGIC_TOKEN', 'User')
    $appId = [Environment]::GetEnvironmentVariable('CODEMAGIC_APP_ID', 'User')
    $asked = $false

    if (-not $token) {
        Write-Host ''
        Write-Host '이 PC에 Codemagic 토큰이 없습니다. (처음 한 번만 물어봅니다)'
        Write-Host '  Codemagic → Settings 또는 Account settings → "Codemagic API" / "API token" → Show → 복사'
        $secure = Read-Host '  토큰을 붙여 넣으세요 (화면에는 안 보여요)' -AsSecureString
        $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
        $asked = $true
    }
    if (-not $appId) {
        Write-Host '  Codemagic → Applications → maeum_book을 연 뒤 주소창 https://codemagic.io/app/<앱 ID>/... 의 <앱 ID>'
        $appId = (Read-Host '  앱 ID를 붙여 넣으세요').Trim()
        $asked = $true
    }
    $token = "$token".Trim()
    if (-not $token -or -not $appId) { throw 'Codemagic 토큰 · 앱 ID가 비어 있어 멈춥니다. (아무것도 바꾸지 않았습니다)' }

    $config = @{ Token = $token; AppId = $appId }
    Test-CodemagicConfig $config

    if ($asked) {
        # 이 PC의 사용자 환경 변수로 저장 (저장소에는 들어가지 않는다)
        [Environment]::SetEnvironmentVariable('CODEMAGIC_TOKEN', $token, 'User')
        [Environment]::SetEnvironmentVariable('CODEMAGIC_APP_ID', $appId, 'User')
        Write-Host '  확인했어요. 이 PC에 저장했으니 다음부터는 묻지 않아요.'
    }
    return $config
}

# 토큰 · 앱 ID가 맞는지 배포를 시작하기 **전에** 확인한다. (틀리면 버전 올리기 · 태그 전에 멈춘다)
function Test-CodemagicConfig($config) {
    try {
        $null = Invoke-RestMethod -Uri "https://api.codemagic.io/apps/$($config.AppId)" -Headers @{ 'x-auth-token' = $config.Token }
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 401 -or $code -eq 403) {
            [Environment]::SetEnvironmentVariable('CODEMAGIC_TOKEN', $null, 'User')
            throw 'Codemagic 토큰이 맞지 않습니다. 저장된 토큰을 지웠으니 다시 실행해서 새로 붙여 넣으세요. (아무것도 바꾸지 않았습니다)'
        }
        if ($code -eq 404) {
            [Environment]::SetEnvironmentVariable('CODEMAGIC_APP_ID', $null, 'User')
            throw 'Codemagic 앱 ID를 찾지 못했습니다. 저장된 앱 ID를 지웠으니 다시 실행해서 새로 붙여 넣으세요. (아무것도 바꾸지 않았습니다)'
        }
        Write-Warning "Codemagic 확인 요청이 실패했지만(인터넷 · 서버 문제일 수 있음) 계속 진행합니다: $($_.Exception.Message)"
    }
}

# 응답 JSON에서 첫 번째로 값이 있는 경로를 고른다. (API 응답 모양이 바뀌어도 조금은 버티게)
function Select-First($object, [string[]]$paths) {
    foreach ($path in $paths) {
        $value = $object
        foreach ($part in $path.Split('.')) {
            if ($null -eq $value) { break }
            $value = $value.$part
        }
        if ($value) { return $value }
    }
    return $null
}

function Start-CodemagicBuild($config, [string]$workflow, [string]$tag) {
    $body = @{ workflow_id = $workflow; tag = $tag } | ConvertTo-Json
    $response = Invoke-RestMethod -Method Post -Uri "$script:CodemagicApi/apps/$($config.AppId)/builds" `
        -Headers @{ 'x-auth-token' = $config.Token } -ContentType 'application/json' -Body $body
    $id = Select-First $response @('data.id', 'data._id', 'buildId', 'id', '_id')
    if (-not $id) { throw "빌드를 시작했지만 빌드 번호를 응답에서 찾지 못했습니다: $($response | ConvertTo-Json -Depth 5 -Compress)" }
    Write-Host "  $workflow 시작 → https://codemagic.io/app/$($config.AppId)/build/$id"
    return @{ Workflow = $workflow; Id = $id }
}

# 빌드들이 모두 끝날 때까지 30초마다 상태를 보고, 바뀔 때만 한 줄씩 알린다. 모두 성공하면 $true.
function Wait-CodemagicBuilds($config, $builds, [int]$timeoutMinutes = 90) {
    $deadline = (Get-Date).AddMinutes($timeoutMinutes)
    $last = @{}
    $result = @{}
    while ($result.Count -lt $builds.Count) {
        if ((Get-Date) -gt $deadline) {
            Write-Warning "$timeoutMinutes 분이 지나도 끝나지 않아 기다리기를 멈춥니다. Codemagic 화면에서 확인하세요."
            return $false
        }
        foreach ($build in $builds) {
            if ($result.ContainsKey($build.Id)) { continue }
            try {
                $response = Invoke-RestMethod -Uri "$script:CodemagicApi/builds/$($build.Id)" -Headers @{ 'x-auth-token' = $config.Token }
                $status = Select-First $response @('data.status', 'status', 'build.status')
            } catch {
                $status = 'initializing' # 시작 직후에는 잠깐 404가 날 수 있다.
            }
            if ($status -and $last[$build.Id] -ne $status) {
                Write-Host ("  [{0:HH:mm}] {1}: {2}" -f (Get-Date), $build.Workflow, $status)
                $last[$build.Id] = $status
            }
            if ($script:CodemagicDone -contains $status) { $result[$build.Id] = $status }
        }
        if ($result.Count -lt $builds.Count) { Start-Sleep -Seconds 30 }
    }
    $ok = @($result.Values | Where-Object { $_ -ne 'finished' }).Count -eq 0
    foreach ($build in $builds) {
        $mark = if ($result[$build.Id] -eq 'finished') { '성공' } else { "실패 ($($result[$build.Id]))" }
        Write-Host "  $($build.Workflow): $mark → https://codemagic.io/app/$($config.AppId)/build/$($build.Id)"
    }
    return $ok
}
