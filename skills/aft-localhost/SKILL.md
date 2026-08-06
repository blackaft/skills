---
name: aft-localhost
description: Use this skill to bootstrap environments locally. Workflows available: git, docker, php (composer), python (pip), nodejs (npm, npx) and aws, gcloud, gh clis.
---

# Aft: Localhost by Blackaft

This skill is a service module for AI. We call these afts. It packages a service into software that AI can execute locally. Because it relies on structured interfaces (e.g. APIs, JSON, CLIs) instead of descriptive prompts, it avoids context bloat.

When using this skill, follow these steps:

1. **Learn - Ingest the manifest**, load and parse `index.json` to obtain this skill's tree in an efficient, programmatic manner.
2. **Inspect - Audit the environment**, if the manifest does not contain sufficient or up-to-date information about the current state, delegate sub-agents to run the necessary `scripts/diagnostics/` based on the user's requirements and the system's specifications.
3. **Act - Bootstrap the environment**, delegate sub-agents to execute environment setups and handle any script prompts and errors.
4. **Verify - Validate results**, use `assurance/evals/` and `assurance/tests/` to validate outcomes against specific acceptance criteria.
5. **Record - Log the session**, sign sessions under `logs/` using `templates/log.md`.

Adapt the workflow to the task, without sacrificing efficiency or traceability.

While using this skill, always consider:

1. **Model used**, based on the intelligence, speed and cost efficiency required to complete the task.
2. **Permission levels and sandboxing**, to ensure continuous alignment with the user's workspace.