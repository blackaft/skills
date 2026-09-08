#!/usr/bin/env bash

blackhost_gh_check_help() {
    cat <<'HELP'
blackhost gh check

Checks whether GitHub CLI is installed and authenticated.

Usage:
  scripts/core/init.sh [--json] gh check [--hostname github.com] [--yes] [--verbose]

Options:
  --json            Append a compact machine-readable result object.
  --hostname VALUE  GitHub hostname to inspect. Defaults to github.com.
  -y, --yes         Do not pause for the final acknowledgement prompt.
  -v, --verbose     Print gh auth status output.
  -h, --help        Show this help text.
HELP
}

blackhost_gh_check() {
    local script_name="blackhost gh check"
    local hostname="github.com"
    local verbose=false
    local gh_available=false
    local auth_available=false

    BLACKHOST_ASSUME_YES=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --hostname)
                shift
                hostname="${1:-}"
                ;;
            --hostname=*)
                hostname="${1#--hostname=}"
                ;;
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -v|--verbose)
                verbose=true
                ;;
            -h|--help)
                blackhost_gh_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $1" >&2
                return 2
                ;;
        esac
        shift
    done

    hostname="${hostname:-github.com}"

    blackhost_section "GitHub CLI Readiness Check"
    blackhost_info "This script does not install, update, or authenticate GitHub CLI."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"
    blackhost_info "GitHub hostname: $hostname"

    blackhost_section "GitHub CLI"
    if blackhost_gh_print_version; then
        gh_available=true
        blackhost_info "gh binary: $(command -v gh)"
    else
        blackhost_warn "Install GitHub CLI before attempting GitHub account workflows."
    fi

    blackhost_section "Authentication"
    if [ "$gh_available" = true ]; then
        if [ "$verbose" = true ]; then
            if blackhost_gh_print_auth_status "$hostname"; then
                auth_available=true
            fi
        elif blackhost_gh_auth_available "$hostname"; then
            auth_available=true
            blackhost_ok "GitHub CLI is authenticated for $hostname."
        else
            blackhost_fail "GitHub CLI is not authenticated for $hostname."
            blackhost_warn "Run scripts/core/init.sh gh auth --hostname $hostname."
        fi
    else
        blackhost_warn "Skipping auth check because gh is not installed."
    fi

    blackhost_section "Summary"
    if [ "$gh_available" = true ] && [ "$auth_available" = true ]; then
        blackhost_ok "GitHub CLI host tooling is ready."
        blackhost_ack "Review the GitHub CLI readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "GitHub CLI host tooling is not fully ready."
    blackhost_warn "Recommended next step: install gh or run scripts/core/init.sh gh auth."
    blackhost_ack "Review the GitHub CLI readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
