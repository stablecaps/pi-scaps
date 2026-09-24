#!/usr/bin/env bash

# Prepare a pi-scaps checkout for use as Pi's global agent directory.
#
# Usage:
#   ./scripts/bootstrap.sh
#
# The script locates the repository relative to its own path, reads the Node and
# Pi version contract from package.json, and reads the external session location
# from settings.json. It verifies that the installed Node and Pi versions satisfy
# that contract, installs the repository's locked npm dependencies with `npm ci`,
# and creates the configured session directory when needed.
#
# HOME is used to expand a sessionDir beginning with `~/`. The script is
# intentionally safe to repeat: it does not install or upgrade Node or Pi, write
# credentials, edit shell configuration, or modify the declared version pins.
# Any failed prerequisite, malformed metadata, version mismatch, dependency
# installation error, or filesystem error produces a non-zero exit status.

# JavaScript passed to node -e intentionally uses literal single quotes.
# shellcheck disable=SC2016
set -euo pipefail

# Print an error message and terminate with a failing status.
fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

# Require an executable command to be discoverable through PATH.
require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "Required command not found: $command_name"
  fi
}

# Return success when one strict semantic version is at least another.
version_at_least() {
  local actual="$1"
  local required="$2"
  local actual_major actual_minor actual_patch
  local required_major required_minor required_patch

  if [[ ! "$actual" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 2
  fi
  if [[ ! "$required" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 2
  fi

  IFS=. read -r actual_major actual_minor actual_patch <<< "$actual"
  IFS=. read -r required_major required_minor required_patch <<< "$required"

  if ((10#$actual_major != 10#$required_major)); then
    ((10#$actual_major > 10#$required_major))
    return
  fi
  if ((10#$actual_minor != 10#$required_minor)); then
    ((10#$actual_minor > 10#$required_minor))
    return
  fi
  ((10#$actual_patch >= 10#$required_patch))
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
package_json="$repo_root/package.json"
settings_json="$repo_root/settings.json"

require_command node
require_command npm

[[ -f "$package_json" ]] || fail "Missing package.json at $package_json"
[[ -f "$settings_json" ]] || fail "Missing settings.json at $settings_json"

metadata=""
if ! metadata="$({
  PI_SCAPS_PACKAGE_JSON="$package_json" \
  PI_SCAPS_SETTINGS_JSON="$settings_json" \
  node -e '
    const fs = require("node:fs");

    try {
      const manifest = JSON.parse(fs.readFileSync(process.env.PI_SCAPS_PACKAGE_JSON, "utf8"));
      const settings = JSON.parse(fs.readFileSync(process.env.PI_SCAPS_SETTINGS_JSON, "utf8"));
      const values = [
        manifest.engines?.node,
        manifest.piHarness?.package,
        manifest.piHarness?.version,
        settings.sessionDir,
      ];

      if (values.some((value) => typeof value !== "string" || value.length === 0)) {
        throw new Error("required harness metadata is missing or invalid");
      }
      process.stdout.write(values.join("\n"));
    } catch (error) {
      console.error(`Failed to read harness metadata: ${error.message}`);
      process.exit(1);
    }
  '
})"; then
  fail "Unable to read package.json and settings.json"
fi

mapfile -t harness_metadata <<< "$metadata"
if ((${#harness_metadata[@]} != 4)); then
  fail "Harness metadata returned an unexpected number of values"
fi

node_requirement="${harness_metadata[0]}"
pi_package="${harness_metadata[1]}"
expected_pi_version="${harness_metadata[2]}"
configured_session_dir="${harness_metadata[3]}"

if [[ "$node_requirement" != '>='* ]]; then
  fail "Unsupported Node requirement format in package.json: $node_requirement"
fi
required_node_version="${node_requirement#>=}"
actual_node_version="$(node --version)"
actual_node_version="${actual_node_version#v}"

if ! version_at_least "$actual_node_version" "$required_node_version"; then
  fail "Node $actual_node_version does not satisfy $node_requirement. Install a supported Node release."
fi

npm_version="$(npm --version)"
pi_install_command="npm install -g --ignore-scripts ${pi_package}@${expected_pi_version}"

if ! command -v pi >/dev/null 2>&1; then
  printf 'ERROR: Required command not found: pi\n' >&2
  printf 'Install the declared Pi version with:\n  %s\n' "$pi_install_command" >&2
  exit 1
fi

if ! pi_version_output="$(pi --version 2>&1)"; then
  fail "Unable to read the installed Pi version"
fi

if [[ "$pi_version_output" =~ ^[[:space:]]*(pi[[:space:]]+)?v?([0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?)[[:space:]]*$ ]]; then
  actual_pi_version="${BASH_REMATCH[2]}"
else
  fail "Could not parse Pi version output: $pi_version_output"
fi

if [[ "$actual_pi_version" != "$expected_pi_version" ]]; then
  printf 'ERROR: Pi version mismatch (expected %s, found %s).\n' "$expected_pi_version" "$actual_pi_version" >&2
  printf 'Install the declared Pi version with:\n  %s\n' "$pi_install_command" >&2
  exit 1
fi

printf 'Node: %s\n' "$actual_node_version"
printf 'npm: %s\n' "$npm_version"
printf 'Pi: %s\n' "$actual_pi_version"

cd -- "$repo_root"
if [[ -f package-lock.json ]]; then
  npm ci
else
  printf 'INFO: package-lock.json not found; skipping npm ci.\n' >&2
fi

if [[ "$configured_session_dir" == \~/* ]]; then
  session_dir="$HOME/${configured_session_dir:2}"
elif [[ "$configured_session_dir" == /* ]]; then
  session_dir="$configured_session_dir"
else
  fail "settings.json sessionDir must be absolute or start with ~/: $configured_session_dir"
fi
mkdir -p -- "$session_dir"

printf '\npi-scaps bootstrap complete.\n\n'
printf 'Next:\n'
printf '  1. Run ./scripts/doctor.sh\n'
printf '  2. Start Pi with: pi\n'
printf '  3. Authenticate with /login if required\n'
