#!/usr/bin/env node
import { writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  PiPackageError,
  parseGitSource,
  readPackageEntries,
  remoteHead,
} from "./pi-package-common.mjs";

function usage() {
  return "Usage: node scripts/pi-package-updates.mjs (--check [--advisory] | --upgrade)";
}

function replaceOnce(text, oldValue, newValue, location) {
  const oldJson = JSON.stringify(oldValue);
  const newJson = JSON.stringify(newValue);
  if (!text.includes(oldJson)) {
    throw new PiPackageError(`${location}\nCould not find the package source text while updating settings.json:\n  ${oldValue}`);
  }
  return text.replace(oldJson, newJson);
}

async function main() {
  const args = new Set(process.argv.slice(2));
  const check = args.has("--check");
  const advisory = args.has("--advisory");
  const upgrade = args.has("--upgrade");
  if (args.size !== process.argv.slice(2).length || check === upgrade || [...args].some((arg) => !["--check", "--advisory", "--upgrade"].includes(arg))) {
    throw new PiPackageError(usage());
  }
  if (advisory && !check) throw new PiPackageError("--advisory can only be used with --check");

  const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
  const { settingsPath, settingsText, entries } = readPackageEntries(repoRoot);
  const gitEntries = entries
    .map((entry) => ({ entry, git: parseGitSource(entry.source) }))
    .filter(({ git }) => git?.isPinned);

  if (gitEntries.length === 0) {
    console.log("No pinned Git Pi packages are declared.");
    return 0;
  }

  const updates = [];
  const current = [];
  for (const { entry, git } of gitEntries) {
    const remote = remoteHead(entry);
    const nextSource = `${git.unpinnedSource}@${remote.sha}`;
    const item = {
      entry,
      git,
      remoteSha: remote.sha,
      nextSource,
      updateAvailable: remote.sha.toLowerCase() !== git.pinnedSha.toLowerCase(),
    };
    if (item.updateAvailable) updates.push(item);
    else current.push(item);
  }

  if (check) {
    if (updates.length === 0) {
      console.log("External Pi package check: all pinned Git packages are current.");
      for (const item of current) {
        console.log(`  ${item.git.displayName}: ${item.git.pinnedSha}`);
      }
      return 0;
    }

    console.log("External Pi package updates are available:");
    for (const item of updates) {
      console.log(`\n${item.git.displayName}`);
      console.log(`  ${item.entry.location}`);
      console.log(`  pinned: ${item.git.pinnedSha}`);
      console.log(`  remote: ${item.remoteSha}`);
    }
    console.log("\nTo upgrade external Pi packages, run:");
    console.log("  ./scripts/upgrade-pi.sh --packages");
    return advisory ? 0 : 1;
  }

  if (updates.length === 0) {
    console.log("External Pi packages are already current. No changes made.");
    return 0;
  }

  let updatedText = settingsText;
  for (const item of updates) {
    updatedText = replaceOnce(updatedText, item.entry.source, item.nextSource, item.entry.location);
  }
  writeFileSync(settingsPath, updatedText);

  console.log("Updated external Pi package pin(s) in settings.json:");
  for (const item of updates) {
    console.log(`\n${item.git.displayName}`);
    console.log(`  ${item.entry.location}`);
    console.log(`  ${item.entry.source}`);
    console.log(`  -> ${item.nextSource}`);
  }
  console.log("\nPackage code has not been reconciled yet; caller should run pi update --extensions.");
  return 0;
}

main()
  .then((code) => process.exit(code))
  .catch((error) => {
    if (error instanceof PiPackageError) {
      console.error(error.message);
      process.exit(error.exitCode);
    }
    console.error(`Failed to check or update Pi packages: ${error.message}`);
    process.exit(2);
  });
