# Initializing `.db.env`

`.db.env` in the monorepo root tells the `test-env` skill which database to
clone. It is gitignored (`*.env`) and never committed.

When it is missing, do not ask the user to type credentials by hand. The
credentials already exist in the submodule `.env` files on this machine.
Compose `.db.env` from them using the procedure below.

## Default target: the dev database

**Point `.db.env` at the dev database unless the user explicitly asks for
another environment.** The dev database is the one the servers are expected to
be developed against, and cloning it cannot disturb live players.

The two databases are distinguished only by their database name in the URL:

| Environment | Where the URL lives | Notes |
|---|---|---|
| **dev** (default) | `game/.env` → `DATABASE_URL`, or `admin/.env` → `DEV_DATABASE_URL` | Both point at the dev database. |
| production | `admin/.env` → `DATABASE_URL`, or `lobby/.env` → `DATABASE_URL` | Real player data. Clone only on an explicit request, and say so plainly first. |

Do not guess a database name. Read it out of the file.

## Procedure

1. Check whether `.db.env` already exists in the monorepo root. If it does,
   stop — do not overwrite it. Read back only `SOURCE_LABEL` and the host and
   database name so the user can confirm the target.

2. Find the dev URL and its credentials. `game/.env` carries all three in the
   naming the template expects:

   ```bash
   grep -E '^DATABASE_(URL|USER|PW)=' game/.env
   ```

   If `game/` has no `.env`, fall back to `admin/.env` and its `DEV_` prefixed
   keys:

   ```bash
   grep -E '^DEV_DATABASE_(URL|USER|PW)=' admin/.env
   ```

   If neither file exists, the submodules are not initialized. Run
   `git submodule update --init --recursive` and retry. If the files exist but
   have no dev entry, ask the user — do not substitute the production URL.

3. Copy the template and fill it in:

   ```bash
   cp .db.env.example .db.env
   ```

   Map the values:

   | `.db.env` key | Source |
   |---|---|
   | `SOURCE_LABEL` | `dev` |
   | `SOURCE_DATABASE_URL` | `DATABASE_URL` from `game/.env` (the `jdbc:` prefix is fine; the script strips it) |
   | `SOURCE_DATABASE_USER` | `DATABASE_USER` |
   | `SOURCE_DATABASE_PASSWORD` | `DATABASE_PW` |

   Leave the `LOCAL_*` defaults alone unless a port is already taken.

4. Optional, only when the user wants to run the `account` server. It uses a
   separate database, whose URL and credentials live in `account/.env`:

   ```bash
   grep -E '^ACCOUNT_DATABASE_(URL|USERNAME|PASSWORD)=' account/.env
   ```

   Map those to `SOURCE_ACCOUNT_DATABASE_URL`, `SOURCE_ACCOUNT_DATABASE_USER`,
   and `SOURCE_ACCOUNT_DATABASE_PASSWORD`. Without them, `env-patch account`
   points the account server at a database that was never populated.

5. Verify without leaking anything, then report the host, database name, and
   label to the user — never the password:

   ```bash
   grep -E '^SOURCE_(LABEL|DATABASE_URL|ACCOUNT_DATABASE_URL)=' .db.env
   ```

## Rules

- Never echo, log, or summarize a password read out of a module `.env`. Move it
  into `.db.env` and refer to it by key name afterwards.
- Never write a real host or credential into `.db.env.example`, this document,
  or any other committed file. The template stays placeholders-only
  (repository `AGENTS.md` §4).
- Never `git add` `.db.env`. Confirm it is ignored if in doubt:

  ```bash
  git check-ignore -v .db.env
  ```

- The source database stays read-only. Composing `.db.env` grants the skill a
  `pg_dump` connection and nothing more.
