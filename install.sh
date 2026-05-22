#!/usr/bin/env bash
# claude-telegram-setup 1회 설치 (Mac/Linux)
# - claude plugin marketplace 등록
# - telegram 플러그인 설치
# - 폴더별 봇 자동 선택 셸 래퍼 등록
set -e

if [[ -t 1 ]]; then
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[36m'
  C_RED=$'\033[31m';                          C_RESET=$'\033[0m'
else
  C_GREEN=; C_YELLOW=; C_BLUE=; C_RED=; C_RESET=
fi
info() { printf "%s%s%s\n" "$C_BLUE"  "$*" "$C_RESET"; }
ok()   { printf "%s✓ %s%s\n" "$C_GREEN" "$*" "$C_RESET"; }
warn() { printf "%s⚠ %s%s\n" "$C_YELLOW" "$*" "$C_RESET"; }
err()  { printf "%s✗ %s%s\n" "$C_RED"  "$*" "$C_RESET" >&2; }

WRAPPER_URL="${WRAPPER_URL:-https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/wrappers/zsh-wrapper.sh}"

# === 1. claude CLI 확인 ===
if ! command -v claude >/dev/null 2>&1; then
  err "claude CLI가 설치되어 있지 않아요."
  err "  npm install -g @anthropic-ai/claude-code"
  exit 1
fi

# === 2. bun 확인 (텔레그램 플러그인 런타임) ===
if ! command -v bun >/dev/null 2>&1; then
  warn "bun이 설치돼 있지 않아요 — 텔레그램 플러그인 실행에 필요합니다."
  info "https://bun.sh 에서 설치하거나 아래 명령으로:"
  echo "    curl -fsSL https://bun.sh/install | bash"
  echo ""
  warn "bun 없이도 plugin 등록은 됩니다만, 실제 봇 통신 시 에러가 납니다."
  echo ""
fi

# === 3. 마켓플레이스 등록 ===
if claude plugin marketplace list 2>/dev/null | grep -q "claude-plugins-official"; then
  ok "마켓플레이스 이미 등록됨"
else
  info "마켓플레이스 등록 중: anthropics/claude-plugins-official"
  claude plugin marketplace add anthropics/claude-plugins-official
fi

# === 4. telegram 플러그인 설치 ===
if claude plugin list 2>/dev/null | grep -q "telegram"; then
  ok "telegram 플러그인 이미 설치됨"
else
  info "텔레그램 플러그인 설치 중"
  claude plugin install telegram@claude-plugins-official
fi

# === 5. 셸 래퍼 등록 ===
if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *zsh ]]; then
  RC="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *bash ]]; then
  RC="$HOME/.bashrc"
else
  err "지원되지 않는 셸이에요. ~/.zshrc 또는 ~/.bashrc에 직접 추가해주세요."
  exit 1
fi

if [[ -f "$RC" ]] && grep -q "claude-telegram-setup-wrapper" "$RC"; then
  ok "셸 래퍼 이미 설치됨 ($RC)"
else
  info "셸 래퍼 등록 중: $RC"
  {
    echo ""
    echo "# === claude-telegram-setup wrapper (added $(date +%Y-%m-%d)) ==="
  } >> "$RC"

  if command -v curl >/dev/null; then
    curl -sSL "$WRAPPER_URL" >> "$RC"
  elif command -v wget >/dev/null; then
    wget -qO- "$WRAPPER_URL" >> "$RC"
  else
    err "curl 또는 wget이 필요해요"
    exit 1
  fi
  echo "" >> "$RC"
  ok "셸 래퍼 등록됨: $RC"
fi

echo ""
ok "셋업 완료!"
echo ""
info "다음 단계:"
echo "  1) 새 터미널을 열거나: source $RC"
echo "  2) 프로젝트 폴더에서 봇 설정 (각 프로젝트마다 1회):"
echo "     curl -sSL https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/setup.sh | bash"
echo "  3) 'claude' 입력 → 텔레그램 연결됨"
