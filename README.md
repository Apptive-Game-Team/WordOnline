# 📝 WordOnline

온라인 멀티플레이어 단어 게임 **WordOnline** 프로젝트의 메인 저장소입니다.  
본 프로젝트는 Unity로 개발된 클라이언트와 Spring Boot 기반의 여러 마이크로서비스 백엔드로 구성된 멀티 모듈 및 서브모듈(Git Submodule) 구조로 설계되어 있습니다.

---

## 🏗️ 전체 아키텍처 및 구성 요소

이 저장소는 다음과 같이 여러 독립적인 서비스와 클라이언트로 나누어져 있으며, 대부분 Git 서브모듈로 관리됩니다.

```
word-online/
├── client/          # Unity 기반 게임 클라이언트 (WordOnlineClient)
├── game/            # Spring Boot 기반 게임 플레이 서버 (WordOnlineServer)
├── lobby/           # Spring Boot 기반 매칭 및 로비 서버 (WordOnlineMatching)
├── account/         # Spring Boot 기반 인증 및 Key-Value 서버 (AccountServer)
├── admin/           # Spring Boot 기반 관리자 웹 서버 (WordOnlineAdmin)
├── website/         # React + Vite + TypeScript 기반 소개 및 관리 웹페이지
└── database/        # Flyway 기반 데이터베이스 마이그레이션 관리 (WordOnlineDatabase)
```

---

## 🛠️ 서비스별 기술 스택 & 역할

### 1. [Client (client)](file:///Users/jeong-yunseong/development/word-online/dev/word-online/client)
* **역할**: 게임 클라이언트 (UI/UX, 매칭 및 인게임 플레이 화면 제공)
* **기술 스택**: Unity, C#, DOTween, TextMeshPro, WebGL
* **상세 정보**: [client/README.md](file:///Users/jeong-yunseong/development/word-online/dev/word-online/client/README.md) 참고

### 2. [Game Server (game)](file:///Users/jeong-yunseong/development/word-online/dev/word-online/game)
* **역할**: 단어 게임의 핵심 인게임 비즈니스 로직 및 플레이 관리
* **기술 스택**: Java, Spring Boot, PostgreSQL, Gradle, Docker
* **상세 정보**: [game/README.md](file:///Users/jeong-yunseong/development/word-online/dev/word-online/game/README.md) 참고

### 3. [Lobby Server (lobby)](file:///Users/jeong-yunseong/development/word-online/dev/word-online/lobby)
* **역할**: 대기실(로비) 관리 및 유저 매치메이킹(Matchmaking) 지원
* **기술 스택**: Java, Spring Boot, Gradle, Docker
* **상세 정보**: [lobby/README.md](file:///Users/jeong-yunseong/development/word-online/dev/word-online/lobby/README.md) 참고

### 4. [Account Server (account)](file:///Users/jeong-yunseong/development/word-online/dev/word-online/account)
* **역할**: 사용자 인증(Auth) 및 간단한 Key-Value 저장소 관리
* **기술 스택**: Java, Spring Boot, Gradle, Docker
* **상세 정보**: [account/README.md](file:///Users/jeong-yunseong/development/word-online/dev/word-online/account/README.md) 참고

### 5. [Admin Server (admin)](file:///Users/jeong-yunseong/development/word-online/dev/word-online/admin)
* **역할**: WordOnline 관리자 대시보드 웹 서버
* **기술 스택**: Java, Spring Boot, Gradle, Docker
* **상세 정보**: [admin/README.md](file:///Users/jeong-yunseong/development/word-online/dev/word-online/admin/README.md) 참고

### 6. [Website (website)](file:///Users/jeong-yunseong/development/word-online/dev/word-online/website)
* **역할**: 서비스 소개 및 사용자용 웹 프론트엔드
* **기술 스택**: React, Vite, TypeScript, TailwindCSS (또는 Vanilla CSS), ESLint
* **상세 정보**: [website/README.md](file:///Users/jeong-yunseong/development/word-online/dev/word-online/website/README.md) 참고

### 7. [Database Migration (database)](file:///Users/jeong-yunseong/development/word-online/dev/word-online/database)
* **역할**: 데이터베이스 스키마 버전 관리 및 마이그레이션 자동화
* **기술 스택**: PostgreSQL, Flyway (`database/migration/` 내 SQL 파일)

---

## 🚀 시작하기

### 1. 저장소 복제 (서브모듈 포함)
이 프로젝트는 서브모듈을 사용하므로, 복제 시 `--recursive` 옵션을 사용하거나 복제 후 서브모듈을 초기화해야 합니다.

```bash
# 서브모듈을 포함하여 프로젝트 복제
git clone --recursive https://github.com/Apptive-Game-Team/WordOnline.git
cd WordOnline

# 또는 이미 복제한 경우 서브모듈 초기화
git submodule update --init --recursive
```

### 2. 환경 변수 설정
로컬 실행을 위해 각 서비스에 필요한 환경 변수(`.env`) 파일이 필요할 수 있습니다. 
* 루트 디렉토리의 `.env` 파일은 절대 Git에 커밋되지 않도록 `.gitignore` 처리되어 있습니다.
* 각 서브모듈 폴더(예: `lobby/`) 내의 `.env.example` 파일을 참고하여 `.env` 파일을 생성하고 설정해 주세요.

---

## 🔒 보안 및 Git 규칙

* **환경 변수 파일 보호**: `.env`, `*.local`, `*.suo` 등 보안 정보나 개인 개발 환경 설정 파일은 `.gitignore`에 등록되어 원격 저장소에 업로드되지 않도록 차단되어 있습니다.
* **서브모듈 관리**: 각 서브모듈 폴더(`client`, `game`, `lobby` 등) 내에서 코드를 수정하는 경우, 해당 서브모듈 저장소에 먼저 커밋/푸시한 후 메인 저장소에서 서브모듈 포인터를 갱신해야 합니다.