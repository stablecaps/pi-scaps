#!/usr/bin/env node
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  PiPackageError,
  installedGitHead,
  parseGitSource,
  readPackageEntries,
  updatePackageEntrySource,
  writeSettings,
} from "./helpers/pi-package-common.mjs";

try {
  const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
  const { settingsPath, settings, entries } = readPackageEntries(repoRoot);
  const changes = [];

  for (const entry of entries) {
    const git = parseGitSource(entry.source);
    if (!git || git.isPinned) continue;

    const installed = installedGitHead(repoRoot, entry);
    const pinnedSource = `${git.unpinnedSource}@${installed.sha}`;
    updatePackageEntrySource(settings, entry, pinnedSource);
    changes.push({ entry, installed, pinnedSource });
  }

  if (changes.length === 0) {
    console.log("All Git Pi package sources are already pinned, or no Git Pi packages are declared.");
    process.exit(0);
  }

  writeSettings(settingsPath, settings);
  console.log("Pinned installed Git Pi package source(s) in settings.json:");
  for (const change of changes) {
    console.log(`\n${change.entry.location}`);
    console.log(`  ${change.entry.source}`);
    console.log(`  -> ${change.pinnedSource}`);
    console.log(`  installed checkout: ${change.installed.localPath}`);
  }
  console.log("\nReview the diff, then commit settings.json deliberately.");
} catch (error) {
  if (error instanceof PiPackageError) {
    console.error(error.message);
    process.exit(error.exitCode);
  }
  console.error(`Failed to pin installed Pi packages: ${error.message}`);
  process.exit(2);
}
