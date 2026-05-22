# claude-telegram-setup

폴더마다 별도의 텔레그램 봇을 자동으로 연결해주는 셋업 스크립트.
프로젝트 폴더에서 명령어 한 줄 → 봇 토큰 붙여넣기 → 끝.

## 어떻게 동작하나요?

1. `setup.sh` (Mac/Linux) 또는 `setup.ps1` (Windows)을 프로젝트 폴더에서 실행
2. 폴더 이름이 자동으로 봇 이름으로 사용됨 (변경 가능)
3. `~/.claude/channels/telegram-{이름}/` 폴더에 봇 설정 저장 (`.env` + `access.json`)
4. 현재 폴더에 `.tgbot` 마커 파일 생성
5. 래퍼 함수가 `claude` 실행 시 현재 폴더의 `.tgbot`을 읽고 알맞은 봇으로 자동 연결

## 사전 요구사항

- [Claude Code](https://claude.com/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- [Bun](https://bun.sh) — 텔레그램 플러그인 런타임 (없으면 install 스크립트가 안내해줌)

## 1회 설치 (각 기기에서 1회)

`install` 스크립트가 다음 세 가지를 한 번에 해줍니다:
1. `claude-plugins-official` 마켓플레이스 등록
2. `telegram` 플러그인 설치
3. 폴더별 봇 자동 선택 셸 래퍼 등록

### Mac / Linux (zsh, bash)

```bash
curl -sSL https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/install.sh | bash
source ~/.zshrc   # 또는 ~/.bashrc
```

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/install.ps1 | iex
. $PROFILE.CurrentUserAllHosts
```

## 프로젝트마다 봇 추가하기

새 프로젝트 폴더에서 (각각 다른 봇으로 쓰고 싶을 때):

### 1. 텔레그램에서 새 봇 생성

1. 텔레그램에서 `@BotFather` 열기
2. `/newbot` 입력
3. 봇 이름(display name) 정하기 — 예: `프로젝트A`
4. 봇 username 정하기 (`_bot`으로 끝나야 함) — 예: `gioza_projectA_bot`
5. BotFather가 주는 토큰 복사
6. 만든 봇과 채팅 시작 → `/start` 전송

### 2. 셋업 스크립트 실행

프로젝트 폴더에서 터미널 열고:

**Mac / Linux**
```bash
curl -sSL https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/setup.sh | bash
```

**Windows PowerShell**
```powershell
iwr -useb https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/setup.ps1 | iex
```

질문 2~3개에 답하면 끝:
- `프로젝트 이름 [현재폴더이름]:` ← 엔터 치면 폴더 이름 사용
- `chat_id 그대로 사용할까요? [Y/n]:` ← 기존 봇 설정이 있으면 재사용
- `봇 토큰:` ← BotFather가 준 토큰 붙여넣기

### 3. 사용

```bash
claude
```
끝. 텔레그램에서 그 폴더 전용 봇으로 메시지가 오갑니다.

## 폴더 구조

설치 후 다음과 같이 됩니다:

```
~/.claude/channels/
├── telegram/                 ← 기본 봇 (기존)
│   ├── .env
│   └── access.json
├── telegram-projectA/        ← 프로젝트 A 봇
│   ├── .env
│   └── access.json
└── telegram-projectB/        ← 프로젝트 B 봇
    ├── .env
    └── access.json

~/Projects/
├── projectA/
│   └── .tgbot                ← 마커 파일 (내용: "projectA")
└── projectB/
    └── .tgbot                ← 마커 파일 (내용: "projectB")
```

## 봇 전환 동작 원리

`claude` 명령을 입력하면 래퍼 함수가:

1. 현재 폴더부터 위로 올라가며 `.tgbot` 마커 파일 찾기
2. 마커가 있으면 그 안의 이름을 사용 → `~/.claude/channels/telegram-{이름}/`
3. 마커가 없으면 현재 폴더 이름으로 매칭 시도
4. 둘 다 없으면 기본 봇(`~/.claude/channels/telegram/`) 사용
5. `TELEGRAM_STATE_DIR` 환경변수 설정 후 `claude --channels plugin:telegram@claude-plugins-official` 실행

## 봇 삭제

```bash
rm -rf ~/.claude/channels/telegram-projectA
rm ~/Projects/projectA/.tgbot
```

(텔레그램의 봇은 `@BotFather` → `/deletebot`)

## 트러블슈팅

- **`claude` 실행해도 봇 인식 안됨**: 터미널 새로 열기 또는 `source ~/.zshrc` (Mac/Linux) / `. $PROFILE.CurrentUserAllHosts` (Windows)
- **봇이 메시지를 안 받음**: 텔레그램에서 그 봇에게 먼저 `/start`를 보내야 함
- **다른 폴더에서 같은 봇 쓰고 싶음**: 그 폴더에 `.tgbot` 파일 만들고 봇 이름 한 줄 적기

## 라이선스

MIT
