# PRD: controlled Pi installation and upgrade workflow

Status: proposed

Date: 2026-09-24

## 1. Summary

Keep Pi and harness dependencies pinned so every machine runs the same declared
versions, while making initial installation, routine synchronisation, deliberate
Pi upgrades, compatibility smoke checking, and explicit recovery straightforward.

The repository remains the source of truth. A normal machine update must converge
the machine to the versions already committed in Git. A separate maintainer
workflow proposes a new Pi pin, loads the complete harness against it, and leaves
the resulting state visible for review or explicit recovery.

This PRD supersedes the earlier skeleton PRD only where that document prohibits
bootstrap from installing Pi or requires a Pi version change to be installed
manually. The existing repository, secret-safety, session-separation, and exact
version requirements remain in force.

## 2. Goals

- Preserve an exact Pi version across every machine using this harness.
- Manage Pi consistently as a global npm installation on every supported machine.
- Make a fresh clone capable of installing the declared Pi version without a
  separate copy-and-paste installation step.
- Make routine harness updates install any newly committed Pi pin automatically.
- Provide one deliberate command for proposing an explicit or latest Pi version.
- Reject a candidate that cannot load the complete harness.
- Preserve an inspectable failed-upgrade state and provide explicit, reliable
  recovery instructions.
- Keep local extension dependencies reproducible through `package-lock.json`.
- Reconcile declared external Pi packages without moving their exact pins.
- Avoid creating a bespoke extension-testing framework or requiring speculative
  unit tests.

## 3. Non-goals

- Automatically installing or upgrading Node.
- Supporting Pi installations managed by the standalone installer or another
  package manager.
- Running an unpinned Pi release in normal bootstrap or update flows.
- Proving every extension feature semantically correct after an upgrade.
- Writing unit tests merely to satisfy this workflow.
- Running arbitrary test commands found inside third-party packages.
- Updating every extension dependency whenever Pi changes.
- Automatically restoring Pi or tracked files after an upgrade failure.
- Adding a dedicated rollback wrapper around Git and bootstrap.
- Automatically committing, pushing, stashing, or rewriting Git history.
- Intentionally reading or printing provider credentials, invoking a model, or
  depending on provider/network health during compatibility smoke checks.
- Building containers, virtual machines, or a second package-management system
  solely to test Pi upgrades.

## 4. Version and dependency policy

### 4.1 Pi

- This harness supports only Pi installed globally through npm.
- `package.json.piHarness.package` and `.version` remain the authoritative Pi
  package and exact version.
- Bootstrap, update, doctor, and upgrade tooling must read this metadata rather
  than maintain separate script constants.
- Installation tooling must verify that the active `pi` executable is the
  npm-managed installation it operates on, and must fail rather than create a
  shadowed second installation.
- A candidate Pi package's Node engine requirement must be checked against both
  the installed Node version and the repository's Node contract before mutation.
- The workflow must not install Node or silently raise the Node contract. If a
  candidate requires a higher minimum, update the Node contract separately and
  deliberately before retrying the Pi upgrade.
- `settings.json.lastChangelogVersion` must continue to match the declared Pi
  version while Pi requires that writable marker.
- Human-facing documentation should avoid duplicating the literal Pi version
  where it can direct the user to bootstrap or repository metadata instead.

### 4.2 Local extension dependencies

- Dependencies imported by repository-owned extensions remain declared in the
  root `package.json` and resolved by `package-lock.json`.
- Normal bootstrap and update use `npm ci`; they do not select newer dependency
  versions.
- A Pi-only version change must not rewrite `package-lock.json` unless a real
  package manifest change requires it.

### 4.3 External Pi packages

- External Pi packages remain declared with exact npm versions or immutable Git
  references.
- Contract checks must reject unpinned external package declarations.
- Bootstrap and routine update must reconcile the declared package set without
  moving its pins.
- A Pi upgrade tests the currently declared external-package set first.
- External packages are upgraded only when deliberately requested or when a
  compatibility failure demonstrates the need.

## 5. User workflows

### 5.1 Fresh machine

```text
install supported Node/npm
clone repository
run bootstrap
run doctor
start Pi and authenticate locally
```

Bootstrap installs the exact declared Pi version when it is missing or different.

### 5.2 Routine machine synchronisation

```text
run update
  -> fast-forward repository
  -> install the repository's exact Pi pin
  -> restore locked local dependencies
  -> reconcile pinned external Pi packages
  -> run doctor
```

Routine update applies a version decision already reviewed and committed on
another machine. It does not discover or select a newer Pi release.

### 5.3 Deliberate Pi upgrade

```text
run upgrade-pi with an explicit version or "latest"
  -> require a clean, healthy current harness
  -> resolve one exact candidate
  -> install the exact candidate
  -> update tracked version metadata
  -> restore locked dependencies and reconcile pinned packages
  -> smoke-check the complete harness offline
  -> leave a reviewable, uncommitted diff
commit after review
```

Upgrade resolution, Pi installation, and external-package reconciliation may
require network access. The compatibility smoke check itself must run offline.

### 5.4 Explicit recovery

An unsuccessful proposal remains visible for diagnosis. To abandon an
uncommitted attempt, restore only the metadata files changed by the upgrade and
reconverge the machine:

```text
git restore --source=HEAD --staged --worktree -- package.json settings.json
./scripts/bootstrap.sh
./scripts/doctor.sh
```

To undo an upgrade that was already committed, start from a clean worktree,
revert its Git commit, and reconverge:

```text
git revert <pi-upgrade-commit>
./scripts/bootstrap.sh
./scripts/doctor.sh
```

Installing the exact reverted version replaces the current global Pi
installation; a separate uninstall step and rollback script are unnecessary.

## 6. Task groups

### Group 0 — Preflight and design confirmation

- [x] Inspect and preserve all pre-existing worktree changes.
- [x] Confirm the maintained Pi npm package name and current version-output format.
- [x] Confirm the npm query used to resolve `latest` and how prereleases are excluded.
- [x] Confirm the supported Pi command for reconciling pinned external packages.
- [x] Confirm how the candidate npm package's Node engine requirement will be read
  and compared with the installed Node version and repository contract.
- [x] Confirm how an active npm-managed Pi executable is distinguished from an
  unsupported standalone or otherwise managed installation.
- [x] Record the existing bootstrap, update, doctor, contract-validator, pre-commit,
  and README behavior that this work changes.
- [x] Treat this PRD as the authority for Pi installation and upgrade semantics while
  leaving unrelated skeleton requirements intact.

- [x] **Group 0 complete:** the implementation scope and conflicts with earlier
  PRDs are explicit before scripts are changed.

#### Group 0 findings — 2026-09-25

- Starting worktree: only this PRD had an unstaged modification; the index was
  clean. That existing diff is preserved. Node `v24.21.0` and npm `11.19.0` are
  available; `pi` is absent, so the version-output and ownership findings below
  are based on upstream source and npm layout, pending runtime verification in
  Group 8.
- The maintained npm package is `@earendil-works/pi-coding-agent`. Its pinned
  `v0.87.1` manifest declares `bin.pi = dist/bundle/cli.js` and
  `engines.node = >=22.19.0`. Pi's CLI `--version` prints the package `VERSION`
  alone; treat a bare version such as `0.87.1` as the expected format and verify
  the actual installed binary after installation. Sources: [Pi package manifest](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/package.json),
  [Pi CLI source](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/src/main.ts).
- Resolve `latest` once with
  `npm view @earendil-works/pi-coding-agent dist-tags.latest --json`.
  npm's `latest` is a publisher-controlled tag, not a
  guarantee of stability. Parse one exact version and reject a prerelease
  identifier (the `-...` suffix) before installation. An explicit prerelease
  remains allowed. Source: [npm view](https://docs.npmjs.com/cli/v11/commands/npm-view/),
  [npm dist-tag](https://docs.npmjs.com/cli/v11/commands/npm-dist-tag/).
- `pi update --extensions` is Pi's supported package-reconciliation command.
  Versioned npm package declarations and fixed Git refs remain pinned during
  reconciliation; this workflow will additionally validate immutable Git commits
  and check that settings pins did not move. Sources: [Pi package documentation](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/packages.md),
  [Pi CLI documentation](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/docs/cli.md).
- Read candidate `engines.node` with
  `npm view <package>@<exact-version> engines.node --json` before installation.
  Compare it with `process.versions.node`
  and `package.json.engines.node` (currently `>=24.21.0`). Both the current Pi
  manifest and this harness use a simple `>=major.minor.patch` minimum. Support
  that form without adding a dependency; fail for an unfamiliar engine range and
  require a deliberate contract decision. Sources: [npm view](https://docs.npmjs.com/cli/v11/commands/npm-view/),
  [Pi package manifest](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/package.json).
- For npm ownership, resolve the active `pi` executable and compare its physical
  path with the global npm bin link under `npm prefix -g`, then verify that link's
  target matches the declared package's `bin.pi` under `npm root -g`. Check before
  replacing an existing Pi and again afterward; reject a shadowed binary. npm
  documents global bin links under `{prefix}/bin`. Source: [npm global-prefix
  layout](https://docs.npmjs.com/cli/v11/commands/npm-prefix/).
- Current behavior: bootstrap reads the Node/Pi contract, rejects missing or
  mismatched Pi, runs `npm ci`, and creates the external session directory.
  Update requires a clean worktree, fast-forwards Git, runs `npm ci`, then doctor.
  Doctor enforces exact Pi/Node versions and runs an offline startup check. The
  contract validator checks the Node minimum, lockfile engine mirror, and Pi
  changelog marker; pre-commit runs it plus `npm ls --depth=0` and safety hooks.
  README still requires a separate manual Pi install and says update does not
  install Pi. Groups 1–8 change those specific behaviors. This PRD governs Pi
  installation and upgrade semantics where the earlier skeleton PRD conflicts;
  its remaining safety, session, and repository requirements stay in force.

### Group 1 — Normalise the version contract

- [x] Retain one authoritative Pi package/version pair in `package.json`.
- [x] Remove unnecessary human-maintained copies of the literal version from normal
  installation instructions.
- [x] Keep required derived metadata, including `lastChangelogVersion`, synchronised
  through tooling.
- [x] Update the existing contract validator and pre-commit checks to enforce only
  intentional cross-file relationships.
- [x] Preserve exact version validation in doctor.

- [x] **Group 1 complete:** a Pi version bump has one source value and only
  necessary derived values.

### Group 2 — Make bootstrap converge Pi

- [x] Change bootstrap from “validate and print a remediation command” to “ensure the
  exact declared Pi version is installed.”
- [x] If `pi` already exists, verify that the active executable belongs to the global
  npm installation being managed; fail clearly if another installation shadows it.
- [x] Skip global installation when the npm-managed Pi executable already reports the
  exact declared version.
- [x] If Pi is absent or mismatched, install
  `package.json.piHarness.package@package.json.piHarness.version` globally through
  npm using `--ignore-scripts`.
- [x] Refresh shell command lookup after installation and verify that the active
  `pi --version` exactly matches the declared version.
- [x] Never invoke `sudo`, edit npm configuration, or change shell profiles.
- [x] Give a clear remediation when the user's npm global prefix is not writable.
- [x] Continue running `npm ci`, creating external state directories, and providing
  concise next steps.
- [x] Validate that every declared external Pi package is pinned, then reconcile the
  declared package set without moving any pin.
- [x] Remain safe and idempotent when run repeatedly.

- [x] **Group 2 complete:** a supported fresh machine with Node/npm can clone the
  repository and obtain the exact declared Pi version by running bootstrap.

### Group 3 — Make routine update reconverge the machine

- [x] Preserve the clean-worktree requirement and `git pull --ff-only` behavior.
- [x] After pulling, ensure the exact Pi version now declared by the repository is
  installed automatically.
- [x] Restore local extension dependencies with `npm ci`.
- [x] Reconcile all declared external Pi packages without changing their pins.
- [x] Run doctor only after Pi and local dependencies match the pulled revision.
- [x] Do not run an unbounded `pi update`, select `latest`, or update external package
  pins during routine synchronisation.
- [x] Reuse bootstrap or a small shared mechanism where that is simpler than
  duplicating version-install logic; do not introduce a framework for reuse.

- [x] **Group 3 complete:** after a reviewed Pi bump is merged,
  `scripts/update.sh` on another machine converges to it without a manual npm
  command.

### Group 4 — Add the maintainer Pi-upgrade command

- [x] Add one documented command, provisionally `scripts/upgrade-pi.sh`, accepting an
  explicit version, including an explicitly requested prerelease, or the literal
  target `latest`.
- [x] Require a clean Git worktree before changing the global Pi installation or
  tracked metadata.
- [x] Require the installed Pi version to match the current repository pin and run
  doctor successfully before attempting an upgrade.
- [x] Resolve the npm registry's `latest` dist-tag once to an exact version and
  display the resolved value before mutation.
- [x] Treat an explicit prerelease as opt-in; never choose one through `latest`.
- [x] Read the candidate package's Node engine requirement before mutation and
  verify that the installed Node version satisfies it.
- [x] If the candidate requires a higher Node minimum than the repository declares,
  stop before mutation and require a separate deliberate Node-contract update.
- [x] Record the previous declared and installed versions before mutation.
- [x] Verify that the active Pi executable is npm-managed and refuse to install a
  second copy that would be shadowed on `PATH`.
- [x] Install the exact candidate through npm with `--ignore-scripts` and without
  using `sudo`.
- [x] Refresh shell command lookup and verify the active `pi --version` before
  changing tracked metadata.
- [x] Update the authoritative Pi pin and required derived metadata without unrelated
  JSON reformatting.
- [x] Write changed metadata atomically so interruption cannot leave malformed JSON.
- [x] Run `npm ci`, validate external package pins, and reconcile those packages
  before the offline smoke check.
- [x] Run the compatibility smoke checks in Group 5.
- [x] On candidate installation or post-installation version-verification failure,
  exit non-zero before changing metadata; report that the active global Pi state may
  need reconvergence through bootstrap.
- [x] On dependency reconciliation or smoke-check failure after metadata changes,
  exit non-zero while leaving the candidate installation and tracked proposal
  visible for diagnosis.
- [x] On every post-mutation failure, print the targeted uncommitted-recovery
  workflow without modifying Git or attempting live rollback.
- [x] On success, leave changes unstaged and uncommitted, and print a concise summary
  of the old version, new version, changed files, verification result, and next
  review or recovery steps.
- [x] Treat an already-declared target as a successful no-op after verifying health.

- [x] **Group 4 complete:** one command can propose a reviewable Pi bump, and failed
  attempts have an explicit, state-appropriate recovery path.

### Group 5 — Add proportionate compatibility smoke checks

- [x] Define the baseline guarantee honestly as “the complete harness loads under the
  candidate Pi version,” not “all extension behavior is proven compatible.”
- [x] Run a non-interactive offline Pi invocation using this checkout as the active
  agent directory and without making a model request.
- [x] Keep registry access and pinned-package reconciliation in the preceding online
  phase; do not make provider or network health part of the smoke result.
- [x] Fail on configuration errors, extension import/factory failures, missing
  dependencies, registration conflicts, or other startup failures.
- [x] Run existing root-level typecheck/check commands only when the repository has
  deliberately declared them as part of its own verification contract.
- [x] Do not discover and execute arbitrary scripts from installed third-party
  packages.
- [x] Do not require new unit tests for simple extensions. Add a focused semantic
  check later only when an important extension has behavior that a load check
  cannot cover and a demonstrated failure justifies it.
- [x] Keep smoke-check output useful without printing credentials or sensitive
  configuration contents.

- [ ] **Group 5 complete:** an upgrade cannot succeed when the candidate fails to
  load the configured harness, without creating a general extension-test
  framework.

The upgrade now uses an offline RPC startup smoke check. Pi's `--help` and
`--list-models` paths exit before runtime diagnostics are checked, so they cannot
establish the Group 5 guarantee. The RPC path reaches runtime diagnostics and
extension binding before exiting on stdin EOF ([Pi startup source](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/src/main.ts),
[Pi RPC source](https://github.com/earendil-works/pi/blob/v0.87.1/packages/coding-agent/src/modes/rpc/rpc-mode.ts)).
A live candidate-Pi run remains for Group 8.

### Group 6 — Preserve dependency and lockfile semantics

- [ ] Verify that a Pi-only bump leaves `package-lock.json` unchanged.
- [x] Keep `npm ci` as the normal local-dependency convergence command.
- [x] Extend the contract validation when external packages are introduced so every
  npm source has an exact version and every Git source has an immutable ref.
- [x] If compatibility requires an extension dependency change, perform that change
  deliberately, regenerate the lockfile through npm, and include it in the same
  reviewed upgrade only when causally related.
- [x] Keep unrelated dependency refreshes separate so failures remain attributable.
- [x] Reconcile currently declared exact external Pi packages only through supported
  Pi package behavior; do not move their pins implicitly.

- [ ] **Group 6 complete:** Pi, local npm dependencies, and external Pi packages
  each retain a clear, reviewable source of truth.

The upgrade command checks `package-lock.json` against `HEAD` before success,
and `npm ci --offline` left the present lockfile unchanged. An actual Pi-only
bump is still required to close the first checkbox and Group 6 acceptance.

### Group 7 — Align doctor and documentation

- [x] Keep doctor strict about the installed Pi version matching the repository pin.
- [x] Update doctor remediation to point to bootstrap/update rather than requiring a
  copied manual installation command as the normal path.
- [x] Add `scripts/upgrade-pi.sh` to doctor's required-file and executable checks.
- [x] Document the difference between bootstrap, routine update, and maintainer
  upgrade.
- [x] Document that only globally npm-installed Pi is supported and how conflicts
  with other installation methods are reported.
- [x] Document that upgrade performs a load-time smoke check, not comprehensive
  behavioral certification.
- [x] Document registry-dependent preparation versus the offline smoke check.
- [x] Document uncommitted-attempt recovery and committed Git-revert recovery, with
  no live rollback or separate uninstall step.
- [x] Make uncommitted recovery restore both the index and worktree from `HEAD`, and
  require a clean worktree before committed `git revert` recovery.
- [x] Explain that Pi upgrades do not normally change the local dependency lockfile.
- [x] Keep all script-level and function documentation aligned with actual behavior.

- [x] **Group 7 complete:** an operator can choose the correct workflow without
  understanding the scripts' implementation.

### Group 8 — Verification and handoff

- [x] Run Bash syntax, ShellCheck, JSON validation, contract validation, pre-commit,
  and whitespace checks.
- [x] Verify bootstrap installs missing Pi, replaces a mismatched Pi, and is a no-op
  for the correct version.
- [x] Verify bootstrap and upgrade refuse an active Pi executable that is not managed
  by the expected global npm installation.
- [x] Verify routine update applies a changed repository pin in a disposable clone or
  otherwise controlled Git setup.
- [x] Verify explicit-version and `latest` upgrade paths.
- [x] Verify `latest` rejects a prerelease result while an explicit prerelease remains
  opt-in.
- [x] Verify an incompatible candidate Node engine fails before Pi installation or
  metadata mutation, and a raised candidate minimum requires a separate Node-contract
  update.
- [x] Verify failed candidate installation exits non-zero and prints targeted recovery
  instructions without changing tracked metadata or Git history.
- [x] Verify failed pinned-package reconciliation exits non-zero while leaving the
  candidate proposal available for diagnosis.
- [ ] Verify failed harness loading exits non-zero while leaving the candidate and
  proposed metadata available for diagnosis.
- [ ] Verify a successful upgrade leaves only the expected reviewable metadata and
  documentation diff.
- [ ] In a controlled checkout, verify targeted restoration of an uncommitted attempt
  followed by bootstrap reinstalls the committed Pi version.
- [ ] In a disposable repository, verify reverting a committed upgrade followed by
  bootstrap reinstalls the previous Pi version and configuration.
- [ ] Verify no Pi-only upgrade changes `package-lock.json`.
- [ ] Verify bootstrap and routine update reconcile pinned external packages without
  moving their declarations.
- [ ] Verify no command commits, pushes, stashes, intentionally reads or prints
  provider credentials, or invokes a model.
- [ ] Re-run doctor twice and confirm the successful state is idempotent.
- [ ] Record any environment-limited checks rather than weakening their acceptance
  criteria.

- [ ] **Group 8 complete:** fresh install, routine synchronisation, successful
  upgrade, failed upgrade, and explicit recovery paths behave as documented.

The first nine checks passed on 2026-09-25. Full pinned pre-commit, Bash/Node
syntax, contract, and whitespace checks passed in this checkout. Disposable
local Git clones with fake npm and Pi executables exercised installation,
ownership, update, candidate selection, Node-engine gates, and failure states;
these do not replace a real registry-backed Pi upgrade check.

## 7. Acceptance criteria

- [ ] A fresh supported machine installs the exact repository-declared Pi version by
  running bootstrap.
- [ ] Every machine running routine update converges to the same Pi and locked local
  dependency versions.
- [ ] The active Pi executable on every supported machine is managed through the
  expected global npm installation; shadowed or alternative installations fail
  clearly.
- [ ] A maintainer can request an explicit version or the current stable `latest` and
  receive a concrete, reviewable version bump.
- [ ] A candidate that cannot load the full harness is rejected with its failure state
  available for diagnosis.
- [ ] Successful upgrades leave version changes for human review and do not commit or
  push automatically.
- [ ] Failed upgrades do not commit, revert, restore, or stash automatically; they do
  not modify the index or rewrite Git history.
- [ ] Candidate Node incompatibility is detected before mutation, and a higher Node
  minimum is never applied implicitly.
- [ ] Pi-only upgrades do not rewrite local dependency lockfiles.
- [ ] Bootstrap and routine update converge pinned external Pi packages as well as Pi
  and local npm dependencies.
- [ ] The workflow runs no arbitrary third-party test suites and requires no broad new
  unit-test effort.
- [ ] Targeted restoration plus bootstrap abandons an uncommitted proposal, while
  `git revert` plus bootstrap reverses a committed Pi upgrade.
- [ ] The workflow does not intentionally read or print provider credentials and does
  not invoke a model.
- [ ] Existing credential, session, trust, cache, and runtime-state protections remain
  intact.

## 8. Implementation principle

Prefer the smallest scripts that implement the workflows above. The value is in
making a pinned upgrade controlled and repeatable, not in constructing a
general release-management, live-rollback, or compatibility-testing platform.
