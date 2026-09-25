# pi-scaps

Reproducible personal configuration and extensions for the Pi coding agent.

This repository is a portable, version-controlled global Pi harness. It is meant to be used directly as Pi's global agent directory; it is not a conventional application or a separately installable Pi package.

Pi itself is installed globally through npm. This repository is the agent
directory Pi loads: it contains the settings, agents, prompts, skills, and
extensions as well as the pinned version contract. Installing Pi does not
automatically select a checkout as its agent directory.

## Prerequisites

- Linux and Bash.
- Node.js `>=24.21.0`; use Node 24.21.0 or newer.
- npm.
- Python 3 for the optional developer pre-commit environment.
- A user-writable npm global prefix whose `bin` directory is on `PATH`.

Bootstrap installs the exact Pi package/version declared in `package.json` through
global npm, or reuses it when already correct. Only npm-managed Pi installations
are supported. If another installation shadows npm's `pi` executable, bootstrap
and the maintainer upgrade command stop with an ownership error; remove that
conflict from `PATH` or switch to the intended npm installation before retrying.
They never install Node or use `sudo`.

## Fresh installation at Pi's default path

Install the prerequisites first, then ensure `~/.pi/agent` does not already exist and run:

```bash
git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
cd ~/.pi/agent
./scripts/bootstrap.sh
./scripts/doctor.sh
pi
```

Inside Pi, run `/login` if authentication is required. Credentials remain local and must never be committed.

Because this checkout is at Pi's default `~/.pi/agent` path, no
`PI_CODING_AGENT_DIR` setting is needed in this case.

## If `~/.pi/agent` already exists

Stop before cloning. Back up the existing directory to a private, dated location, inspect its contents, and create a clean clone only after the original is safe. Manually merge only intentional, non-secret configuration into the clone; do not copy credentials, runtime state, downloaded packages, or caches. Authenticate again with `/login` if needed.

The repository scripts do not delete, replace, or merge an existing agent directory.

## Using an existing checkout elsewhere

If this repository is already checked out somewhere other than `~/.pi/agent`,
keep that checkout and run the following from a terminal. Replace the first
line's example path with the actual checkout path:

```bash
cd /path/to/pi-scaps
export PI_CODING_AGENT_DIR="$PWD"
./scripts/bootstrap.sh
./scripts/doctor.sh
pi
```

`bootstrap.sh` installs the repository's pinned Pi version and locked local
dependencies, but it cannot set an environment variable in the parent shell.
The `export` above selects this checkout for Pi and doctor in the current
terminal only. It redirects Pi's whole global agent directory, including
configuration and writable state such as credentials, locks, diagnostics,
trust data, caches, and managed packages. The configured session directory
remains separate unless `PI_CODING_AGENT_SESSION_DIR` overrides it.

Bootstrap also prints the exact export command for this checkout. To use the
same agent directory in future Bash terminals, add that printed command,
which contains the **absolute checkout path**, to `~/.bashrc`. Do not put
`export PI_CODING_AGENT_DIR="$PWD"` in `~/.bashrc`: there, `$PWD` would mean
whichever directory a new terminal happens to start in. Bootstrap never edits
the startup file itself. Inside Pi, run `/login` if authentication is required.

## Repository layout

| Path | Responsibility |
| --- | --- |
| `README.md` | Installation, operation, recovery, and safety guidance. |
| `AGENTS.md` | Short global instructions loaded for every Pi session. |
| `settings.json` | Portable Pi settings, including the external session directory and changelog marker. |
| `models.json.example` | Safe schema example for an optional, ignored local `models.json`. |
| `package.json` | Node requirement, authoritative Pi package/version contract, and future local extension dependencies. |
| `package-lock.json` | npm-generated lockfile for deterministic local dependency installation. |
| `.gitignore` | Guardrails excluding credentials, runtime state, managed installs, caches, and local-only files. |
| `.pre-commit-config.yaml` | Pinned standard hooks, ShellCheck, and small local harness-specific checks. |
| `requirements-dev.txt` | Exact Python `pre-commit` framework version for the developer hook environment. |
| `extensions/` | In-repository TypeScript extensions discovered by Pi. Initially inert. |
| `skills/` | Reusable skills discovered by Pi. Initially inert. |
| `prompts/` | Reusable prompt templates discovered by Pi. Initially inert. |
| `themes/` | Custom themes discovered by Pi. Initially inert. |
| `agents/` | Harness convention for future role definitions; not a Pi-native auto-discovery directory. |
| `agents/README.md` | Defines what a future role file may control and prevents mistaken auto-discovery assumptions. |
| `scripts/` | Operator commands that are safe to invoke from any working directory. |
| `scripts/bootstrap.sh` | Converges the declared npm-managed Pi, installs locked local dependencies, reconciles pinned external packages, and prepares the external session directory. |
| `scripts/doctor.sh` | Checks activation, versions, configuration, resource structure, state separation, and offline Pi startup. |
| `scripts/update.sh` | Fast-forwards a clean checkout, then uses bootstrap to converge Pi, locked dependencies, and pinned packages before doctor. |
| `scripts/upgrade-pi.sh` | Proposes one explicit or npm-`latest` Pi version and leaves verified metadata changes for review. |
| `scripts/pi-npm-common.sh` | Shared npm-ownership and Pi-version checks used by bootstrap and upgrade. |
| `scripts/set-pi-version.mjs` | Atomically updates the Pi pin and derived changelog marker during a proposal. |
| `scripts/smoke-pi.mjs` | Checks offline RPC startup and extension binding without sending a model prompt. |
| `scripts/validate-contract.mjs` | Validates the Node/Pi contract and pinned package declarations; `--sync-pi-marker` updates the derived changelog marker after an intentional Pi pin change. |
| `tasks/` | Versioned planning, review, and implementation-checklist material. |

The empty resource directories contain only zero-content `.gitkeep` placeholders so Git preserves their structure. Pi also supports root `keybindings.json`, `SYSTEM.md`, and `APPEND_SYSTEM.md`; they are deliberately absent until a demonstrated need exists.

## Discovery and package semantics

Pi discovers global configuration and resources because this checkout is the active agent directory. That differs from Pi's package-manifest mechanism: this repository intentionally has no root Pi package manifest or `pi-package` keyword, and installing it as a Pi package would not reproduce global settings or instructions.

Dependencies imported directly by local extensions belong in root `package.json` and `package-lock.json`. External Pi packages are a separate concern: when deliberately introduced, declare them through Pi's package configuration and pin npm packages to exact versions and Git packages to immutable commits. The initial harness installs no external Pi packages.

The maintainer upgrade command updates the authoritative Pi version in
`package.json` and Pi's required `settings.json.lastChangelogVersion` marker
together. If editing the pin manually, run
`node scripts/validate-contract.mjs --sync-pi-marker` to align the marker. The
normal validator and pre-commit hook reject an unsynchronised marker.

## Secrets and local state

> Never commit credentials, a real `models.json`, sessions, crash diagnostics, trust state, downloaded packages, caches, or lock directories.

This includes `auth.json`, OAuth data, `.env` files, private keys, `sessions/`, `crashes.json`, `trust.json`, `git/`, `npm/`, `bin/`, `models-store.json`, logs, and temporary data. `.gitignore` is only a guardrail, not a security boundary: inspect changes and never force-add sensitive files.

Sessions are configured to live at `~/.local/state/pi/sessions`, outside the checkout. If session history is wanted on another machine, transfer it separately through a private channel; it may contain sensitive prompts, paths, commands, and model output.

Pi may legitimately rewrite tracked `settings.json` after a persisted settings change. Review the resulting diff, then intentionally commit it or revert it before updating the harness.

## Pre-commit checks

Create an isolated developer environment and install the exactly pinned framework:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/pre-commit install
.venv/bin/pre-commit run --all-files
```

If this clone previously used the superseded `.githooks/` hook, first run `git config --local --unset-all core.hooksPath`. New clones do not need that migration command.

The pinned upstream hooks handle whitespace, line endings, JSON and YAML syntax, merge markers, large files, executable/shebang consistency, broken symlinks, private keys, and ShellCheck. Local hooks are limited to the Pi-specific metadata contract, forbidden Pi state paths, inert resource placeholders, and `npm ls --depth=0`. The first run downloads the pinned hook environments; hooks do not call Pi and do not replace GitHub secret scanning. `settings.json` is deliberately excluded from the end-of-file fixer because Pi initially serializes it without a final newline.

## Choosing a workflow

Run `./scripts/bootstrap.sh` after a fresh clone or when this machine needs to
match the Pi pin already in the checkout. It does not choose a newer release.
Run `./scripts/update.sh` from a clean checkout to fast-forward Git, then run
bootstrap and doctor against the pulled revision. Only a maintainer proposing
a new Pi pin should run `./scripts/upgrade-pi.sh`.

## Routine update and deliberate upgrade

From a clean checkout, run:

```bash
./scripts/update.sh
```

This fast-forwards the harness, then runs bootstrap to install the exact Pi
version already declared by the pulled revision, restore locked local
dependencies, and reconcile pinned external packages. Doctor runs last. Update
does not select a new Pi release or move any package pin.

To propose a deliberate Pi version change from a clean, healthy checkout:

```bash
./scripts/upgrade-pi.sh latest
# or: ./scripts/upgrade-pi.sh <exact-version>
```

An explicit prerelease is allowed; `latest` is rejected if npm points it at a
prerelease. The command checks the candidate's Node requirement before changing
anything, installs the exact candidate, updates only the Pi version and derived
changelog marker, reconciles locked dependencies and packages, and runs an
offline load check plus doctor. It leaves changes unstaged for review and never
commits or rolls back automatically. A Pi-only bump should not change
`package-lock.json`.

The smoke check's guarantee is that the configured harness reaches Pi's normal
runtime and extension-binding path under the candidate version. It catches
startup, import, registration, and dependency errors; it does not certify every
extension's behavior. Registry resolution and pinned-package reconciliation
happen before the offline check. The check sends no model prompt and suppresses
raw Pi output that could contain local configuration details. This repository
currently declares no root check/typecheck scripts or extension unit-test suite,
so the upgrade command does not invent or run any. It never runs scripts found
inside third-party packages as compatibility tests.

Local extension dependencies belong in root `package.json` and
`package-lock.json`; routine convergence uses `npm ci`. If an actual extension
incompatibility requires changing one, update that dependency deliberately,
regenerate and review the lockfile, and include it with the Pi bump only when
the changes are related. Keep unrelated dependency refreshes separate. External
Pi packages remain pinned in `settings.json` to exact npm versions or Git
commits; reconciliation must not move those declarations.

If installation fails before metadata changes, run bootstrap to reconverge the
declared Pi version. If an attempt fails after metadata changes, inspect the
diff first. To abandon an uncommitted proposal, restore only the files changed
by the upgrade (including any staged copies) and reconverge:

```bash
git restore --source=HEAD --staged --worktree -- package.json settings.json
./scripts/bootstrap.sh
./scripts/doctor.sh
```

## Reverting a committed upgrade

Start from a clean worktree. Identify and revert the upgrade commit without
rewriting shared history, then reinstall the version declared by the resulting
checkout and run doctor:

```bash
git log --oneline
git revert <pi-upgrade-commit>
./scripts/bootstrap.sh
./scripts/doctor.sh
```

Neither recovery path performs live rollback or needs a separate Pi uninstall;
bootstrap installs the exact version declared after restoration or revert.
No special commit convention is required.

## Repository-owner security action

- [ ] In the GitHub repository settings, verify secret scanning and push protection are enabled where available. If the repository is public, also verify public-repository secret-scanning behavior.

## Philosophy

Keep the harness close to Pi's minimal core: add resources only for demonstrated, reusable needs; prefer simple, inspectable configuration; and preserve exact versions and reproducible changes.
