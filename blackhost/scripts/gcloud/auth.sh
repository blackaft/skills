#!/usr/bin/env bash

blackhost_gcloud_auth_help() {
    cat <<'HELP'
blackhost gcloud auth

Starts Google Cloud CLI browser authentication and validates active account state.

Usage:
  scripts/core/init.sh [--json] gcloud auth [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print the browser auth command without executing it.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_gcloud_auth() {
    local script_name="blackhost gcloud auth"

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
                blackhost_gcloud_auth_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Google Cloud CLI Browser Authentication"
    blackhost_info "This command starts Google Cloud CLI browser-based authentication."
    blackhost_info "Dry-run mode: $BLACKHOST_DRY_RUN"
    blackhost_warn "Google Cloud CLI may open a browser, or print a URL that you must open manually."
    blackhost_warn "Complete the browser validation, then return to this terminal for the final status."

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Authentication commands will be printed but not executed."
    elif ! blackhost_gcloud_cli_available; then
        blackhost_fail "Google Cloud CLI is not installed."
        blackhost_warn "Run scripts/core/init.sh gcloud install first, then rerun this command."
        return 1
    fi

    if blackhost_gcloud_auth_available && [ "$BLACKHOST_DRY_RUN" = false ]; then
        blackhost_ok "Google Cloud CLI is already authenticated."
        blackhost_gcloud_print_auth_status || true
        return 0
    fi

    if ! blackhost_confirm "Start Google Cloud browser authentication now?"; then
        blackhost_fail "Google Cloud authentication skipped."
        return 1
    fi

    blackhost_run_cmd gcloud auth login
    blackhost_dry_run_summary "Google Cloud CLI authentication"

    blackhost_section "Authentication Summary"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_ok "Dry-run completed. No browser authentication was started."
        blackhost_info "Run without --dry-run to authenticate."
    elif blackhost_gcloud_print_auth_status; then
        blackhost_ok "Google Cloud CLI authentication completed."
    else
        blackhost_fail "Google Cloud CLI still has no active account."
        blackhost_warn "Review the gcloud output above and rerun scripts/core/init.sh gcloud auth."
        return 1
    fi
}
