#!/usr/bin/env bash

# Shared checks for the npm-managed Pi executable. Source this file after
# defining fail(); it never installs or changes anything.

# Return success when one strict three-component version meets a minimum.
version_at_least() {
  local actual="$1" required="$2"
  local actual_major actual_minor actual_patch required_major required_minor required_patch
  [[ "$actual" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$required" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 2
  IFS=. read -r actual_major actual_minor actual_patch <<< "$actual"
  IFS=. read -r required_major required_minor required_patch <<< "$required"
  if ((10#$actual_major != 10#$required_major)); then
    ((10#$actual_major > 10#$required_major)); return
  fi
  if ((10#$actual_minor != 10#$required_minor)); then
    ((10#$actual_minor > 10#$required_minor)); return
  fi
  ((10#$actual_patch >= 10#$required_patch))
}

# Reject an active Pi binary outside the selected global npm package.
check_pi_ownership() {
  local pi_package="$1" active_pi npm_prefix npm_root npm_link expected_target
  npm_prefix="$(npm prefix -g)" || fail "Unable to read npm global prefix"
  npm_root="$(npm root -g)" || fail "Unable to read npm global package root"
  [[ "$npm_prefix" == /* && "$npm_root" == /* ]] || fail "npm global paths must be absolute"
  npm_link="$npm_prefix/bin/pi"
  if command -v pi >/dev/null 2>&1; then
    active_pi="$(command -v pi)"
    [[ "$active_pi" == /* ]] || fail "Active pi is not an npm-managed executable: $active_pi"
    [[ -L "$npm_link" ]] || fail "Active pi is not managed by this npm global prefix: $active_pi"
    expected_target="$(
      PI_SCAPS_NPM_ROOT="$npm_root" PI_SCAPS_PI_PACKAGE="$pi_package" node -e '
        const fs = require("node:fs");
        const path = require("node:path");
        const packageDir = path.join(process.env.PI_SCAPS_NPM_ROOT, process.env.PI_SCAPS_PI_PACKAGE);
        try {
          const manifest = JSON.parse(fs.readFileSync(path.join(packageDir, "package.json"), "utf8"));
          const bin = typeof manifest.bin === "string" ? manifest.bin : manifest.bin?.pi;
          if (manifest.name !== process.env.PI_SCAPS_PI_PACKAGE || typeof bin !== "string") process.exit(1);
          const target = path.resolve(packageDir, bin);
          if (!target.startsWith(packageDir + path.sep)) process.exit(1);
          process.stdout.write(target);
        } catch { process.exit(1); }
      '
    )" || fail "Could not identify npm-managed $pi_package's pi entry point"
    [[ -f "$expected_target" &&
      "$(readlink -f -- "$active_pi")" == "$(readlink -f -- "$expected_target")" &&
      "$(readlink -f -- "$npm_link")" == "$(readlink -f -- "$expected_target")" ]] ||
      fail "Active pi is not the npm-managed $pi_package executable under $npm_prefix: $active_pi"
  fi
}

# Print the active Pi version without its optional CLI prefix.
read_pi_version() {
  local output
  output="$(pi --version 2>&1)" || fail "Unable to read the installed Pi version"
  [[ "$output" =~ ^[[:space:]]*(pi[[:space:]]+)?v?([0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?)[[:space:]]*$ ]] ||
    fail "Could not parse Pi version output: $output"
  printf '%s\n' "${BASH_REMATCH[2]}"
}
