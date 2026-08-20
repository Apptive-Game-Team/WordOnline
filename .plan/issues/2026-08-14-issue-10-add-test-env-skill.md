# 2026-08-14 — test-env 스킬 추가

- Date: 2026-08-14
- GitHub Issue: #10
- Status: Complete

## Goal

공유 게임 데이터베이스를 로컬 Docker Postgres로 복제하고, `database/migration`의 Flyway 마이그레이션을 복제본에 적용한 뒤, 서버를 그 복제본에 붙여 실행하는 repo-local skill을 추가한다. 현실적인 데이터로 테스트할 환경을 반복 가능한 방식으로 만든다.

## Non-goals

- 소스 데이터베이스 변경. 소스는 `pg_dump` 인자로만 쓰이는 읽기 전용이다.
- 새 마이그레이션 작성이나 `database/` 서브모듈 포인터 갱신
- 계정 데이터베이스 스키마 관리. AccountServer는 자체 저장소에서 관리한다.
- 배포 파이프라인 변경

## Context / Constraints

- `V000`이 `create database`로 시작하고 `pg_catalog` 덤프를 포함해서 빈 DB에서 체인을 재생할 수 없다 (WordOnlineDatabase issue #23). 그래서 빈 DB 구축이 아니라 복제가 유일한 방법이다.
- 호스트에 `psql`, `pg_dump`, `flyway`가 없을 수 있다. 세 가지 모두 컨테이너로 실행해 Docker만 전제로 둔다.
- 모듈마다 DB 설정 키 이름이 다르다. `game`/`admin`은 JDBC, `lobby`/`account`는 R2DBC이고 사용자/비밀번호 키 이름도 제각각이다.
- 네 모듈 모두 `management.server.port` 기본값이 `8081`이라 두 번째 서버부터 포트 충돌로 죽는다.
- `.db.env`는 자격증명을 담으므로 커밋하지 않는다. 루트 `.gitignore`의 `*.env`가 이미 처리한다.

## Approach (Checklist)
- [x] **Step 0: Recon** (서브모듈 DB 키 매핑, Flyway 체인 상태, 호스트 도구 유무 확인)
- [x] **Step 1: Implementation** (`.agents/skills/test-env/` 및 `.db.env.example` 생성)
- [x] **Step 2: Tests** (가짜 소스 DB로 end-to-end 검증, 이후 실제 dev DB로 재검증)
- [x] **Step 3: Rollout / Rollback** (repo-local skill로 즉시 사용, 필요 시 파일 revert)

## Validation
- **Commands to run:** `.agents/skills/test-env/scripts/testenv.sh up --yes --with game,lobby`
- **Expected output:** 복제본 연결 정보와 Flyway `info` 출력, 서버 기동 로그 경로

검증한 내용:
- 가짜 소스 DB 컨테이너로 전체 경로 확인 — 버전 감지, 덤프, 복원, `flyway validate`, pending 마이그레이션 적용 시도, 실패 시 즉시 중단
- 실제 dev DB(`wordonlinedev`) 복제 후 `game`/`lobby`/`admin`/`account` 기동, 복제본에 JDBC·R2DBC 커넥션 확인
- `env-patch` / `env-restore` 왕복에서 DB 외 키 보존 확인
- `down` 후 서버 프로세스와 포트 잔여 없음 확인

## Risks & Rollback
- **Risks:** `.db.env`가 운영 DB를 가리킬 수 있음, 계정 데이터가 로컬 디스크에 복제됨, `env-patch` 후 원복 누락, `database` 서브모듈 포인터가 소스보다 뒤처져 스키마 불일치
- **완화:** 덤프 전 대상 표시 후 확인, 백업을 서브모듈 밖에 저장, 드리프트 감지 시 경고, `down`이 패치된 `.env` 잔존을 보고
- **Rollback steps:** skill 디렉터리와 plan 파일 revert, `testenv.sh down --purge`, 각 모듈 `env-restore`

## Open Questions
- 계정 데이터베이스는 Flyway 체인이 없어 복제본에 아무것도 적용하지 않는다. AccountServer가 체인을 갖추면 `.db.env`의 `ACCOUNT_MIGRATION_DIR`로 연결한다.
