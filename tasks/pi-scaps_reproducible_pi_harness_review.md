# Review: reproducible Pi harness skeleton

Reviewed: 2026-09-24

Scope:

- `tasks/pi-scaps_reproducible_pi_harness_skeleton.md`
- the appended “Things that should probably be incorporated” section
- `tasks/missed_things.md`
- current upstream Pi documentation, source, releases, and security guidance

## Recommendation

Use the existing PRD, but amend it before implementation. One implementation task is enough; this does not need to become a chain of small PRDs.

The overall architecture is right for the stated priority: clone the repository directly to `~/.pi/agent`, keep intentional behavior in Git, move sessions out of the checkout, ignore the remaining mutable state, and authenticate separately on each machine.

Do not implement the current text unchanged. The main corrections are:

1. add an explicit Pi and Node version contract;
2. move sessions outside the repository in `settings.json`;
3. replace `skills/README.md` and `prompts/README.md` placeholders with inert `.gitkeep` files;
4. stop describing the root `package.json` Pi manifest as what loads global resources;
5. expand the runtime-state ignore list for current Pi;
6. make `doctor.sh` verify that the checkout is Pi's active agent directory;
7. add current Pi surfaces such as `themes/` and document `keybindings.json`, `SYSTEM.md`, and `APPEND_SYSTEM.md` without creating speculative files;
8. strengthen public-repository secret safeguards and acceptance checks.

## Current upstream facts that affect the PRD

As of this review, the maintained project is `earendil-works/pi`, the npm package is `@earendil-works/pi-coding-agent`, and the latest release is `0.87.1`. The package requires Node `>=22.19.0`. The old `@mariozechner/pi-coding-agent` line is deprecated; the current security guidance says to migrate to `@earendil-works/pi-coding-agent >=0.78.1`.

This machine currently has Node `20.19.5` and no `pi` executable. Node 20 is EOL, so the present PRD's “command exists” test would not be enough even if Pi were installed.

Pi's agent directory defaults to `~/.pi/agent`. It contains both versionable configuration and writable state. Current documented configuration surfaces include:

- `settings.json`
- `keybindings.json`
- `models.json`
- `auth.json`
- `AGENTS.md` and related context files
- `SYSTEM.md` and `APPEND_SYSTEM.md`
- `extensions/`, `skills/`, `prompts/`, and `themes/`

Pi supports `sessionDir`, `PI_CODING_AGENT_SESSION_DIR`, and `--session-dir`, in increasing precedence. Pi also supports `PI_CODING_AGENT_DIR`, but that changes the whole agent directory, not just tracked configuration.

Pi packages installed through Pi are stored below the agent directory in `npm/` or `git/`. Pi also writes or manages `models-store.json`, `trust.json`, `bin/`, `tmp/`, logs, authentication, and sessions. These are state/cache/install outputs rather than source configuration.

## Required PRD changes

### 1. Add a version contract

Add these requirements:

- use the current package name, `@earendil-works/pi-coding-agent`;
- declare Node `>=22.19.0` in `package.json.engines`;
- recommend the current Node 24 LTS line for a new machine;
- record one exact tested Pi version in a single machine-readable place;
- initially set the Pi version to `0.87.1`;
- make `doctor.sh` fail on an unsupported Node version or a Pi version that does not match the declared version;
- print an exact remediation command, for example:

  ```bash
  npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.87.1
  ```

Do not silently upgrade Pi in `bootstrap.sh` or `update.sh`. That preserves the PRD's no-surprise rule. The README should contain the exact install command, and version bumps should be deliberate Git changes.

A small custom field in `package.json` is sufficient; another tool or framework is unnecessary:

```json
{
  "engines": {
    "node": ">=22.19.0"
  },
  "piHarness": {
    "package": "@earendil-works/pi-coding-agent",
    "version": "0.87.1"
  }
}
```

### 2. Isolate sessions now

Make this part of the initial `settings.json`:

```json
{
  "defaultThinkingLevel": "medium",
  "sessionDir": "~/.local/state/pi/sessions"
}
```

`bootstrap.sh` should idempotently create:

```bash
mkdir -p "$HOME/.local/state/pi/sessions"
```

`doctor.sh` should check that the directory exists and is writable, and should verify that the configured session directory does not resolve inside the Git worktree.

This is the most useful item from the missed-things section. It prevents normal conversation history from accumulating in the repository at all, instead of relying only on `.gitignore`.

### 3. Use inert directory placeholders

Do not create `skills/README.md` or `prompts/README.md`.

Pi turns Markdown files in `prompts/` into slash commands; the filename becomes the command name. It also accepts some standalone Markdown files in `skills/`. The proposed placeholders can therefore become a `/README` prompt or an invalid/bogus skill and can produce startup diagnostics.

Use:

```text
extensions/.gitkeep
skills/.gitkeep
prompts/.gitkeep
themes/.gitkeep
```

Explain those directories in the root README. `agents/README.md` is safe because `agents/` is a harness convention and is not a Pi-native auto-discovery directory.

### 4. Correct the role of `package.json`

The checkout is being used as Pi's global agent directory. Pi loads `extensions/`, `skills/`, `prompts/`, and `themes/` there through its documented agent-directory discovery.

The `pi` field in `package.json` is a Pi **package** manifest. It matters when that directory is loaded as a Pi package. Merely placing it at the root of `~/.pi/agent` is not what makes global resources load.

For this skeleton, use `package.json` for:

- repository identity;
- Node compatibility metadata;
- the expected Pi version;
- future npm dependencies imported by local extensions;
- the lockfile used by `npm ci`.

Recommendation: omit `keywords: ["pi-package"]` and the `pi` manifest for now. Add them later only if this repository is intentionally supported as a separately installable Pi package. Package installation alone would not install this repository's `settings.json` or global `AGENTS.md`, so presenting package installation as an equivalent setup method would be misleading.

### 5. Include all current mutable-state paths in `.gitignore`

At minimum add:

```gitignore
# Pi credentials and local provider configuration
/auth.json
/oauth.json
/models.json

# Pi runtime state and caches
/sessions/
/models-store.json
/trust.json
/trust.json.lock/
/pi-debug.log
/logs/
*.log
/tmp/

# Pi-managed packages and binaries
/git/
/npm/
/bin/
/tools/

# Local dependencies and environments
node_modules/
/venv/
/.venv/

# Other likely secret-bearing local files
.env
.env.*
!.env.example
.npmrc
*.secret
*.pem
*.key
```

The leading `/` on Pi's top-level state paths is intentional. It avoids accidentally ignoring a legitimate `bin/`, `tmp/`, or similarly named directory inside a future extension.

Keep `settings.json`, `package.json`, `package-lock.json`, `AGENTS.md`, `keybindings.json` if later added, and intentional resources trackable.

The existing worktree contains an untracked `venv/`, while the proposed Pi-specific ignore list does not cover it. Include `venv/` and `.venv/` so replacing the current generic ignore file does not expose that directory for accidental staging.

### 6. Make `doctor.sh` verify activation, not just files

The scripts may run correctly from any checkout, but Pi will not use that checkout unless it is:

- the default `~/.pi/agent`, or
- the directory named by `PI_CODING_AGENT_DIR`.

`doctor.sh` should canonicalize both paths and fail (or produce a very prominent warning) if the repository is not the active agent directory. Its remediation should say either:

```bash
git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
```

or:

```bash
export PI_CODING_AGENT_DIR=/absolute/path/to/pi-scaps
```

Also add these checks:

- Node version satisfies the declared minimum;
- installed Pi version matches the declared Pi version;
- the session directory is outside the checkout and writable;
- required scripts are executable;
- forbidden state/credential paths are not tracked by Git;
- strict JSON files parse;
- installed dependencies are internally consistent (`npm ls --depth=0`, after bootstrap);
- shell syntax passes `bash -n scripts/*.sh`.

Keep `npm ci` in `bootstrap.sh` and the acceptance commands rather than in `doctor.sh`: `doctor.sh` should diagnose without deleting/reinstalling `node_modules` or requiring network access.

Run Pi diagnostics offline where possible (`PI_OFFLINE=1`) so `doctor.sh` does not depend on update servers, telemetry, or model-catalog refreshes.

### 7. Add `themes/`; document other supported surfaces

Add `themes/.gitkeep` and describe it in the README. Themes are a current first-class Pi resource beside extensions, skills, and prompts.

Do not create empty `keybindings.json`, `SYSTEM.md`, or `APPEND_SYSTEM.md`, but mention them in an “optional future files” section:

- `keybindings.json`: portable UI keybindings;
- `SYSTEM.md`: replace Pi's system prompt;
- `APPEND_SYSTEM.md`: append to Pi's system prompt.

This keeps the skeleton minimal without omitting supported configuration surfaces from the architecture.

### 8. Strengthen public-repository safety

`.gitignore` is not a security boundary: it does not help after a secret-bearing file has been deliberately force-added or was already tracked.

Add a doctor/acceptance check that fails if `git ls-files` contains any forbidden runtime path, including `auth.json`, `models.json`, `models-store.json`, `trust.json`, `sessions/`, `npm/`, `git/`, `bin/`, or `tmp/`.

Also add a one-time repository administration step to the README: confirm GitHub secret scanning and push protection are enabled. GitHub says secret scanning runs automatically for public repositories, while repository push protection can block supported secrets before they are accepted.

Do not add a home-grown regex secret scanner to this skeleton. It is easy to create false confidence. The tracked-path check plus GitHub's scanner is proportionate here.

### 9. Cover the existing-directory migration case

The install instructions assume `~/.pi/agent` does not exist. Add:

- clone before first launching Pi on a new machine where possible;
- if `~/.pi/agent` already exists, move it to a dated backup and inspect/merge intentional configuration manually;
- never have bootstrap delete or overwrite an existing agent directory;
- authenticate with `/login` after bootstrap;
- do not copy `auth.json` through this public repository;
- if sessions must be moved, copy the external session directory separately and privately.

This is important for a real machine transfer even though it should remain a short README note rather than a migration framework.

### 10. Fix acceptance and update semantics

Replace the acceptance command:

```bash
find . -maxdepth 2 -type f | sort
```

with:

```bash
git ls-files | sort
```

The original `find` command includes `.git` internals and untracked files, so it does not actually test the expected tracked skeleton.

Document that `./scripts/update.sh` updates the **harness checkout** with `git pull --ff-only`; it must not call Pi's own `pi update`, because current Pi uses that command for self/package updates and that would defeat the version pin.

## Disposition of the 14 missed items

| # | Item | Decision | Reason |
|---|---|---|---|
| 1 | Move sessions outside the repo | **Include now** | High-value isolation; officially supported by `sessionDir`. |
| 2 | Document `PI_CODING_AGENT_DIR` | **Include briefly** | Useful alternative and needed for `doctor.sh` activation checks. Keep default clone-to-agent-dir flow first. |
| 3 | Warn that `PI_CODING_AGENT_DIR` redirects writable state | **Include now** | Accurate architectural caveat; session isolation only moves sessions, not auth/trust/cache/package state. |
| 4 | Ignore `models-store.json` | **Include now** | Current Pi-managed model-catalog cache. |
| 5 | Ignore `bin/` | **Include now** | Current Pi-managed `rg`/`fd` binary location. |
| 6 | Check extensions/skills actually load | **Partly include** | For the empty skeleton, require inert directories and no startup diagnostics. Add resource counts/load smoke tests when real resources are introduced. Do not invent an unreliable “7 extensions loaded” check now. |
| 7 | Semantically check model configuration | **Conditional** | If `models.json` is absent, there is nothing to check. When present, use Pi offline model listing/startup diagnostics rather than only JSON parsing. |
| 8 | Check authentication state | **Information only** | File presence is not authoritative because Pi also supports environment credentials. Never inspect or print credential content. `/login` remains a manual step. |
| 9 | Check `rg`, `fd`, `jq` | **Do not include as requirements** | Pi can manage `rg`/`fd`; `jq` is not used by this skeleton. Only check a command when a committed script actually needs it. |
| 10 | Install Pi / validate a Pi version | **Validate now; do not auto-install** | Fail with an exact pinned install command. Avoid silent global changes. |
| 11 | Pin the Pi executable/version | **Include now** | Essential to reproducibility and especially important across current package/Node migrations. |
| 12 | Empty external-package declaration | **Do not include** | An empty placeholder adds no behavior. Add only reviewed, pinned package entries. |
| 13 | Git rollback workflow | **Include briefly** | A two-command README note (`git log`, `git revert`) is cheap and supports the design goal. |
| 14 | Commit convention | **Defer** | Helpful but unrelated to rebuilding the harness; examples are enough, not an acceptance criterion. |

## Additional omissions found during review

| Item | Include now? | Notes |
|---|---|---|
| Inert placeholders for scanned directories | **Yes** | This fixes real accidental resource discovery. |
| `themes/` | **Yes** | Current native Pi resource type. |
| Active-agent-directory check | **Yes** | Prevents a healthy-looking but unused checkout. |
| Node semantic version check | **Yes** | Latest Pi requires Node `>=22.19.0`; this machine is currently below it. |
| Current package/repository names | **Yes** | Avoid deprecated installation instructions and vulnerable old package lines. |
| Offline doctor behavior | **Yes** | Makes diagnostics deterministic and avoids background network operations. |
| Existing `~/.pi/agent` handling | **Yes** | Necessary for safe transfer to a machine on which Pi may already have run. |
| `venv/` ignore | **Yes** | It already exists untracked in this repository. |
| GitHub push protection note | **Yes** | Proportionate defense for a public configuration repository. |
| `LICENSE` decision | **Before publishing code for reuse** | A public repository without a license is viewable but does not grant reuse rights. Choose a license explicitly; do not have the implementation invent one. |
| CI/GitHub Actions | No | Still unnecessary for this first local skeleton. |
| Automatic Node installation | No | Keep setup transparent; document the required supported Node version. |
| Automatic Pi installation | No | Print the exact pinned command instead. |
| Full resource-load test framework | No | Add alongside the first real extension/skill/prompt, when there is something concrete to assert. |

## Revised minimal repository shape

```text
pi-scaps/
├── AGENTS.md
├── README.md
├── settings.json
├── models.json.example
├── package.json
├── package-lock.json
├── .gitignore
│
├── agents/
│   └── README.md
├── extensions/
│   └── .gitkeep
├── skills/
│   └── .gitkeep
├── prompts/
│   └── .gitkeep
├── themes/
│   └── .gitkeep
└── scripts/
    ├── bootstrap.sh
    ├── doctor.sh
    └── update.sh
```

The `tasks/` directory can remain as repository planning material if desired, but it is not part of the installed Pi interface.

## Fast transfer path after these amendments

On the new machine:

```bash
# Install a supported Node release first (Node 24 LTS is the recommended line).
npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.87.1

git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
cd ~/.pi/agent
./scripts/bootstrap.sh
./scripts/doctor.sh
pi
```

Then run `/login` once. No credentials should move through Git. If old sessions are wanted, copy `~/.local/state/pi/sessions` through a private transfer mechanism.

That is still the simple workflow the original PRD was aiming for; the amendments mainly ensure it is true in practice.

## Primary sources

- [Pi configuration and agent-directory layout](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md)
- [Pi settings reference (`sessionDir`, resources, and package declarations)](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/settings.md)
- [Pi sessions documentation](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/sessions.md)
- [Pi packages documentation](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/packages.md)
- [Pi skills discovery and validation](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md)
- [Pi prompt-template discovery](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/prompt-templates.md)
- [Pi extension loading and security model](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md)
- [Pi environment variables](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/environment-variables.md)
- [Current Pi package metadata and Node engine requirement](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/package.json)
- [Pi releases](https://github.com/earendil-works/pi/releases)
- [GitHub advisory for the deprecated/current Pi package lines](https://github.com/advisories/GHSA-jfgx-wxx8-mp94)
- [GitHub secret scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)
- [GitHub push protection](https://docs.github.com/en/code-security/concepts/secret-security/push-protection)
- [Node.js release status](https://nodejs.org/en/about/previous-releases)
