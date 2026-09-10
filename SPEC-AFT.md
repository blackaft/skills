> v1.0.0-beta

# Specification

This specification extends the original spec for agent skills and adapters with a more deterministic and programmatic approach, treating them as a self-contained executable programs for LLMs, called [Afts](https://www.merriam-webster.com/dictionary/aft).

Afts follow specific principles:

- Programmatic approach, not natural language
- Agnostic
- Multidisciplinary implementation
- Self-containment
- Context distribution

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

### interface.sh

### commons/

## Examples