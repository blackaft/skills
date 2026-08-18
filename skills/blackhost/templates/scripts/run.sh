#!/usr/bin/env bash

blackhost_package_run_help() {
    cat <<'HELP'
blackhost package run

Runs package-managed local tooling with explicit prompts.

Usage:
  scripts/core/init.sh [--json] package run [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing run steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_package_run() {
    local script_name="blackhost package run"

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
                blackhost_package_run_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Package Run"
    blackhost_info "This script runs package-managed local tooling."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Commands will be printed but not executed."
    fi

    if ! blackhost_confirm "Run package tooling now?"; then
        blackhost_fail "Package run skipped."
        return 1
    fi

    blackhost_run_cmd package-manager run package
    blackhost_dry_run_summary "Package run"
}
