#!/usr/bin/env bash

blackhost_yaml_update_help() {
    cat <<'HELP'
blackhost yaml update

Updates PyYAML in the blackhost-managed virtualenv with explicit prompts.

Usage:
  scripts/core/init.sh [--json] yaml update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Update path:
  python3 -m venv <blackhost-skill>/local/.venv
  <blackhost-skill>/local/.venv/bin/python -m pip install --upgrade pip PyYAML
HELP
}

blackhost_yaml_update() {
    local script_name="blackhost yaml update"

    BLACKHOST_ASSUME_YES=false
    BLACKHOST_DRY_RUN=false

    for arg in "$@"; do
        case "$arg" in
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            --dry-run)
                BLACKHOST_DRY_RUN=true
                ;;
            -h|--help)
                blackhost_yaml_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "YAML Tooling Update"
    blackhost_info "This script updates PyYAML in the blackhost-managed virtualenv."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"
    blackhost_info "Managed virtualenv: $BLACKHOST_YAML_VENV_PATH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    fi

    if [ "$BLACKHOST_DRY_RUN" = false ] && ! blackhost_yaml_python_available; then
        blackhost_fail "Python 3 is not available."
        blackhost_warn "Run scripts/core/init.sh python install first, then rerun this command."
        return 1
    fi

    blackhost_yaml_print_pyyaml_version || blackhost_warn "PyYAML is not currently installed. Update will install it if pip permits."

    if ! blackhost_confirm "Create/update the blackhost YAML virtualenv and update PyYAML now?"; then
        blackhost_fail "PyYAML update skipped."
        return 1
    fi

    blackhost_run_cmd python3 -m venv "$BLACKHOST_YAML_VENV_PATH" || return 1
    blackhost_run_cmd "$BLACKHOST_YAML_VENV_PATH/bin/python" -m pip install --upgrade pip PyYAML || return 1

    blackhost_dry_run_summary "YAML tooling update"

    blackhost_section "Post-Update Check"
    blackhost_yaml_print_pyyaml_version || true

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "PyYAML update dry-run completed. Run without --dry-run to apply the printed commands."
    elif blackhost_yaml_pyyaml_available; then
        blackhost_ok "PyYAML update path completed."
        blackhost_info "Next step: scripts/core/init.sh yaml check --verbose"
    else
        blackhost_warn "PyYAML update command completed, but python3 still cannot import yaml."
        blackhost_warn "Review pip output above, then rerun scripts/core/init.sh yaml check."
    fi
}
