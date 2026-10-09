#!/usr/bin/env bash

# Apply non-secret machine-local wiring for committed extension config files.
#
# Usage:
#   ./scripts/apply-local-config.sh
#   ./scripts/apply-local-config.sh --check
#   ./scripts/apply-local-config.sh --check --require-secrets
#   ./scripts/apply-local-config.sh --force
#
# The committed config files stay in this checkout. Firecrawl reads
# pi-firecrawl.json from Pi's active agent directory, so the active agent dir
# must be this repository. pi-web-kit 0.3.0 reads only
# ~/.pi/agent/pi-web-kit.json, so this script links that path back to the
# committed pi-web-kit.json when the checkout lives elsewhere.
#
# The script never writes API keys. Source EXA_API_KEY, CONTEXT7_API_KEY, and
# FIRECRAWL_API_KEY from a private local file before launching Pi.

set -euo pipefail

mode="apply"
force=false
require_secrets=false
failures=0

usage() {
  cat <<'EOF'
Usage: ./scripts/apply-local-config.sh [--check] [--require-secrets] [--force]

Apply or verify non-secret extension config wiring for this pi-scaps checkout.

Options:
  --check             Verify files, active agent dir, symlink, and secret env status without changing anything.
  --require-secrets   Fail when EXA_API_KEY, CONTEXT7_API_KEY, or FIRECRAWL_API_KEY is missing.
  --force             Replace an existing ~/.pi/agent/pi-web-kit.json file or symlink with the repo symlink.
  -h, --help          Show this help.
EOF
}

info() {
  printf '[INFO] %s\n' "$*"
}

pass() {
  printf '[PASS] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  failures=$((failures + 1))
}

fatal() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    fatal "Required command not found: $command_name"
  fi
}

while (($# > 0)); do
  case "$1" in
    --check)
      mode="check"
      ;;
    --force)
      force=true
      ;;
    --require-secrets)
      require_secrets=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fatal "Unknown argument: $1"
      ;;
  esac
  shift
done

require_command node
require_command readlink

[[ -n "${HOME-}" ]] || fatal "HOME is unset"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
repo_root_real="$(readlink -f -- "$repo_root")"
web_kit_config="$repo_root/pi-web-kit.json"
firecrawl_config="$repo_root/pi-firecrawl.json"
default_agent_dir="$HOME/.pi/agent"
web_kit_target="$default_agent_dir/pi-web-kit.json"

validate_json_configs() {
  if PI_SCAPS_WEB_KIT_JSON="$web_kit_config" PI_SCAPS_FIRECRAWL_JSON="$firecrawl_config" node <<'NODE'
const fs = require("node:fs");

for (const envName of ["PI_SCAPS_WEB_KIT_JSON", "PI_SCAPS_FIRECRAWL_JSON"]) {
  const path = process.env[envName];
  try {
    JSON.parse(fs.readFileSync(path, "utf8"));
  } catch (error) {
    console.error(`${path}: ${error.message}`);
    process.exitCode = 1;
  }
}
NODE
  then
    pass "committed extension JSON files parse"
  else
    fail "committed extension JSON files are invalid"
  fi
}

active_agent_dir() {
  if [[ -n "${PI_CODING_AGENT_DIR+x}" ]]; then
    if [[ -z "$PI_CODING_AGENT_DIR" ]]; then
      return 1
    fi
    printf '%s\n' "$PI_CODING_AGENT_DIR"
  else
    printf '%s\n' "$default_agent_dir"
  fi
}

check_active_agent_dir() {
  local active_dir active_real

  if ! active_dir="$(active_agent_dir)"; then
    fail "PI_CODING_AGENT_DIR is set but empty"
    return
  fi

  if [[ ! -d "$active_dir" ]]; then
    fail "active Pi agent directory does not exist: $active_dir"
    return
  fi

  active_real="$(readlink -f -- "$active_dir")"
  if [[ "$active_real" == "$repo_root_real" ]]; then
    pass "active Pi agent directory is this checkout"
  else
    fail "active Pi agent directory is not this checkout: $active_dir"
    info "Run: export PI_CODING_AGENT_DIR=$(printf '%q' "$repo_root")"
  fi
}

link_points_to_repo_config() {
  local target_real source_real

  [[ -e "$web_kit_target" || -L "$web_kit_target" ]] || return 1
  target_real="$(readlink -f -- "$web_kit_target" 2>/dev/null)" || return 1
  source_real="$(readlink -f -- "$web_kit_config")"
  [[ "$target_real" == "$source_real" ]]
}

apply_web_kit_link() {
  if link_points_to_repo_config; then
    pass "pi-web-kit config path points at the repo config"
    return
  fi

  if [[ -e "$web_kit_target" || -L "$web_kit_target" ]]; then
    if [[ "$force" != true ]]; then
      fail "$web_kit_target already exists and does not point at $web_kit_config"
      info "Review that file, then rerun with --force if replacing it is intended."
      return
    fi
    if [[ -d "$web_kit_target" && ! -L "$web_kit_target" ]]; then
      fail "$web_kit_target is a directory; refusing to replace it"
      return
    fi
    rm -f -- "$web_kit_target"
  fi

  mkdir -p -- "$default_agent_dir"
  ln -s -- "$web_kit_config" "$web_kit_target"
  pass "linked $web_kit_target to the repo pi-web-kit.json"
}

check_web_kit_link() {
  if link_points_to_repo_config; then
    pass "pi-web-kit config path points at the repo config"
  else
    fail "$web_kit_target does not point at $web_kit_config"
  fi
}

check_secret_env() {
  local missing=0
  local name

  for name in EXA_API_KEY CONTEXT7_API_KEY FIRECRAWL_API_KEY; do
    if [[ -n "${!name-}" ]]; then
      pass "$name is set"
    else
      if [[ "$require_secrets" == true ]]; then
        fail "$name is not set"
      else
        warn "$name is not set; source your private key file before launching Pi"
      fi
      missing=$((missing + 1))
    fi
  done

  if ((missing == 0)); then
    pass "required API-key environment variables are present"
  fi
}

printf 'pi-scaps local config %s\n\n' "$mode"
validate_json_configs
check_active_agent_dir

if [[ "$mode" == "apply" ]]; then
  if ((failures == 0)); then
    apply_web_kit_link
  else
    warn "skipping pi-web-kit link because earlier checks failed"
  fi
else
  check_web_kit_link
fi
check_secret_env

if ((failures > 0)); then
  printf '\n%s issue(s) found.\n' "$failures" >&2
  exit 1
fi

cat <<EOF

Next:
  1. Source your private API-key file, for example: source ~/.ssh/pi-api-keys.env
  2. Start or reload Pi: pi  # or /reload inside Pi
  3. Verify Firecrawl with: /firecrawl status
EOF
