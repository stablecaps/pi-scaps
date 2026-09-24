# pi-scaps

Reproducible personal configuration and extensions for the Pi coding agent.

This repository is a portable, version-controlled global Pi harness. It is meant to be used directly as Pi's global agent directory; it is not a conventional application or a separately installable Pi package.

## Prerequisites

- Linux and Bash.
- Node.js `>=24.21.0`; use Node 24.21.0 or newer.
- npm.
- `@earendil-works/pi-coding-agent` at the version pinned in `package.json` (currently `0.87.1`).

Install the pinned Pi release explicitly:

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.87.1
```

The harness scripts validate Node and Pi; they do not install or upgrade them.

## Fresh installation

Install the prerequisites first, then ensure `~/.pi/agent` does not already exist and run:

```bash
git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
cd ~/.pi/agent
./scripts/bootstrap.sh
./scripts/doctor.sh
pi
```

Inside Pi, run `/login` if authentication is required. Credentials remain local and must never be committed.

## If `~/.pi/agent` already exists

Stop before cloning. Back up the existing directory to a private, dated location, inspect its contents, and create a clean clone only after the original is safe. Manually merge only intentional, non-secret configuration into the clone; do not copy credentials, runtime state, downloaded packages, or caches. Authenticate again with `/login` if needed.

The repository scripts do not delete, replace, or merge an existing agent directory.

## Alternative agent directory

The default and recommended location is `~/.pi/agent`. To use another checkout for the current shell:

```bash
export PI_CODING_AGENT_DIR="$HOME/src/pi-scaps"
```

This redirects Pi's whole global agent directory, including configuration and writable state such as credentials, locks, diagnostics, trust data, caches, and managed packages. It is not only a source-code lookup path. The configured session directory remains separate unless `PI_CODING_AGENT_SESSION_DIR` overrides it.

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
| `extensions/` | In-repository TypeScript extensions discovered by Pi. Initially inert. |
| `skills/` | Reusable skills discovered by Pi. Initially inert. |
| `prompts/` | Reusable prompt templates discovered by Pi. Initially inert. |
| `themes/` | Custom themes discovered by Pi. Initially inert. |
| `agents/` | Harness convention for future role definitions; not a Pi-native auto-discovery directory. |
| `agents/README.md` | Defines what a future role file may control and prevents mistaken auto-discovery assumptions. |
| `scripts/` | Operator commands that are safe to invoke from any working directory. |
| `scripts/bootstrap.sh` | Validates prerequisites, installs locked local dependencies, and prepares the external session directory. |
| `scripts/doctor.sh` | Checks activation, versions, configuration, resource structure, state separation, and offline Pi startup. |
| `scripts/update.sh` | Fast-forwards a clean harness checkout, restores locked dependencies, and runs the doctor. |
| `tasks/` | Versioned planning, review, and implementation-checklist material. |

The empty resource directories contain only zero-content `.gitkeep` placeholders so Git preserves their structure. Pi also supports root `keybindings.json`, `SYSTEM.md`, and `APPEND_SYSTEM.md`; they are deliberately absent until a demonstrated need exists.

## Discovery and package semantics

Pi discovers global configuration and resources because this checkout is the active agent directory. That differs from Pi's package-manifest mechanism: this repository intentionally has no root Pi package manifest or `pi-package` keyword, and installing it as a Pi package would not reproduce global settings or instructions.

Dependencies imported directly by local extensions belong in root `package.json` and `package-lock.json`. External Pi packages are a separate concern: when deliberately introduced, declare them through Pi's package configuration and pin npm packages to exact versions and Git packages to immutable commits. The initial harness installs no external Pi packages.

## Secrets and local state

> Never commit credentials, a real `models.json`, sessions, crash diagnostics, trust state, downloaded packages, caches, or lock directories.

This includes `auth.json`, OAuth data, `.env` files, private keys, `sessions/`, `crashes.json`, `trust.json`, `git/`, `npm/`, `bin/`, `models-store.json`, logs, and temporary data. `.gitignore` is only a guardrail, not a security boundary: inspect changes and never force-add sensitive files.

Sessions are configured to live at `~/.local/state/pi/sessions`, outside the checkout. If session history is wanted on another machine, transfer it separately through a private channel; it may contain sensitive prompts, paths, commands, and model output.

Pi may legitimately rewrite tracked `settings.json` after a persisted settings change. Review the resulting diff, then intentionally commit it or revert it before updating the harness.

## Updating

From a clean checkout, run:

```bash
./scripts/update.sh
```

This fast-forwards the harness, installs its locked local dependencies, and runs the doctor. It does not update Pi itself or change the pinned Pi version. Pi version changes are deliberate repository changes and must keep metadata, documentation, and the install command aligned.

## Rollback

Inspect repository history and revert the unwanted change without rewriting shared history:

```bash
git log --oneline
git revert <commit>
```

No special commit convention is required.

## Repository-owner security action

- [ ] In the GitHub repository settings, verify secret scanning and push protection are enabled where available. If the repository is public, also verify public-repository secret-scanning behavior.

## Philosophy

Keep the harness close to Pi's minimal core: add resources only for demonstrated, reusable needs; prefer simple, inspectable configuration; and preserve exact versions and reproducible changes.
