---
name: deploy
description: Create or reuse GitHub pull requests from main to deploy across the WordOnline monorepo root and its Git submodules, then merge only repositories with commits to promote. Use when the user invokes $deploy or asks to promote, merge, or deploy all eligible repository main branches into deploy.
---

# Deploy Main Branches

Promote `main` to `deploy` independently in each Git repository. Preserve every local checkout and working tree.

## Safety Rules

- Run from WordOnline monorepo root containing `.gitmodules`.
- Include root repository and every initialized submodule declared in `.gitmodules`.
- Use `origin/main` and `origin/deploy` as source of truth after fetching.
- Never create a missing `main` or `deploy` branch.
- Never switch branches, pull, push, reset, stash, or edit files.
- Never bypass conflicts, required checks, reviews, or branch protection.
- Never delete `main` or `deploy`.
- Process repositories independently. One failure must not block other eligible repositories.
- When `gh` authentication fails only inside sandbox, retry same `gh` command with escalated execution before reporting auth failure.

## Workflow

1. Verify tools and root:

   ```bash
   git rev-parse --show-toplevel
   test -f .gitmodules
   gh auth status
   ```

2. Build repository list:
   - Add `.` first.
   - Read submodule paths with Git config, not manual text parsing:

     ```bash
     git config -f .gitmodules --get-regexp '^submodule\..*\.path$'
     ```

   - Skip declared submodules that are not initialized Git repositories.

3. For each repository path:
   - Resolve and record `origin` URL.
   - Refresh remote refs without changing local branches:

     ```bash
     git -C <path> fetch --prune origin
     ```

   - Verify both refs:

     ```bash
     git -C <path> show-ref --verify --quiet refs/remotes/origin/main
     git -C <path> show-ref --verify --quiet refs/remotes/origin/deploy
     ```

   - If either remote branch does not exist, mark `skipped: missing main` or `skipped: missing deploy`.
   - Count source-only commits:

     ```bash
     git -C <path> rev-list --count origin/deploy..origin/main
     ```

   - If count is `0`, mark `skipped: up to date`. Do not create a PR.

4. For each repository with source-only commits:
   - Run every GitHub command with explicit `-R <owner/repo>`.
   - Find an existing open PR whose base is `deploy` and head is `main`.

     ```bash
     gh pr list -R <owner/repo> --state open --base deploy --head main \
       --json number,url
     ```

   - Reuse that PR when found. Never create a duplicate.
   - Otherwise create:

     ```bash
     gh pr create -R <owner/repo> --base deploy --head main \
       --title "Deploy main to deploy" \
       --body "Promotes the current main branch to deploy."
     ```

5. Validate PR before merge:
   - Confirm base is `deploy`, head is `main`, state is open, and PR is mergeable.
   - Wait for required checks:

     ```bash
     gh pr checks -R <owner/repo> <pr> --required --watch --fail-fast
     ```

   - If no required checks are configured, continue.
   - If checks fail, PR conflicts, reviews are required, or protection blocks merge, leave PR open and mark `blocked`.

6. Merge eligible PR:

   ```bash
   gh pr merge -R <owner/repo> <pr> --merge
   ```

   Do not pass `--admin`, `--auto`, or `--delete-branch`.

7. Report one row per repository:

   | Repository | Commits | PR | Result |
   |---|---:|---|---|
   | owner/repo | 3 | URL | merged |
   | owner/repo | 0 | - | skipped: up to date |
   | owner/repo | - | - | skipped: missing deploy |
   | owner/repo | 2 | URL | blocked: checks failed |

End with totals for `merged`, `skipped`, `blocked`, and `failed`.

## Failure Handling

- `fetch` network failure: retry once with escalated execution when sandbox networking is likely responsible.
- GitHub auth failure: retry with user session credentials through escalated execution.
- Ambiguous multiple matching PRs: do not merge; report `blocked`.
- Merge command failure: refresh PR state once, report exact GitHub reason, continue to next repository.
