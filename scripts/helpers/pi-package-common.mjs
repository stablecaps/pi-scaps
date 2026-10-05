import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

const GIT_SHA_PATTERN = /^[0-9a-fA-F]{40}$/;
const PINNED_GIT_PATTERN = /@([0-9a-fA-F]{40})$/;

export class PiPackageError extends Error {
  constructor(message, { exitCode = 2 } = {}) {
    super(message);
    this.name = "PiPackageError";
    this.exitCode = exitCode;
  }
}

export function readSettings(repoRoot = process.cwd()) {
  const path = join(repoRoot, "settings.json");
  let text;
  let settings;
  try {
    text = readFileSync(path, "utf8");
  } catch (error) {
    throw new PiPackageError(`Could not read settings.json at ${path}: ${error.message}`);
  }
  try {
    settings = JSON.parse(text);
  } catch (error) {
    throw new PiPackageError(`Could not parse settings.json at ${path}: ${error.message}`);
  }
  return { path, text, settings };
}

function lineNumberForOffset(text, offset) {
  return text.slice(0, offset).split("\n").length;
}

function findJsonStringLocations(text, value) {
  const needle = JSON.stringify(value);
  const locations = [];
  let offset = 0;
  while (true) {
    const index = text.indexOf(needle, offset);
    if (index === -1) break;
    locations.push({ offset: index, line: lineNumberForOffset(text, index) });
    offset = index + needle.length;
  }
  return locations;
}

export function readPackageEntries(repoRoot = process.cwd()) {
  const { path, text, settings } = readSettings(repoRoot);
  if (settings.packages === undefined) return { settingsPath: path, settingsText: text, settings, entries: [] };
  if (!Array.isArray(settings.packages)) {
    throw new PiPackageError("settings.json packages must be an array");
  }

  const sourceUseCounts = new Map();
  const sourceLocations = new Map();
  const entries = settings.packages.map((entry, index) => {
    const source = typeof entry === "string" ? entry : entry?.source;
    if (typeof source !== "string") {
      throw new PiPackageError(
        `settings.json packages[${index}] must be a string source or an object with a string source`,
      );
    }

    if (!sourceLocations.has(source)) sourceLocations.set(source, findJsonStringLocations(text, source));
    const useCount = sourceUseCounts.get(source) ?? 0;
    sourceUseCounts.set(source, useCount + 1);
    const location = sourceLocations.get(source)?.[useCount];

    return {
      index,
      entry,
      source,
      line: location?.line,
      location: location?.line ? `settings.json:${location.line}` : `settings.json packages[${index}]`,
    };
  });

  return { settingsPath: path, settingsText: text, settings, entries };
}

export function updatePackageEntrySource(settings, entry, nextSource) {
  if (!Array.isArray(settings.packages)) {
    throw new PiPackageError("settings.json packages must be an array");
  }
  if (typeof nextSource !== "string" || nextSource.length === 0) {
    throw new PiPackageError(`${entry.location}\nReplacement package source must be a non-empty string`);
  }

  const current = settings.packages[entry.index];
  if (typeof current === "string") {
    if (current !== entry.source) {
      throw new PiPackageError(`${entry.location}\nPackage source changed before update could be applied:\n  expected: ${entry.source}\n  actual: ${current}`);
    }
    settings.packages[entry.index] = nextSource;
    return;
  }

  if (!current || typeof current !== "object" || Array.isArray(current) || current.source !== entry.source) {
    const actual = current && typeof current === "object" && !Array.isArray(current) ? current.source : current;
    throw new PiPackageError(`${entry.location}\nPackage source changed before update could be applied:\n  expected: ${entry.source}\n  actual: ${typeof actual === "string" ? actual : JSON.stringify(actual)}`);
  }
  current.source = nextSource;
}

export function writeSettings(settingsPath, settings) {
  writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
}

export function parseGitSource(source) {
  if (typeof source !== "string" || !source.startsWith("git:")) return null;

  const pinnedMatch = source.match(PINNED_GIT_PATTERN);
  const pinnedSha = pinnedMatch?.[1] ?? null;
  const unpinnedSource = pinnedSha ? source.slice(0, -41) : source;
  const body = unpinnedSource.slice(4);

  let host;
  let owner;
  let repo;
  let remoteUrl;

  let match = body.match(/^github\.com\/([^/\s]+)\/([^/\s]+?)(?:\.git)?$/);
  if (match) {
    host = "github.com";
    owner = match[1];
    repo = match[2];
    remoteUrl = `https://github.com/${owner}/${repo}.git`;
  }

  match = body.match(/^https:\/\/github\.com\/([^/\s]+)\/([^/\s]+?)(?:\.git)?$/);
  if (!host && match) {
    host = "github.com";
    owner = match[1];
    repo = match[2];
    remoteUrl = `https://github.com/${owner}/${repo}.git`;
  }

  match = body.match(/^git@github\.com:([^/\s]+)\/([^/\s]+?)(?:\.git)?$/);
  if (!host && match) {
    host = "github.com";
    owner = match[1];
    repo = match[2];
    remoteUrl = `git@github.com:${owner}/${repo}.git`;
  }

  return {
    source,
    unpinnedSource,
    pinnedSha,
    isPinned: Boolean(pinnedSha),
    isExactPin: Boolean(pinnedSha && GIT_SHA_PATTERN.test(pinnedSha)),
    body,
    host,
    owner,
    repo,
    remoteUrl,
    localPath: host && owner && repo ? join("git", host, owner, repo) : null,
    displayName: host && owner && repo ? `${owner}/${repo}` : body,
    supportedForLocalCheckout: Boolean(host && owner && repo),
  };
}

export function validateExactPackageSource(entry) {
  const exactNpm = /^npm:(?:@[a-z0-9][\w.-]*\/[a-z0-9][\w.-]*|[a-z0-9][\w.-]*)@\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;
  const immutableGit = /^git:.+@[0-9a-fA-F]{40}$/;
  if (exactNpm.test(entry.source) || immutableGit.test(entry.source)) return;

  const git = parseGitSource(entry.source);
  if (git && !git.isPinned) {
    throw new PiPackageError(`${entry.location}\nPi package source is not reproducible because it is missing a Git commit pin:\n  ${entry.source}\n\nIf this package is already installed locally, run:\n  node scripts/pin-installed-pi-packages.mjs\n\nOtherwise install/reconcile packages first, then pin:\n  PI_CODING_AGENT_DIR="$PWD" pi update --extensions\n  node scripts/pin-installed-pi-packages.mjs`);
  }

  throw new PiPackageError(`${entry.location}\nUnsupported or unpinned Pi package source:\n  ${entry.source}\n\nExpected one of:\n  npm:name@1.2.3\n  npm:@scope/name@1.2.3\n  git:<repo>@<40-character-commit-sha>`);
}

export function runGit(args, { cwd = process.cwd(), allowFailure = false } = {}) {
  const result = spawnSync("git", args, { cwd, encoding: "utf8" });
  if (result.error) {
    if (allowFailure) return result;
    throw new PiPackageError(`Could not run git ${args.join(" ")}: ${result.error.message}`);
  }
  if (result.status !== 0 && !allowFailure) {
    const details = (result.stderr || result.stdout || "git exited with a non-zero status").trim();
    throw new PiPackageError(`git ${args.join(" ")} failed:\n${details}`);
  }
  return result;
}

export function installedGitHead(repoRoot, entry) {
  const git = parseGitSource(entry.source);
  if (!git) return null;
  if (!git.supportedForLocalCheckout) {
    throw new PiPackageError(`${entry.location}\nCannot map this Git Pi package source to a local checkout path:\n  ${entry.source}\n\nSupported local pinning forms include:\n  git:github.com/owner/repo\n  git:https://github.com/owner/repo`);
  }

  const checkoutPath = join(repoRoot, git.localPath);
  if (!existsSync(checkoutPath)) {
    throw new PiPackageError(`${entry.location}\nUnpinned Git Pi package:\n  ${entry.source}\n\nNo installed checkout was found at:\n  ${git.localPath}\n\nRun:\n  PI_CODING_AGENT_DIR="$PWD" pi update --extensions\nthen:\n  node scripts/pin-installed-pi-packages.mjs`);
  }

  const inside = runGit(["-C", checkoutPath, "rev-parse", "--is-inside-work-tree"], { allowFailure: true });
  if (inside.status !== 0 || inside.stdout.trim() !== "true") {
    throw new PiPackageError(`${entry.location}\nInstalled package path exists but is not a Git checkout:\n  ${git.localPath}\n\nRemove or repair that path, then run:\n  PI_CODING_AGENT_DIR="$PWD" pi update --extensions`);
  }

  const head = runGit(["-C", checkoutPath, "rev-parse", "HEAD"]);
  const sha = head.stdout.trim();
  if (!GIT_SHA_PATTERN.test(sha)) {
    throw new PiPackageError(`${entry.location}\nCould not read a valid 40-character Git HEAD from:\n  ${git.localPath}\n\nGit returned:\n  ${sha || "<empty>"}`);
  }
  return { ...git, checkoutPath, sha };
}

export function remoteHead(entry) {
  const git = parseGitSource(entry.source);
  if (!git) return null;
  if (!git.remoteUrl) {
    throw new PiPackageError(`${entry.location}\nCannot check updates for unsupported Git package source:\n  ${entry.source}\n\nSupported update-check forms include GitHub sources such as:\n  git:github.com/owner/repo@<40-character-commit-sha>`);
  }

  const result = runGit(["ls-remote", git.remoteUrl, "HEAD"], { allowFailure: true });
  if (result.status !== 0) {
    const details = (result.stderr || result.stdout || "git ls-remote exited with a non-zero status").trim();
    throw new PiPackageError(`${entry.location}\nCould not check remote updates for:\n  ${entry.source}\n\nRemote queried:\n  ${git.remoteUrl}\n\n${details}`);
  }

  const sha = result.stdout.trim().split(/\s+/)[0];
  if (!GIT_SHA_PATTERN.test(sha)) {
    throw new PiPackageError(`${entry.location}\nRemote update check did not return a valid HEAD commit for:\n  ${entry.source}\n\nRemote queried:\n  ${git.remoteUrl}\nResponse:\n  ${result.stdout.trim() || "<empty>"}`);
  }
  return { ...git, sha };
}

export function pinnedGitEntries(entries) {
  return entries
    .map((entry) => ({ entry, git: parseGitSource(entry.source) }))
    .filter(({ git }) => git?.isPinned);
}
