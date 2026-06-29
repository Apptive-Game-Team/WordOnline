# 2026-06-29 — Admin grant defaults and parameter dropdown

- Date: 2026-06-29
- Status: In Progress

## Goal

- admin 서버에서 모든 default adventure(FREE access type)와 magic(DEFAULT access type)을 모든 user들에게 부여하는 기능을 구현한다. (메인 대시보드에 버튼으로 연동)
- game object 상세(parameter value 비교) 화면에서 parameter를 드롭다운으로 골라서 신규 parameter value를 추가하는 기능을 구현한다.

## Non-goals

- 유저의 기존 완료 상태나 덱 구성을 파괴적으로 변경
- PVE 이외의 게임 플레이 데이터 강제 잠금 해제

## Context / Constraints

- `admin` 모듈은 Git 서브모듈로 구성되어 있으므로, 변경 사항은 서브모듈 내부에서 커밋 및 푸시 후 모노레포 루트에서 포인터를 갱신해야 한다.
- `secondary` 데이터베이스(Dev 환경) 설정 여부에 따라 secondary DB에 대해서도 부여 기능을 지원해야 한다.

## Approach (Checklist)
- [x] **Step 1: Admin Backend 구현**
  - [x] `ParameterRepository` 에 `findAllByOrderByNameAsc` 추가
  - [x] `AdminPageController` 에서 대시보드 및 상세 화면 진입 시 필요한 데이터(Parameters, DB 사용 여부)를 모델에 바인딩
  - [x] `SecondaryAdminDataService` 및 `DefaultContentService` 에 default adventure/magic을 전체 유저에게 부여하는 쿼리 및 서비스 로직 구현
  - [x] `DefaultContentController` 에 `/api/admin/grant-default-contents` POST API 구현
- [x] **Step 2: UI 구현 및 연동**
  - [x] `index.html`에 "Grant Defaults (Prod / Dev)" 버튼 연동 및 fetch 스크립트 작성
  - [x] `admin-parameter-value.html`에 parameter select 및 value 입력 폼, `syncSecondary` 체크박스 및 전송 스크립트 복원
- [x] **Step 3: Validation & Build**
  - [x] `./gradlew compileJava` 성공 확인
- [ ] **Step 4: Branch, Commit & Pull Request 생성**
  - [ ] `admin` submodule 브랜치 생성 및 변경 커밋, Push
  - [ ] `admin` submodule PR 생성
  - [ ] 모노레포 루트 브랜치 생성 및 submodule pointer 갱신 커밋
  - [ ] 모노레포 루트 PR 생성

## Validation
- **Commands to run:** `./gradlew compileJava` in admin module
- **Expected output:** Build successful

## Risks & Rollback
- **Risks:** 중복 insert로 인한 constraint 위반 (이미 `NOT EXISTS` 절로 처리 완료)
- **Rollback steps:** git checkout 또는 revert로 변경 파일 원복
