# 🤖 Agent Instructions (WordOnline Monorepo)

이 저장소는 멀티모듈 및 Git 서브모듈(Submodule)로 이루어진 monorepo 프로젝트입니다. 에이전트(AI Coding Assistant)가 이 프로젝트에서 작업을 수행할 때 반드시 다음 지침을 준수해야 합니다.

---

## 📁 1. 서브모듈 이동 및 개별 가이드라인 준수 (Submodule Workflow)

본 프로젝트는 각 도메인별로 독립된 서브모듈로 나누어져 있습니다.
따라서 작업을 시작하기 전, **해당 작업이 어느 모듈에 속하는지 파악하고 그 모듈 디렉토리로 이동한 뒤, 개별 가이드라인을 먼저 읽어야 합니다.**

### 🔍 작업 전 확인 순서:
1. **대상 모듈 디렉토리로 이동**:
   * `client/` : Unity 웹/데스크톱 클라이언트
   * `game/` : Spring Boot 기반 인게임 서버
   * `lobby/` : Spring Boot 기반 매칭/로비 서버
   * `account/` : Spring Boot 기반 회원 인증/KV 서버
   * `admin/` : Spring Boot 기반 관리자 웹 서버
   * `website/` : React + Vite 웹 프론트엔드
   * `database/` : Flyway DB 마이그레이션
2. **개별 에이전트 가이드 준수**:
   * 각 모듈 폴더 내에 존재하는 `AGENTS.md` 및 `CLAUDE.md` 파일을 먼저 읽고, 해당 프로젝트 고유의 빌드 명령(예: Gradle, Unity CLI), 코딩 스타일, 브랜치 네이밍 규칙을 완벽하게 따라야 합니다.
   * 각 서브모듈의 개별 `skill`이나 `docs/` 내 문서를 참고하여 개발합니다.

---

## 📊 2. graphify 가이드라인

이 프로젝트는 `graphify-out/` 경로에 클래스/메서드/파일 간의 관계를 분석한 지식 그래프를 가지고 있습니다.

* `/graphify` 명령어 입력 시, 다른 작업을 진행하기 전에 `skill: "graphify"` 스킬 도구를 우선적으로 호출하십시오.
* **코드베이스 질문 시**: `graphify-out/graph.json`이 존재한다면, `graphify query "<질문>"`을 먼저 실행하십시오.
* **개념/구조 설명 시**: `graphify explain "<개념>"` 또는 두 노드 간의 관계인 `graphify path "<A>" "<B>"`를 활용하여 분석합니다.
* **그래프 갱신**: 코드 수정 후에는 AST 분석 그래프를 항상 최신 상태로 유지하기 위해 `graphify update .` 명령어를 실행하십시오. (추가 API 비용 없음)

---

## 🔒 3. 보안 및 작업 환경 가이드

* **환경 변수 파일 보호**: 루트 디렉토리 및 각 서브모듈 내부의 `.env` 파일은 절대로 원격 저장소에 커밋되어 노출되지 않도록 차단해야 합니다. (수정 시 루트의 `.gitignore` 또는 개별 `.gitignore` 필수 검토)
* **서브모듈 포인터 관리**: 서브모듈 코드 변경 후에는 해당 서브모듈에서 먼저 커밋 및 푸시를 완료한 뒤, 메인 저장소에서 해당 서브모듈 포인터를 갱신하여 커밋해야 합니다.
