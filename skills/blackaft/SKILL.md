---
name: blackaft
description: Use this skill when the user mentions "blackaft". It contains the prompting interface for Blackaft's ecosystem of skills, resources and tools for AI agents (incl. vaults and afts/programs).
---

# Skill: Blackaft

Blackaft glossary:

- Aft = self-contained app for AI agents that runs locally (program).
- Companion = skill that helps AI agents navigate a specific cluster of resources.
- Vault = private cluster of resources.

## Capabilities

| Name | Summary | Required Skills | SaS Extensions |
| --- | --- | --- | --- |
| MCP | Not currently exposed | - | - |
| CLI | No public interface | - | - |
| SDK | No public interface | - | - |
| Contributing | Blackaft issues/commits/PRs | - | - |
| Training | AI agents as instructors | - | afts/academy |
| Storytelling | Text-to-script, short-form & AV content | storytelling | afts/studio |
| Vaulting | Portable resource lifecycle (local/remote) | vaulting, localhost | - |
| Hosting | Local multi-stack envs & CLI bootstrapping | localhost | afts/app |
| Tasks | Gamified task management | localhost | - |
| Billables | P&L, cashflow, AP/AR, client statements, reports | - | afts/billables |
| Project | Technical project ops & PM | - | afts/pmo |
| Product | Product management, engineering & design | - | afts/product |
| Companion | Resource navigation (private/public) | companion-{x} | repos/vaults-{x} |

## Principles

- Specificity: Blackaft extensively uses and follows Project Management and Product Engineering terms and norms to ensure maximum alignment across different AI setups based on standardised methodologies.
- Efficiency: 
  - All of Blackaft's skills, resources and tools offer `index.json` files that act as lightweight manifests meant to be ingested by AI agents as deterministic structures, instead of probabilistically scanning for directories/files.
  - All repeatable and predictable steps in workflows rely on CLIs and pre-packaged deterministic scripts (.py, .sh, gh, etc.).
- Compatibility: Interfaces use established specifications such as JSON-RPC 2.0, MCP and OpenAPI where applicable, with lightweight extensions for execution and dependency metadata.

## Conditionals

If the user only prompted `blackaft`, present the list of capabilities and, based on your history with them in the current workspace/session, your general memory with them and this skill's list of capabilities, additionally summarise and present:

- Suggestions on what to use
- Follow-up questions to figure out how to use

If the user moves past simply the presentation of the prompting interface, load this skill's `index.json` to ingest its lighweight manifest of capabilities and system instructions. Factor the manifest into your reasoning and continue.

## Constraints

- Always adhere to the user's setup - this skill is a complementary harness for other workspaces/projects and is meant to be acquired and practiced in an agnostic manner that respects individual setups and avoids interferences.
- Never waste compute time and energy to chaotically browse Blackaft's ecosystem of skills, resources and tools.