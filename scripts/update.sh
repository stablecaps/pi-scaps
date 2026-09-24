#!/usr/bin/env bash

# Update a clean pi-scaps checkout to the latest fast-forward revision.
#
# Usage:
#   ./scripts/update.sh
#
# The script locates the repository relative to its own path, refuses to proceed
# when any tracked or untracked non-ignored change is present, pulls with
# `git pull --ff-only`, reinstalls exactly the dependencies in package-lock.json
# with `npm ci`, and runs the harness doctor. It updates only this Git-managed
# harness: it never stashes local work, creates a merge commit, invokes
# `pi update`, or silently changes the declared Pi version.
#
# The command requires git and npm on PATH. Pull, dependency, or diagnostic
# failures stop execution immediately and produce a non-zero exit status. A
# successful run may replace node_modules according to the lockfile and prints a
# single completion message after doctor succeeds.

set -euo pipefail

# Print an error message and terminate with a failing status.
fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"

command -v git >/dev/null 2>&1 || fail "Required command not found: git"
command -v npm >/dev/null 2>&1 || fail "Required command not found: npm"

if ! git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "Not a Git working tree: $repo_root"
fi

if [[ -n "$(git -C "$repo_root" status --porcelain --untracked-files=all)" ]]; then
  fail "Working tree is not clean. Commit, remove, or intentionally ignore local changes before updating."
fi

cd -- "$repo_root"
git pull --ff-only
npm ci
./scripts/doctor.sh

printf 'pi-scaps harness update complete.\n'
