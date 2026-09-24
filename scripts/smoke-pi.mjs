/** Load the complete Pi harness offline through RPC startup without a model request.
 *
 * Pi's help and model-list commands exit before checking runtime diagnostics.
 * RPC startup reaches those checks, binds extensions, then exits on stdin EOF.
 * Raw output is withheld because extensions and local settings may contain
 * sensitive details; the operator can run the printed command to diagnose.
 */
import { spawnSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const result = spawnSync("pi", ["--mode", "rpc", "--no-session", "--offline"], {
  cwd: repoRoot,
  env: { ...process.env, PI_CODING_AGENT_DIR: repoRoot, PI_OFFLINE: "1" },
  input: "",
  encoding: "utf8",
  timeout: 30_000,
  maxBuffer: 1024 * 1024,
});

if (result.status !== 0) {
  const category = result.error?.code === "ENOENT"
    ? "could not find the Pi executable"
    : result.error?.code === "ETIMEDOUT"
      ? "timed out"
    : /Failed to load extension/i.test(result.stderr ?? "")
      ? "extension load failed"
      : "configuration or runtime startup failed";
  console.error(`Pi offline harness smoke check ${category}. No model request was sent.`);
  console.error("For details, inspect a local run of: PI_OFFLINE=1 pi --mode rpc --no-session --offline < /dev/null");
  process.exit(1);
}

console.log("Pi offline harness smoke check passed: RPC startup and extension binding completed.");
