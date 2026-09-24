#!/usr/bin/env bash

# Diagnose whether this checkout is a complete, safe, and active Pi harness.
#
# Usage:
#   ./scripts/doctor.sh
#   PI_CODING_AGENT_DIR="$PWD" ./scripts/doctor.sh
#
# The doctor validates the tracked harness structure, strict JSON metadata,
# executable scripts, Node and pinned Pi versions, npm dependency consistency,
# resource placeholders, external session storage, and the absence of tracked
# credentials or runtime state. It also performs Pi's model-list diagnostic in
# offline mode to prove that the active configuration can start without making
# network health part of the result.
#
# PI_CODING_AGENT_DIR selects the active agent directory; otherwise the default
# is `$HOME/.pi/agent`. PI_CODING_AGENT_SESSION_DIR, when set, overrides the
# configured session directory for effective-path checks. The command reports
# every check it can complete, counts required-check failures, and exits non-zero
# after the full report if any required check failed. Missing authentication and
# an uncommitted worktree are informational warnings, not failures. The script
# is diagnostic and is not intended to install dependencies or alter the harness.

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
  elif [[ "$configured_path" == '~/'* ]]; then
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

git_worktree=false
if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_worktree=true
  pass "checkout is a Git working tree"
else
  fail "checkout is not a Git working tree: $repo_root"
fi

required_files=(
  .gitignore
  AGENTS.md
  README.md
  settings.json
  models.json.example
  package.json
  package-lock.json
  agents/README.md
  scripts/bootstrap.sh
  scripts/doctor.sh
  scripts/update.sh
)
missing_files=()
for required_file in "${required_files[@]}"; do
  if [[ ! -f "$repo_root/$required_file" ]]; then
    missing_files+=("$required_file")
  fi
done
if ((${#missing_files[@]} == 0)); then
  pass "required harness files are present"
else
  fail "required harness files are missing: ${missing_files[*]}"
fi

untracked_required_files=()
if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  for required_file in "${required_files[@]}"; do
    if [[ -f "$repo_root/$required_file" ]] &&
      ! git -C "$repo_root" ls-files --error-unmatch -- "$required_file" >/dev/null 2>&1; then
      untracked_required_files+=("$required_file")
    fi
  done
  if ((${#untracked_required_files[@]} == 0)); then
    pass "present required harness files are tracked by Git"
  else
    fail "required harness files are not tracked: ${untracked_required_files[*]}"
  fi
fi

required_directories=(agents extensions prompts scripts skills themes)
missing_directories=()
for required_directory in "${required_directories[@]}"; do
  if [[ ! -d "$repo_root/$required_directory" ]]; then
    missing_directories+=("$required_directory/")
  fi
done
if ((${#missing_directories[@]} == 0)); then
  pass "required harness directories are present"
else
  fail "required harness directories are missing: ${missing_directories[*]}"
fi

non_executable_scripts=()
for script_name in bootstrap.sh doctor.sh update.sh; do
  if [[ ! -x "$repo_root/scripts/$script_name" ]]; then
    non_executable_scripts+=("scripts/$script_name")
  fi
done
if ((${#non_executable_scripts[@]} == 0)); then
  pass "harness scripts are executable"
else
  fail "harness scripts are missing or not executable: ${non_executable_scripts[*]}"
fi

if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
  [[ -n "$(git -C "$repo_root" status --porcelain)" ]]; then
  warn "Git working tree has uncommitted changes"
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

canonical_repo_root="$(canonicalize_path "$repo_root")"
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

node_available=false
if command -v node >/dev/null 2>&1; then
  node_available=true
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

json_files=(package.json package-lock.json settings.json models.json.example)
invalid_json_files=()
if [[ "$node_available" == true ]]; then
  for json_file in "${json_files[@]}"; do
    if [[ ! -f "$repo_root/$json_file" ]] ||
      ! node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));' "$repo_root/$json_file" >/dev/null 2>&1; then
      invalid_json_files+=("$json_file")
    fi
  done
else
  invalid_json_files=("${json_files[@]}")
fi
if ((${#invalid_json_files[@]} == 0)); then
  pass "committed JSON files are strict valid JSON"
else
  fail "missing or invalid committed JSON files: ${invalid_json_files[*]}"
fi

metadata_valid=false
pi_contract_valid=false
node_requirement=""
pi_package=""
expected_pi_version=""
last_changelog_version=""
configured_session_dir=""
if [[ "$node_available" == true && -f "$repo_root/package.json" && -f "$repo_root/settings.json" ]]; then
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
          settings.lastChangelogVersion,
          settings.sessionDir,
        ];

        if (values.some((value) => typeof value !== "string" || value.length === 0)) {
          throw new Error("required harness metadata is missing or invalid");
        }
        process.stdout.write(values.join("\n"));
      } catch {
        process.exit(1);
      }
    '
  })"; then
    mapfile -t harness_metadata <<< "$metadata"
    if ((${#harness_metadata[@]} == 5)); then
      node_requirement="${harness_metadata[0]}"
      pi_package="${harness_metadata[1]}"
      expected_pi_version="${harness_metadata[2]}"
      last_changelog_version="${harness_metadata[3]}"
      configured_session_dir="${harness_metadata[4]}"
      metadata_valid=true
      pass "required harness metadata is present"
    else
      fail "harness metadata returned an unexpected number of values"
    fi
  else
    fail "required package.json or settings.json metadata is invalid"
  fi
else
  fail "required harness metadata could not be read"
fi

if [[ "$metadata_valid" == true ]]; then
  if [[ "$last_changelog_version" == "$expected_pi_version" ]]; then
    pass "Pi changelog marker matches the harness contract"
  else
    fail "settings.json lastChangelogVersion $last_changelog_version does not match Pi $expected_pi_version"
  fi

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

  pi_install_command="npm install -g --ignore-scripts ${pi_package}@${expected_pi_version}"
  if command -v pi >/dev/null 2>&1; then
    if pi_version_output="$(pi --version 2>&1)"; then
      if [[ "$pi_version_output" =~ ^[[:space:]]*(pi[[:space:]]+)?v?([0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?)[[:space:]]*$ ]]; then
        actual_pi_version="${BASH_REMATCH[2]}"
        if [[ "$actual_pi_version" == "$expected_pi_version" ]]; then
          pi_contract_valid=true
          pass "Pi $actual_pi_version matches the harness contract"
        else
          fail "Pi version mismatch: expected $expected_pi_version, found $actual_pi_version"
          info "Install the declared version with: $pi_install_command"
        fi
      else
        fail "could not parse Pi version output"
        info "Install the declared version with: $pi_install_command"
      fi
    else
      fail "could not run pi --version"
      info "Install the declared version with: $pi_install_command"
    fi
  else
    fail "required command not found: pi"
    info "Install the declared version with: $pi_install_command"
  fi

  configured_session_path=""
  if configured_session_path="$(resolve_session_path "$configured_session_dir" "$invocation_dir")"; then
    canonical_configured_session_path="$(canonicalize_path "$configured_session_path")"
    if [[ "$canonical_configured_session_path" == "$canonical_repo_root" ||
      "$canonical_configured_session_path" == "$canonical_repo_root/"* ]]; then
      fail "configured session directory resolves inside the Git checkout"
    else
      pass "configured session directory resolves outside the Git checkout"
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

extension_count=0
skill_count=0
prompt_count=0
theme_count=0
if [[ "$git_worktree" == true ]]; then
  for resource_directory in extensions skills prompts themes; do
    real_resource_count=0
    gitkeep_tracked=false

    while IFS= read -r -d '' tracked_resource_file; do
      if [[ "$tracked_resource_file" == "$resource_directory/.gitkeep" ]]; then
        gitkeep_tracked=true
        continue
      fi

      case "$tracked_resource_file" in
        extensions/*.ts | extensions/*.js | extensions/*.mjs | extensions/*.cjs)
          extension_count=$((extension_count + 1))
          real_resource_count=$((real_resource_count + 1))
          ;;
        skills/*)
          skill_relative_path="${tracked_resource_file#skills/}"
          if [[ "${skill_relative_path##*/}" == "SKILL.md" ||
            ("$skill_relative_path" != */* && "$skill_relative_path" == *.md) ]]; then
            skill_count=$((skill_count + 1))
            real_resource_count=$((real_resource_count + 1))
          fi
          ;;
        prompts/*.md)
          prompt_count=$((prompt_count + 1))
          real_resource_count=$((real_resource_count + 1))
          ;;
        themes/*.json)
          theme_count=$((theme_count + 1))
          real_resource_count=$((real_resource_count + 1))
          ;;
      esac
    done < <(git -C "$repo_root" ls-files -z -- "$resource_directory")

    if ((real_resource_count == 0)); then
      if [[ "$gitkeep_tracked" == true && -f "$repo_root/$resource_directory/.gitkeep" ]]; then
        pass "$resource_directory/ has its inert tracked placeholder"
      else
        fail "$resource_directory/ has no real tracked resource and requires a tracked .gitkeep"
      fi
    elif [[ "$gitkeep_tracked" == true ]]; then
      fail "$resource_directory/.gitkeep must be removed after adding a real tracked resource"
    else
      pass "$resource_directory/ contains real tracked resources without a placeholder"
    fi
  done
else
  fail "resource tracking could not be inspected outside a Git working tree"
fi
info "$extension_count extensions, $skill_count skills, $prompt_count prompts, $theme_count themes"

if [[ "$pi_contract_valid" == true && "$activation_valid" == true ]]; then
  if PI_CODING_AGENT_DIR="$canonical_active_agent_dir" PI_OFFLINE=1 pi --list-models >/dev/null 2>&1; then
    pass "Pi configuration starts in offline diagnostic mode"
  else
    fail "Pi configuration failed to start in offline diagnostic mode"
  fi
else
  fail "Pi offline startup diagnostic requires an active checkout and the declared Pi version"
fi

forbidden_tracked_paths=()
if [[ "$git_worktree" == true ]]; then
  while IFS= read -r -d '' tracked_path; do
    case "$tracked_path" in
      auth.json|oauth.json|models.json|models-store.json|crashes.json|trust.json|pi-debug.log|\
        auth.json.lock|auth.json.lock/*|settings.json.lock|settings.json.lock/*|\
        trust.json.lock|trust.json.lock/*|sessions|sessions/*|logs|logs/*|\
        git|git/*|npm|npm/*|bin|bin/*|tools|tools/*|tmp|tmp/*)
        forbidden_tracked_paths+=("$tracked_path")
        ;;
      *)
        if [[ "$tracked_path" != */* && "$tracked_path" == *.log ]]; then
          forbidden_tracked_paths+=("$tracked_path")
        fi
        ;;
    esac
  done < <(git -C "$repo_root" ls-files -z)

  if ((${#forbidden_tracked_paths[@]} == 0)); then
    pass "no forbidden Pi credential or runtime state is tracked"
  else
    fail "forbidden Pi credential or runtime state is tracked: ${forbidden_tracked_paths[*]}"
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
  printf '\n[FAIL] doctor found %d required check(s) that need attention.\n' "$failures" >&2
  exit 1
fi

printf '\nHarness looks healthy.\n'
