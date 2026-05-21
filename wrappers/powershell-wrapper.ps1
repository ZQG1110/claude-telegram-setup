# claude-telegram-setup-wrapper
# 현재 폴더에 맞는 텔레그램 봇 상태 폴더를 자동으로 선택해줍니다.
# 매칭 우선순위: .tgbot 마커 파일 > 현재 폴더 이름 매칭 > 기본 봇
function claude {
    $dir = (Get-Location).Path
    $name = $null

    $current = $dir
    while ($current) {
        $marker = Join-Path $current ".tgbot"
        if (Test-Path $marker) {
            $name = (Get-Content $marker -TotalCount 1).Trim()
            break
        }
        if ($current -eq $env:USERPROFILE) { break }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }

    if (-not $name) { $name = Split-Path $dir -Leaf }

    $stateDir = Join-Path $env:USERPROFILE ".claude\channels\telegram-$name"
    $envFile = Join-Path $stateDir ".env"

    if ((Test-Path $stateDir) -and (Test-Path $envFile)) {
        $env:TELEGRAM_STATE_DIR = $stateDir
    } else {
        if (Test-Path Env:\TELEGRAM_STATE_DIR) {
            Remove-Item Env:\TELEGRAM_STATE_DIR
        }
    }

    $claudePath = $null
    $candidates = @(
        "$env:APPDATA\npm\claude.ps1",
        "$env:USERPROFILE\AppData\Roaming\npm\claude.ps1"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $claudePath = $c; break }
    }
    if (-not $claudePath) {
        $cmd = Get-Command claude.ps1 -CommandType ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd) { $claudePath = $cmd.Source }
    }
    if (-not $claudePath) {
        Write-Error "claude.ps1을 찾을 수 없어요. 설치: npm install -g @anthropic-ai/claude-code"
        return
    }

    if ($args -contains '--channels') {
        & $claudePath @args
    } else {
        & $claudePath --channels 'plugin:telegram@claude-plugins-official' @args
    }
}
