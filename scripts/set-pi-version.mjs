/** Atomically replace only the authoritative Pi version and its derived marker. */
import { readFileSync, renameSync, writeFileSync, unlinkSync } from "node:fs";
import { randomUUID } from "node:crypto";

/** Replace one JSON string field while retaining surrounding formatting. */
function replaceField(path, pattern, oldVersion, newVersion) {
  const original = readFileSync(path, "utf8");
  let matches = 0;
  const updated = original.replace(pattern, (whole, prefix, value) => {
    matches += 1;
    if (value !== oldVersion) throw new Error(`${path} has an unexpected Pi version`);
    return prefix + JSON.stringify(newVersion);
  });
  if (matches !== 1) throw new Error(`${path} must contain exactly one Pi version field`);
  JSON.parse(updated);
  return updated;
}

/** Write a complete valid JSON file through a same-directory rename. */
function writeAtomic(path, contents) {
  const temporary = `${path}.tmp-${randomUUID()}`;
  try {
    writeFileSync(temporary, contents, { flag: "wx" });
    renameSync(temporary, path);
  } finally {
    try { unlinkSync(temporary); } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
}

try {
  const [oldVersion, newVersion] = process.argv.slice(2);
  if (process.argv.length !== 4 || !oldVersion || !newVersion) {
    throw new Error("usage: node scripts/set-pi-version.mjs <old-version> <new-version>");
  }
  const manifest = replaceField(
    "package.json",
    /("piHarness"\s*:\s*\{[^{}]*"version"\s*:\s*)"([^"]*)"/g,
    oldVersion,
    newVersion,
  );
  const settings = replaceField(
    "settings.json",
    /("lastChangelogVersion"\s*:\s*)"([^"]*)"/g,
    oldVersion,
    newVersion,
  );
  writeAtomic("package.json", manifest);
  writeAtomic("settings.json", settings);
} catch (error) {
  console.error(`Could not update Pi metadata: ${error.message}`);
  process.exit(1);
}
