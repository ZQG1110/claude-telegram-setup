#!/usr/bin/env bash
# claude-telegram-setup
# 현재 폴더에 대한 텔레그램 봇 설정을 생성합니다.
# 사용: 프로젝트 폴더 안에서 실행하세요.

set -e

if [[ -t 1 ]]; then
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[36m'
  C_RED=$'\033[31m';   C_BOLD=$'\033[1m';     C_RESET=$'\033[0m'
else
  C_GREEN=; C_YELLOW=; C_BLUE=; C_RED=; C_BOLD=; C_RESET=
fi

info() { printf "%s%s%s\n" "$C_BLUE"   "$*" "$C_RESET"; }
ok()   { printf "%s✓ %s%s\n" "$C_GREEN" "$*" "$C_RESET"; }
warn() { printf "%s⚠ %s%s\n" "$C_YELLOW" "$*" "$C_RESET"; }
err()  { printf "%s✗ %s%s\n" "$C_RED"   "$*" "$C_RESET" >&2; }

# curl | bash로 실행 시 stdin이 스크립트 자체. read가 스크립트 다음 줄을 값으로
# 읽어가버리니, /dev/tty를 별도 FD(3)로 열어두고 read는 -u 3로 받는다.
# stdin은 그대로 둬야 bash가 나머지 스크립트를 계속 읽음.
if [[ -t 0 ]]; then
  exec 3<&0
else
  if (: </dev/tty) 2>/dev/null; then
    exec 3</dev/tty
  else
    err "대화형 입력이 필요해요. 스크립트를 다운받아 실행해주세요:"
    err "  curl -sSL https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/setup.sh -o setup.sh"
    err "  bash setup.sh"
    exit 1
  fi
fi

CHANNELS_DIR="$HOME/.claude/channels"
DEFAULT_TELEGRAM="$CHANNELS_DIR/telegram"

echo ""
info "${C_BOLD}claude-telegram-setup${C_RESET}"
info "현재 폴더: $PWD"
echo ""

DEFAULT_NAME=$(basename "$PWD")
read -u 3 -r -p "프로젝트 이름 [${DEFAULT_NAME}]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_NAME}

SAFE_NAME=$(echo "$PROJECT_NAME" | sed 's/[^a-zA-Z0-9_-]/-/g')
if [[ "$SAFE_NAME" != "$PROJECT_NAME" ]]; then
  warn "이름에 특수문자가 있어 '$SAFE_NAME'으로 변환했어요"
  PROJECT_NAME=$SAFE_NAME
fi

STATE_DIR="$CHANNELS_DIR/telegram-$PROJECT_NAME"

if [[ -d "$STATE_DIR" ]]; then
  warn "'$STATE_DIR' 이미 있어요"
  read -u 3 -r -p "덮어쓸까요? [y/N]: " OVERWRITE
  case "$OVERWRITE" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "취소됨"; exit 1 ;;
  esac
fi

CHAT_ID=""
if [[ -f "$DEFAULT_TELEGRAM/access.json" ]]; then
  CHAT_ID=$(grep -oE '"[0-9]+"' "$DEFAULT_TELEGRAM/access.json" | head -n1 | tr -d '"')
fi

if [[ -n "$CHAT_ID" ]]; then
  info "기존 텔레그램 설정에서 chat_id 발견: $CHAT_ID"
  read -u 3 -r -p "그대로 사용할까요? [Y/n]: " USE_EXISTING
  case "$USE_EXISTING" in
    [nN]|[nN][oO]) CHAT_ID="" ;;
  esac
fi

if [[ -z "$CHAT_ID" ]]; then
  read -u 3 -r -p "본인 텔레그램 chat_id (숫자): " CHAT_ID
fi

if ! [[ "$CHAT_ID" =~ ^[0-9]+$ ]]; then
  err "chat_id는 숫자여야 해요: $CHAT_ID"
  exit 1
fi

echo ""
info "BotFather에서 받은 봇 토큰을 붙여넣으세요 (입력 시 화면 표시 안됨)"
read -u 3 -r -s -p "봇 토큰: " BOT_TOKEN
echo ""

if [[ -z "$BOT_TOKEN" ]]; then
  err "토큰이 비어있어요"
  exit 1
fi

if ! [[ "$BOT_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
  warn "토큰 형식이 평소와 달라요 (예상: 숫자:문자열)"
  read -u 3 -r -p "그래도 진행할까요? [y/N]: " CONFIRM
  case "$CONFIRM" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "취소됨"; exit 1 ;;
  esac
fi

mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR" 2>/dev/null || true

cat > "$STATE_DIR/.env" <<EOF
TELEGRAM_BOT_TOKEN=$BOT_TOKEN
EOF
chmod 600 "$STATE_DIR/.env" 2>/dev/null || true

cat > "$STATE_DIR/access.json" <<EOF
{
  "dmPolicy": "pairing",
  "allowFrom": [
    "$CHAT_ID"
  ],
  "groups": {},
  "pending": {}
}
EOF

echo "$PROJECT_NAME" > "$PWD/.tgbot"

WRAPPER_INSTALLED=0
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [[ -f "$rc" ]] && grep -q "claude-telegram-setup-wrapper" "$rc"; then
    WRAPPER_INSTALLED=1
    break
  fi
done

echo ""
ok "셋업 완료!"
echo "  봇 폴더: $STATE_DIR"
echo "  마커 파일: $PWD/.tgbot (프로젝트 이름 = $PROJECT_NAME)"
echo ""
info "${C_BOLD}다음 단계:${C_RESET}"
echo "  1) 텔레그램에서 새 봇과 채팅 시작 ('/start' 메시지 전송)"
if [[ "$WRAPPER_INSTALLED" == 0 ]]; then
  echo "  2) (최초 1회) 래퍼 설치:"
  echo "     curl -sSL https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/install.sh | bash"
  echo "  3) 새 터미널을 열거나 'source ~/.zshrc' 후 'claude' 실행"
else
  echo "  2) 'claude' 입력 → 텔레그램 연결됨"
fi
