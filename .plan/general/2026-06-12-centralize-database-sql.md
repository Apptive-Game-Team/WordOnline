# 2026-06-12 — 운영 SQL을 database 저장소로 중앙화

- Date: 2026-06-12
- GitHub Issue: None
- Status: Complete

## Goal

운영 PostgreSQL schema, seed, backfill, cleanup SQL의 단일 source of truth를 `database` Flyway migration으로 통합한다.

## Non-goals

- 모듈별 H2 테스트 fixture 이동
- 이미 배포된 `V000` migration 수정
- 애플리케이션 코드나 데이터 모델의 동작 변경

## Context / Constraints

- 각 하위 저장소는 독립 Git 이력과 workflow를 가진다.
- 운영 DB에 이미 반영된 SQL도 있을 수 있으므로 신규 migration은 재실행에 안전해야 한다.
- 서버 저장소의 schema SQL은 삭제 전 런타임 참조 여부를 확인한다.

## Approach (Checklist)
- [x] **Step 0: Recon** SQL별 실행 주체, 중복, 의존성, DB 경계를 확인한다.
- [x] **Step 1: Implementation** 운영 SQL을 신규 Flyway migration으로 옮기고 서버 저장소의 운영 SQL 복사본을 제거한다.
- [x] **Step 2: Tests** Flyway 파일 순서, SQL 참조, Gradle 테스트를 검증한다.
- [x] **Step 3: Rollout / Rollback** database migration을 먼저 배포하고 서버 저장소 변경을 뒤따르게 한다.

## Validation
- **Commands to run:** `rg` 참조 검사, Flyway validation/migrate, 영향 모듈의 `./gradlew test`
- **Expected output:** 운영 SQL은 `database/migration`에만 존재하고 서버 테스트 fixture는 정상 동작한다.

## Risks & Rollback
- **Risks:** 기존 DB와 migration 내용 충돌, seed 중복, 서버가 삭제된 classpath SQL을 참조할 가능성
- **Rollback steps:** 서버 정리 커밋을 먼저 revert한다. 적용된 migration은 수정하지 않고 forward-fix migration을 추가한다.

## Open Questions

- None. Account database SQL remains in AccountServer because it uses a
  separate database.
