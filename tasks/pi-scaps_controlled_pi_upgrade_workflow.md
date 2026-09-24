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
- Running an unpinned Pi release in normal bootstrap or update flows.
- Proving every extension feature semantically correct after an upgrade.
- Writing unit tests merely to satisfy this workflow.
- Running arbitrary test commands found inside third-party packages.
- Updating every extension dependency whenever Pi changes.
- Automatically restoring Pi or tracked files after an upgrade failure.
- Adding a dedicated rollback wrapper around Git and bootstrap.
- Automatically committing, pushing, stashing, or rewriting Git history.
- Using credentials, invoking a model, or depending on provider/network health
  during compatibility smoke checks.
- Building containers, virtual machines, or a second package-management system
  solely to test Pi upgrades.

## 4. Version and dependency policy

### 4.1 Pi

- `package.json.piHarness.package` and `.version` remain the authoritative Pi
  package and exact version.
- Bootstrap, update, doctor, and upgrade tooling must read this metadata rather
  than maintain separate script constants.
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
git restore package.json settings.json
./scripts/bootstrap.sh
./scripts/doctor.sh
```

To undo an upgrade that was already committed, revert its Git commit and
reconverge:

```text
git revert <pi-upgrade-commit>
./scripts/bootstrap.sh
./scripts/doctor.sh
```

Installing the exact reverted version replaces the current global Pi
installation; a separate uninstall step and rollback script are unnecessary.

## 6. Task groups

### Group 0 — Preflight and design confirmation

- [ ] Inspect and preserve all pre-existing worktree changes.
- [ ] Confirm the maintained Pi npm package name and current version-output format.
- [ ] Confirm the npm query used to resolve `latest` and how prereleases are excluded.
- [ ] Confirm the supported Pi command for reconciling pinned external packages.
- [ ] Confirm the minimum supported Node contract remains independent of Pi upgrades.
- [ ] Record the existing bootstrap, update, doctor, contract-validator, pre-commit,
  and README behavior that this work changes.
- [ ] Treat this PRD as the authority for Pi installation and upgrade semantics while
  leaving unrelated skeleton requirements intact.

- [ ] **Group 0 complete:** the implementation scope and conflicts with earlier
  PRDs are explicit before scripts are changed.

### Group 1 — Normalise the version contract

- [ ] Retain one authoritative Pi package/version pair in `package.json`.
- [ ] Remove unnecessary human-maintained copies of the literal version from normal
  installation instructions.
- [ ] Keep required derived metadata, including `lastChangelogVersion`, synchronised
  through tooling.
- [ ] Update the existing contract validator and pre-commit checks to enforce only
  intentional cross-file relationships.
- [ ] Preserve exact version validation in doctor.

- [ ] **Group 1 complete:** a Pi version bump has one source value and only
  necessary derived values.

### Group 2 — Make bootstrap converge Pi

- [ ] Change bootstrap from “validate and print a remediation command” to “ensure the
  exact declared Pi version is installed.”
- [ ] If Pi is absent or mismatched, install
  `package.json.piHarness.package@package.json.piHarness.version` globally through
  npm using `--ignore-scripts`.
- [ ] Skip global installation when the correct Pi version is already present.
- [ ] Never invoke `sudo`, edit npm configuration, or change shell profiles.
- [ ] Give a clear remediation when the user's npm global prefix is not writable.
- [ ] Continue running `npm ci`, creating external state directories, and providing
  concise next steps.
- [ ] Validate that every declared external Pi package is pinned, then reconcile the
  declared package set without moving any pin.
- [ ] Remain safe and idempotent when run repeatedly.

- [ ] **Group 2 complete:** a supported fresh machine with Node/npm can clone the
  repository and obtain the exact declared Pi version by running bootstrap.

### Group 3 — Make routine update reconverge the machine

- [ ] Preserve the clean-worktree requirement and `git pull --ff-only` behavior.
- [ ] After pulling, ensure the exact Pi version now declared by the repository is
  installed automatically.
- [ ] Restore local extension dependencies with `npm ci`.
- [ ] Reconcile all declared external Pi packages without changing their pins.
- [ ] Run doctor only after Pi and local dependencies match the pulled revision.
- [ ] Do not run an unbounded `pi update`, select `latest`, or update external package
  pins during routine synchronisation.
- [ ] Reuse bootstrap or a small shared mechanism where that is simpler than
  duplicating version-install logic; do not introduce a framework for reuse.

- [ ] **Group 3 complete:** after a reviewed Pi bump is merged,
  `scripts/update.sh` on another machine converges to it without a manual npm
  command.

### Group 4 — Add the maintainer Pi-upgrade command

- [ ] Add one documented command, provisionally `scripts/upgrade-pi.sh`, accepting an
  explicit stable version or the literal target `latest`.
- [ ] Require a clean Git worktree before changing the global Pi installation or
  tracked metadata.
- [ ] Require the installed Pi version to match the current repository pin and run
  doctor successfully before attempting an upgrade.
- [ ] Resolve the npm registry's `latest` dist-tag once to an exact version and
  display the resolved value before mutation.
- [ ] Treat an explicit prerelease as opt-in; never choose one through `latest`.
- [ ] Record the previous declared and installed versions before mutation.
- [ ] Install the exact candidate through npm with `--ignore-scripts` and without
  using `sudo`.
- [ ] Update the authoritative Pi pin and required derived metadata without unrelated
  JSON reformatting.
- [ ] Write changed metadata atomically so interruption cannot leave malformed JSON.
- [ ] Run `npm ci`, validate external package pins, and reconcile those packages
  before the offline smoke check.
- [ ] Run the compatibility smoke checks in Group 5.
- [ ] On installation or smoke-check failure, exit non-zero while leaving available
  candidate state and tracked changes visible for diagnosis.
- [ ] On failure, print the targeted uncommitted-recovery workflow without modifying
  Git or attempting live rollback.
- [ ] On success, leave changes unstaged and uncommitted, and print a concise summary
  of the old version, new version, changed files, verification result, and next
  review or recovery steps.
- [ ] Treat an already-declared target as a successful no-op after verifying health.

- [ ] **Group 4 complete:** one command can propose a reviewable Pi bump, and failed
  proposals remain inspectable with an explicit recovery path.

### Group 5 — Add proportionate compatibility smoke checks

- [ ] Define the baseline guarantee honestly as “the complete harness loads under the
  candidate Pi version,” not “all extension behavior is proven compatible.”
- [ ] Run a non-interactive offline Pi invocation using this checkout as the active
  agent directory and without making a model request.
- [ ] Keep registry access and pinned-package reconciliation in the preceding online
  phase; do not make provider or network health part of the smoke result.
- [ ] Fail on configuration errors, extension import/factory failures, missing
  dependencies, registration conflicts, or other startup failures.
- [ ] Run existing root-level typecheck/check commands only when the repository has
  deliberately declared them as part of its own verification contract.
- [ ] Do not discover and execute arbitrary scripts from installed third-party
  packages.
- [ ] Do not require new unit tests for simple extensions. Add a focused semantic
  check later only when an important extension has behavior that a load check
  cannot cover and a demonstrated failure justifies it.
- [ ] Keep smoke-check output useful without printing credentials or sensitive
  configuration contents.

- [ ] **Group 5 complete:** an upgrade cannot succeed when the candidate fails to
  load the configured harness, without creating a general extension-test
  framework.

### Group 6 — Preserve dependency and lockfile semantics

- [ ] Verify that a Pi-only bump leaves `package-lock.json` unchanged.
- [ ] Keep `npm ci` as the normal local-dependency convergence command.
- [ ] Extend the contract validation when external packages are introduced so every
  npm source has an exact version and every Git source has an immutable ref.
- [ ] If compatibility requires an extension dependency change, perform that change
  deliberately, regenerate the lockfile through npm, and include it in the same
  reviewed upgrade only when causally related.
- [ ] Keep unrelated dependency refreshes separate so failures remain attributable.
- [ ] Reconcile currently declared exact external Pi packages only through supported
  Pi package behavior; do not move their pins implicitly.

- [ ] **Group 6 complete:** Pi, local npm dependencies, and external Pi packages
  each retain a clear, reviewable source of truth.

### Group 7 — Align doctor and documentation

- [ ] Keep doctor strict about the installed Pi version matching the repository pin.
- [ ] Update doctor remediation to point to bootstrap/update rather than requiring a
  copied manual installation command as the normal path.
- [ ] Add `scripts/upgrade-pi.sh` to doctor's required-file and executable checks.
- [ ] Document the difference between bootstrap, routine update, and maintainer
  upgrade.
- [ ] Document that upgrade performs a load-time smoke check, not comprehensive
  behavioral certification.
- [ ] Document registry-dependent preparation versus the offline smoke check.
- [ ] Document uncommitted-attempt recovery and committed Git-revert recovery, with
  no live rollback or separate uninstall step.
- [ ] Explain that Pi upgrades do not normally change the local dependency lockfile.
- [ ] Keep all script-level and function documentation aligned with actual behavior.

- [ ] **Group 7 complete:** an operator can choose the correct workflow without
  understanding the scripts' implementation.

### Group 8 — Verification and handoff

- [ ] Run Bash syntax, ShellCheck, JSON validation, contract validation, pre-commit,
  and whitespace checks.
- [ ] Verify bootstrap installs missing Pi, replaces a mismatched Pi, and is a no-op
  for the correct version.
- [ ] Verify routine update applies a changed repository pin in a disposable clone or
  otherwise controlled Git setup.
- [ ] Verify explicit-version and `latest` upgrade paths.
- [ ] Verify failed candidate installation exits non-zero and prints targeted recovery
  instructions without changing Git history.
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
- [ ] Verify no command commits, pushes, stashes, uses credentials, or invokes a
  model.
- [ ] Re-run doctor twice and confirm the successful state is idempotent.
- [ ] Record any environment-limited checks rather than weakening their acceptance
  criteria.

- [ ] **Group 8 complete:** fresh install, routine synchronisation, successful
  upgrade, failed upgrade, and explicit recovery paths behave as documented.

## 7. Acceptance criteria

- [ ] A fresh supported machine installs the exact repository-declared Pi version by
  running bootstrap.
- [ ] Every machine running routine update converges to the same Pi and locked local
  dependency versions.
- [ ] A maintainer can request an explicit version or the current stable `latest` and
  receive a concrete, reviewable version bump.
- [ ] A candidate that cannot load the full harness is rejected with its failure state
  available for diagnosis.
- [ ] Successful upgrades leave version changes for human review and do not commit or
  push automatically.
- [ ] Failed upgrades do not commit, revert, restore, stash, or otherwise rewrite Git
  state automatically.
- [ ] Pi-only upgrades do not rewrite local dependency lockfiles.
- [ ] Bootstrap and routine update converge pinned external Pi packages as well as Pi
  and local npm dependencies.
- [ ] The workflow runs no arbitrary third-party test suites and requires no broad new
  unit-test effort.
- [ ] Targeted restoration plus bootstrap abandons an uncommitted proposal, while
  `git revert` plus bootstrap reverses a committed Pi upgrade.
- [ ] Existing credential, session, trust, cache, and runtime-state protections remain
  intact.

## 8. Implementation principle

Prefer the smallest scripts that implement the workflows above. The value is in
making a pinned upgrade controlled and repeatable, not in constructing a
general release-management, live-rollback, or compatibility-testing platform.
