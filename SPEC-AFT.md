> v1.0.0-beta

# Specification

This specification extends the original spec for agent skills and adapters with a more deterministic and programmatic approach, treating them as self-contained executable programs for LLMs, called [afts](https://www.merriam-webster.com/dictionary/aft). Afts act as local/deployable apps, plugins and even connectors, relying almost exclusively on CLIs and SDKs bundled under executable scripts designed specifically for LLMs.

The idea behind ...

## Principles

- **Programmatic approach**, not natural language
- **Agnostic**
- **Multidisciplinary implementation**, meaning a single aft should employ the principles, methods and techniques of multiple disciplines (i.e. combining project management with storytelling), an approach which is in par with [Blackaft](https://blackaft.com/)'s own foundation.
- **Self-containment**: an aft should not require additional plugins, connectors or any other third-party services and should 
- **Context distribution**

## Architecture

Whereas the original spec for agent skills and adapters only requires a `SKILL.md` file with specific frontmatter, Afts are noticeably more deterministic in nature, thus containing more files and directories.

progressive loading TBD
path references

## Directory Structure

Required files and directories:

- `apps/`
- `config/`
    - `skill.json`
- `manifests/`
    - `interface.json` is the entrypoint manifest.
- `scripts/`
    - `interface.sh` is the universal entrypoint.
- `templates/`
    - `manifest.json`
    - `script.sh`
- `SKILL.md`

Optional:

- `docs/`
- `VERSION` is the skill's current version, follows [SemVer 2.0](https://semver.org/)
- `CHANGELOG.md` 
- `LICENSE.md`
- `README.md`

## SKILL.md

### Frontmatter

### Contents

## Manifests

## Scripts

Scripts represent the bedrock of afts. They offer bundles of commands and functions and can include scripts written in different languages (i.e. .js, .python, .php, .sh).

- 

### interface.sh

### commons/

## Examples