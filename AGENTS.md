# pi-scaps global harness

This repository is the version-controlled global harness for Pi.

- Prefer simple solutions with low ongoing token and maintenance cost.
- Choose the simplest maintainable language for each script: Bash for straightforward
  command orchestration, Node for Pi/npm paths where it is already required, and
  Python where it improves clarity. Do not add a runtime prerequisite casually.
- Keep verification and process proportional to risk. Avoid frameworks, elaborate
  abstractions, speculative tests, and extra approval or checklist steps without
  a demonstrated need.
- Add an extension or dependency only for a demonstrated, reusable need.
- Do not recreate behavior already handled cheaply and reliably by Pi's core tools.
- Never commit credentials, secrets, sessions, trust decisions, caches, or other runtime state.
- Keep behavioral changes reproducible, reviewable, and documented.
- Preserve pinned versions; update their documentation and verification together with any deliberate version change.
- Before finalizing any task that changed files, inspect the diff and provide a ready-to-use multi-line commit message. If the change is trivial, a single line is fine.

Web retrieval policy:
- Prefer `web_search` for discovery and current information.
- Prefer `web_fetch` when the relevant URL is already known.
- Prefer `library_docs` for package, framework, SDK, and API documentation.
- Prefer `code_search` for real-world implementation examples and usage patterns.
- Prefer authoritative or primary sources when available.
- Do not fetch pages when search results already provide sufficient evidence.
- Use Firecrawl only for mapping, crawling, structured extraction, difficult pages, or when ordinary `web_fetch` cannot retrieve the required content.
- Request only the number of results and amount of content needed for the task.
