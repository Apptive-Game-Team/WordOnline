# 2026-06-12 — deploy 스킬 추가

- Date: 2026-06-12
- GitHub Issue: #3
- Status: Complete

## Goal

모노레포 루트와 Git 서브모듈 중 `main`에서 `deploy`로 올릴 커밋이 있는 저장소만 PR을 만들거나 재사용해 병합하는 repo-local skill을 추가한다.

## Non-goals

- 배포 브랜치 생성
- 애플리케이션 빌드 또는 배포 파이프라인 변경
- 작업 트리나 현재 브랜치 변경
- PR 병합 뒤 브랜치 삭제

## Context / Constraints

- 각 서브모듈은 독립 Git 저장소다.
- 일부 저장소에는 `deploy` 브랜치가 없을 수 있으므로 건너뛰고 보고해야 한다.
- 기존 열린 `main -> deploy` PR이 있으면 중복 생성하지 않는다.
- 충돌, 실패한 검사, 보호 규칙은 우회하지 않는다.

## Approach (Checklist)
- [x] **Step 0: Recon** (서브모듈, 원격 브랜치, 기존 skill 위치 확인)
- [x] **Step 1: Implementation** (`.agents/skills/deploy/` 생성)
- [x] **Step 2: Tests** (skill validator 및 내용 점검)
- [x] **Step 3: Rollout / Rollback** (repo-local skill로 즉시 사용, 필요 시 파일 revert)

## Validation
- **Commands to run:** `quick_validate.py .agents/skills/deploy`
- **Expected output:** skill frontmatter와 UI metadata가 유효함

## Risks & Rollback
- **Risks:** stale remote refs, 잘못된 비교 방향, 중복 PR, merge 가능 상태 오판
- **Rollback steps:** deploy skill 디렉터리와 plan 파일을 revert

## Open Questions
- 없음
