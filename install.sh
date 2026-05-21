#!/usr/bin/env bash
# claude-telegram-setup 래퍼 1회 설치 (Mac/Linux)
set -e

WRAPPER_URL="${WRAPPER_URL:-https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/wrappers/zsh-wrapper.sh}"

if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *zsh ]]; then
  RC="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *bash ]]; then
  RC="$HOME/.bashrc"
else
  echo "지원되지 않는 셸이에요. ~/.zshrc 또는 ~/.bashrc에 직접 추가해주세요."
  exit 1
fi

if [[ -f "$RC" ]] && grep -q "claude-telegram-setup-wrapper" "$RC"; then
  echo "✓ 래퍼가 이미 설치되어 있어요 ($RC)"
  exit 0
fi

echo "다운로드: $WRAPPER_URL"
{
  echo ""
  echo "# === claude-telegram-setup wrapper (added $(date +%Y-%m-%d)) ==="
} >> "$RC"

if command -v curl >/dev/null; then
  curl -sSL "$WRAPPER_URL" >> "$RC"
elif command -v wget >/dev/null; then
  wget -qO- "$WRAPPER_URL" >> "$RC"
else
  echo "curl 또는 wget이 필요해요"
  exit 1
fi
echo "" >> "$RC"

echo "✓ 래퍼 설치됨: $RC"
echo ""
echo "지금 적용하려면:"
echo "  source $RC"
echo "또는 터미널 새로 열기"
