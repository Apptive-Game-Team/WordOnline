# magic-card — 카드 하나가 마법 하나가 되는 개편

이 문서는 `magic-card` 브랜치가 무엇을 바꾸는지 설명한다. 저장소 6개가 같은 이름의 브랜치와 같은 이름의 마일스톤을 쓴다.

- 루트 이슈: [Apptive-Game-Team/WordOnline#23](https://github.com/Apptive-Game-Team/WordOnline/issues/23)
- 계획: [`.plan/issues/2026-09-08-issue-23-magic-card-redesign.md`](../.plan/issues/2026-09-08-issue-23-magic-card-redesign.md)

## 왜 브랜치를 나누는가

이 개편은 데이터베이스 스키마, 게임 서버의 시전 프로토콜, 덱 API, admin 화면, 클라이언트 UI 를 한꺼번에 바꾼다. 절반만 들어간 상태에서는 어떤 마법도 시전되지 않는다. 그래서 `main` 에 조금씩 넣지 않고, 저장소마다 `magic-card` 브랜치를 두고 거기에만 쌓는다. 다 끝나면 default branch 를 옮기거나 한 번에 병합한다.

`main` 은 그동안 그대로 살아 있다. 개편을 접기로 하면 브랜치를 버리면 된다. 단 dev 데이터베이스에 마이그레이션을 한 번 적용한 뒤에는 forward-fix 마이그레이션으로만 되돌릴 수 있다.

## 지금 모델

카드는 원소이고, 마법은 카드 조합의 결과다.

- `cards` 는 11장이다. 원소 6장(Fire, Water, Lightning, Rock, Nature, Wind)과 시전 종류 5장(Shoot, Build, Spawn, Explode, Drop).
- `magics` 는 69개다. `magic_cards` 가 마법과 카드를 잇고, 카드를 정렬한 목록이 곧 조합의 키다. 조합 대부분이 카드 2장이고, 가장 긴 것이 5장이다. 같은 카드가 두 장 필요한 조합은 행을 두 번 넣어서 표현한다.
- 덱은 15장이고, 같은 카드 최대 3장, 원소 카드 2종 이상, 시전 종류 카드 3종 이상이어야 한다.
- 손패는 6장이고 1초마다 한 장씩 뽑는다. fever 동안 간격이 절반이 된다.
- 마나 비용은 낸 카드들의 `mana_cost` 합이다. 사거리는 시전 종류 이름으로 `parameter_values` 에서 읽는다. `parameters.getValue("Shoot", "range")` 같은 식이다.
- 소유가 두 갈래다. `user_cards` 는 카드를 3장씩 갖고, `user_magics` 는 마법 해금 여부를 갖는다. 조합이 맞아도 그 마법을 갖고 있지 않으면 시전이 거부된다.
- 시전은 세 단계다. 카드를 하나씩 고르면 select 와 unselect 메시지가 오가고, 조합이 성립하면 조준으로 넘어가고, 위치를 찍으면 카드 목록과 위치를 담은 메시지를 보낸다.

## 새 모델

카드 한 장이 마법 하나다.

- `magics` 가 카드 목록이 된다. `magic_cards` 와 `cards` 는 없어진다.
- 원소는 마법의 속성으로 남는다. `magics.element` 에 `Fire`~`Wind` 와 `None` 이 들어간다. 원소 상성표 7x7(`ElementalChart`)은 그대로 쓴다.
- 시전 종류는 없앤다. `Shoot`, `Drop` 같은 5개짜리 축이 사라지므로 마나 비용과 사거리는 시전 종류 이름이 아니라 마법 이름으로 키를 옮긴다. `game_objects.name` 이 `magics.name` 과 같아지고, 값은 `parameter_values` 에 그대로 남는다.
- 조준 표시 모양만 마법별 값 하나로 남긴다. `aim_shape` 가 `1` 이면 직선, `0` 이면 원이다. 클라이언트가 조준선을 그릴 때 필요한 유일한 정보다. 지금은 `castType == Shoot` 인지로 판단하고 있다.
- 소유가 한 갈래가 된다. `user_magics` 에 `count` 가 생기고 `user_cards` 는 없어진다.
- 시전이 두 단계가 된다. 손패에서 카드를 고르면 그 마법이 정해지고, 위치를 찍으면 시전한다. 조합 조립, 조합 취소, 조합 미리보기, 조합 추천 UI 가 전부 없어진다.
- 덱 규칙은 15장, 같은 마법 카드 최대 3장, 서로 다른 원소 2종 이상이다. 앞의 두 숫자는 지금 값 그대로다. 원소 2종 이상은 지금의 "원소 카드 2종 이상"을 옮긴 것이다.
- 손패 6장과 1초 draw 간격, fever 는 그대로 둔다.

## 밸런스는 개편 직후 그대로 유지한다

마이그레이션이 옛 조합에서 초기값을 계산한다.

| 값 | 초기값 |
| --- | --- |
| `magics.element` | 조합에 가장 많이 든 원소 카드. 같으면 `cards.id` 가 작은 쪽. 원소 카드가 없으면 `None` |
| `mana_cost` | 조합에 든 카드들의 `mana_cost` 합. 같은 카드가 두 번 들었으면 두 번 더한다 |
| `range` | 조합에 든 시전 종류 카드의 `range` |
| `aim_shape` | 조합에 `Shoot` 이 있으면 `1`, 아니면 `0` |
| `user_magics.count` | 3. 지금 첫 로그인 지급이 카드마다 3장을 주는 것과 같은 수 |

그래서 개편 직후 어떤 마법의 마나와 사거리도 지금과 같다. 이후 밸런스 조정은 이 개편 밖의 일이다.

한 가지 주의할 점이 있다. 조합 SQL 이 이 저장소에 있는 마법은 19개뿐이고 나머지 약 50개의 조합은 운영 데이터베이스에만 있다. 위 계산은 SQL 로 하므로 운영과 dev 에서는 전부 채워지지만, 빈 데이터베이스에서 마이그레이션 체인을 재생해서 확인할 수는 없다. `V000` 이 `create database` 로 시작하는 `pg_catalog` 덤프라는 기존 제약과 같은 이유다.

## 덱과 소유 데이터는 새로 만든다

기존 덱 15장은 전부 원소·시전 종류 카드라 새 모델에서 의미가 없다. 마이그레이션이 모든 덱의 내용을 지우고 `access_type = 'DEFAULT'` 인 마법으로 15장짜리 기본 덱을 다시 채운다. `users.selected_deck_id` 와 덱 자체는 살아 있고 내용만 바뀐다. 되돌릴 수 없는 변경이다.

## 저장소별 영향

| 저장소 | 핵심 변경 | 이슈 |
| --- | --- | --- |
| [WordOnlineDatabase](https://github.com/Apptive-Game-Team/WordOnlineDatabase) | `magics` 에 `element` 추가, 마법별 parameter 값 seed, 덱·소유 이전, 통계 합치기, 옛 표 삭제 | #99 #100 #101 #102 #103 |
| [WordOnlineServer](https://github.com/Apptive-Game-Team/WordOnlineServer) | 조합 해석 제거, 시전 입력을 마법 id 하나로, parameter 키 이동, 봇, 통계 | #495 #496 #497 #498 #499 |
| [WordOnlineMatching](https://github.com/Apptive-Game-Team/WordOnlineMatching) | 덱 검증 규칙, 카드 목록 API, `/api/data/magics` 응답, 지급과 보상 | #116 #117 #118 |
| [WordOnlineAdmin](https://github.com/Apptive-Game-Team/WordOnlineAdmin) | 조합 편집기, 밸런스 화면의 마나 계산, 봇 덱, 통계 화면 | #105 #106 #107 #108 |
| [WordOnlineClient](https://github.com/Apptive-Game-Team/WordOnlineClient) | 카드 자료형과 아트, 손패와 시전, 덱 화면, 도감, 튜토리얼, 번역표 | #575 #576 #577 #578 #579 #580 |
| [WordOnline](https://github.com/Apptive-Game-Team/WordOnline) | 문서, 서브모듈 포인터, 전환 | #23 #24 #25 |

account, website, infra 는 바뀌지 않는다.

## 바꾸지 않는 것

- 원소 상성표 7x7. 서버 `ElementalChart` 와 클라이언트 `ElementChartView` 양쪽에 같은 값이 하드코딩되어 있고, 그대로 둔다.
- 마법 구현 클래스 구조. `AbstractShotMagic`, `AbstractDropMagic`, `AbstractSpawnMagic`, `AbstractSummonMagic`, `AbstractExplosionMagic` 은 그대로다. 없어지는 것은 데이터 쪽의 시전 종류 축이지 코드 구조가 아니다.
- 마법 bean 이름과 `magics.name` 이 같아야 한다는 규칙.
- 손패 6장, 1초 draw, fever 간격 절반.
- 매칭이 게임 서버에 넘기는 payload. 지금도 세션 식별자와 사용자 id 만 넘기고 덱 내용은 게임 서버가 데이터베이스에서 직접 읽는다.

## 트랙이 공유하는 계약

저장소 5개가 동시에 움직이므로 경계면을 먼저 못 박는다. 아래 형식이 기준이고, 바꾸려면 이 문서를 먼저 고친다.

### 데이터베이스 목표 스키마

```sql
magics(id bigserial primary key,
       name varchar(255) not null unique,
       element varchar(10) not null default 'None',   -- Fire|Water|Lightning|Rock|Nature|Wind|None
       access_type varchar(10) not null default 'DEFAULT')

user_magics(id bigserial primary key, user_id bigint, magic_id bigint,
            count integer not null default 3,
            unique(user_id, magic_id))

deck_cards(id bigserial primary key, deck_id bigint, magic_id bigint references magics,
           count integer not null default 1,
           unique(magic_id, deck_id))
```

- `element` 는 Postgres enum 이 아니라 `varchar(10)` 에 check 제약을 건다. `card_type` enum 은 지운다.
- `deck_cards` 는 표 이름을 그대로 두고 `card_id` 만 `magic_id` 로 바꾼다. `decks` 와 `users.selected_deck_id` 는 그대로다.
- `game_objects.name` 이 `magics.name` 과 같다. `parameters` 에 `mana_cost`, `range`, `aim_shape` 가 있고 `aim_shape` 는 `1` 이면 직선, `0` 이면 원이다.
- 통계는 `statistic_game_magics` 하나로 합치고 사용 횟수 컬럼을 둔다.
- `magics.cast_type` 은 운영 데이터베이스에 있지만 이 저장소의 마이그레이션 어디에서도 만들지 않는다. `V000` 이 덤프라서 생긴 기존 drift 다. 시전 종류를 없애므로 이 컬럼도 `drop column if exists` 로 지운다. 지금 이 컬럼을 읽는 곳은 lobby 의 `magic/domain/Magic.java` 다.
- `aim_shape` 초기값은 `magics.cast_type` 이 있으면 그 값에서, 없으면 조합에 `Shoot` 이 들어 있는지에서 정한다.

### 시전 프로토콜

STOMP 목적지는 지금과 같은 `/app/game/input/{sessionId}/{userId}` 다.

```json
{ "type": "useMagic",     "magicId": 34, "id": 7, "position": { "x": 9.0, "y": 0.0, "z": 5.0 } }
{ "type": "selectCard",   "magicId": 34, "id": 7 }
{ "type": "unselectCard", "magicId": 34, "id": 7 }
```

- `card` 와 `cards` 필드는 없어진다. `toggleCard` 와 `cancelCard` 도 없앤다. 한 번에 한 장만 고르므로 `unselectCard` 하나면 된다.
- `selectCard` 는 지금처럼 시전자에게 그 원소의 idle aura 를 붙이는 용도다. 원소는 서버가 `magics.element` 에서 찾는다.
- `id` 는 클라이언트가 매기는 요청 번호이고 `InputResponseDto` 가 그대로 돌려준다. `InputResponseDto` 형식은 바뀌지 않는다.
- frame 의 `cards.added` 는 카드 이름 문자열 목록에서 마법 id 목록(`long`)이 된다.

### 마법 목록 응답

`GET /api/data/magics`:

```json
{ "requiresRefresh": true, "version": 13, "source_url": "...",
  "magics": [ { "id": 34, "name": "leafair", "text": "...",
                "element": "Nature", "manaCost": 3, "aimShape": 0 } ] }
```

`castType` 과 `cards` 를 뺀다.

### 덱과 카드 목록 API

- `GET /api/users/mine/cards`, `GET /api/users/mine/cardLists` 의 항목은 `{ id, name, element, manaCost, count, unlocked, unlockText, progressText }` 다. `id` 는 `magics.id` 다.
- `POST`, `PUT /api/users/mine/decks` 의 본문은 `{ name, cardIds }` 형식을 그대로 둔다. 값만 `magics.id` 가 된다. 서버와 클라이언트 양쪽의 필드 이름 변경을 줄이려는 결정이다.
- 덱 규칙은 15장, 같은 마법 카드 최대 3장, 서로 다른 원소 2종 이상이다.

## 작업 규칙

- 각 저장소의 이슈 브랜치는 `magic-card` 에서 따고 `magic-card` 로 병합한다. base 를 `main` 으로 두지 않는다.
- 브랜치 이름과 label 규칙(`<label>/<번호>`), assignee 와 label 필수 규칙은 각 저장소의 `AGENTS.md` 를 그대로 따른다.
- WordOnlineDatabase 는 pull request 를 한 줄로 쌓는다. 마이그레이션 번호는 `main` 의 최고 번호보다 커야 한다. 작성 시점 기준 `main` 의 최고 번호는 `V067` 이다. `validate_migrations.yml` 은 pull request 의 base branch 기준으로만 순서를 검사하므로, `magic-card` 안에서만 번호를 맞추면 나중에 `main` 병합에서 순서가 깨진다.
- 버전은 pull request 마다 올리지 않는다. promotion 때 `deploy` 스킬이 한 번 올린다. 프로토콜이 깨지는 변경이므로 commit 메시지를 정확히 써야 MAJOR 로 올라간다.

## 전환 순서

1. 각 저장소 magic-card 마일스톤의 이슈를 전부 닫는다.
2. 각 저장소 magic-card 에 `main` 을 병합해서 그동안의 변경을 흡수한다.
3. WordOnlineDatabase 의 마이그레이션 번호가 `main` 의 최고 번호보다 큰지 다시 확인한다.
4. WordOnlineDatabase 의 magic-card 를 `main` 에 병합한다. push 즉시 dev 데이터베이스가 마이그레이션된다.
5. `test-env` 스킬로 복제본에서 game, lobby, admin, client 를 한 판 돌려 확인한다.
6. 나머지 4개 저장소를 병합하거나 default branch 를 옮긴다.
7. `deploy` 스킬로 promotion 한다. 데이터베이스가 먼저, 그다음 서버, 마지막이 클라이언트다.

전환 계획은 [WordOnline#25](https://github.com/Apptive-Game-Team/WordOnline/issues/25) 에서 관리한다.
