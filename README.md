# claude-telegram-setup

폴더마다 다른 텔레그램 봇을 자동으로 연결해주는 [Claude Code](https://claude.com/claude-code)용 셋업 도구.
프로젝트 폴더에서 명령어 하나 → 봇 토큰 붙여넣기 → 끝.

---

## TL;DR

```bash
# 1회: 각 기기에서 한 번 (마켓플레이스 + 플러그인 + 셸 래퍼 자동 설치)
curl -sSL https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/install.sh | bash
source ~/.zshrc

# 프로젝트마다: BotFather에서 새 봇 만든 뒤, 프로젝트 폴더에서
curl -sSL https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/setup.sh | bash
# → 폴더 이름 / chat_id / 봇 토큰 입력

# 사용
claude
```

Windows PowerShell은 `iwr -useb <url> | iex` 형태 + `.ps1` 확장자.

---

## 어떤 문제를 풀어주나요?

기본 Claude Code 텔레그램 플러그인은 봇을 **한 개**만 설정할 수 있어요.
- 데스크탑 / 노트북 사이를 오가며 작업하면 어느 기기에서 메시지가 왔는지 헷갈림
- 여러 프로젝트를 동시에 굴리면 메시지가 한 채팅창에 섞임

이 도구를 쓰면:
- 폴더(프로젝트)마다 **별도 봇** 사용 가능 → 텔레그램에서 각각 다른 채팅창
- `cd ~/projectA && claude` → A봇이 응답, `cd ~/projectB && claude` → B봇이 응답
- 봇 이름/아바타를 다르게 해서 시각적으로도 명확하게 구분

---

## 사전 요구사항

- [Claude Code](https://claude.com/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- [Bun](https://bun.sh) — 텔레그램 플러그인이 사용하는 런타임 (없으면 install 스크립트가 알려줌)

---

## 1회 설치 (각 기기에서 한 번)

`install` 스크립트가 한 번에 다 해줍니다:
1. `anthropics/claude-plugins-official` 마켓플레이스 등록
2. `telegram` 플러그인 설치
3. 폴더별 봇 자동 전환 셸 래퍼 등록 (`~/.zshrc` / `~/.bashrc` / PowerShell `$PROFILE`)

재실행해도 안전 (idempotent — 이미 된 단계는 건너뜀).

### Mac / Linux

```bash
curl -sSL https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/install.sh | bash
source ~/.zshrc   # 또는 새 터미널 열기
```

### Windows PowerShell

```powershell
iwr -useb https://raw.githubusercontent.com/ZQG1110/claude-telegram-setup/main/install.ps1 | iex
. $PROFILE.CurrentUserAllHosts   # 또는 PowerShell 새로 열기
```

---

## 프로젝트마다 봇 추가하기

### 1. BotFather에서 새 봇 만들기

1. 텔레그램에서 `@BotFather` 검색해서 열기
2. `/newbot` 입력
3. 봇 display name 정하기 (예: `프로젝트A봇`)
4. 봇 username 정하기 (`_bot`으로 끝나야 함, 예: `myname_projectA_bot`)
5. BotFather가 주는 토큰 복사 (`123456789:AAH...` 형식)
6. 만든 봇 채팅창 열어서 `/start` 한 번 보내기 (안 보내면 봇이 본인한테 메시지 못 보냄)

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

질문에 답하기:
- `프로젝트 이름 [현재폴더이름]:` → 엔터 (폴더 이름 그대로 사용)
- `chat_id 그대로 사용할까요? [Y/n]:` → Y (기존 설정 재사용) 또는 직접 입력
- `봇 토큰:` → BotFather가 준 토큰 붙여넣기 (입력 시 화면에 안 보이는 게 정상)

### 3. 사용

```bash
claude
```
끝. 텔레그램에서 그 폴더 전용 봇으로 메시지가 오갑니다.

---

## 내부 구조

### 파일 레이아웃

```
~/.claude/channels/
├── telegram/                 ← 기본 봇 (Claude 플러그인 기본 위치)
│   ├── .env
│   └── access.json
├── telegram-projectA/        ← 프로젝트 A 봇
│   ├── .env                  ← TELEGRAM_BOT_TOKEN=...
│   └── access.json           ← { "allowFrom": ["chat_id"], ... }
└── telegram-projectB/        ← 프로젝트 B 봇
    ├── .env
    └── access.json

~/Projects/
├── projectA/
│   └── .tgbot                ← 마커 파일 (내용: "projectA")
└── projectB/
    └── .tgbot                ← 마커 파일 (내용: "projectB")
```

### 봇 자동 선택 흐름

`claude` 명령 입력 시 셸 래퍼가:
1. 현재 폴더부터 위로 올라가며 `.tgbot` 마커 파일 찾기
2. 마커가 있으면 그 안의 이름 사용 → `~/.claude/channels/telegram-{이름}/`
3. 마커가 없으면 현재 폴더 이름으로 매칭 시도
4. 둘 다 없으면 기본 봇(`~/.claude/channels/telegram/`) 사용
5. `TELEGRAM_STATE_DIR` 환경변수 설정 후 `claude --channels plugin:telegram@claude-plugins-official` 실행

플러그인 내부에서 `TELEGRAM_STATE_DIR`이 설정돼 있으면 그 경로의 `.env`를 우선적으로 읽어요 — 그래서 폴더별 봇 분리가 가능.

---

## 봇 삭제

```bash
rm -rf ~/.claude/channels/telegram-projectA
rm ~/path/to/projectA/.tgbot
```

텔레그램 봇 자체는 `@BotFather` → `/deletebot`으로 삭제.

---

## 트러블슈팅

- **`claude` 실행 시 봇 인식 안됨**
  새 터미널을 열거나 `source ~/.zshrc` (Mac/Linux) / `. $PROFILE.CurrentUserAllHosts` (Windows)

- **봇이 메시지를 안 받음**
  텔레그램에서 그 봇과 채팅 시작 (`/start`) 먼저 보내야 됨

- **`plugin not installed` 경고**
  `install.sh` 재실행하거나, 수동으로:
  ```
  claude plugin marketplace add anthropics/claude-plugins-official
  claude plugin install telegram@claude-plugins-official
  ```

- **다른 폴더에서 같은 봇 쓰고 싶음**
  그 폴더에 `.tgbot` 파일 만들고 봇 이름 한 줄 적기

- **bun이 없다고 함**
  맥: `curl -fsSL https://bun.sh/install | bash`
  윈도우: `powershell -c "irm bun.sh/install.ps1 | iex"`

---

## 라이선스

MIT
