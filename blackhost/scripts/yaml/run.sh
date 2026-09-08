#!/usr/bin/env bash

blackhost_yaml_run_help() {
    cat <<'HELP'
blackhost yaml run

Parses a YAML file with PyYAML to confirm the active python3 environment can read it.

Usage:
  scripts/core/init.sh [--json] yaml run <yaml-file> [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print the parse command without reading the file through PyYAML.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_yaml_run() {
    local script_name="blackhost yaml run"
    local yaml_file=""
    local yaml_path

    BLACKHOST_ASSUME_YES=false
    BLACKHOST_DRY_RUN=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run)
                BLACKHOST_DRY_RUN=true
                ;;
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -h|--help)
                blackhost_yaml_run_help
                return 0
                ;;
            -*)
                echo "[$script_name] Unknown option: $1" >&2
                return 2
                ;;
            *)
                if [ -n "$yaml_file" ]; then
                    echo "[$script_name] Unexpected argument: $1" >&2
                    return 2
                fi
                yaml_file="$1"
                ;;
        esac
        shift
    done

    if [ -z "$yaml_file" ]; then
        blackhost_yaml_run_help
        return 2
    fi

    if [ ! -f "$yaml_file" ]; then
        blackhost_fail "YAML file does not exist: $yaml_file"
        return 1
    fi

    yaml_path="$(cd "$(dirname "$yaml_file")" && pwd)/$(basename "$yaml_file")"

    blackhost_section "YAML Parse Run"
    blackhost_info "YAML file: $yaml_path"
    blackhost_info "YAML Python: $(blackhost_yaml_python_bin)"
    blackhost_info "Dry-run mode: $BLACKHOST_DRY_RUN"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Parse command will be printed but not executed."
    elif ! blackhost_yaml_pyyaml_available; then
        blackhost_fail "PyYAML is not available to python3."
        blackhost_warn "Run scripts/core/init.sh yaml install first, then rerun this command."
        return 1
    fi

    if ! blackhost_confirm "Parse this YAML file with PyYAML now?"; then
        blackhost_fail "YAML parse skipped."
        return 1
    fi

    blackhost_run_cmd "$(blackhost_yaml_python_bin)" -c 'import pathlib, sys, yaml; path = pathlib.Path(sys.argv[1]); yaml.safe_load(path.read_text()); print("YAML parsed successfully: " + str(path))' "$yaml_path"
    blackhost_dry_run_summary "YAML parse run"

    blackhost_section "YAML Run Summary"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_ok "Dry-run completed. The YAML file was not parsed."
    else
        blackhost_ok "YAML parse completed."
    fi
}
