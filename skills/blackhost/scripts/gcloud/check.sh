#!/usr/bin/env bash

blackhost_gcloud_check_help() {
    cat <<'HELP'
blackhost gcloud check

Checks whether the host is ready for Google Cloud CLI workflows.

Usage:
  scripts/core/init.sh [--json] gcloud check [--yes] [--verbose]

Options:
  --json         Append a compact machine-readable result object.
  -y, --yes      Do not pause for the final acknowledgement prompt.
  -v, --verbose  Print gcloud configuration details when available.
  -h, --help     Show this help text.
HELP
}

blackhost_gcloud_check() {
    local script_name="blackhost gcloud check"
    local verbose=false
    local cli_available=false
    local auth_available=false

    BLACKHOST_ASSUME_YES=false

    for arg in "$@"; do
        case "$arg" in
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -v|--verbose)
                verbose=true
                ;;
            -h|--help)
                blackhost_gcloud_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Google Cloud CLI Host Readiness Check"
    blackhost_info "This script does not install, update, or authenticate Google Cloud CLI."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    blackhost_section "Google Cloud CLI"
    if blackhost_gcloud_print_version; then
        cli_available=true
        blackhost_info "gcloud binary: $(command -v gcloud)"
    else
        blackhost_warn "Install Google Cloud CLI before attempting Google Cloud workflows."
    fi

    blackhost_section "Authentication"
    if [ "$cli_available" = true ] && blackhost_gcloud_print_auth_status; then
        auth_available=true
    elif [ "$cli_available" = true ]; then
        blackhost_warn "Run scripts/core/init.sh gcloud auth to start browser authentication."
    else
        blackhost_warn "Skipping authentication status because Google Cloud CLI is unavailable."
    fi

    if [ "$verbose" = true ] && [ "$cli_available" = true ]; then
        blackhost_section "Verbose Google Cloud Configuration"
        blackhost_gcloud_print_config
    fi

    blackhost_section "Summary"
    if [ "$cli_available" = true ] && [ "$auth_available" = true ]; then
        blackhost_ok "Google Cloud CLI host tooling is ready."
        blackhost_ack "Review the Google Cloud CLI readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "Google Cloud CLI host tooling is not fully ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh gcloud install or scripts/core/init.sh gcloud auth as appropriate."
    blackhost_ack "Review the Google Cloud CLI readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
