#!/usr/bin/env bash

# Diagnose whether this machine can run this checkout as the active Pi harness.
#
# Usage:
#   ./scripts/doctor.sh
#   PI_CODING_AGENT_DIR="$PWD" ./scripts/doctor.sh
#
# The doctor focuses on runtime health: activation, required commands, Node/Pi
# version compatibility, dependency installation, safe writable session storage,
# and offline Pi startup with the configured harness. Repository hygiene such as
# file inventory, JSON syntax, forbidden tracked state, and static script checks
# belongs in pre-commit/CI rather than this runtime diagnostic.

set -euo pipefail

failures=0

# Report a successful required check.
pass() {
  printf '[PASS] %s\n' "$*"
}

# Report a non-fatal condition that deserves attention.
warn() {
  printf '[WARN] %s\n' "$*"
}

# Report contextual or remediation information.
info() {
  printf '[INFO] %s\n' "$*"
}

# Report a failed required check and increment the aggregate failure count.
fail() {
  printf '[FAIL] %s\n' "$*" >&2
  failures=$((failures + 1))
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

# Resolve a possibly nonexistent path to a physical absolute path.
canonicalize_path() {
  local candidate="$1"
  local suffix=""
  local leaf parent resolved

  if [[ "$candidate" != /* ]]; then
    candidate="$PWD/$candidate"
  fi
  if [[ "$candidate" != "/" ]]; then
    candidate="${candidate%/}"
  fi

  while [[ ! -e "$candidate" ]]; do
    leaf="${candidate##*/}"
    suffix="/$leaf$suffix"
    parent="${candidate%/*}"
    [[ -n "$parent" ]] || parent="/"
    [[ "$parent" != "$candidate" ]] || return 1
    candidate="$parent"
  done

  if [[ -d "$candidate" ]]; then
    resolved="$(cd -- "$candidate" && pwd -P)"
  else
    parent="$(cd -- "$(dirname -- "$candidate")" && pwd -P)"
    resolved="$parent/$(basename -- "$candidate")"
  fi

  if [[ "$resolved" == "/" ]]; then
    printf '/%s\n' "${suffix#/}"
  else
    printf '%s%s\n' "$resolved" "$suffix"
  fi
}

# Expand a configured session path without requiring it to exist.
resolve_session_path() {
  local configured_path="$1"
  local invocation_dir="$2"

  if [[ "$configured_path" == "~" ]]; then
    [[ -n "${HOME-}" ]] || return 1
    printf '%s\n' "$HOME"
  elif [[ "$configured_path" == \~/* ]]; then
    [[ -n "${HOME-}" ]] || return 1
    printf '%s/%s\n' "$HOME" "${configured_path:2}"
  elif [[ "$configured_path" == /* ]]; then
    printf '%s\n' "$configured_path"
  else
    printf '%s/%s\n' "$invocation_dir" "$configured_path"
  fi
}

printf 'pi-scaps doctor\n\n'

invocation_dir="$(pwd -P)"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
canonical_repo_root="$(canonicalize_path "$repo_root")"

if command -v git >/dev/null 2>&1 && git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ -n "$(git -C "$repo_root" status --porcelain)" ]]; then
    warn "Git working tree has uncommitted changes"
  else
    info "Git working tree is clean"
  fi
else
  info "Git checkout status unavailable; skipping worktree warning"
fi

node_available=false
if command -v node >/dev/null 2>&1; then
  node_available=true
  pass "node is available"
else
  fail "required command not found: node"
fi

npm_available=false
if command -v npm >/dev/null 2>&1; then
  npm_available=true
  pass "npm is available"
else
  fail "required command not found: npm"
fi

metadata_valid=false
node_requirement=""
pi_package=""
expected_pi_version=""
configured_session_dir=""
if [[ "$node_available" == true ]]; then
  metadata=""
  if metadata="$({
    PI_SCAPS_PACKAGE_JSON="$repo_root/package.json" \
    PI_SCAPS_SETTINGS_JSON="$repo_root/settings.json" \
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
          throw new Error("required runtime metadata is missing or invalid");
        }
        process.stdout.write(values.join("\n"));
      } catch {
        process.exit(1);
      }
    '
  })"; then
    mapfile -t harness_metadata <<< "$metadata"
    if ((${#harness_metadata[@]} == 4)); then
      node_requirement="${harness_metadata[0]}"
      pi_package="${harness_metadata[1]}"
      expected_pi_version="${harness_metadata[2]}"
      configured_session_dir="${harness_metadata[3]}"
      metadata_valid=true
      pass "runtime metadata is readable"
    else
      fail "runtime metadata returned an unexpected number of values"
    fi
  else
    fail "runtime metadata could not be read from package.json and settings.json"
  fi
fi

active_agent_dir=""
canonical_active_agent_dir=""
activation_valid=false
if [[ -n "${PI_CODING_AGENT_DIR+x}" ]]; then
  if [[ -n "$PI_CODING_AGENT_DIR" ]]; then
    active_agent_dir="$PI_CODING_AGENT_DIR"
    info "using PI_CODING_AGENT_DIR for activation"
  else
    fail "PI_CODING_AGENT_DIR is set but empty"
  fi
elif [[ -n "${HOME-}" ]]; then
  active_agent_dir="$HOME/.pi/agent"
  info "using the default Pi agent directory"
else
  fail "HOME is unset, so the default Pi agent directory cannot be resolved"
fi

if [[ -n "$active_agent_dir" ]]; then
  if canonical_active_agent_dir="$(canonicalize_path "$active_agent_dir")"; then
    if [[ "$canonical_repo_root" == "$canonical_active_agent_dir" ]]; then
      activation_valid=true
      pass "checkout is the active Pi agent directory"
    else
      fail "checkout is not the active Pi agent directory"
      info "Clone to the default location: git clone https://github.com/stablecaps/pi-scaps.git ~/.pi/agent"
      info "Or activate this checkout: export PI_CODING_AGENT_DIR=\"$repo_root\""
    fi
  else
    fail "could not resolve the active Pi agent directory"
  fi
fi

if [[ "$metadata_valid" == true ]]; then
  if [[ "$node_requirement" == '>='* ]]; then
    required_node_version="${node_requirement#>=}"
    actual_node_version="$(node --version)"
    actual_node_version="${actual_node_version#v}"
    if version_at_least "$actual_node_version" "$required_node_version"; then
      pass "Node $actual_node_version satisfies $node_requirement"
    else
      fail "Node version mismatch: expected $node_requirement, found $actual_node_version"
    fi
  else
    fail "unsupported Node requirement format: $node_requirement"
  fi

  pi_contract_valid=false
  if command -v pi >/dev/null 2>&1; then
    if pi_version_output="$(pi --version 2>&1)"; then
      if [[ "$pi_version_output" =~ ^[[:space:]]*(pi[[:space:]]+)?v?([0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?)[[:space:]]*$ ]]; then
        actual_pi_version="${BASH_REMATCH[2]}"
        if [[ "$actual_pi_version" == "$expected_pi_version" ]]; then
          pi_contract_valid=true
          pass "Pi $actual_pi_version matches $pi_package@$expected_pi_version"
        else
          fail "Pi version mismatch: expected $expected_pi_version, found $actual_pi_version"
          info "Run ./scripts/bootstrap.sh to install the declared Pi version"
        fi
      else
        fail "could not parse Pi version output"
        info "Run ./scripts/bootstrap.sh to install the declared Pi version"
      fi
    else
      fail "could not run pi --version"
      info "Run ./scripts/bootstrap.sh to install the declared Pi version"
    fi
  else
    fail "required command not found: pi"
    info "Run ./scripts/bootstrap.sh to install the declared Pi version"
  fi

  configured_session_path=""
  if configured_session_path="$(resolve_session_path "$configured_session_dir" "$invocation_dir")"; then
    canonical_configured_session_path="$(canonicalize_path "$configured_session_path")"
    if [[ "$canonical_configured_session_path" == "$canonical_repo_root" ||
      "$canonical_configured_session_path" == "$canonical_repo_root/"* ]]; then
      fail "configured session directory resolves inside the Git checkout"
    else
      pass "configured session directory resolves outside the checkout"
    fi
  else
    fail "configured session directory could not be resolved"
  fi

  effective_session_setting="$configured_session_dir"
  if [[ -n "${PI_CODING_AGENT_SESSION_DIR+x}" ]]; then
    info "PI_CODING_AGENT_SESSION_DIR overrides settings.json sessionDir"
    effective_session_setting="$PI_CODING_AGENT_SESSION_DIR"
  fi

  if [[ -z "$effective_session_setting" ]]; then
    fail "effective session directory is empty"
  elif effective_session_path="$(resolve_session_path "$effective_session_setting" "$invocation_dir")"; then
    canonical_effective_session_path="$(canonicalize_path "$effective_session_path")"
    if [[ "$canonical_effective_session_path" == "$canonical_repo_root" ||
      "$canonical_effective_session_path" == "$canonical_repo_root/"* ]]; then
      fail "effective session directory resolves inside the Git checkout"
    elif [[ ! -d "$effective_session_path" ]]; then
      fail "effective session directory does not exist: $effective_session_path"
    elif [[ ! -w "$effective_session_path" ]]; then
      fail "effective session directory is not writable: $effective_session_path"
    else
      pass "effective session directory exists, is writable, and is outside the checkout"
    fi
  else
    fail "effective session directory could not be resolved"
  fi

  if [[ "$npm_available" == true ]]; then
    if (
      cd -- "$repo_root" &&
        npm_config_update_notifier=false \
          npm_config_audit=false \
          npm_config_fund=false \
          npm ls --depth=0 >/dev/null 2>&1
    ); then
      pass "npm dependency tree is valid"
    else
      fail "npm dependency tree is invalid; run npm ci from the repository root"
    fi
  fi

  if [[ "$pi_contract_valid" == true && "$activation_valid" == true ]]; then
    if PI_CODING_AGENT_DIR="$canonical_active_agent_dir" PI_OFFLINE=1 pi --list-models >/dev/null 2>&1; then
      pass "Pi configuration starts in offline diagnostic mode"
    else
      fail "Pi configuration failed to start in offline diagnostic mode"
    fi
  else
    fail "Pi offline startup diagnostic requires an active checkout and the declared Pi version"
  fi
fi

auth_agent_dir="$canonical_active_agent_dir"
if [[ -z "$auth_agent_dir" ]]; then
  auth_agent_dir="$active_agent_dir"
fi
if [[ -n "$auth_agent_dir" && -f "$auth_agent_dir/auth.json" ]]; then
  info "Stored Pi authentication file is present"
else
  info "No stored auth.json detected; use /login or a supported environment credential"
fi

if ((failures > 0)); then
  printf '\n[FAIL] doctor found %d runtime check(s) that need attention.\n' "$failures" >&2
  exit 1
fi

printf '\nHarness runtime looks healthy.\n'
