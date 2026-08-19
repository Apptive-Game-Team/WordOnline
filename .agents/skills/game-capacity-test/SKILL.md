---
name: game-capacity-test
description: Measure how many concurrent game sessions a WordOnline game server holds at a given CPU and memory limit, by binary searching the bot session count against the loop frame rate. Use when asked how many sessions a server takes, how many bot sessions it survives, what to size a container at, or to check whether a change made the game loop cheaper or more expensive.
---

# Game Server Capacity Test

Answer "how many sessions does one game server hold" with a number that came from a
measurement. The server fills itself with self-play bot games, so the load needs no client:
set `BOT_AUTO_MATCH_TARGET_GAMES` and the scheduler tops the server up to that many sessions
every check interval.

One trial is one container at a fixed session count. The search doubles the count until a
trial fails, then binary searches between the last pass and the first failure.

## What counts as holding the load

The loops target 20 frames per second (`GameLoop.FPS`). A trial passes when, over a settled
sampling window:

- the tenth percentile session stays at or above the pass threshold, 15 fps by default;
- no loop stalls past ten seconds and none is reaped by `GameLoopWatchdog`;
- the container is not OOM killed and the JVM throws no `OutOfMemoryError`.

Three details are what make the number trustworthy, and each of them was wrong in an earlier
version of this rig:

- **Percentile, not mean.** The mean stays comfortable long after the slowest sessions have
  become unplayable. At 128 sessions on one core the mean read 15.3 fps while the tenth
  percentile was 10.2 and the worst session was under 3.
- **Rate the frame in flight.** `GameContext.getDeltaTime()` holds the last *completed* frame,
  so a loop that has been off the CPU for eight seconds still reports the 20 fps of the frame
  before it stalled. Take `1 / max(deltaTime, secondsSinceLastFrameEnded)` instead.
- **Count the reaps.** A run that keeps its frame rate by losing sessions did not hold the
  load. `GameLoopWatchdog` reaps a loop that stops completing frames and the session is
  recorded `ABANDONED`, which is invisible in a frame rate average taken over the survivors.

## Prerequisites

- Docker, and a JDK for the Gradle build.
- A checkout of the monorepo with the `game` and `database` submodules.
- `keys/public.pem` at the monorepo root, used as `JWT_PUBLIC_KEY`.

## Procedure

### 1. Pick the tree under test and instrument it

Build from a scratch copy or a worktree, never from a working checkout, so the measurement
cannot pick up unrelated local edits and the harness cannot dirty them:

```bash
mkdir -p /tmp/capacity/game && git -C game archive origin/main | tar -x -C /tmp/capacity/game
```

The frame rate is not exposed as a metric by the server. Copy `resources/LoopFpsMetrics.java`
into `src/main/java/com/wordonline/server/session/service/` of that copy; it publishes
`wordonline_loop_fps_{mean,p10,min}`, `wordonline_loop_sessions` and `wordonline_loop_stalled`
on the management port, which is where `scripts/capacity-search.sh` reads them. Keep it out of
the committed tree unless it is being landed deliberately.

Build the image:

```bash
cd /tmp/capacity/game && ./gradlew bootJar -x test
printf 'FROM eclipse-temurin:21-jre\nWORKDIR /app\nCOPY %s app.jar\nENTRYPOINT ["java","-jar","app.jar"]\n' \
    "$(basename build/libs/*.jar)" > build/libs/Dockerfile
docker build -t ac-loadtest-game:local build/libs
```

### 2. Bring up the database

```bash
.agents/skills/game-capacity-test/scripts/setup-db.sh --migrations <path-to-database>/migration
```

The migrations must come from a checkout that is **at least as new as the game tree under
test**, or the server will not boot. A game built from `origin/main` reads
`servers.target_bot_sessions`, which arrived in the database repository separately; a stale
`database/` checkout leaves the column out and the application fails at startup with
`column s1_0.target_bot_sessions does not exist`. Extract the migrations from `origin/main`
rather than trusting the submodule's working checkout:

```bash
git -C database archive origin/main migration | tar -x -C /tmp/capacity
```

Two quirks the script already handles, worth knowing when it breaks:

- `V000_20260406__init_tables.sql` is an IDE-generated dump that redeclares parts of
  `information_schema` and `pg_catalog`. Flyway refuses it, so the script applies it through
  `psql` twice, ignoring the catalog errors, and then baselines Flyway at `000.20260406`.
- `magic_tags` and `tag_counter_rules` exist on the deployed databases but no migration in the
  repository creates them. The script creates them empty. Bot counter weights therefore read
  zero in this rig; that is a small understatement of the per-cast work.

### 3. Search

```bash
.agents/skills/game-capacity-test/scripts/capacity-search.sh \
    --image ac-loadtest-game:local --cpus 1 --memory 1g --fps-pass 15 --start 8 --max 256
```

Each trial starts a fresh container, waits for health, waits for the session count to reach
nine tenths of the target, warms up, then samples. Results land in a CSV: target, verdict,
p10, mean and worst frame rate, average session count, stalls, memory, and the reason for a
failure.

Useful options: `--warmup` and `--sample` (seconds, default 45 and 60), `--poll`, `--out`,
`--start`, `--max`, `--cpus`, `--memory`, `--fps-pass`.

### 4. Keep the box quiet

The container is capped by a cgroup quota, but the harness is not the only thing on the
machine. Do not run a Gradle build, another container, or anything else heavy while a trial is
sampling; if it cannot be avoided, pin it away from the load (`taskset -c 8-15 nice -n 19 ...`)
and re-run the affected trial afterwards to confirm the verdict.

Leave `DISCORD_WEBHOOK_URL` unset for the run. With a webhook configured the server alerts on
sessions below 15 fps, which is precisely what a capacity search spends its time producing.

## Measured baseline

Game server `origin/main` at `7c427e4`, one CPU and 1 GiB, JVM defaults (max heap 256 MiB),
bot self-play sessions, pass threshold 15 fps at the tenth percentile:

| target sessions | verdict | p10 fps | mean fps | worst session | memory |
| --- | --- | --- | --- | --- | --- |
| 8 | pass | 19.68 | 19.90 | 19.61 | 305 MiB |
| 16 | pass | 19.77 | 19.94 | 18.87 | 317 MiB |
| 32 | pass | 19.62 | 19.90 | 18.52 | 333 MiB |
| 64 | pass | 18.90 | 19.70 | 12.82 | 331 MiB |
| 96 | pass | 15.37 | 17.41 | 5.08 | 351 MiB |
| 104 | pass | 16.60 | 18.05 | 9.17 | 360 MiB |
| 105 | fail | 13.71 | 17.00 | 9.09 | 354 MiB |
| 106 | fail | 13.90 | 15.57 | 8.70 | 350 MiB |
| 108 | fail | 11.80 | 15.28 | 0.50 | 359 MiB |
| 128 | fail | 10.20 | 13.60 | 2.82 | 369 MiB |

The search settled at 104 sessions, with the first failure at 105. Roughly one hundred
sessions per core. Read the boundary as a band rather than a line: the
trials either side of it sit within a couple of frames per second of each other, and each
verdict comes from a single sixty second window.

CPU is the limit, not memory: the container never went past 370 MiB of its gigabyte, and no
trial stalled or was reaped even well past the frame rate threshold — the loops degrade
smoothly rather than dying.

Re-run the search after any change to the loop, the bot brain, or the systems the loop drives,
and compare against this table rather than against a remembered number.
