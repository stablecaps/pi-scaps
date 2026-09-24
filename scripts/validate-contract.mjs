import { readFileSync } from "node:fs";

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function compareVersions(actual, required) {
  for (let index = 0; index < 3; index += 1) {
    if (actual[index] !== required[index]) {
      return actual[index] - required[index];
    }
  }
  return 0;
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
