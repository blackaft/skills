#!/usr/bin/env bash

blackhost_package_auth_help() {
    cat <<'HELP'
blackhost package auth

Starts browser-based package authentication with explicit prompts.

Usage:
  scripts/core/init.sh [--json] package auth [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print authentication commands without executing them.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_package_auth() {
    local script_name="blackhost package auth"

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
                blackhost_package_auth_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Package Authentication"
    blackhost_info "This script is a template for browser-based authentication commands."
    blackhost_warn "The final package script should explain browser validation and post-auth checks explicitly."

    if ! blackhost_confirm "Start package authentication now?"; then
        blackhost_fail "Package authentication skipped."
        return 1
    fi

    blackhost_run_cmd package-cli auth login --web
    blackhost_dry_run_summary "Package authentication"
}
