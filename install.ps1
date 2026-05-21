# claude-telegram-setup 래퍼 1회 설치 (Windows / PowerShell)
$ErrorActionPreference = 'Stop'

$wrapperUrl = if ($env:WRAPPER_URL) { $env:WRAPPER_URL } else {
    "https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/wrappers/powershell-wrapper.ps1"
}

$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

if (Test-Path $profilePath) {
    if (Select-String -Path $profilePath -Pattern "claude-telegram-setup-wrapper" -Quiet) {
        Write-Host "[OK] 래퍼가 이미 설치되어 있어요 ($profilePath)" -ForegroundColor Green
        exit 0
    }
}

Write-Host "다운로드: $wrapperUrl"
$content = (Invoke-WebRequest -UseBasicParsing -Uri $wrapperUrl).Content

$header = "`n# === claude-telegram-setup wrapper (added $(Get-Date -Format 'yyyy-MM-dd')) ===`n"
Add-Content -Path $profilePath -Value $header -Encoding utf8
Add-Content -Path $profilePath -Value $content -Encoding utf8

Write-Host "[OK] 래퍼 설치됨: $profilePath" -ForegroundColor Green
Write-Host ""
Write-Host "지금 적용하려면:"
Write-Host "  . `$PROFILE.CurrentUserAllHosts"
Write-Host "또는 PowerShell 새로 열기"
