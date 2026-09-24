#!/usr/bin/env bash

# Propose one deliberate Pi version upgrade, leaving an uncommitted reviewable diff.
# Usage: ./scripts/upgrade-pi.sh <exact-version|latest>
# Requires a clean, healthy checkout and npm-managed Pi. Registry preparation may
# use the network; the final Pi load and doctor checks run offline without a model.
# Failures never alter Git history or roll back state automatically.

# Node snippets intentionally use literal single quotes.
# shellcheck disable=SC2016
set -euo pipefail

upgrade_stage=preflight

# Report failure with recovery appropriate to the point already reached.
fail() {
  printf 'ERROR: %s\n' "$*" >&2
  if [[ "$upgrade_stage" == installing ]]; then
    printf 'The global Pi installation may have changed. Run ./scripts/bootstrap.sh to reconverge it.\n' >&2
  elif [[ "$upgrade_stage" == metadata ]]; then
    printf 'To abandon this uncommitted proposal, first review the diff, then run:\n' >&2
    printf '  git restore --source=HEAD --staged --worktree -- package.json settings.json\n' >&2
    printf '  ./scripts/bootstrap.sh\n  ./scripts/doctor.sh\n' >&2
  fi
  exit 1
}

# Parse one JSON string from npm's --json output.
json_string() {
  node -e '
    const fs = require("node:fs");
    const value = JSON.parse(fs.readFileSync(0, "utf8"));
    if (typeof value !== "string" || value.length === 0) process.exit(1);
    process.stdout.write(value);
  '
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
# shellcheck source=scripts/pi-npm-common.sh
source "$script_dir/pi-npm-common.sh"

[[ $# == 1 ]] || fail "Usage: ./scripts/upgrade-pi.sh <exact-version|latest>"
for required_command in git node npm readlink; do
  command -v "$required_command" >/dev/null 2>&1 || fail "Required command not found: $required_command"
done
git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Not a Git working tree"
[[ -z "$(git -C "$repo_root" status --porcelain --untracked-files=all)" ]] ||
  fail "Working tree must be clean before proposing a Pi upgrade"

cd -- "$repo_root"
node scripts/validate-contract.mjs || fail "Harness contract is invalid"
mapfile -t contract < <(node -e '
  const manifest = require("./package.json");
  process.stdout.write([manifest.piHarness.package, manifest.piHarness.version, manifest.engines.node].join("\n"));
')
[[ ${#contract[@]} == 3 ]] || fail "Could not read the Pi and Node contract"
pi_package="${contract[0]}"
previous_version="${contract[1]}"
node_requirement="${contract[2]}"

command -v pi >/dev/null 2>&1 || fail "Pi is missing; run ./scripts/bootstrap.sh first"
check_pi_ownership "$pi_package"
installed_version="$(read_pi_version)"
[[ "$installed_version" == "$previous_version" ]] ||
  fail "Installed Pi $installed_version differs from the declared $previous_version; run bootstrap first"
PI_CODING_AGENT_DIR="$repo_root" ./scripts/doctor.sh || fail "Current harness is not healthy"

target="$1"
if [[ "$target" == latest ]]; then
  latest_json="$(npm view "$pi_package" dist-tags.latest --json)" || fail "Could not resolve npm latest tag"
  candidate="$(printf '%s' "$latest_json" | json_string)" || fail "npm latest tag was not one version string"
else
  candidate="$target"
fi
[[ "$candidate" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]] ||
  fail "Candidate must be an exact semantic version"
if [[ "$target" == latest && "$candidate" =~ ^[0-9]+\.[0-9]+\.[0-9]+- ]]; then
  fail "npm latest resolved to a prerelease; request that version explicitly if intended"
fi
printf 'Pi candidate: %s -> %s\n' "$previous_version" "$candidate"
if [[ "$candidate" == "$previous_version" ]]; then
  printf 'Pi is already at the declared version; doctor passed. No changes made.\n'
  exit 0
fi

engine_json="$(npm view "${pi_package}@${candidate}" engines.node --json)" ||
  fail "Could not read candidate Node engine requirement"
engine_requirement="$(printf '%s' "$engine_json" | json_string)" ||
  fail "Candidate Node engine requirement is missing or invalid"
[[ "$engine_requirement" =~ ^\>=([0-9]+\.[0-9]+\.[0-9]+)$ ]] ||
  fail "Unsupported candidate Node engine range: $engine_requirement"
candidate_minimum="${BASH_REMATCH[1]}"
[[ "$node_requirement" =~ ^\>=([0-9]+\.[0-9]+\.[0-9]+)$ ]] ||
  fail "Unsupported repository Node requirement: $node_requirement"
repo_minimum="${BASH_REMATCH[1]}"
actual_node="$(node --version)"
actual_node="${actual_node#v}"
if ! version_at_least "$actual_node" "$candidate_minimum"; then
  fail "Node $actual_node does not satisfy candidate requirement $engine_requirement"
fi
if ! version_at_least "$repo_minimum" "$candidate_minimum"; then
  fail "Candidate needs $engine_requirement, above repository minimum $node_requirement; update the Node contract deliberately first"
fi

upgrade_stage=installing
printf 'Installing exact candidate %s@%s through npm.\n' "$pi_package" "$candidate"
npm install -g --ignore-scripts "${pi_package}@${candidate}" || fail "Candidate installation failed"
hash -r
command -v pi >/dev/null 2>&1 || fail "Installed Pi is not on PATH"
check_pi_ownership "$pi_package"
verified_version="$(read_pi_version)"
[[ "$verified_version" == "$candidate" ]] ||
  fail "Active Pi version $verified_version does not match candidate $candidate"

upgrade_stage=metadata
node scripts/set-pi-version.mjs "$previous_version" "$candidate" || fail "Could not update Pi metadata"
node scripts/validate-contract.mjs || fail "Candidate metadata fails the contract"
npm ci || fail "Locked local dependency installation failed"
git diff --quiet -- package-lock.json || fail "Pi-only upgrade unexpectedly changed package-lock.json"
packages_before="$(node -e 'process.stdout.write(JSON.stringify(require("./settings.json").packages ?? []))')"
package_count="$(node -e 'process.stdout.write(String(require("./settings.json").packages?.length ?? 0))')"
if ((package_count > 0)); then
  PI_CODING_AGENT_DIR="$repo_root" pi update --extensions || fail "Pinned Pi package reconciliation failed"
  packages_after="$(node -e 'process.stdout.write(JSON.stringify(require("./settings.json").packages ?? []))')"
  [[ "$packages_after" == "$packages_before" ]] || fail "Pi package pins changed during reconciliation"
  node scripts/validate-contract.mjs || fail "Reconciliation changed the contract"
fi
PI_CODING_AGENT_DIR="$repo_root" PI_OFFLINE=1 pi --help >/dev/null || fail "Candidate harness failed offline load check"
PI_CODING_AGENT_DIR="$repo_root" ./scripts/doctor.sh || fail "Candidate failed doctor"

changed_files="$(git diff --name-only)"
printf '\nPi upgrade proposal verified: %s -> %s\n' "$previous_version" "$candidate"
printf 'Changed files:\n%s\n' "$changed_files"
printf 'Offline load and doctor checks passed. Review the unstaged diff, then commit deliberately.\n'
printf 'To abandon: git restore --source=HEAD --staged --worktree -- package.json settings.json; ./scripts/bootstrap.sh; ./scripts/doctor.sh\n'
