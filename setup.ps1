# claude-telegram-setup
# 현재 폴더에 대한 텔레그램 봇 설정을 생성합니다.
# 사용: 프로젝트 폴더 안 PowerShell에서 실행.

$ErrorActionPreference = 'Stop'

function Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Err($msg)  { Write-Host "[X] $msg" -ForegroundColor Red }

$channelsDir = Join-Path $env:USERPROFILE ".claude\channels"
$defaultTelegram = Join-Path $channelsDir "telegram"

Write-Host ""
Info "claude-telegram-setup"
Info "현재 폴더: $((Get-Location).Path)"
Write-Host ""

$defaultName = Split-Path (Get-Location).Path -Leaf
$projectName = Read-Host "프로젝트 이름 [$defaultName]"
if ([string]::IsNullOrWhiteSpace($projectName)) { $projectName = $defaultName }

$safeName = $projectName -replace '[^a-zA-Z0-9_-]', '-'
if ($safeName -ne $projectName) {
    Warn "이름에 특수문자가 있어 '$safeName'으로 변환했어요"
    $projectName = $safeName
}

$stateDir = Join-Path $channelsDir "telegram-$projectName"

if (Test-Path $stateDir) {
    Warn "'$stateDir' 이미 있어요"
    $overwrite = Read-Host "덮어쓸까요? [y/N]"
    if ($overwrite -notmatch '^[yY]') {
        Write-Host "취소됨"
        exit 1
    }
}

$chatId = $null
$existingAccess = Join-Path $defaultTelegram "access.json"
if (Test-Path $existingAccess) {
    try {
        $existing = Get-Content $existingAccess -Raw | ConvertFrom-Json
        if ($existing.allowFrom -and $existing.allowFrom.Count -gt 0) {
            $chatId = $existing.allowFrom[0]
        }
    } catch { }
}

if ($chatId) {
    Info "기존 텔레그램 설정에서 chat_id 발견: $chatId"
    $useExisting = Read-Host "그대로 사용할까요? [Y/n]"
    if ($useExisting -match '^[nN]') { $chatId = $null }
}

if (-not $chatId) {
    $chatId = Read-Host "본인 텔레그램 chat_id (숫자)"
}

if ($chatId -notmatch '^\d+$') {
    Err "chat_id는 숫자여야 해요: $chatId"
    exit 1
}

Write-Host ""
Info "BotFather에서 받은 봇 토큰을 붙여넣으세요"
$tokenSecure = Read-Host "봇 토큰" -AsSecureString
$botToken = [System.Net.NetworkCredential]::new('', $tokenSecure).Password

if ([string]::IsNullOrWhiteSpace($botToken)) {
    Err "토큰이 비어있어요"
    exit 1
}

if ($botToken -notmatch '^\d+:[A-Za-z0-9_-]+$') {
    Warn "토큰 형식이 평소와 달라요 (예상: 숫자:문자열)"
    $confirm = Read-Host "그래도 진행할까요? [y/N]"
    if ($confirm -notmatch '^[yY]') {
        Write-Host "취소됨"
        exit 1
    }
}

New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

$envFile = Join-Path $stateDir ".env"
"TELEGRAM_BOT_TOKEN=$botToken" | Out-File -FilePath $envFile -Encoding utf8 -NoNewline

$accessObj = [ordered]@{
    dmPolicy  = "pairing"
    allowFrom = @($chatId)
    groups    = @{}
    pending   = @{}
}
$accessJson = $accessObj | ConvertTo-Json -Depth 4
$accessJson | Out-File -FilePath (Join-Path $stateDir "access.json") -Encoding utf8

$markerPath = Join-Path (Get-Location).Path ".tgbot"
$projectName | Out-File -FilePath $markerPath -Encoding utf8 -NoNewline

$profilePath = $PROFILE.CurrentUserAllHosts
$wrapperInstalled = $false
if (Test-Path $profilePath) {
    if (Select-String -Path $profilePath -Pattern "claude-telegram-setup-wrapper" -Quiet) {
        $wrapperInstalled = $true
    }
}

Write-Host ""
Ok "셋업 완료!"
Write-Host "  봇 폴더: $stateDir"
Write-Host "  마커 파일: $markerPath (프로젝트 이름 = $projectName)"
Write-Host ""
Info "다음 단계:"
Write-Host "  1) 텔레그램에서 새 봇과 채팅 시작 ('/start' 메시지 전송)"
if (-not $wrapperInstalled) {
    Write-Host "  2) (최초 1회) 래퍼 설치:"
    Write-Host "     iwr -useb https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/install.ps1 | iex"
    Write-Host "  3) PowerShell 새로 열거나 '. `$PROFILE.CurrentUserAllHosts' 후 'claude' 실행"
} else {
    Write-Host "  2) 'claude' 입력 → 텔레그램 연결됨"
}
