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

- `docs/` contains artifacts related to the skill's development.
- `VERSION` is the skill's current version, follows [SemVer 2.0](https://semver.org/).
- `CHANGELOG.md` includes one-liners with references to relevant PRs, tags and/or releases.
- `LICENSE.md`
- `README.md` is the only artifact designated for humans.

## SKILL.md

### Frontmatter

### Contents

## Manifests

## Scripts

Scripts are the bedrock of afts and they are designed exclusively for LLMs. They are organised under modules and each script offers a bundle of commands/functions.

- `scripts/interface.sh` is a universal entrypoint allowing LLMs to call, load an execute an aft's modules and its scripts programmatically without having to search for or read any other files.
- `scripts/{module-name}/module.sh` is a module's central router, granting `interface.sh` with access the available scripts.



### interface.sh

### commons/

## Examples