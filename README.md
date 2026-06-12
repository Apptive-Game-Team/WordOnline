# WordOnline

WordOnline은 Unity 클라이언트와 독립적으로 배포되는 여러 백엔드 서비스로 구성된 온라인 멀티플레이어 게임 플랫폼입니다. 이 저장소는 각 구성 요소를 Git 서브모듈로 관리하며, 시스템 전반의 개발 진입점 역할을 합니다.

## 저장소 구조

| 경로 | 역할 | 주요 기술 |
| --- | --- | --- |
| [`client/`](client/) | 게임 클라이언트, UI, 씬 흐름, WebGL 빌드 | Unity 2022.3.34f1, C# |
| [`game/`](game/) | 실시간 게임 세션, 게임 규칙, WebSocket 통신 | Java 21, Spring Boot, PostgreSQL |
| [`lobby/`](lobby/) | 매칭, 로비 상태, 덱, 퀘스트, 진행도 API | Java/Kotlin, Spring WebFlux, PostgreSQL, Redis |
| [`account/`](account/) | 인증, 인가, Key-Value 서비스 | Java 21, Spring WebFlux, PostgreSQL |
| [`admin/`](admin/) | 내부 관리 화면과 콘텐츠 관리 | Java 21, Spring Boot, Thymeleaf, PostgreSQL |
| [`website/`](website/) | 프로젝트 공개 웹사이트 | React, TypeScript, Vite |
| [`database/`](database/) | 공통 데이터베이스 스키마 마이그레이션 | Flyway, PostgreSQL |

각 디렉터리는 독립적인 저장소 이력과 빌드 설정을 가집니다. 모듈을 수정하기 전에 해당 디렉터리의 `README.md`, `AGENTS.md`, 관련 문서를 먼저 확인합니다.

## 시작하기

서브모듈을 포함해 저장소를 복제합니다.

```bash
git clone --recursive https://github.com/Apptive-Game-Team/WordOnline.git
cd WordOnline
```

이미 복제한 저장소라면 서브모듈을 초기화합니다.

```bash
git submodule update --init --recursive
```

루트에는 전체 시스템을 한 번에 빌드하거나 실행하는 도구가 없습니다. 각 구성 요소는 해당 모듈 디렉터리에서 개별적으로 빌드하고 실행합니다.

## 주요 명령

백엔드 서비스는 각 모듈에 포함된 Gradle Wrapper를 사용합니다.

```bash
cd game        # 또는 lobby, account, admin
./gradlew test
./gradlew bootRun
```

웹사이트를 로컬에서 실행합니다.

```bash
cd website
npm ci
npm run dev
```

`client/`는 Unity `2022.3.34f1`에서 엽니다. WebGL 빌드는 Unity Editor 또는 모듈에 정의된 빌드 스크립트를 사용합니다.

## 환경 설정

백엔드 서비스는 각 모듈의 `src/main/resources/application.yml`과 선택적인 로컬 `.env` 파일에서 실행 설정을 읽습니다. 서비스 포트, 데이터베이스 접속 정보, 서비스 URL, Redis 설정, 인증 키 등이 필요할 수 있습니다.

`.env` 파일과 인증 정보는 커밋하지 않습니다. 구체적인 설정은 각 모듈의 문서와 `application.yml`을 기준으로 확인합니다.

데이터베이스 스키마 변경은 [`database/migration/`](database/migration/)에 추가합니다. 서비스 내부의 SQL 파일은 테스트, 초기 데이터, 개발 작업을 지원할 수 있지만 공통 마이그레이션 이력을 대체하지 않습니다.

## 개발 절차

1. 변경 사항을 소유한 모듈을 확인합니다.
2. 해당 모듈의 `AGENTS.md`와 관련 문서를 읽습니다.
3. 서브모듈 내부에서 구현하고 검증합니다.
4. 서브모듈 변경을 커밋하고 푸시합니다.
5. 이 저장소에서 변경된 서브모듈 포인터를 커밋합니다.

여러 서비스에 걸친 변경은 프로토콜, 스키마, 배포 호환성을 명시적으로 관리해야 합니다. 새 스키마에 의존하는 코드를 배포하기 전에 데이터베이스 마이그레이션 순서를 조율합니다.

## 저장소 지침

저장소 공통 에이전트 지침, 모듈 소유권, Graphify 사용법, 보안 규칙, 서브모듈 변경 절차는 [`AGENTS.md`](AGENTS.md)를 참고합니다.
