# pi-scaps reproducible Pi harness: detailed implementation tasks

Status: in progress

This is the single execution checklist for implementing the Pi harness skeleton.

Source documents:

- [Original PRD](./pi-scaps_reproducible_pi_harness_skeleton.md) — original scope and provenance.
- [Audited PRD Version 02](./pi-scaps_reproducible_pi_harness_skeleton_v02.md) — current implementation authority.
- [Review findings](./pi-scaps_reproducible_pi_harness_review.md) — rationale for the Version 02 corrections.
- [Full earlier answer](./missed_things.md) — source material behind the original PRD and review.

If the original PRD conflicts with Version 02, follow Version 02. This checklist does not replace either PRD; it turns the audited requirements into checkable work groups.

## How to use this checklist

- Complete groups in order unless a task is explicitly independent.
- Change `[ ]` to `[x]` only after the task and its stated verification are complete.
- Tick a group-complete box only when every required checkbox in that group is complete.
- Record material deviations or blocked checks in the execution notes at the bottom.
- Do not weaken a requirement merely because the current development machine lacks the required Node or Pi version.
- Do not add features listed as out of scope in PRD Version 02 section 17.

## Group 0 — Preflight and scope protection

References: PRD v02 sections 1–5, 16, and 17.

- [x] Inspect `git status --short` and record pre-existing tracked and untracked changes before editing.
- [x] Confirm the implementation target is `@earendil-works/pi-coding-agent` version `0.87.1` with Node `>=24.21.0`.
- [x] Confirm the repository is intended to be used directly as Pi's global agent directory, not installed as a Pi package.
- [x] Confirm the default installation remains a clone at `~/.pi/agent`, with `PI_CODING_AGENT_DIR` documented only as an alternative.
- [x] Confirm no existing user files will be overwritten or deleted during implementation.
- [x] Keep all PRD and review files under `tasks/`; do not rewrite their history during implementation.
- [x] Confirm that speculative extensions, skills, prompts, themes, agent roles, orchestration, MCP, telemetry, CI, automatic Node installation, and automatic Pi installation remain out of scope.
- [x] Record whether full runtime verification is possible on the current machine; if not, continue with implementation and static checks, then clearly record the outstanding runtime checks.
- [x] **Group 0 complete: scope and starting state are understood.**

## Group 1 — Repository safety and inert structure

References: PRD v02 sections 4.2, 4.3, 4.7, 6, 7.6, 7.7, 8, 9, and 15.

### `.gitignore`

- [x] Replace the generic root `.gitignore` with the harness-specific rules required by PRD v02 section 9.
- [x] Ignore root credential and local-provider files: `/auth.json`, `/auth.json.lock/`, `/oauth.json`, and `/models.json`.
- [x] Ignore root Pi state: `/sessions/`, `/models-store.json`, `/crashes.json`, `/settings.json.lock/`, `/trust.json`, `/trust.json.lock/`, `/pi-debug.log`, `/logs/`, root `/tmp/`, and log files.
- [x] Ignore root Pi-managed install locations: `/git/`, `/npm/`, `/bin/`, and `/tools/`.
- [x] Ignore local dependency and environment directories: `node_modules/`, `/venv/`, and `/.venv/`.
- [x] Ignore likely secret-bearing local files: `.env`, `.env.*` except `.env.example`, `.npmrc`, `*.secret`, `*.pem`, and `*.key`.
- [x] Preserve root anchoring for Pi-owned directories so similarly named source directories inside future extensions remain trackable.
- [x] Verify that `settings.json`, `models.json.example`, package metadata, instructions, scripts, and intentional resources are not ignored.

### Required directories

- [x] Create `extensions/`, `skills/`, `prompts/`, `themes/`, `agents/`, and `scripts/` if absent.
- [x] Add zero-content `.gitkeep` files to `extensions/`, `skills/`, `prompts/`, and `themes/`.
- [x] Do not place placeholder Markdown files in `extensions/`, `skills/`, `prompts/`, or `themes/`.
- [x] Create `agents/README.md` explaining that `agents/` is a harness convention for future role definitions, not a Pi-native auto-discovery directory.
- [x] Ensure `agents/README.md` distinguishes role instructions, model choice, thinking level, and task/context allocation.
- [x] Do not create speculative architect, worker, reviewer, or scout role files.
- [x] **Group 1 complete: state is ignored and the initial resource structure is inert.**

## Group 2 — Canonical configuration and dependency metadata

References: PRD v02 sections 3, 7, 13.8, and 14.

### Global instructions

- [x] Create concise root `AGENTS.md` identifying the checkout as the global Pi harness.
- [x] In `AGENTS.md`, prefer simplicity, low token overhead, demonstrated reusable needs, reproducible changes, and preservation of pinned versions.
- [x] In `AGENTS.md`, forbid committing secrets and runtime state.
- [x] Keep `AGENTS.md` short enough to avoid unnecessary global context overhead.

### Pi settings and model example

- [x] Create strict `settings.json` with `lastChangelogVersion` set to `0.87.1`, `defaultThinkingLevel` set to `medium`, and `sessionDir` set to `~/.local/state/pi/sessions`.
- [x] Serialize the initial `settings.json` with two-space indentation and no final newline, matching current Pi write behavior.
- [x] Do not add provider credentials, fabricated model IDs, private endpoints, usernames, account IDs, or empty package declarations.
- [x] Create strict `models.json.example` containing only `{ "providers": {} }` in formatted JSON.
- [x] Do not create a real tracked `models.json`.

### Node and Pi contract

- [x] Create root `package.json` with the name, private flag, description, and version specified in PRD v02 section 7.4.
- [x] Set `package.json.engines.node` to `>=24.21.0`.
- [x] Set `package.json.piHarness.package` to `@earendil-works/pi-coding-agent`.
- [x] Set the authoritative `package.json.piHarness.version` to `0.87.1`.
- [x] Verify that `settings.json.lastChangelogVersion` exactly mirrors `package.json.piHarness.version`.
- [x] Do not add `keywords: ["pi-package"]`, a root `pi` package manifest, or unused dependencies.
- [x] Generate `package-lock.json` with a supported Node/npm environment; do not hand-author it.
- [x] Immediately parse `settings.json`, `models.json.example`, `package.json`, and `package-lock.json` as strict JSON.
- [x] **Group 2 complete: canonical tracked configuration and version metadata exist.**

## Group 3 — Bootstrap script

References: PRD v02 section 10 and acceptance sections 18.2–18.7.

- [x] Create executable `scripts/bootstrap.sh` using `#!/usr/bin/env bash` and `set -euo pipefail`.
- [x] Resolve the repository root from the script's own location and operate correctly from any caller working directory.
- [x] Check that `node`, `npm`, and `pi` are available before attempting dependent work.
- [x] Read the Node requirement and expected Pi package/version from `package.json`; do not maintain an independent script version constant.
- [x] Correctly compare the installed Node semantic version with the declared minimum.
- [x] Normalize and compare `pi --version` with the exact declared Pi version.
- [x] On missing or mismatched Pi, fail non-zero and print the exact pinned `npm install -g --ignore-scripts ...` remediation command derived from metadata.
- [x] Print concise installed Node, npm, and Pi version information.
- [x] Run `npm ci` when `package-lock.json` exists.
- [x] Create `$HOME/.local/state/pi/sessions` idempotently without touching existing session contents.
- [x] Run `scripts/doctor.sh`, or clearly direct the user to it, consistently with the final README.
- [x] Print concise next steps for doctor, starting Pi, and `/login`.
- [x] Confirm bootstrap does not install Node, install or upgrade Pi, create credentials, edit shell profiles, call `pi update`, delete directories, or install undeclared Pi packages.
- [x] Run `bash -n scripts/bootstrap.sh`.
- [x] **Group 3 complete: bootstrap is safe, metadata-driven, and idempotent.**

## Group 4 — Doctor script

References: PRD v02 section 11 and acceptance sections 18.3–18.12.

### Framework and activation

- [x] Create executable `scripts/doctor.sh` using strict Bash behavior.
- [x] Emit concise `[PASS]`, `[WARN]`, `[INFO]`, and `[FAIL]` statuses.
- [x] Accumulate independent failures where practical and return non-zero if any required check fails.
- [x] Resolve the repository root independently of the caller's working directory.
- [x] Check that the checkout is a Git working tree and required tracked files/directories exist.
- [x] Check that all three scripts have executable bits.
- [x] Resolve the active agent directory from `PI_CODING_AGENT_DIR` or default `$HOME/.pi/agent`.
- [x] Canonicalize the checkout and active-agent paths so valid symlinked paths compare correctly.
- [x] Fail with direct remediation if the checkout is not Pi's active agent directory.

### Runtime and configuration

- [x] Validate Node against `package.json.engines.node` and show expected versus actual values on failure.
- [x] Validate installed Pi exactly against `package.json.piHarness.version` and show the pinned remediation command on failure.
- [x] Parse all four committed JSON files strictly without requiring `jq` or Python.
- [x] Validate that `piHarness.package`, `piHarness.version`, `settings.json.sessionDir`, and `settings.json.lastChangelogVersion` are present and correctly related.
- [x] Validate the effective session directory, including the `PI_CODING_AGENT_SESSION_DIR` override when set.
- [x] Verify the effective session directory exists, is writable, and resolves outside the checkout.
- [x] Run `npm ls --depth=0` without running `npm ci` or otherwise changing installed dependencies.

### Resources and Pi startup

- [x] Verify `extensions/`, `skills/`, `prompts/`, `themes/`, and `agents/` exist.
- [x] Require skeleton `.gitkeep` files only while their corresponding directory has no real tracked resource.
- [x] Report informational counts for real extensions, skills, prompts, and themes without counting `.gitkeep`.
- [x] Run an offline non-model startup diagnostic using the active agent directory, equivalent to `PI_OFFLINE=1 pi --list-models`.
- [x] Treat a non-zero offline Pi diagnostic as a doctor failure.

### Git and secret safety

- [x] Fail if `git ls-files` contains forbidden credentials, provider configuration, sessions, crash records, caches, lock directories, managed packages/binaries, temporary files, or root logs.
- [x] Cover at least every forbidden path listed in PRD v02 section 11.2.
- [x] Report authentication only as the presence or absence of stored `auth.json`.
- [x] Never parse, display, or enumerate credentials, credential providers, or environment credential values.
- [x] Print a concise healthy summary when all required checks pass.
- [x] Run `bash -n scripts/doctor.sh`.
- [x] **Group 4 complete: doctor proves the checkout is active, compatible, safe, and loadable.**

## Group 5 — Harness update script

References: PRD v02 section 12 and acceptance section 18.13.

- [x] Create executable `scripts/update.sh` using strict Bash behavior.
- [x] Resolve the repository root from the script's own location.
- [x] Confirm the target is a Git working tree.
- [x] Refuse to run when tracked or untracked non-ignored changes exist.
- [x] Use `git pull --ff-only` and never create an implicit merge commit.
- [x] Run `npm ci` after a successful pull.
- [x] Run `scripts/doctor.sh` after dependency installation.
- [x] Do not stash changes automatically.
- [x] Do not call `pi update`, silently change the Pi pin, or perform unpinned external upgrades.
- [x] Return non-zero on any failure.
- [x] Run `bash -n scripts/update.sh`.
- [x] **Group 5 complete: harness updates are fast-forward-only and respect the version contract.**

## Group 6 — Operational README

References: PRD v02 sections 5 and 13.

- [x] Replace the root README with the required title and concise harness description.
- [x] Explain that the repository is a portable global Pi harness, not a conventional application or separately installable Pi package.
- [x] Document Linux, Bash, Node `>=24.21.0`, the Node 24.21.0-or-newer recommendation, and the exact pinned Pi install command.
- [x] Document the default fresh-install sequence: install prerequisites, clone to `~/.pi/agent`, bootstrap, doctor, start Pi, and authenticate with `/login`.
- [x] Document safe handling of an existing `~/.pi/agent`: stop, back it up, inspect it, merge only intentional non-secret configuration, and never let scripts overwrite it.
- [x] Document `PI_CODING_AGENT_DIR` as an alternative and explain that it redirects both configuration and writable Pi state.
- [x] Describe every initial tracked directory and file responsibility.
- [x] Mention `keybindings.json`, `SYSTEM.md`, and `APPEND_SYSTEM.md` as supported future files that are deliberately absent.
- [x] Explain global resource discovery versus the separate Pi package-manifest mechanism.
- [x] Explain local extension dependencies versus pinned external Pi packages.
- [x] Prominently warn against committing credentials, real `models.json`, sessions, crash diagnostics, trust state, downloaded packages, caches, or lock directories.
- [x] Explain that sessions live at `~/.local/state/pi/sessions` and must be transferred separately and privately if wanted.
- [x] Explain that Pi may legitimately rewrite tracked `settings.json` after a persisted settings change and that the diff must be reviewed, committed, or reverted.
- [x] Document `./scripts/update.sh` and clarify that it updates the harness rather than Pi itself.
- [x] Document rollback with `git log --oneline` and `git revert <commit>` without imposing a commit convention.
- [x] Add a repository-owner action to verify GitHub secret scanning and push protection.
- [x] Keep the philosophy section short and aligned with Pi's minimal-core approach.
- [x] **Group 6 complete: a new-machine operator can install, update, recover, and understand the harness.**

## Group 7 — Static and repository-level verification

References: PRD v02 sections 18.1, 18.8–18.10, 18.12, 18.14, and 20.

- [x] Use `git ls-files | sort` to compare the tracked implementation with the required repository structure.
- [x] Confirm no scanned placeholder `README.md` exists under `extensions/`, `skills/`, `prompts/`, or `themes/`.
- [x] Parse `package.json`, `package-lock.json`, `settings.json`, and `models.json.example` with `JSON.parse`.
- [x] Run `bash -n scripts/bootstrap.sh scripts/doctor.sh scripts/update.sh`.
- [x] Verify all scripts are executable.
- [x] Run `npm ci` with a supported Node/npm version.
- [x] Run `npm ls --depth=0`.
- [x] Exercise `.gitignore` rules with representative forbidden root paths and verify intentional configuration remains unignored.
- [x] Inspect `git ls-files` explicitly for every forbidden credential and runtime path.
- [x] Inspect the diff for accidental credentials, private endpoints, tokens, usernames, machine paths, or generated runtime data without printing any real secret contents.
- [x] Run `git diff --check`.
- [x] Confirm README filenames, commands, versions, paths, and script behavior agree with the implementation.
- [x] Confirm no out-of-scope feature or dependency was introduced.
- [x] Replace the hand-written Git hook with a pinned Python `pre-commit` configuration using maintained standard hooks and ShellCheck.
- [x] Keep local hooks limited to Pi-specific metadata, forbidden state paths, resource placeholders, and `npm ls --depth=0`.
- [x] Pin the framework in `requirements-dev.txt` and document isolated installation plus the normal `pre-commit install` workflow.
- [x] **Group 7 complete: static validation and repository safety checks pass.**

## Group 8 — Runtime, negative-path, and portability verification

References: PRD v02 sections 18.2–18.7, 18.11, 18.13, and 20.

### Supported development checkout

- [ ] Use a machine or isolated environment with Node `>=24.21.0` and Pi `0.87.1`.
- [ ] From the development checkout, run `PI_CODING_AGENT_DIR="$PWD" ./scripts/bootstrap.sh` successfully.
- [ ] Run bootstrap a second time and confirm it remains safe and idempotent.
- [ ] Run `PI_CODING_AGENT_DIR="$PWD" ./scripts/doctor.sh` successfully twice.
- [ ] Run `PI_CODING_AGENT_DIR="$PWD" PI_OFFLINE=1 pi --list-models` successfully without a model request.
- [ ] Confirm the effective session directory exists, is writable, and is outside the checkout.
- [ ] Confirm bootstrap, repeated doctor runs, and the offline Pi diagnostic leave `git status --short` empty on a clean checkout.

### Negative paths

- [ ] Verify doctor fails clearly when the checkout is not the active Pi agent directory.
- [ ] Verify missing Pi produces a non-zero result and the exact pinned install command.
- [ ] Verify a mismatched Pi version produces a non-zero result showing expected and actual versions.
- [x] Verify an unsupported Node version produces a clear non-zero result.
- [ ] Verify a session directory resolving inside the checkout is rejected.
- [ ] Verify an unwritable effective session directory is rejected where the platform permits a reliable test.
- [ ] Verify a tracked forbidden-state fixture is rejected in a disposable test repository; do not add a real credential.
- [ ] Verify authentication absence remains informational rather than causing doctor failure.
- [ ] Verify `scripts/update.sh` refuses a dirty tree.
- [ ] Test successful update behavior only in a disposable clean clone or controlled branch where `git pull --ff-only` is safe.

### Fresh-clone portability

- [ ] In a clean disposable home or second machine, clone the repository to the effective `~/.pi/agent` location.
- [ ] Run bootstrap and doctor without editing either script.
- [ ] Start Pi and confirm no session file is created inside the repository.
- [ ] Confirm first startup at the pinned Pi version does not create a changelog-only `settings.json` diff.
- [ ] If a Pi setting is intentionally persisted, confirm the resulting tracked `settings.json` change remains visible for review.
- [ ] **Group 8 complete: runtime, failure-mode, and fresh-machine checks pass.**

## Group 9 — Final audit and handoff

References: PRD v02 sections 18–23.

- [ ] Re-run the complete minimum verification command set from PRD v02 section 20.
- [ ] Re-run doctor from the active agent-directory context.
- [ ] Confirm all acceptance criteria in PRD v02 section 18 are satisfied or explicitly recorded as blocked by the environment.
- [ ] Confirm no credentials, sessions, crash records, caches, trust data, managed packages, lock directories, or generated logs are tracked.
- [ ] Confirm the final working-tree diff contains only intentional harness implementation and documentation changes.
- [ ] Confirm no unrelated pre-existing user changes were overwritten, reformatted, staged, or deleted.
- [ ] Leave the license choice to the repository owner; do not invent one as part of this task.
- [ ] Record final verification results and any environment-limited checks in the execution notes.
- [ ] Provide the repository owner with the one-time GitHub secret-scanning and push-protection reminder.
- [ ] **Group 9 complete: implementation is ready for commit and transfer to another computer.**

## Overall completion

- [ ] All group-complete boxes are checked.
- [ ] All required runtime checks pass on a supported machine.
- [ ] PRD Version 02 acceptance criteria are satisfied.
- [ ] The harness can be recreated on another Linux computer using the documented short installation sequence.
- [ ] **The reproducible Pi harness skeleton is complete.**

## Execution notes

Add dated notes here only for material decisions, deviations, blocked checks, or evidence that would help resume the work. Do not paste credentials or private runtime data.

- 2026-09-24 — Group 0 was completed retrospectively after Group 1 was supplied first. Before Group 1 edits, `git status --short` showed a staged `.gitignore` modification and the untracked `tasks/` directory. The staged change added an unanchored `venv` rule; Group 1 intentionally replaced the generic ignore file and preserved that intent as `/venv/`. No unrelated file was overwritten or deleted.
- 2026-09-24 — The implementation contract is `@earendil-works/pi-coding-agent` `0.87.1` on Node `>=22.19.0`, using the checkout directly as the global agent directory. The default remains `~/.pi/agent`; `PI_CODING_AGENT_DIR` is only an alternative. PRD and review material remains under `tasks/`, and Version 02 section 17 remains the scope boundary.
- 2026-09-24 — Full runtime verification is unavailable on this machine: installed Node is `v20.19.5`, npm is `10.8.2`, and `pi` is not installed. Static work may continue, but all supported-runtime checks remain outstanding until Node `>=22.19.0` and Pi `0.87.1` are available.
- 2026-09-24 — Group 2 is partially blocked by the supported-runtime requirement. `package.json` and its Pi/Node contract are complete, but `package-lock.json` was not generated because the installed NVM versions are only Node 18 and 20. The lockfile, four-file JSON parse, and Group 2 completion boxes remain open until Node `>=22.19.0` is available.
- 2026-09-24 — Group 7 static checks passed for inert resources, Bash syntax, executable modes, `npm ls --depth=0`, `.gitignore` behavior, forbidden tracked paths, redacted sensitive-diff review, README/implementation consistency, and scope. The README clone example was corrected to the canonical GitHub URL. The required tracked-structure comparison still lacks `package-lock.json`; four-file JSON parsing and supported-runtime `npm ci` therefore remain open, as does Group 7 completion. Exact `git diff --check` passed for the unstaged diff, while a supplemental `git diff --cached --check` reported a pre-existing extra blank line at EOF in the original PRD; scope protection leaves that source document unchanged. One generic absolute-path example in the original PRD was reviewed in redacted form and is an explicit example of what scripts must avoid, not leaked machine data.
- 2026-09-24 — Node `v24.21.0` with npm `11.19.0` is now installed and was selected explicitly for verification. It generated `package-lock.json` through npm, parsed all four committed JSON formats, and passed `npm ci` plus `npm ls --depth=0`. This supersedes the earlier Node-version block for Groups 2 and 7. Pi remains unavailable. At the time of verification the new lockfile was untracked, so the Group 7 completion box remains open until the tracked-file audit can see it.
- 2026-09-24 — At the repository owner's request, the harness minimum Node contract was raised from `>=22.19.0` to `>=24.21.0`. `package.json` remains authoritative; bootstrap and doctor consume that metadata rather than duplicating the version. README, PRD Version 02, the execution checklist, and the npm-generated lockfile were aligned. Historical source/review documents and earlier dated execution notes retain the old value as provenance. Bootstrap was exercised with retained Node `v20.19.5` and correctly failed non-zero while reporting the new minimum.
- 2026-09-24 — Added a tracked dependency-free Bash pre-commit hook under `.githooks/`. Activation is deliberately explicit and repository-local. The hook validates the staged index and repository safety but does not install dependencies, invoke Pi, contact the network deliberately, or replace GitHub secret scanning. It passed against a disposable index containing the full intended tree and correctly rejected a separate empty `auth.json` fixture without displaying file contents.
- 2026-09-24 — Group 7 completed after `package-lock.json` entered the tracked file set and the full intended tree passed the static and repository-safety checks.
- 2026-09-24 — Superseded the hand-written `.githooks/pre-commit` with Python `pre-commit` `4.6.2`, standard hooks `v6.0.0`, ShellCheck wrapper `v0.11.0.1-1`, declarative filename rejection hooks, and a small Node cross-file contract validator. This reduces custom maintenance while retaining Pi-specific checks. The earlier hook note remains as implementation history. The complete intended tree passed `pre-commit run --all-files`; an ignored empty `auth.json` fixture was also rejected without reading or displaying its contents.
