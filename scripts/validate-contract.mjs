/** Validate the checked-in Node/Pi contract; optionally sync Pi's derived marker. */
import { readFileSync, writeFileSync } from "node:fs";

/** Read a checked-in JSON file. */
function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

/** Compare two three-component numeric versions. */
function compareVersions(actual, required) {
  for (let index = 0; index < 3; index += 1) {
    if (actual[index] !== required[index]) {
      return actual[index] - required[index];
    }
  }
  return 0;
}

/** Reject unpinned external Pi package declarations. */
function validatePackages(packages) {
  if (packages === undefined) return;
  if (!Array.isArray(packages)) throw new Error("settings.json packages must be an array");

  for (const entry of packages) {
    const source = typeof entry === "string" ? entry : entry?.source;
    if (typeof source !== "string") {
      throw new Error("each Pi package must have a string source");
    }
    const exactNpm = /^npm:(?:@[a-z0-9][\w.-]*\/[a-z0-9][\w.-]*|[a-z0-9][\w.-]*)@\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;
    const immutableGit = /^git:.+@[0-9a-fA-F]{40}$/;
    if (!exactNpm.test(source) && !immutableGit.test(source)) {
      throw new Error(`Pi package source must use an exact npm version or Git commit: ${source}`);
    }
  }
}

try {
  const manifest = readJson("package.json");
  const lock = readJson("package-lock.json");
  const settings = readJson("settings.json");
  const models = readJson("models.json.example");

  const requirement = manifest.engines?.node;
  const match = typeof requirement === "string" && requirement.match(/^>=(\d+)\.(\d+)\.(\d+)$/);
  if (!match) {
    throw new Error("package.json has an unsupported Node requirement");
  }

  const requiredVersion = match.slice(1).map(Number);
  const actualVersion = process.versions.node.split(".").slice(0, 3).map(Number);
  if (compareVersions(actualVersion, requiredVersion) < 0) {
    throw new Error(`Node ${process.versions.node} does not satisfy ${requirement}`);
  }

  if (lock.packages?.[""]?.engines?.node !== requirement) {
    throw new Error("package-lock.json does not mirror package.json engines.node");
  }
  if (
    typeof manifest.piHarness?.package !== "string" ||
    !/^(@[a-z0-9][\w.-]*\/)?[a-z0-9][\w.-]*$/.test(manifest.piHarness.package) ||
    typeof manifest.piHarness?.version !== "string" ||
    !/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/.test(manifest.piHarness.version)
  ) {
    throw new Error("package.json must declare one exact Pi package and version");
  }
  validatePackages(settings.packages);

  if (process.argv[2] === "--sync-pi-marker") {
    if (process.argv.length !== 3) throw new Error("unexpected arguments");
    if (settings.lastChangelogVersion !== manifest.piHarness.version) {
      const original = readFileSync("settings.json", "utf8");
      const updated = original.replace(
        /("lastChangelogVersion"\s*:\s*)"[^"]*"/,
        `$1${JSON.stringify(manifest.piHarness.version)}`,
      );
      if (updated === original || JSON.parse(updated).lastChangelogVersion !== manifest.piHarness.version) {
        throw new Error("could not update settings.json lastChangelogVersion");
      }
      writeFileSync("settings.json", updated);
      settings.lastChangelogVersion = manifest.piHarness.version;
    }
  } else if (process.argv.length !== 2) {
    throw new Error("unexpected arguments");
  }
  if (settings.lastChangelogVersion !== manifest.piHarness?.version) {
    throw new Error("settings.json lastChangelogVersion does not mirror the Pi version");
  }
  if (
    !models.providers ||
    typeof models.providers !== "object" ||
    Array.isArray(models.providers) ||
    Object.keys(models.providers).length !== 0 ||
    Object.keys(models).length !== 1
  ) {
    throw new Error("models.json.example must contain only an empty providers object");
  }

  console.log("Pi harness contract is valid");
} catch (error) {
  console.error(`Pi harness contract is invalid: ${error.message}`);
  process.exit(1);
}
