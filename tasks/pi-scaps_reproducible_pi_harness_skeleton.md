# PRD: pi-scaps Reproducible Pi Harness Skeleton

## 1. Summary

Create the initial repository structure for `stablecaps/pi-scaps` as the canonical, version-controlled definition of a personal Pi coding-agent harness.

Repository:

`https://github.com/stablecaps/pi-scaps`

The repository should be cloneable onto a new machine and provide the configuration, directory structure, scripts, documentation, and dependency metadata required to recreate the same Pi harness.

The repository is **public**, therefore no credentials, API keys, authentication state, session data, machine-specific runtime data, or other secrets may be committed.

This task establishes the harness foundation only. It should not invent or install unnecessary extensions, skills, agents, or prompts.

---

# 2. Goal

After this work, the intended setup flow should be approximately:

```bash
git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
cd ~/.pi/agent
./scripts/bootstrap.sh
./scripts/doctor.sh
pi
```

Authentication remains a separate local step, for example through Pi's `/login`.

The checked-out repository should then act as the source of truth for the user's global Pi configuration.

---

# 3. Design Principles

The implementation must follow these principles.

### 3.1 Git is the source of truth

Anything that intentionally defines Pi behaviour should eventually be capable of being represented in this repository:

* global Pi instructions
* settings
* model configuration where appropriate
* extensions
* skills
* prompts
* agent definitions
* scripts
* package/dependency declarations

Changes to harness behaviour should therefore be inspectable, diffable, revertible, and reproducible through Git.

### 3.2 Runtime state is not configuration

Runtime-generated data must not be committed.

Examples include:

* authentication tokens
* sessions
* logs
* caches
* downloaded package repositories
* installed dependencies
* temporary files

### 3.3 Public-repository safe

A fresh `git status` after normal Pi usage must not encourage accidental committing of credentials or runtime state.

Secret-bearing files must be explicitly excluded by `.gitignore`.

### 3.4 Minimal initial implementation

Do not populate the repository with speculative functionality.

Create the structure required to support future:

* extensions
* skills
* prompts
* subagent definitions
* automation/orchestration
* model configuration

but leave those areas empty or documented until functionality is deliberately added.

### 3.5 Reproducibility over convenience

Where external packages are eventually added, versions should be pinned where practical.

A rebuild should not silently install arbitrary newer versions and produce a materially different harness.

### 3.6 Idempotent tooling

Running bootstrap or validation scripts repeatedly should be safe.

---

# 4. Required Repository Structure

Create the following structure:

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
│   └── README.md
│
├── skills/
│   └── README.md
│
├── prompts/
│   └── README.md
│
└── scripts/
    ├── bootstrap.sh
    ├── doctor.sh
    └── update.sh
```

Do not create empty directories without tracked files because Git will not preserve them.

Use the small `README.md` files inside placeholder directories to explain their intended purpose.

---

# 5. File Requirements

## 5.1 `AGENTS.md`

Purpose:

Global instructions automatically available to Pi when this repository is installed as `~/.pi/agent`.

For this initial task, keep it intentionally minimal.

It should:

* identify this repository as the global Pi harness
* state that repo configuration should favour simplicity and low token overhead
* state that new extensions or dependencies should solve a demonstrated reusable problem
* discourage implementing functionality already easily achievable using Pi's core tools unless there is a clear efficiency/reliability benefit
* state that secrets must never be committed
* instruct future agents to preserve reproducibility

Do not add lengthy behavioural instructions yet.

---

## 5.2 `settings.json`

Create a valid Pi global settings file.

It should contain only deliberately portable, non-secret configuration.

Do not add fabricated model IDs, provider credentials, machine-specific filesystem paths, or packages that have not yet been selected.

Start with the smallest useful valid configuration.

For example, where supported:

```json
{
  "defaultThinkingLevel": "medium"
}
```

If current Pi configuration semantics make an empty object preferable, use:

```json
{}
```

The important requirement is that the committed settings file is valid and safe.

Future external Pi packages will be declared here and should normally be pinned to a tag or commit.

---

## 5.3 `models.json.example`

Do **not** commit a real machine-specific `models.json` unless there is already a concrete requirement for custom model/provider definitions.

Instead provide:

```text
models.json.example
```

Document that users can copy it to:

```text
models.json
```

when custom providers/models are required.

The example must contain no keys, tokens, private endpoints, account IDs, or fabricated credentials.

`models.json` itself should be gitignored.

---

# 6. Pi Package Manifest

## 6.1 `package.json`

Create a minimal package manifest.

Use:

```json
{
  "name": "pi-scaps",
  "version": "0.1.0",
  "private": true,
  "description": "Reproducible personal Pi coding-agent harness",
  "keywords": [
    "pi-package"
  ],
  "pi": {
    "extensions": [
      "./extensions"
    ],
    "skills": [
      "./skills"
    ],
    "prompts": [
      "./prompts"
    ]
  }
}
```

Adjust only where required by current Pi package semantics.

Do not add runtime dependencies merely to populate the package.

Generate and commit a valid `package-lock.json`.

The manifest gives the repository an explicit declaration of Pi resources rather than relying solely on directory auto-discovery.

---

# 7. Directory Responsibilities

## 7.1 `extensions/`

Reserved for TypeScript Pi extensions.

`extensions/README.md` should explain:

* extensions add executable functionality
* extensions should only be introduced for reusable capabilities
* each extension should have a clear reason for existing
* expensive/context-heavy behaviour should be considered carefully
* third-party source should not simply be copied here without justification

Future likely examples include:

* subagent orchestration
* ping-pong review loops
* context-efficient search/retrieval
* observability/token accounting

These are examples only. Do not implement them in this task.

---

## 7.2 `skills/`

Reserved for Pi/Agent Skills.

`skills/README.md` should explain that skills are preferable when the requirement is reusable procedural knowledge rather than executable Pi functionality.

No skills should be invented for this task.

---

## 7.3 `prompts/`

Reserved for reusable prompt templates.

`prompts/README.md` should state that prompts should contain repeatable user workflows that benefit from named invocation.

Do not add example prompts merely for demonstration.

---

## 7.4 `agents/`

This is a harness-level convention rather than necessarily a Pi-native resource directory.

It will hold future subagent/persona/task-role definitions used by orchestration extensions.

`agents/README.md` should explain the intended distinction between:

* agent role
* model selection
* thinking level
* task/context allocation

Do not create `architect.md`, `worker.md`, `reviewer.md`, etc. yet.

Those roles should be introduced only when the orchestration mechanism actually consumes them.

---

# 8. `.gitignore`

Replace or refine the current generic Node `.gitignore` so it is specifically suitable for a Pi harness.

At minimum ignore:

```gitignore
# Authentication / secrets
auth.json
.env
.env.*
!.env.example
*.secret

# Local custom model/provider configuration
models.json

# Pi runtime state
sessions/
logs/
*.log
pi-debug.log
trust.json

# Pi-managed downloaded packages
git/
npm/

# Node dependencies
node_modules/

# OS/editor noise
.DS_Store
Thumbs.db
*.swp
*.swo
```

Also ignore any additional known Pi runtime files that current Pi documentation identifies as machine-generated state.

Do not ignore:

* `settings.json`
* `package.json`
* `package-lock.json`
* `AGENTS.md`
* source extensions
* skills
* prompts
* agent definitions

---

# 9. `scripts/bootstrap.sh`

Create an executable Bash script.

Purpose:

Prepare a newly cloned harness for use without introducing secrets or silently making major system changes.

Requirements:

1. Enable strict shell behaviour:

```bash
set -euo pipefail
```

2. Determine the repository root robustly rather than assuming the current working directory.

3. Check that required commands exist:

* `node`
* `npm`
* `pi`

4. Print useful version information:

```text
Node: ...
npm: ...
Pi: ...
```

5. Run:

```bash
npm ci
```

when a lockfile exists.

6. Create any required local runtime directories that intentionally live outside version control.

7. Do not create authentication credentials.

8. Do not prompt for or store API keys.

9. Do not automatically modify `.bashrc`, `.zshrc`, or unrelated user configuration.

10. Finish with concise next steps, including authentication if required.

Example final output:

```text
pi-scaps bootstrap complete.

Next:
  1. Run ./scripts/doctor.sh
  2. Start Pi with: pi
  3. Authenticate with /login if required
```

The script must be safe to run repeatedly.

---

# 10. `scripts/doctor.sh`

Create an executable validation script.

This script answers:

> Is this machine capable of running the harness as expected?

Checks should include:

```text
[PASS] repository structure
[PASS] node available
[PASS] npm available
[PASS] pi available
[PASS] package.json valid
[PASS] settings.json valid
[PASS] extensions directory present
[PASS] skills directory present
[PASS] prompts directory present
[PASS] agents directory present
```

Where possible also report versions.

Example:

```text
pi-scaps doctor

[PASS] Node 22.x
[PASS] npm 10.x
[PASS] Pi installed
[PASS] settings.json valid JSON
[PASS] package.json valid JSON
[PASS] harness directories present

Harness looks healthy.
```

Failures must:

* produce a clear message
* identify what needs fixing
* return a non-zero exit code

Avoid adding dependencies merely to implement validation.

Use standard shell/Node functionality where practical.

The script must NOT print credentials or secret file contents.

---

# 11. `scripts/update.sh`

Create a small executable script for safely updating the harness checkout.

Responsibilities:

1. Refuse to overwrite uncommitted repository changes.
2. Pull the latest Git changes.
3. Run `npm ci` if dependency metadata changed or simply running it is cheap/idempotent.
4. Run `doctor.sh`.
5. Do not automatically run unpinned external package upgrades.

Example conceptual workflow:

```text
check working tree
      ↓
git pull --ff-only
      ↓
npm ci
      ↓
doctor.sh
```

Use:

```bash
git pull --ff-only
```

rather than performing implicit merge commits.

---

# 12. README

Replace the current single-line README with useful project documentation.

It should contain these sections.

## `# pi-scaps`

Short description:

> Reproducible personal configuration and extensions for the Pi coding agent.

## Purpose

Explain that this repository represents the portable Pi harness rather than a software application.

## Installation

Document:

```bash
git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
cd ~/.pi/agent
./scripts/bootstrap.sh
./scripts/doctor.sh
```

Then:

```bash
pi
```

and authenticate locally if required.

## Architecture

Briefly explain:

```text
AGENTS.md      global agent instructions
settings.json  portable Pi configuration
extensions/    executable Pi extensions
skills/        reusable agent skills
prompts/       reusable prompt templates
agents/        subagent role definitions
scripts/       bootstrap/update/validation tooling
```

## Secrets

Explicitly state:

**Never commit credentials to this repository.**

Mention at least:

* `auth.json`
* `.env`
* `models.json` where it contains private provider configuration

## Updating

Document:

```bash
./scripts/update.sh
```

## Philosophy

Briefly state:

* Pi's small core toolset is intentional.
* Add reusable capabilities where they improve reliability, repeatability, or token/cost efficiency.
* Avoid extensions that merely replicate things the model can already accomplish cheaply with Pi's core tools.
* Prefer declarative/reproducible configuration.
* Pin third-party functionality where possible.

Keep the README concise.

---

# 13. Security Requirements

Because this repository is public:

### MUST NOT commit

* API keys
* OAuth tokens
* cookies
* Pi `auth.json`
* environment secrets
* SSH keys
* personal access tokens
* session transcripts
* private model endpoints containing credentials
* private project data

### MUST

* include appropriate ignore rules
* keep examples synthetic
* avoid printing secrets in scripts
* ensure bootstrap does not ask users to commit local auth data

---

# 14. Portability

Initial target:

* Linux
* Bash

Do not attempt Windows PowerShell support in this task.

Scripts should avoid hard-coded usernames or absolute paths such as:

```text
/home/giri/...
```

Use `$HOME` or paths relative to the repository root where necessary.

The intended default installation location is:

```text
~/.pi/agent
```

but repository scripts should operate correctly if the repo is checked out elsewhere.

---

# 15. Dependency Policy

Do not add libraries unless needed.

For this initial skeleton:

* shell should handle orchestration
* Node may be used for JSON validation
* npm manages any eventual extension dependencies

Avoid dependencies such as:

* jq
* Python packages
* external bootstrap frameworks

unless a concrete requirement makes them necessary.

The goal is for the harness bootstrap mechanism itself to have very few prerequisites.

---

# 16. External Pi Packages

Do not install any third-party Pi packages in this task.

Future packages should be:

1. reviewed before adoption
2. added for a specific capability
3. represented declaratively in harness configuration
4. pinned to an explicit version, tag, or commit where practical

A future change should therefore look conceptually like:

```text
feat: add <capability> extension
```

rather than manually installing something on one machine without recording it here.

---

# 17. Out of Scope

Do NOT implement in this task:

* scout/research agents
* architect/worker/reviewer agents
* ping-pong review automation
* Firecrawl
* Context7 mirrors
* JEV integration
* MCP servers
* browser automation
* token telemetry
* model routing
* specialist thinking-level routing
* CI/CD
* GitHub Actions
* automatic Pi installation
* automatic Node installation
* secret managers
* cross-platform PowerShell support

These should be separate changes with their own justification.

---

# 18. Acceptance Criteria

The task is complete when all of the following are true.

### Repository structure

Running:

```bash
find . -maxdepth 2 -type f | sort
```

shows the expected tracked files.

### Fresh clone

A user can run:

```bash
git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent
cd ~/.pi/agent
./scripts/bootstrap.sh
```

without editing scripts.

### Validation

Running:

```bash
./scripts/doctor.sh
```

provides clear PASS/FAIL output and exits successfully when requirements are met.

### Idempotence

Running:

```bash
./scripts/bootstrap.sh
./scripts/bootstrap.sh
```

must not corrupt state or produce conflicting configuration.

### Git cleanliness

After bootstrap:

```bash
git status --short
```

should remain clean, excluding intentional user modifications.

### Secrets

There must be no credentials or private runtime state tracked by Git.

Verify with:

```bash
git ls-files
```

and inspect all configuration files.

### JSON

The following must parse successfully:

```text
package.json
settings.json
models.json.example
```

if the example is JSON.

### Shell scripts

The following must be executable:

```text
scripts/bootstrap.sh
scripts/doctor.sh
scripts/update.sh
```

### Documentation

README installation instructions must agree with actual script names and repository structure.

---

# 19. Implementation Sequence

Implement in this order:

1. Refine `.gitignore`.
2. Create directory skeleton.
3. Create `AGENTS.md`.
4. Create `settings.json`.
5. Create `models.json.example`.
6. Create `package.json`.
7. Generate `package-lock.json`.
8. Create directory README placeholders.
9. Implement `bootstrap.sh`.
10. Implement `doctor.sh`.
11. Implement `update.sh`.
12. Replace root `README.md`.
13. Set executable bits on shell scripts.
14. Run validation.
15. Check Git diff for accidental secrets or generated state.

---

# 20. Verification Commands

Before considering implementation complete, run at minimum:

```bash
npm ci
./scripts/bootstrap.sh
./scripts/doctor.sh
git status --short
git diff --check
```

Also validate JSON using Node:

```bash
node -e 'JSON.parse(require("fs").readFileSync("package.json"))'
node -e 'JSON.parse(require("fs").readFileSync("settings.json"))'
```

Inspect tracked files:

```bash
git ls-files
```

Confirm no credential/runtime files are included.

---

# 21. Expected Result

After this PR, `pi-scaps` is not yet a sophisticated agent harness.

It is something more important at this stage:

**a clean, reproducible, version-controlled foundation upon which every subsequent Pi harness capability can be added deliberately.**

Future work should then be implemented as small independently reviewable changes, for example:

```text
feat: add subagent orchestration
feat: add ephemeral scout
feat: add ping-pong review workflow
feat: add efficient web retrieval
feat: add context documentation retrieval
feat: add token/cost telemetry
```

This keeps the evolution of the harness observable and reversible rather than allowing `~/.pi/agent` to become an undocumented collection of local customisations.



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Thinbgs that should probably be incorporated




Compared with my **original harness outline**, these specific things did **not make it into the PRD as explicit requirements**:

1. **Explicitly moving Pi sessions outside the repo**
   I originally suggested something like:

   ```json
   {
     "sessionDir": "~/.local/state/pi/sessions"
   }
   ```

   The PRD says runtime data should live outside Git, but it does **not explicitly require configuring `sessionDir`**.

2. **`PI_CODING_AGENT_DIR` as an alternative installation method**
   I explained the option of:

   ```bash
   export PI_CODING_AGENT_DIR="$HOME/src/pi-harness"
   ```

   and why I preferred cloning directly into `~/.pi/agent`. The PRD only documents the `~/.pi/agent` approach.

3. **The caveat that `PI_CODING_AGENT_DIR` also redirects writable state**
   I mentioned that this can drag `auth.json`/other Pi state into the repo directory and referenced the current Pi limitation. That architectural caveat isn't in the PRD.

4. **`models-store.json` in `.gitignore`**
   My first proposed ignore list explicitly contained:

   ```gitignore
   models-store.json
   ```

   The PRD doesn't name it specifically.

5. **`bin/` in `.gitignore`**
   Same thing: my original example ignored:

   ```gitignore
   bin/
   ```

   The PRD doesn't explicitly include it.

6. **Checking that extensions actually load**
   My original `doctor.sh` sketch included things like:

   ```text
   ✓ 7 extensions load
   ✓ 11 skills discovered
   ```

   The PRD currently only requires that the directories exist. It doesn't require Pi to actually discover/load their contents.

7. **Checking model configuration through `doctor.sh`**
   Original sketch:

   ```text
   ✓ model configuration valid
   ```

   The PRD validates JSON but doesn't require semantic validation of Pi model configuration.

8. **Checking authentication state**
   Original sketch included:

   ```text
   ✓ auth present
   ```

   The PRD intentionally avoids reading/displaying auth data and doesn't require reporting whether authentication exists.

9. **Checking optional harness CLI dependencies such as `rg`, `fd`, `jq`**
   I originally suggested a mature bootstrap could verify:

   ```text
   rg
   fd
   jq
   ```

   The PRD deliberately dropped this and actually says not to add `jq` etc. unless something needs them.

10. **Potentially installing Pi / validating a specific Pi version**
    My earlier mature-bootstrap sketch included:

    ```text
    verify Node version
    verify/install Pi version
    ```

    The PRD only verifies that Node/npm/Pi exist. It explicitly makes automatic Pi/Node installation out of scope.

11. **Pinning the Pi executable/version itself**
    I strongly discussed reproducibility and pinning third-party extensions, but the PRD does **not define a mechanism for saying “this harness expects Pi version X”**. At the moment `doctor.sh` merely reports whatever version happens to be installed.

12. **A concrete external-package declaration example**
    I originally showed something conceptually like:

    ```json
    {
      "packages": [
        "git:github.com/foo/pi-something@<pinned-version>",
        "npm:@foo/pi-other@<pinned-version>"
      ]
    }
    ```

    The PRD describes this policy, but doesn't include a placeholder/declarative package section because we haven't selected any packages yet.

13. **Explicit Git rollback workflow**
    I originally highlighted:

    ```bash
    git revert <commit>
    ```

    as one of the benefits of the design. The PRD talks about reversibility, but doesn't document rollback usage.

14. **Commit-convention examples as an operational practice**
    I gave examples like:

    ```text
    feat: add ephemeral scout
    perf: add JEV log filtering
    chore: pin context7 extension
    ```

    The PRD contains some future `feat:` examples, but does not establish a commit convention as a requirement.

The **two omissions I'd actually add to the PRD now** are **#1 session isolation** and **#11 Pi-version reproducibility**.

And I'd probably upgrade **#6** too: eventually `doctor.sh` should verify that Pi can *actually discover/load* the declared resources, rather than merely confirming that `extensions/` exists. Those three materially improve the “clone anywhere and get the same harness” objective.

