# PRD v02: pi-scaps Reproducible Pi Harness Skeleton

Status: ready for implementation; Turn 2 accuracy audit complete

Reviewed against upstream Pi `v0.87.1` documentation and source: 2026-09-24

Repository: `https://github.com/stablecaps/pi-scaps`

---

## 1. Summary

Create the initial repository structure for `stablecaps/pi-scaps` as the canonical, version-controlled definition of a personal Pi coding-agent harness.

The repository must be cloneable onto a new Linux machine and provide the configuration, directory structure, scripts, documentation, dependency metadata, and version contract needed to recreate the same harness with minimal manual work.

The intended setup remains deliberately small:

```bash
# Install a supported Node release first.
npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.87.1

git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
cd ~/.pi/agent
./scripts/bootstrap.sh
./scripts/doctor.sh
pi
```

Authentication is a separate local step performed through Pi's `/login` command or supported environment credentials.

This is a public repository. Credentials, authentication state, session transcripts, trust decisions, downloaded packages, caches, and machine-specific runtime state must never be committed.

This task creates the complete initial foundation in one change. It must not be split into numerous follow-up PRDs merely to create the skeleton. Future functional capabilities can be added as ordinary focused changes when there is a demonstrated need.

---

## 2. Goal

After implementation:

- Git is the source of truth for intentional harness behavior.
- A new machine can reproduce the harness using the documented commands.
- Pi uses the checkout as its global agent directory.
- Pi and Node compatibility are validated against a declared version contract.
- Pi sessions live outside the Git checkout.
- Remaining Pi-generated state, including crash records and transient lock directories, is explicitly ignored.
- Bootstrap and validation are safe to run repeatedly.
- Routine startup with the pinned Pi version does not create a settings-only worktree diff.
- Intentional settings changes made through Pi remain visible as configuration diffs to review, commit, or revert.
- The repository contains no speculative extensions, agents, skills, or prompts.

The initial result is a reproducible foundation, not a feature-rich multi-agent system.

---

## 3. Upstream Compatibility Baseline

Implementation must target this reviewed baseline:

| Component | Requirement |
|---|---|
| Pi project | `earendil-works/pi` |
| Pi npm package | `@earendil-works/pi-coding-agent` |
| Expected Pi version | `0.87.1` |
| Minimum Node version | `24.21.0` |
| Recommended Node line for a new machine | Node 24 LTS, version 24.21.0 or newer |
| Operating system | Linux |
| Script shell | Bash |

`package.json.piHarness.version` is the authoritative machine-readable Pi version. Scripts must read it rather than maintain an independent hard-coded value. Human-facing commands may show the resolved version explicitly.

`settings.json.lastChangelogVersion` must mirror the authoritative value. This is an intentional exception, required because current Pi writes its changelog acknowledgement into the global settings file. Doctor must detect a mismatch. A version-upgrade change must update both fields together.

The initial expected version is `0.87.1`. A later Pi upgrade must be a deliberate Git change that updates the version contract, documentation where necessary, and verification results together.

Do not use the deprecated `@mariozechner/pi-coding-agent` package name.

Do not automatically upgrade Pi as part of harness bootstrap or harness update.

---

## 4. Design Principles

### 4.1 Git is the source of truth

Anything that intentionally defines Pi behavior should be capable of being represented in this repository, including:

- global instructions;
- portable settings;
- safe custom model examples;
- extensions;
- skills;
- prompts;
- themes;
- future agent-role definitions;
- scripts;
- local extension dependency declarations;
- pinned external Pi package declarations.

Behavioral changes must be inspectable, diffable, reversible, and reproducible through Git.

### 4.2 Runtime state is not configuration

Do not commit generated or machine-local data, including:

- credentials and OAuth tokens;
- sessions and transcripts;
- project trust decisions;
- cached model catalogs;
- downloaded Pi packages;
- Pi-managed binaries;
- crash-diagnostic records;
- transient authentication and settings lock directories;
- installed Node dependencies;
- logs and temporary files.

### 4.3 Public-repository safety

A clean repository must make accidental secret commits difficult.

`.gitignore` is necessary but is not a complete security boundary. Validation must also reject known forbidden paths if they become tracked. GitHub secret scanning and push protection should be enabled for the public repository.

### 4.4 Minimal initial implementation

Create only the files and directories that form a useful reproducible foundation.

Do not create demonstration extensions, dummy prompts, fake agent roles, or empty configuration keys merely to show where future functionality might go.

### 4.5 Reproducibility over silent convenience

- Validate the declared Pi version exactly.
- Validate Node against the supported minimum.
- Pin future third-party Pi packages to an npm version, Git tag, or preferably an immutable commit where practical.
- Use `package-lock.json` and `npm ci` for local extension dependencies.
- Never silently upgrade external components.

### 4.6 Idempotent and non-destructive tooling

Running bootstrap or doctor repeatedly must be safe.

Scripts must not:

- delete or overwrite an existing agent directory;
- create credentials;
- edit shell startup files;
- change unrelated user configuration;
- perform implicit Git merges;
- discard local changes.

### 4.7 Keep scanned resource directories inert until used

Pi discovers resources from its global directories. Placeholder files must not accidentally become resources.

In particular:

- Markdown files in `prompts/` can become slash commands;
- standalone Markdown files in `skills/` can be treated as skills.

Use `.gitkeep` in Pi-scanned placeholder directories and explain their purpose in the root README.

---

## 5. Installation Model

### 5.1 Recommended installation

The recommended installation is a direct clone to Pi's default global agent directory:

```text
~/.pi/agent
```

This provides the shortest and least surprising setup flow.

### 5.2 Alternative installation location

Pi supports an alternative agent directory through:

```bash
export PI_CODING_AGENT_DIR="/absolute/path/to/pi-scaps"
```

This alternative must be documented, but it must not replace the default instructions.

`PI_CODING_AGENT_DIR` redirects the entire Pi agent directory, including writable files such as authentication, settings locks, crash records, trust state, caches, packages, and managed binaries. It is not a configuration-only path.

The external `sessionDir` setting reduces this coupling for sessions, but other runtime state still belongs below the selected agent directory and must remain ignored.

### 5.3 Existing agent directory

The README must say that `git clone ... ~/.pi/agent` requires the destination not to contain an existing Pi setup.

If `~/.pi/agent` already exists:

1. stop and back it up;
2. inspect its intentional configuration;
3. clone this repository into a clean agent directory;
4. manually merge only wanted non-secret configuration;
5. authenticate locally again or transfer credentials only through an appropriate private mechanism.

No repository script may automate deletion or overwriting of the existing directory.

---

## 6. Required Repository Structure

Create this harness structure:

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
│
├── extensions/
│   └── .gitkeep
│
├── skills/
│   └── .gitkeep
│
├── prompts/
│   └── .gitkeep
│
├── themes/
│   └── .gitkeep
│
└── scripts/
    ├── bootstrap.sh
    ├── doctor.sh
    └── update.sh
```

Existing planning material under `tasks/` may remain in the repository. It is not part of Pi's runtime interface.

Do not use `README.md` as a placeholder inside `skills/` or `prompts/`.

---

## 7. File Requirements

### 7.1 `AGENTS.md`

Purpose: minimal global instructions automatically available when the checkout is Pi's agent directory.

It must:

- identify the repository as the global Pi harness;
- favor simplicity and low token overhead;
- require new extensions or dependencies to solve a demonstrated reusable problem;
- discourage recreating functionality already handled cheaply and reliably by Pi's core tools;
- forbid committing secrets or runtime state;
- require reproducible, reviewable changes;
- direct future agents to preserve pinned versions and update documentation with behavior changes.

It must remain concise. Do not add a large behavioral manifesto in the skeleton.

### 7.2 `settings.json`

Create strict, valid JSON containing only portable, deliberate settings:

```json
{
  "lastChangelogVersion": "0.87.1",
  "defaultThinkingLevel": "medium",
  "sessionDir": "~/.local/state/pi/sessions"
}
```

Rationale:

- `lastChangelogVersion` mirrors `package.json.piHarness.version` so first startup on the pinned release does not rewrite tracked settings merely to record that the changelog was seen;
- `defaultThinkingLevel` is portable and non-secret;
- `sessionDir` prevents transcript files from accumulating inside the Git checkout.

`settings.json` is tracked configuration, but it is also writable by Pi. Commands and UI actions that persist a model, thinking level, theme, package, or other setting may legitimately rewrite it. The README must tell the user to review and commit an intentional settings change, or revert it if it was accidental. Such changes are not runtime-state leakage and are outside the clean-worktree guarantee.

Current Pi serializes the entire settings object with two-space JSON formatting and no final newline whenever it writes the file. The initial file should use that serialization to avoid a formatting-only diff on the first legitimate settings write.

Do not add:

- fabricated model IDs;
- provider credentials;
- account identifiers;
- private endpoints;
- hard-coded usernames;
- external package entries before a package is selected and reviewed.

Although current Pi can accept JSONC in some configuration files, committed skeleton files must use strict JSON so generic Node validation remains reliable.

### 7.3 `models.json.example`

Do not commit a real `models.json` in this task.

Create a strict JSON example containing no credentials, keys, private endpoints, or invented provider definitions:

```json
{
  "providers": {}
}
```

The README must explain:

- built-in providers normally require `/login`, not `models.json`;
- `models.json` is for compatible custom endpoints or model overrides;
- users may copy the example to `models.json` when needed;
- real `models.json` is ignored because it may contain local endpoints, commands, headers, or secrets.

### 7.4 `package.json`

Create:

```json
{
  "name": "pi-scaps",
  "version": "0.1.0",
  "private": true,
  "description": "Reproducible personal Pi coding-agent harness",
  "engines": {
    "node": ">=24.21.0"
  },
  "piHarness": {
    "package": "@earendil-works/pi-coding-agent",
    "version": "0.87.1"
  }
}
```

Do not add runtime dependencies merely to populate the manifest.

Do not add `keywords: ["pi-package"]` or a `pi` package manifest in this task.

The repository is used directly as Pi's global agent directory. Pi discovers its global `extensions/`, `skills/`, `prompts/`, and `themes/` directories through agent-directory discovery. A `package.json` `pi` field is for a directory loaded as a Pi package and is not what activates this checkout's global resources.

Add a Pi package manifest later only if the repository deliberately supports package installation as a separate distribution mode. Such a mode would not automatically apply this repository's `settings.json` or global `AGENTS.md` and must not be documented as equivalent without additional setup.

### 7.5 `package-lock.json`

Generate and commit a valid lockfile using the supported Node/npm environment, for example:

```bash
npm install --package-lock-only --ignore-scripts
```

Do not hand-author the lockfile.

The lockfile may initially contain no third-party dependencies. It establishes the deterministic dependency workflow for future local extensions.

### 7.6 Placeholder directories

Create zero-content `.gitkeep` files in:

- `extensions/`;
- `skills/`;
- `prompts/`;
- `themes/`.

All explanations belong in the root README so Pi does not discover placeholder documentation as a resource.

### 7.7 `agents/README.md`

`agents/` is a harness convention, not a core Pi auto-discovery directory in this design.

Its README must explain that future orchestration may keep role definitions here and distinguish:

- role/instructions;
- model selection;
- thinking level;
- task and context allocation.

Do not create `architect.md`, `worker.md`, `reviewer.md`, or similar roles until an implemented extension consumes them.

---

## 8. Directory Responsibilities

### 8.1 `extensions/`

Reserved for trusted TypeScript or JavaScript Pi extensions.

Extensions add executable behavior and run with the user's operating-system permissions. Introduce one only for a reusable capability with a clear reliability, repeatability, integration, or efficiency benefit.

Do not copy third-party extension source into this directory merely to avoid declaring a dependency.

Future examples might include subagent orchestration, review loops, or observability, but none are part of this task.

### 8.2 `skills/`

Reserved for Agent Skills.

Use a skill when the requirement is reusable procedural knowledge, supporting files, or scripts and does not need a new Pi runtime integration point.

Future skills should use the portable directory form:

```text
skills/<skill-name>/SKILL.md
```

Do not add a skill in this task.

### 8.3 `prompts/`

Reserved for Markdown prompt templates that become named slash commands.

Do not add a demonstration prompt or `README.md` in this task.

### 8.4 `themes/`

Reserved for intentional Pi theme JSON files.

Do not copy built-in themes or add a demonstration theme in this task.

### 8.5 `agents/`

Reserved for future harness-specific role definitions consumed by an orchestration extension.

Files here have no effect until code deliberately consumes them.

### 8.6 Optional future root files

Document, but do not create, these supported Pi files:

- `keybindings.json` for portable terminal UI and application keybindings;
- `SYSTEM.md` to replace Pi's default system prompt;
- `APPEND_SYSTEM.md` to append to Pi's default system prompt.

They should be added only when a concrete requirement exists.

---

## 9. `.gitignore`

Replace the current generic Node ignore file with a concise harness-specific file.

It must include at least:

```gitignore
# Pi credentials and local provider configuration
/auth.json
/auth.json.lock/
/oauth.json
/models.json

# Pi runtime state and caches
/sessions/
/models-store.json
/crashes.json
/settings.json.lock/
/trust.json
/trust.json.lock/
/pi-debug.log
/logs/
*.log
/tmp/

# Pi-managed packages, binaries, and legacy managed tools
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

# OS and editor noise
.DS_Store
Thumbs.db
*.swp
*.swo
```

The leading `/` on Pi top-level paths is intentional. It prevents the root ignore file from hiding a legitimate `bin/`, `tmp/`, or similarly named source directory inside a future extension.

Do not ignore:

- `settings.json`;
- `models.json.example`;
- `package.json`;
- `package-lock.json`;
- `AGENTS.md`;
- `keybindings.json` if intentionally added later;
- source extensions;
- real skills;
- real prompts;
- themes;
- future agent definitions.

---

## 10. `scripts/bootstrap.sh`

Create an executable Bash script that prepares an already-cloned checkout for use.

### 10.1 Required behavior

1. Enable strict shell behavior:

   ```bash
   set -euo pipefail
   ```

2. Resolve the repository root from the script location instead of assuming the current working directory.

3. Check for:

   - `node`;
   - `npm`;
   - `pi`.

4. Validate that Node satisfies the `package.json.engines.node` minimum without adding a semver library merely for this check.

5. Read the expected Pi package and version from `package.json.piHarness`.

6. Validate `pi --version` against the declared exact version.

7. On missing or mismatched Pi, fail clearly and print the exact remediation command derived from repository metadata:

   ```text
   npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.87.1
   ```

8. Print concise version information:

   ```text
   Node: ...
   npm: ...
   Pi: ...
   ```

9. Run `npm ci` when `package-lock.json` exists.

10. Create the external session directory idempotently:

    ```bash
    mkdir -p "$HOME/.local/state/pi/sessions"
    ```

11. Run or direct the user to `doctor.sh`.

12. Finish with concise next steps:

    ```text
    pi-scaps bootstrap complete.

    Next:
      1. Run ./scripts/doctor.sh
      2. Start Pi with: pi
      3. Authenticate with /login if required
    ```

### 10.2 Prohibited behavior

Bootstrap must not:

- install Node;
- silently install or upgrade Pi;
- create `auth.json`;
- request or store API keys;
- delete or replace an agent directory;
- edit `.bashrc`, `.zshrc`, or other shell profiles;
- run `pi update`;
- install third-party Pi packages not declared in settings;
- require `jq`, Python, `rg`, or `fd`.

---

## 11. `scripts/doctor.sh`

Create an executable, read-mostly validation script that answers:

> Is this checkout valid, active, and capable of running the declared harness?

### 11.1 Output format

Use clear statuses:

```text
[PASS] ...
[WARN] ...
[INFO] ...
[FAIL] ...
```

Accumulate failures where practical so one run reports multiple problems. Exit non-zero when any required check fails.

### 11.2 Required checks

Check all of the following:

#### Repository and activation

- repository root can be resolved;
- required tracked files and directories exist;
- script files are executable;
- the checkout is a Git working tree;
- the canonical checkout path equals the active Pi agent directory.

The active agent directory is:

1. `$PI_CODING_AGENT_DIR` when set;
2. otherwise `$HOME/.pi/agent`.

Canonicalize paths so a valid symlinked location is handled correctly.

If the checkout is not active, fail with a direct remediation showing either the default clone location or an export of `PI_CODING_AGENT_DIR`.

During development or validation from another checkout, the supported invocation is:

```bash
PI_CODING_AGENT_DIR="$PWD" ./scripts/doctor.sh
```

#### Runtime versions

- `node` exists;
- Node satisfies the minimum version;
- `npm` exists;
- `pi` exists;
- `pi --version` exactly matches `package.json.piHarness.version`.

Version failures must print the expected and actual values and a concrete fix.

#### Configuration

- `package.json` is strict valid JSON;
- `package-lock.json` is strict valid JSON;
- `settings.json` is strict valid JSON;
- `models.json.example` is strict valid JSON;
- `package.json.piHarness.package` and `.version` exist and are non-empty;
- `settings.json.lastChangelogVersion` exactly matches `package.json.piHarness.version`;
- `settings.json.sessionDir` exists and is a non-empty string;
- external session directory exists and is writable;
- configured/effective session directory resolves outside the Git checkout.

If `PI_CODING_AGENT_SESSION_DIR` is set, report that it overrides the committed setting and validate the effective location too.

#### Dependencies

- `npm ls --depth=0` succeeds.

Do not run `npm ci` from doctor. Doctor should diagnose without deleting or reinstalling dependencies or requiring network access.

#### Resource structure

- `extensions/`, `skills/`, `prompts/`, `themes/`, and `agents/` exist;
- skeleton `.gitkeep` files are present until replaced by real tracked resources;
- report informational counts for real extension, skill, prompt, and theme resources;
- do not count `.gitkeep` as a resource.

The initial skeleton has no functional resources to load. When a real extension, skill, prompt, theme, or model configuration is added, its change must add a suitable semantic smoke check at the same time.

#### Pi startup smoke check

With the pinned Pi version, run a non-interactive offline command that loads configuration without invoking a model, such as:

```bash
PI_OFFLINE=1 pi --list-models >/dev/null
```

Use the active agent directory for this check. Treat a non-zero exit as a failure. Do not make network availability part of doctor health.

#### Git and secret safety

- fail if `git ls-files` contains a forbidden Pi state path;
- check at least `auth.json`, `auth.json.lock/`, `oauth.json`, `models.json`, `models-store.json`, `crashes.json`, `settings.json.lock/`, `trust.json`, `trust.json.lock/`, `sessions/`, `git/`, `npm/`, `bin/`, `tools/`, `tmp/`, and root log files;
- never print the contents of credential or environment files;
- never enumerate environment-variable values as part of authentication checks.

#### Authentication status

Authentication must not be a PASS/FAIL prerequisite because Pi can authenticate using stored credentials or supported environment variables.

Doctor may report only:

```text
[INFO] Stored Pi authentication file is present
```

or:

```text
[INFO] No stored auth.json detected; use /login or a supported environment credential
```

Do not parse, list providers from, or display any part of `auth.json`.

### 11.3 Healthy output

Example shape:

```text
pi-scaps doctor

[PASS] checkout is the active Pi agent directory
[PASS] Node satisfies >=24.21.0
[PASS] npm available
[PASS] Pi 0.87.1 matches the harness contract
[PASS] committed JSON files are valid
[PASS] Pi changelog marker matches the harness contract
[PASS] external session directory is writable
[PASS] npm dependency tree is valid
[PASS] required harness directories are present
[PASS] no forbidden Pi state is tracked
[PASS] Pi configuration starts in offline diagnostic mode
[INFO] 0 extensions, 0 skills, 0 prompts, 0 themes
[INFO] No stored auth.json detected; use /login or a supported environment credential

Harness looks healthy.
```

---

## 12. `scripts/update.sh`

Create an executable Bash script for updating the harness checkout safely.

### 12.1 Required workflow

1. Resolve the repository root from the script location.
2. Confirm the directory is a Git working tree.
3. Refuse to continue if tracked or untracked non-ignored changes exist.
4. Run:

   ```bash
   git pull --ff-only
   ```

5. Run:

   ```bash
   npm ci
   ```

6. Run `scripts/doctor.sh`.

### 12.2 Important distinction

`scripts/update.sh` updates the Git-managed harness checkout.

It must not invoke Pi's `pi update` command. Current Pi uses `pi update` for Pi self-updates and package updates, which would bypass or conflict with the harness's declared version contract.

If a pulled harness change deliberately raises the expected Pi version, doctor should fail with the exact manual installation command. The user then installs that declared version and reruns doctor.

### 12.3 Safety requirements

The script must:

- refuse to overwrite local changes;
- avoid merge commits;
- avoid stashing automatically;
- avoid unpinned external upgrades;
- return non-zero on failure.

---

## 13. README Requirements

Replace the current single-line README with concise operational documentation.

### 13.1 Title and description

```markdown
# pi-scaps

Reproducible personal configuration and extensions for the Pi coding agent.
```

### 13.2 Purpose

Explain that the repository is the portable global Pi harness, not a conventional application.

### 13.3 Prerequisites

Document:

- Linux and Bash;
- Node `>=24.21.0`;
- Node 24 LTS version 24.21.0 or newer recommended for a new installation;
- exact expected Pi version read from the repository contract;
- initial pinned install command:

  ```bash
  npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.87.1
  ```

### 13.4 Fresh installation

Document:

```bash
git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
cd ~/.pi/agent
./scripts/bootstrap.sh
./scripts/doctor.sh
pi
```

Then authenticate locally with `/login` if required.

### 13.5 Existing installation

Briefly explain that an existing `~/.pi/agent` must be backed up and reviewed before cloning. Scripts will not overwrite it.

Do not suggest copying credentials into Git.

### 13.6 Alternative location

Document `PI_CODING_AGENT_DIR`, including the caveat that it redirects both configuration and writable agent state.

### 13.7 Architecture

Describe:

```text
AGENTS.md      global agent instructions
settings.json  portable Pi settings and external session location
extensions/    executable Pi extensions
skills/        reusable Agent Skills
prompts/       slash-command prompt templates
themes/        Pi themes
agents/        future harness-specific role definitions
scripts/       bootstrap, validation, and harness update tooling
```

Also list `keybindings.json`, `SYSTEM.md`, and `APPEND_SYSTEM.md` as supported optional future files that are deliberately absent initially.

### 13.8 Package semantics

Explain that:

- global resources are discovered because the checkout is the Pi agent directory;
- the root `package.json` manages compatibility metadata and future local extension dependencies;
- future external Pi packages belong in `settings.json.packages` and must be pinned;
- installing this Git repository as a Pi package would not by itself apply its global settings or `AGENTS.md`.

### 13.9 Secrets and local state

Prominently state:

> Never commit credentials or private runtime data to this repository.

Mention:

- `auth.json`;
- `.env` files;
- real `models.json`;
- sessions;
- crash diagnostics;
- transient `*.json.lock/` directories;
- trust state;
- downloaded packages and caches.

Explain that sessions live at `~/.local/state/pi/sessions` and that users who want to transfer them must use a separate private mechanism.

Explain separately that `settings.json` is tracked configuration which Pi may rewrite after an intentional persisted settings change. The resulting diff must be reviewed and committed or reverted; it must not be hidden by `.gitignore`.

Add a repository-owner checklist item to confirm GitHub secret scanning and push protection are enabled.

### 13.10 Updating

Document:

```bash
./scripts/update.sh
```

Clarify that this updates the harness, not Pi itself.

### 13.11 Rollback

Document the simple Git workflow:

```bash
git log --oneline
git revert <commit>
```

Do not establish a mandatory commit-message convention in this task.

### 13.12 Philosophy

Keep this section short:

- Pi's small core is intentional.
- Add capabilities when they materially improve reliability, repeatability, integration, or token/cost efficiency.
- Prefer declarative and reproducible configuration.
- Pin third-party functionality.
- Avoid extensions that merely recreate cheap core behavior.

---

## 14. Dependency and Package Policy

### 14.1 Local npm dependencies

Only add a dependency when a real local extension needs it.

Place runtime packages imported by local extensions in `dependencies` and keep the lockfile current.

Do not add libraries to implement checks that standard Bash and Node can handle clearly.

### 14.2 Pi host-provided packages

When future extensions import Pi's host-provided packages, follow current upstream Pi package guidance. Do not add duplicate physical runtime copies merely for type imports if Pi expects those packages as host-provided peers.

This skeleton does not need those declarations because it contains no extensions.

### 14.3 External Pi packages

Do not install any third-party Pi package in this task.

Future external packages must be:

1. reviewed for trust and necessity;
2. added for a specific capability;
3. declared in `settings.json.packages`;
4. pinned to an exact npm version, Git tag, or immutable commit;
5. validated by doctor or a focused smoke test.

Conceptual future configuration:

```json
{
  "packages": [
    "npm:@example/pi-tool@1.2.3",
    "git:github.com/example/pi-extension@<commit>"
  ]
}
```

Do not add an empty `packages` array merely as a placeholder.

### 14.4 Optional command-line tools

Do not require `rg`, `fd`, or `jq` in the initial bootstrap or doctor.

Pi can manage `rg` and `fd` for its own use, and this skeleton does not use `jq`. Add a prerequisite check only when a committed harness feature actually requires that command.

---

## 15. Security Requirements

### 15.1 Must not be committed

- API keys;
- OAuth tokens;
- cookies;
- `auth.json` or legacy auth files;
- environment secrets;
- SSH keys;
- personal access tokens;
- session transcripts;
- trust decisions;
- cached model catalogs;
- credential-bearing provider configuration;
- private project data;
- private endpoints whose disclosure is sensitive.
- Pi crash-diagnostic records, which may contain local diagnostic context.
- transient lock directories for credential, settings, or trust files.

### 15.2 Scripts must

- avoid printing secrets;
- avoid parsing or displaying auth contents;
- avoid echoing environment credential values;
- fail safely;
- never prompt users to commit local state;
- never execute downloaded code beyond declared dependency installation;
- keep doctor network-independent by using Pi offline mode for smoke checks.

### 15.3 Tracked-path audit

Before completion, inspect `git ls-files` and fail if any known forbidden root state path is tracked.

This audit supplements `.gitignore`; it does not replace GitHub secret scanning.

### 15.4 Extension trust

Future extensions execute with the user's permissions. Their source and dependencies must be reviewed before adoption. Do not imply that project trust or `.gitignore` sandboxes extension code.

---

## 16. Portability Requirements

Initial platform:

- Linux;
- Bash;
- supported Node/npm installation;
- current pinned Pi package.

Do not implement PowerShell support in this task.

Scripts must avoid:

- hard-coded usernames;
- hard-coded absolute checkout paths;
- assumptions about the caller's current directory;
- dependency on a specific Node version manager;
- modifying shell profiles.

Use `$HOME` in shell code and `~` only where Pi's configuration semantics support it.

The repository scripts must operate from any checkout location. Doctor must additionally tell the user whether that checkout is the active Pi agent directory.

---

## 17. Out of Scope

Do not implement any of the following in this task:

- scout or research agents;
- architect/worker/reviewer roles;
- subagent orchestration;
- ping-pong review automation;
- Firecrawl;
- Context7 mirrors;
- JEV integration;
- MCP servers;
- browser automation;
- token or cost telemetry;
- model routing;
- specialist thinking-level routing;
- functional prompt templates;
- functional skills;
- custom themes;
- custom keybindings;
- system-prompt replacement;
- CI/CD or GitHub Actions;
- automatic Node installation;
- automatic Pi installation or upgrade;
- secret managers;
- cross-platform PowerShell support;
- a custom secret-scanning implementation;
- a comprehensive resource-test framework before real resources exist;
- a mandatory commit convention;
- an automatically chosen open-source license.

The repository owner should make an explicit license choice before encouraging third-party reuse, but implementation must not invent that legal choice.

---

## 18. Acceptance Criteria

### 18.1 Repository structure

Use the tracked-file list, not an unrestricted filesystem search:

```bash
git ls-files | sort
```

It must show all required harness files. Additional tracked planning documents under `tasks/` are allowed.

There must be no `README.md` placeholder inside `skills/` or `prompts/`.

### 18.2 Fresh clone

On a machine with a supported Node version and the declared Pi version installed:

```bash
git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
cd ~/.pi/agent
./scripts/bootstrap.sh
./scripts/doctor.sh
```

must succeed without editing scripts.

### 18.3 Alternative checkout validation

From a development checkout outside `~/.pi/agent`:

```bash
PI_CODING_AGENT_DIR="$PWD" ./scripts/bootstrap.sh
PI_CODING_AGENT_DIR="$PWD" ./scripts/doctor.sh
```

must validate the same repository without modifying shell startup files.

### 18.4 Session isolation

- `settings.json` declares `~/.local/state/pi/sessions`;
- bootstrap creates it;
- doctor verifies it is writable and outside the checkout;
- no session file appears in the repository after normal Pi use.

### 18.5 Version validation

- unsupported Node causes a clear non-zero failure;
- missing Pi causes a clear non-zero failure and exact install command;
- mismatched Pi causes a clear non-zero failure showing expected and actual versions;
- correct versions pass.

### 18.6 Idempotence

Running:

```bash
./scripts/bootstrap.sh
./scripts/bootstrap.sh
./scripts/doctor.sh
./scripts/doctor.sh
```

must not corrupt state, duplicate configuration, or introduce worktree changes.

### 18.7 Git cleanliness

After bootstrap and doctor on a clean clone:

```bash
git status --short
```

must be empty.

This guarantee covers bootstrap, doctor, and the offline startup diagnostic with `settings.json.lastChangelogVersion` matching the pinned Pi release. It does not cover a user deliberately persisting a setting through Pi. A persisted settings change must remain visible in Git for review.

### 18.8 JSON validity

These files must parse as strict JSON:

- `package.json`;
- `package-lock.json`;
- `settings.json`;
- `models.json.example`.

### 18.9 Shell validity

These files must be executable and pass Bash syntax validation:

- `scripts/bootstrap.sh`;
- `scripts/doctor.sh`;
- `scripts/update.sh`.

### 18.10 Dependency reproducibility

The following must succeed:

```bash
npm ci
npm ls --depth=0
```

### 18.11 Pi startup

With the checkout active as the Pi agent directory:

```bash
PI_OFFLINE=1 pi --list-models
```

must exit successfully without needing a model call.

### 18.12 Secret and state safety

- no forbidden credential or runtime path is tracked;
- ignored paths include current Pi runtime locations, `crashes.json`, and transient top-level lock directories used by Pi;
- scripts never display credential contents;
- `models.json.example` contains no real endpoint credentials;
- GitHub secret scanning and push protection are documented as repository-owner setup.

### 18.13 Update behavior

- `scripts/update.sh` refuses a dirty tree;
- it uses `git pull --ff-only`;
- it runs `npm ci` and doctor;
- it does not run `pi update`;
- it does not silently change the pinned Pi version.

### 18.14 Documentation consistency

README commands, filenames, version requirements, session location, and actual script behavior must agree.

---

## 19. Implementation Sequence

Implement in this order:

1. Refine `.gitignore` with anchored Pi state paths.
2. Create inert directory placeholders and `agents/README.md`.
3. Create the concise global `AGENTS.md`.
4. Create `settings.json` with external session storage.
5. Create `models.json.example`.
6. Create `package.json` with Node and Pi version metadata.
7. Generate `package-lock.json` using npm.
8. Implement `scripts/bootstrap.sh`.
9. Implement `scripts/doctor.sh`.
10. Implement `scripts/update.sh`.
11. Replace the root README.
12. Set executable bits on shell scripts.
13. Run strict JSON and Bash syntax checks.
14. Run bootstrap and doctor using `PI_CODING_AGENT_DIR="$PWD"` in the development checkout.
15. Run the offline Pi startup smoke check.
16. Inspect the tracked-file list for forbidden state and secrets.
17. Confirm the worktree diff contains only intended changes.

---

## 20. Minimum Verification Commands

Before considering implementation complete, run at minimum:

```bash
npm ci

node -e 'JSON.parse(require("fs").readFileSync("package.json", "utf8"))'
node -e 'JSON.parse(require("fs").readFileSync("package-lock.json", "utf8"))'
node -e 'JSON.parse(require("fs").readFileSync("settings.json", "utf8"))'
node -e 'JSON.parse(require("fs").readFileSync("models.json.example", "utf8"))'

bash -n scripts/bootstrap.sh scripts/doctor.sh scripts/update.sh

PI_CODING_AGENT_DIR="$PWD" ./scripts/bootstrap.sh
PI_CODING_AGENT_DIR="$PWD" ./scripts/doctor.sh
PI_CODING_AGENT_DIR="$PWD" PI_OFFLINE=1 pi --list-models

npm ls --depth=0
git ls-files | sort
git status --short
git diff --check
```

Inspect `git ls-files` explicitly for credentials and runtime state.

Testing in the present development environment requires upgrading Node from `20.19.5` to a supported version and installing the declared Pi version first. Implementation must not weaken the checks merely to accommodate the current unsupported local runtime.

---

## 21. Decisions on Previously Missed Items

This version incorporates the earlier review as follows:

| Item | v02 decision |
|---|---|
| External session directory | Required now. |
| `PI_CODING_AGENT_DIR` alternative | Documented with writable-state caveat. |
| `models-store.json` ignore | Required now. |
| `crashes.json` and transient Pi lock directories | Required now; they are writable state, and crash records may contain diagnostic context. |
| `bin/` ignore | Required now, root-anchored. |
| Pi rewriting tracked `settings.json` | A matching `lastChangelogVersion` prevents first-start churn; intentional persisted settings changes remain reviewable Git diffs. |
| Real resource loading checks | Offline Pi startup smoke now; resource-specific checks added with the first real resource. |
| Semantic model configuration check | Conditional on a real `models.json`; offline Pi diagnostics preferred. |
| Authentication check | Informational only and never reads credentials. |
| `rg`, `fd`, `jq` prerequisites | Not required until a committed feature needs them. |
| Automatic Pi installation | Still out of scope. |
| Exact Pi version validation | Required now. |
| Empty package declaration | Not added. |
| Git rollback instructions | Included briefly in README. |
| Mandatory commit convention | Deferred. |

---

## 22. Expected Result

After this task, `pi-scaps` will be a clean and current reproducible harness foundation:

- one Git repository defines intentional global Pi behavior;
- one authoritative Pi version, with a validated Pi-required settings mirror, makes compatibility visible;
- session data lives outside Git;
- other runtime state, including crash records and transient locks, remains safely local and ignored;
- inert placeholders do not accidentally load as resources;
- bootstrap prepares dependencies and local state without surprising system changes;
- doctor detects inactive checkouts, incompatible runtimes, malformed configuration, and tracked state;
- a new computer can be brought online quickly with a short documented sequence.

Future capabilities can then be added as ordinary focused changes, for example:

```text
feat: add subagent orchestration
feat: add ephemeral scout
feat: add review loop
feat: add efficient web retrieval
feat: add token and cost telemetry
```

Those examples are not a mandatory commit convention and are not part of this skeleton.

---

## 23. Upstream References

Version-sensitive Pi documentation and source links are pinned to the target `v0.87.1` tag. The releases page remains unpinned so a future deliberate upgrade can identify newer releases.

- [Pi configuration and agent-directory layout](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/configuration.md)
- [Pi settings reference](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/settings.md)
- [Pi sessions](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/sessions.md)
- [Pi packages](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/packages.md)
- [Pi skills](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/skills.md)
- [Pi prompt templates](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/prompt-templates.md)
- [Pi extensions](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/extensions.md)
- [Pi environment variables](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/environment-variables.md)
- [Pi coding-agent package metadata](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/package.json)
- [Pi settings persistence implementation](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/src/core/settings-manager.ts)
- [Pi authentication storage and locking implementation](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/src/core/auth-storage.ts)
- [Pi releases](https://github.com/earendil-works/pi/releases)
- [Upstream settings serialization behavior report](https://github.com/earendil-works/pi/issues/8009)
- [Pi package-line security advisory](https://github.com/advisories/GHSA-jfgx-wxx8-mp94)
- [GitHub secret scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)
- [GitHub push protection](https://docs.github.com/en/code-security/concepts/secret-security/push-protection)
- [Node release status](https://nodejs.org/en/about/previous-releases)
