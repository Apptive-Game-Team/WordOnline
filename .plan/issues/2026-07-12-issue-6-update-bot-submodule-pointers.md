# 2026-07-12 — 봇 관리 기능 submodule 포인터 갱신

- Date: 2026-07-12
- GitHub Issue: #6
- Status: Implemented

## Goal

Database, Game, Lobby, Admin의 published Bot 기능 commit 조합을 parent WordOnline 저장소에 기록한다.

## Non-goals

- Module source 변경
- Client 또는 기존 root 문서 변경 포함

## Context / Constraints

- Root worktree에는 사용자 소유 AGENTS/client/website/.cate 변경이 있으므로 선택적 stage만 허용한다.
- Database migration을 service 변경보다 먼저 배포한다.

## Approach (Checklist)

- [x] **Step 0: Recon** (module branch, commit, PR publish 상태 확인)
- [x] **Step 1: Implementation** (database/game/lobby/admin pointer만 갱신)
- [x] **Step 2: Tests** (Game/Admin/Lobby module tests와 build 결과 참조)
- [x] **Step 3: Rollout / Rollback** (Database → Game/Lobby → Admin 순서 문서화)

## Validation

- **Commands to run:** `git diff --cached --submodule=short`; `git status --short`
- **Expected output:** 4개 pointer와 이 plan만 staged, 기존 사용자 변경 제외

## Risks & Rollback

- **Risks:** Service pointer를 Database migration보다 먼저 배포하면 schema mismatch 발생
- **Rollback steps:** Parent pointer commit revert; module commits는 독립 유지

## Open Questions

- 없음
