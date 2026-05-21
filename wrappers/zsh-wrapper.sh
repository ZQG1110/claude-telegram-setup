# claude-telegram-setup-wrapper
# 현재 폴더에 맞는 텔레그램 봇 상태 폴더를 자동으로 선택해줍니다.
# 매칭 우선순위: .tgbot 마커 파일 > 현재 폴더 이름 매칭 > 기본 봇
claude() {
  local dir="$PWD"
  local name=""

  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.tgbot" ]]; then
      name=$(head -n1 "$dir/.tgbot" | tr -d '[:space:]')
      break
    fi
    [[ "$dir" == "$HOME" ]] && break
    local parent=$(dirname "$dir")
    [[ "$parent" == "$dir" ]] && break
    dir="$parent"
  done

  [[ -z "$name" ]] && name=$(basename "$PWD")

  local state_dir="$HOME/.claude/channels/telegram-$name"

  if [[ -d "$state_dir" && -f "$state_dir/.env" ]]; then
    export TELEGRAM_STATE_DIR="$state_dir"
  else
    unset TELEGRAM_STATE_DIR
  fi

  if [[ " $* " == *" --channels "* ]]; then
    command claude "$@"
  else
    command claude --channels 'plugin:telegram@claude-plugins-official' "$@"
  fi
}
