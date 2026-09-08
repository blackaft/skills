# Skill: Blackhost

![Target Audience](https://img.shields.io/badge/Target_Audience-Humans-FF5722?style=flat-square&logo=userpilot&logoColor=white)

Manage local environments with your AI.

This skill is a program for AI. We call these afts. It packages a service into software that AI can execute locally. Because it relies on structured interfaces (e.g. APIs, JSON, CLIs) instead of descriptive prompts, it avoids context bloat and drift.

Pairs nicely with `skills/blackaft/`.

## ☕ Use

Prompt your agent with `blackhost` to initiate the prompting interface.

## 🚀 Setup

Copy and paste the following prompt to your agent:

```markdown
Help me install the `blackhost` skill from the github.com/blackaft/skills/ repository.
It's a complementary skill that can help us manage our local environment.
We'll explore its capabilities together and determine what we need to use. 
```

## 🤖 Models

Proposed LLMs for this skill:

| Provider | Model | Use |
| --- | --- | --- |
| OpenAI | `gpt-5.6-luna` with low reasoning | When you just want to open your PHP, Python, Node.js, or Dockerised app in the browser. |
| OpenAI | `gpt-5.6-terra` with medium reasoning | For normal package checks, installs, updates, and small fixes. |
| OpenAI | `gpt-5.6-sol` with high reasoning | For changing blackhost itself, adding cloud packages, or reviewing another agent's work. |
| Anthropic | `claude-haiku-4-5` | For light cleanup after the package pattern is already clear. |
| Anthropic | `claude-sonnet-5` | For everyday package additions, script updates, and assurance fixes. |
| Anthropic | `claude-opus-5` or `claude-fable-5` | For harder architecture work or high-risk reviews. |
| Google | Gemini CLI Auto with Gemini 3 | When you just want to open your PHP app, run local checks, or make routine environment changes. |
| Google | `gemini-3.7-flash` | For quick package work where speed matters. |
| Google | `gemini-3.1-pro-preview` | For advanced architecture, complex reasoning, or new provider packages. |
| Google | `gemini-3.5-flash-lite` | For low-cost follow-up edits and repetitive cleanup. |

---

*Created and maintained by [Blackaft Associates](https://github.com/blackaft/) jointly by humans and machines (AI). This software is protected and distributed by the [PolyForm Shield License 1.0.0](LICENSE.md). Badges by [shields.io](https://github.com/badges/shields).*
