@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@''

Yes. For your setup I’d use **one private Git repo as the canonical definition of the Pi harness**, and make rebuilding a machine essentially:

```bash
git clone git@github.com:giri/pi-harness.git ~/.pi/agent
cd ~/.pi/agent
./bootstrap.sh
pi
```

That pattern is already being used successfully by other Pi configurations, and Pi natively treats `~/.pi/agent` as its global configuration directory. ([GitHub][1])

I would structure yours roughly like this:

```text
pi-harness/
├── AGENTS.md
├── settings.json
├── models.json
├── package.json
├── package-lock.json
│
├── extensions/
│   ├── subagents/
│   ├── ping-pong/
│   ├── telemetry/
│   └── ...
│
├── skills/
│   ├── research/
│   ├── code-review/
│   └── ...
│
├── prompts/
│   ├── review.md
│   └── ...
│
├── agents/
│   ├── architect.md
│   ├── worker.md
│   └── reviewer.md
│
├── scripts/
│   ├── bootstrap.sh
│   ├── doctor.sh
│   └── update.sh
│
├── .gitignore
└── README.md
```

### The important separation

**Commit anything that defines behaviour.**

That means your extensions, skills, prompts, agent definitions, model configuration, Pi settings, package versions and bootstrap scripts.

**Do not commit runtime state or secrets.**

I'd have something like:

```gitignore
# credentials
auth.json
.env
*.secret

# machine/runtime state
sessions/
trust.json
pi-debug.log
models-store.json
bin/

# downloaded packages/cache
git/
npm/

# JS dependencies
node_modules/
```

Pi stores provider credentials in `auth.json`, so that file absolutely should stay out of Git. ([GitHub][2])

I would also explicitly put sessions somewhere outside the repo:

```json
{
  "sessionDir": "~/.local/state/pi/sessions"
}
```

Pi supports a separate session directory, which stops thousands of session files turning your harness checkout into a rubbish dump. ([GitHub][3])

### Use `package.json` as the harness manifest

This is particularly useful for what we've been discussing about **a small number of worthwhile extensions rather than endlessly accumulating agent-harness cruft**.

For example:

```json
{
  "name": "giri-pi-harness",
  "private": true,
  "version": "1.0.0",
  "pi": {
    "extensions": ["./extensions"],
    "skills": ["./skills"],
    "prompts": ["./prompts"]
  }
}
```

Pi understands repositories with a `pi` manifest and can expose extensions, skills, prompts and themes from them. It can also install Pi packages directly from Git and pin them to a tag or commit. ([GitHub][4])

Then `settings.json` becomes the declaration of **external components** you use rather than copying their source into your repo.

Conceptually:

```json
{
  "defaultProvider": "...",
  "defaultModel": "...",
  "defaultThinkingLevel": "medium",

  "packages": [
    "git:github.com/foo/pi-something@<pinned-version>",
    "npm:@foo/pi-other@<pinned-version>"
  ]
}
```

I strongly favour **pinning third-party extensions**. Otherwise "rebuild my Pi harness" actually means "install whatever happens to be current today", which defeats reproducibility.

### Then have one bootstrap script

Something along these lines:

```bash
#!/usr/bin/env bash
set -euo pipefail

# install JS deps used by our own extensions
npm ci

# create runtime state outside git
mkdir -p "$HOME/.local/state/pi/sessions"

echo
echo "Harness installed."
echo "Run 'pi' and use /login to authenticate providers."
```

You could make it more sophisticated later:

```text
bootstrap.sh
    │
    ├── verify Node version
    ├── verify/install Pi version
    ├── npm ci
    ├── verify rg/fd/jq/etc
    ├── create state directories
    ├── check extension dependencies
    └── run doctor.sh
```

And `doctor.sh` is worth having. Something as simple as:

```text
✓ Pi installed: 0.xx.x
✓ Node 22.x
✓ rg
✓ jq
✓ 7 extensions load
✓ 11 skills discovered
✓ model configuration valid
✓ auth present
```

That is much more useful than discovering six months later that your "reproducible harness" depends on something you installed manually once.

### One wrinkle with `PI_CODING_AGENT_DIR`

Pi also lets you keep the repo somewhere cleaner:

```bash
~/src/pi-harness
```

and then:

```bash
export PI_CODING_AGENT_DIR="$HOME/src/pi-harness"
```

Pi officially supports this. ([GitHub][5])

But `PI_CODING_AGENT_DIR` redirects **the whole agent directory**, including `auth.json` and other writable state. There's even an open Pi issue discussing precisely this lack of separation. ([GitHub][6])

So for **your personal harness**, I don't think you gain much.

I'd simply do:

```text
~/.pi/
└── agent/             ← THIS IS THE GIT REPOSITORY
    ├── .git/
    ├── AGENTS.md
    ├── settings.json
    ├── extensions/
    ├── skills/
    └── ...
```

with runtime/secrets gitignored and sessions explicitly stored elsewhere.

## The result

A new computer becomes:

```bash
# install Pi / Node
git clone git@github.com:giri/pi-harness.git ~/.pi/agent

cd ~/.pi/agent
./scripts/bootstrap.sh

pi
# /login once
```

And you're back to essentially the **same Pi**.

Even better, every change we're now making to your harness becomes an actual commit:

```text
feat: add ephemeral scout
feat: add ping-pong reviewer
perf: replace web scraper with Firecrawl extension
perf: add JEV log filtering
chore: pin context7 extension
```

So when one of our experiments turns out to be bollocks, you can literally:

```bash
git revert <commit>
```

That, rather than building a giant installer, is the model I'd use for the Pi harness we're designing. Git becomes the **harness's memory, distribution mechanism, versioning system and rollback system simultaneously**.

[1]: https://github.com/rfgamaral/pi-config?utm_source=chatgpt.com "GitHub - rfgamaral/pi-config: Personal harness configuration for the Pi coding agent: extensions, skills, and prompts. · GitHub"
[2]: https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/models.md?utm_source=chatgpt.com "pi/packages/coding-agent/docs/models.md at main · earendil-works/pi · GitHub"
[3]: https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/settings.md?plain=1&utm_source=chatgpt.com "pi/packages/coding-agent/docs/settings.md at main · earendil-works/pi · GitHub"
[4]: https://github.com/bochen2029-pixel/pi-harness/blob/main/packages/coding-agent/README.md?utm_source=chatgpt.com "pi-harness/packages/coding-agent/README.md at main · bochen2029-pixel/pi-harness · GitHub"
[5]: https://github.com/earendil-works/pi/blob/main/packages/coding-agent/src/config.ts?utm_source=chatgpt.com "pi/packages/coding-agent/src/config.ts at main · earendil-works/pi · GitHub"
[6]: https://github.com/earendil-works/pi/issues/3455?utm_source=chatgpt.com "Support loading shared AGENTS.md from packages or configured paths without using PI_CODING_AGENT_DIR · Issue #3455 · earendil-works/pi · GitHub"
