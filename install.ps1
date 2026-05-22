# claude-telegram-setup 1회 설치 (Windows / PowerShell)
# - claude plugin marketplace 등록
# - telegram 플러그인 설치
# - 폴더별 봇 자동 선택 PowerShell 래퍼 등록
$ErrorActionPreference = 'Stop'

function Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Err($msg)  { Write-Host "[X] $msg" -ForegroundColor Red }

$wrapperUrl = if ($env:WRAPPER_URL) { $env:WRAPPER_URL } else {
    "https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/wrappers/powershell-wrapper.ps1"
}

# === 1. claude CLI 확인 ===
$claudeCmd = Get-Command claude.ps1 -CommandType ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $claudeCmd) {
    $candidates = @("$env:APPDATA\npm\claude.ps1", "$env:USERPROFILE\AppData\Roaming\npm\claude.ps1")
    foreach ($c in $candidates) { if (Test-Path $c) { $claudeCmd = @{ Source = $c }; break } }
}
if (-not $claudeCmd) {
    Err "claude CLI가 설치되어 있지 않아요."
    Err "  npm install -g @anthropic-ai/claude-code"
    exit 1
}
$claudePath = $claudeCmd.Source

# === 2. bun 확인 (텔레그램 플러그인 런타임) ===
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    Warn "bun이 설치돼 있지 않아요 — 텔레그램 플러그인 실행에 필요합니다."
    Info "PowerShell에서 설치:"
    Write-Host "    powershell -c `"irm bun.sh/install.ps1 | iex`""
    Write-Host ""
    Warn "bun 없이도 plugin 등록은 됩니다만, 실제 봇 통신 시 에러가 납니다."
    Write-Host ""
}

# === 3. 마켓플레이스 등록 ===
$mpList = & $claudePath plugin marketplace list 2>&1 | Out-String
if ($mpList -match "claude-plugins-official") {
    Ok "마켓플레이스 이미 등록됨"
} else {
    Info "마켓플레이스 등록 중: anthropics/claude-plugins-official"
    & $claudePath plugin marketplace add anthropics/claude-plugins-official
}

# === 4. telegram 플러그인 설치 ===
$pList = & $claudePath plugin list 2>&1 | Out-String
if ($pList -match "telegram") {
    Ok "telegram 플러그인 이미 설치됨"
} else {
    Info "텔레그램 플러그인 설치 중"
    & $claudePath plugin install telegram@claude-plugins-official
}

# === 5. PowerShell 래퍼 등록 ===
$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

if ((Test-Path $profilePath) -and (Select-String -Path $profilePath -Pattern "claude-telegram-setup-wrapper" -Quiet)) {
    Ok "PowerShell 래퍼 이미 설치됨 ($profilePath)"
} else {
    Info "PowerShell 래퍼 등록 중: $profilePath"
    $content = (Invoke-WebRequest -UseBasicParsing -Uri $wrapperUrl).Content
    $header = "`n# === claude-telegram-setup wrapper (added $(Get-Date -Format 'yyyy-MM-dd')) ===`n"
    Add-Content -Path $profilePath -Value $header -Encoding utf8
    Add-Content -Path $profilePath -Value $content -Encoding utf8
    Ok "PowerShell 래퍼 등록됨: $profilePath"
}

Write-Host ""
Ok "셋업 완료!"
Write-Host ""
Info "다음 단계:"
Write-Host "  1) PowerShell 새로 열거나: . `$PROFILE.CurrentUserAllHosts"
Write-Host "  2) 프로젝트 폴더에서 봇 설정 (각 프로젝트마다 1회):"
Write-Host "     iwr -useb https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/setup.ps1 | iex"
Write-Host "  3) 'claude' 입력 → 텔레그램 연결됨"
