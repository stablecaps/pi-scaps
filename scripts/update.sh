#!/usr/bin/env bash

# Update a clean pi-scaps checkout to the latest fast-forward revision.
#
# Usage:
#   ./scripts/update.sh
#
# The script locates the repository relative to its own path, refuses to proceed
# when any tracked or untracked non-ignored change is present, pulls with
# `git pull --ff-only`, runs bootstrap to install the pulled Pi pin and locked
# dependencies and reconcile pinned packages, then runs the harness doctor.
# It never stashes local work, creates a merge commit, selects a new Pi version,
# or invokes an unbounded `pi update`.
#
# The command requires git, Node, and npm on PATH. Pull, dependency, or diagnostic
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
./scripts/bootstrap.sh
PI_CODING_AGENT_DIR="$repo_root" ./scripts/doctor.sh

printf 'pi-scaps harness update complete.\n'
