# 2026-09-08 — 카드 하나가 마법 하나가 되는 개편 (magic-card)

- Date: 2026-09-08
- GitHub Issue: #23
- Status: Draft

## Goal

원소 카드를 조합해서 마법을 만드는 규칙을 없애고, 카드 한 장이 마법 하나가 되게 한다. 덱·손패·시전·소유·통계가 모두 마법 카드 단위로 움직인다. 저장소 6개가 각각 `magic-card` 브랜치와 같은 이름의 마일스톤을 쓰고, 다 끝나면 default branch 를 옮기거나 한 번에 병합한다.

설계는 [`docs/magic-card.md`](../../docs/magic-card.md) 에 있다.

## Non-goals

- 밸런스 조정. 마이그레이션이 옛 조합에서 초기값을 계산해서 개편 직후 숫자를 지금과 같게 만든다. 조정은 그다음 일이다.
- 원소 상성표 변경. 7x7 표는 그대로 둔다.
- 마법 구현 클래스 구조 변경. 없어지는 것은 데이터 쪽의 시전 종류 축이지 `AbstractShotMagic` 같은 코드 구조가 아니다.
- account, website, infra 변경.
- 마법 추가나 삭제. 지금 있는 69개가 그대로 카드가 된다.
- 새 카드 아트 제작. 마법 아트는 이미 `Assets/Resources/Game/sprites/` 에 있으므로 그것을 카드 앞면으로 쓴다.

## Context / Constraints

- 지금 `cards` 11장(원소 6, 시전 종류 5)과 `magic_cards` 로 마법 69개를 만든다. 조합 대부분이 카드 2장이고 가장 긴 것이 5장이다.
- 조합 SQL 이 `database/migration` 에 있는 마법은 19개뿐이다. 나머지 약 50개의 조합은 운영 데이터베이스에만 있다. 초기값 계산은 SQL 로 하므로 운영·dev 에서는 채워지지만 빈 데이터베이스에서 재생해서 확인할 수 없다.
- `V000` 이 `create database` 로 시작하는 `pg_catalog` 덤프라 마이그레이션 체인을 빈 데이터베이스에서 재생할 수 없다. 검증은 `test-env` 스킬로 만든 복제본에서만 가능하다.
- `validate_migrations.yml` 은 pull request 의 base branch 기준으로만 순서를 검사한다. `magic-card` 안에서 번호를 맞춰도 `main` 병합에서 깨질 수 있다. 작성 시점 `main` 의 최고 번호는 `V067` 이다.
- WordOnlineDatabase 는 pull request 를 한 줄로 쌓아야 한다. `main` 으로 향하는 pull request 는 한 번에 하나뿐이다.
- 마나 비용과 사거리가 시전 종류 이름(`Shoot`, `Drop` 등)으로 `parameter_values` 를 조회한다. 시전 종류를 없애면 키를 마법 이름으로 옮겨야 한다.
- 클라이언트가 조준 표시 모양을 `castType == Shoot` 로 정한다. 시전 종류가 없어지면 이 판단을 대신할 값 하나(`aim_shape`)가 필요하다.
- 기존 덱 15장은 전부 원소·시전 종류 카드라 새 모델에서 의미가 없다. 덱 내용을 다시 채우는 것은 되돌릴 수 없다.
- 게임 서버 프로토콜과 클라이언트가 동시에 깨진다. 둘 중 하나만 배포되면 시전이 전부 실패한다.

## Approach (Checklist)

- [x] **Step 0: Recon** (game·lobby·admin·client·database 에서 조합에 묶인 지점 확인, 저장소별 규칙 확인)
- [x] **Step 1: 브랜치와 마일스톤** (저장소 6개에 `magic-card` 브랜치와 동명 마일스톤 생성)
- [x] **Step 2: 문서** (`docs/magic-card.md`, `README.md`, 이 계획 파일 — #23)
- [ ] **Step 3: 데이터베이스** (#99 element 컬럼 → #100 마법별 parameter 값 → #101 덱·소유 이전 → #102 통계 합치기 → #103 옛 표 삭제, 한 줄로 쌓는다)
- [ ] **Step 4: 게임 서버** (#495 조합 해석 제거 → #496 시전 입력 → #497 parameter 키 이동 → #498 봇 → #499 통계)
- [ ] **Step 5: 매칭 서버** (#116 덱 API → #117 `/api/data/magics` → #118 지급과 보상)
- [ ] **Step 6: admin** (#105 편집 화면 → #106 밸런스 화면 → #107 봇 덱 → #108 통계 화면)
- [ ] **Step 7: 클라이언트** (#575 자료형과 아트 → #576 손패와 시전 → #577 덱 화면 → #578 도감 → #579 튜토리얼, #576 과 병행 가능한 #580 번역표)
- [ ] **Step 8: 서브모듈 포인터** (#24)
- [ ] **Step 9: 전환** (#25)

Step 3 은 Step 4~6 보다 먼저 dev 에 들어가야 한다. Step 4 와 Step 7 은 payload 형식을 먼저 합의한 뒤 병행한다. Step 5 와 Step 6 은 서로 독립적이다.

## Validation

- **Commands to run:**
  - `.agents/skills/test-env/scripts/testenv.sh up --yes --with game,lobby,admin` — 복제본에 magic-card 마이그레이션을 적용하고 서버를 붙인다
  - 각 서버 저장소에서 `./gradlew test`
  - `scripts/ci/validate-migrations.sh origin/magic-card` (WordOnlineDatabase)
  - `.agents/skills/game-capacity-test` — 봇 변경 전후 세션 수용량 비교
- **Expected output:**
  - 마법 몇 개를 골라 개편 전후 `mana_cost` 와 `range` 가 같다
  - 복제본에서 카드 한 장을 골라 조준하고 시전하는 흐름이 끝까지 동작한다
  - 모든 사용자의 선택된 덱이 15장이고 같은 마법이 4장 이상 든 덱이 없다

## Risks & Rollback

- **Risks:**
  - 덱 내용을 다시 채우는 것은 되돌릴 수 없다. 사용자가 짜 둔 덱이 사라진다.
  - 마이그레이션 번호를 `magic-card` 기준으로만 맞추면 `main` 병합에서 순서가 깨진다. CI 가 잡아 주지 않는다.
  - 조합이 저장소에 없는 마법 약 50개의 초기값은 운영 데이터베이스에서만 계산된다. dev 와 운영의 값이 다를 수 있다.
  - 게임 서버와 클라이언트 중 하나만 배포되면 시전이 전부 실패한다. promotion 순서를 지켜야 한다.
  - 마법 69개 각각에 카드 앞면 아트가 필요하다. 지금 카드 아트는 11장뿐이다.
  - `magic-card` 가 길어지면 `main` 과 벌어진다. 각 저장소에서 주기적으로 `main` 을 병합해 흡수한다.
- **Rollback steps:**
  - 코드: `magic-card` 브랜치를 버리면 된다. `main` 은 건드리지 않는다.
  - 데이터베이스: dev 에 적용한 뒤에는 forward-fix 마이그레이션으로만 되돌린다 (WordOnlineDatabase README rule 5).
  - 운영: 이전 tag 로 되돌린다. 단 스키마가 이미 바뀐 뒤라면 옛 서버는 뜨지 않는다. 전환 전에 덤프를 남긴다.

## Open Questions

- 덱 규칙의 "서로 다른 원소 2종 이상"이 새 모델에서도 적절한지. 지금 숫자를 그대로 옮긴 것이라 실제로 플레이해 보고 조정해야 할 수 있다.
- 마법 69개 전부를 처음부터 카드 목록에 넣을지, 일부만 `access_type = 'DEFAULT'` 로 둘지. 지금 기본 지급 규칙을 그대로 쓰면 기본 마법만 들어간다.
- `magics.element` 를 Postgres enum 으로 만들지 `varchar` 로 둘지. 기존 `card_type` enum 은 지우는 방향이다.
