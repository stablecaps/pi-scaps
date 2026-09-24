# Agent role definitions

This directory is a pi-scaps harness convention. Pi does not discover agent roles from `agents/` automatically.

Future orchestration may store role definitions here only after an implemented extension consumes them. Each definition should keep these concerns distinct:

- role and instructions;
- model selection;
- thinking level;
- task and context allocation.

The initial harness deliberately defines no speculative roles.
