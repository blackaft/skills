#!/usr/bin/env bash

blackhost_aws_update_help() {
    cat <<'HELP'
blackhost aws update

Updates AWS CLI v2 with explicit prompts.

Usage:
  scripts/core/init.sh [--json] aws update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_aws_update() {
    local script_name="blackhost aws update"

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
                blackhost_aws_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "AWS CLI Update"
    blackhost_info "This script updates AWS CLI v2 for local AWS account and deployment workflows."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    elif ! blackhost_aws_cli_available; then
        blackhost_fail "AWS CLI is not installed."
        blackhost_warn "Run scripts/core/init.sh aws install before scripts/core/init.sh aws update."
        return 1
    fi

    blackhost_aws_print_version || true

    if blackhost_confirm "Run aws update now?"; then
        blackhost_run_cmd aws update
    else
        blackhost_warn "AWS CLI update skipped."
    fi

    blackhost_dry_run_summary "AWS CLI update"

    blackhost_section "Post-Update Check"
    blackhost_aws_print_version || true
}
