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
