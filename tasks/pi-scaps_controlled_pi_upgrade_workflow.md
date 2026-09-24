# PRD: controlled Pi installation and upgrade workflow

Status: proposed

Date: 2026-09-24

## 1. Summary

Keep Pi and harness dependencies pinned so every machine runs the same declared
versions, while making initial installation, routine synchronisation, deliberate
Pi upgrades, compatibility smoke checking, and rollback straightforward.

The repository remains the source of truth. A normal machine update must converge
the machine to the versions already committed in Git. A separate maintainer
workflow advances the Pi pin only after the candidate can load the complete
harness.

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
- Restore the previous global Pi version and tracked metadata after a failed
  upgrade attempt.
- Keep local extension dependencies reproducible through `package-lock.json`.
- Avoid creating a bespoke extension-testing framework or requiring speculative
  unit tests.

## 3. Non-goals

- Automatically installing or upgrading Node.
- Running an unpinned Pi release in normal bootstrap or update flows.
- Proving every extension feature semantically correct after an upgrade.
- Writing unit tests merely to satisfy this workflow.
- Running arbitrary test commands found inside third-party packages.
- Updating every extension dependency whenever Pi changes.
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
  -> run doctor
```

Routine update applies a version decision already reviewed and committed on
another machine. It does not discover or select a newer Pi release.

### 5.3 Deliberate Pi upgrade

```text
run upgrade-pi with an explicit version or "latest"
  -> resolve one exact candidate
  -> install and smoke-check it
  -> update tracked version metadata
  -> leave a reviewable, uncommitted diff
commit after review
```

## 6. Task groups

### Group 0 — Preflight and design confirmation

- Inspect and preserve all pre-existing worktree changes.
- Confirm the maintained Pi npm package name and current version-output format.
- Confirm the npm query used to resolve `latest` and how prereleases are excluded.
- Confirm the minimum supported Node contract remains independent of Pi upgrades.
- Record the existing bootstrap, update, doctor, contract-validator, pre-commit,
  and README behavior that this work changes.
- Treat this PRD as the authority for Pi installation and upgrade semantics while
  leaving unrelated skeleton requirements intact.

Completion condition: the implementation scope and conflicts with earlier PRDs
are explicit before scripts are changed.

### Group 1 — Normalise the version contract

- Retain one authoritative Pi package/version pair in `package.json`.
- Remove unnecessary human-maintained copies of the literal version from normal
  installation instructions.
- Keep required derived metadata, including `lastChangelogVersion`, synchronised
  through tooling.
- Update the existing contract validator and pre-commit checks to enforce only
  intentional cross-file relationships.
- Preserve exact version validation in doctor.

Completion condition: a Pi version bump has one source value and only necessary
derived values.

### Group 2 — Make bootstrap converge Pi

- Change bootstrap from “validate and print a remediation command” to “ensure the
  exact declared Pi version is installed.”
- If Pi is absent or mismatched, install
  `package.json.piHarness.package@package.json.piHarness.version` globally through
  npm with the repository's chosen lifecycle-script policy.
- Skip global installation when the correct Pi version is already present.
- Never invoke `sudo`, edit npm configuration, or change shell profiles.
- Give a clear remediation when the user's npm global prefix is not writable.
- Continue running `npm ci`, creating external state directories, and providing
  concise next steps.
- Remain safe and idempotent when run repeatedly.

Completion condition: a supported fresh machine with Node/npm can clone the
repository and obtain the exact declared Pi version by running bootstrap.

### Group 3 — Make routine update reconverge the machine

- Preserve the clean-worktree requirement and `git pull --ff-only` behavior.
- After pulling, ensure the exact Pi version now declared by the repository is
  installed automatically.
- Restore local extension dependencies with `npm ci`.
- Run doctor only after Pi and local dependencies match the pulled revision.
- Do not run an unbounded `pi update`, select `latest`, or update external package
  pins during routine synchronisation.
- Reuse bootstrap or a small shared mechanism where that is simpler than
  duplicating version-install logic; do not introduce a framework for reuse.

Completion condition: after a reviewed Pi bump is merged, `scripts/update.sh` on
another machine converges to it without a manual npm command.

### Group 4 — Add the maintainer Pi-upgrade command

- Add one documented command, provisionally `scripts/upgrade-pi.sh`, accepting an
  explicit stable version or the literal target `latest`.
- Require a clean Git worktree before changing the global Pi installation or
  tracked metadata.
- Resolve `latest` once to an exact stable version and display the resolved value.
- Treat an explicit prerelease as opt-in; never choose one through `latest`.
- Record the previous declared and installed versions before mutation.
- Install the exact candidate through npm without using `sudo`.
- Update the authoritative Pi pin and required derived metadata without unrelated
  JSON reformatting.
- Run the compatibility smoke checks in Group 5.
- On failure, restore the previous global Pi version and original tracked files.
- On success, leave changes unstaged and uncommitted, and print a concise summary
  of the old version, new version, changed files, verification result, and next
  review steps.
- Treat an already-declared target as a successful no-op after verifying health.

Completion condition: one command can propose a reviewable Pi bump, while a
failed proposal returns the machine and worktree to their previous state.

### Group 5 — Add proportionate compatibility smoke checks

- Define the baseline guarantee honestly as “the complete harness loads under the
  candidate Pi version,” not “all extension behavior is proven compatible.”
- Run a non-interactive offline Pi invocation using this checkout as the active
  agent directory and without making a model request.
- Fail on configuration errors, extension import/factory failures, missing
  dependencies, registration conflicts, or other startup failures.
- Run existing root-level typecheck/check commands only when the repository has
  deliberately declared them as part of its own verification contract.
- Do not discover and execute arbitrary scripts from installed third-party
  packages.
- Do not require new unit tests for simple extensions. Add a focused semantic
  check later only when an important extension has behavior that a load check
  cannot cover and a demonstrated failure justifies it.
- Keep smoke-check output useful without printing credentials or sensitive
  configuration contents.

Completion condition: an upgrade cannot succeed when the candidate fails to load
the configured harness, without creating a general extension-test framework.

### Group 6 — Preserve dependency and lockfile semantics

- Verify that a Pi-only bump leaves `package-lock.json` unchanged.
- Keep `npm ci` as the normal local-dependency convergence command.
- If compatibility requires an extension dependency change, perform that change
  deliberately, regenerate the lockfile through npm, and include it in the same
  reviewed upgrade only when causally related.
- Keep unrelated dependency refreshes separate so failures remain attributable.
- Reconcile currently declared exact external Pi packages only through supported
  Pi package behavior; do not move their pins implicitly.

Completion condition: Pi, local npm dependencies, and external Pi packages each
retain a clear, reviewable source of truth.

### Group 7 — Align doctor and documentation

- Keep doctor strict about the installed Pi version matching the repository pin.
- Update doctor remediation to point to bootstrap/update rather than requiring a
  copied manual installation command as the normal path.
- Document the difference between bootstrap, routine update, and maintainer
  upgrade.
- Document that upgrade performs a load-time smoke check, not comprehensive
  behavioral certification.
- Document automatic failure rollback and successful Git-based rollback.
- Explain that Pi upgrades do not normally change the local dependency lockfile.
- Keep all script-level and function documentation aligned with actual behavior.

Completion condition: an operator can choose the correct workflow without
understanding the scripts' implementation.

### Group 8 — Verification and handoff

- Run Bash syntax, ShellCheck, JSON validation, contract validation, pre-commit,
  and whitespace checks.
- Verify bootstrap installs missing Pi, replaces a mismatched Pi, and is a no-op
  for the correct version.
- Verify routine update applies a changed repository pin in a disposable clone or
  otherwise controlled Git setup.
- Verify explicit-version and `latest` upgrade paths.
- Verify failed candidate installation and failed harness loading both restore the
  prior declared/installed Pi version and leave no tracked diff.
- Verify a successful upgrade leaves only the expected reviewable metadata and
  documentation diff.
- Verify no Pi-only upgrade changes `package-lock.json`.
- Verify no command commits, pushes, stashes, uses credentials, or invokes a
  model.
- Re-run doctor twice and confirm the successful state is idempotent.
- Record any environment-limited checks rather than weakening their acceptance
  criteria.

Completion condition: fresh install, routine synchronisation, successful upgrade,
failed upgrade, and rollback paths behave as documented.

## 7. Acceptance criteria

- A fresh supported machine installs the exact repository-declared Pi version by
  running bootstrap.
- Every machine running routine update converges to the same Pi and locked local
  dependency versions.
- A maintainer can request an explicit version or the current stable `latest` and
  receive a concrete, reviewable version bump.
- A candidate that cannot load the full harness is rejected and rolled back.
- Successful upgrades leave version changes for human review and do not commit or
  push automatically.
- Pi-only upgrades do not rewrite local dependency lockfiles.
- The workflow runs no arbitrary third-party test suites and requires no broad new
  unit-test effort.
- `git revert` of a committed Pi bump followed by routine update reinstalls the
  previous exact Pi version.
- Existing credential, session, trust, cache, and runtime-state protections remain
  intact.

## 8. Implementation principle

Prefer the smallest scripts that implement the workflows above. The value is in
making a pinned upgrade transactional and repeatable, not in constructing a
general release-management or compatibility-testing platform.
