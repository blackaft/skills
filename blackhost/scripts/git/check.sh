#!/usr/bin/env bash

blackhost_git_check_help() {
    cat <<'HELP'
blackhost git check

Checks whether the host is ready for Git workflows.

Usage:
  scripts/core/init.sh [--json] git check [--yes] [--verbose]

Options:
  --json         Append a compact machine-readable result object.
  -y, --yes      Do not pause for the final acknowledgement prompt.
  -v, --verbose  Print repository and global identity details when available.
  -h, --help     Show this help text.
HELP
}

blackhost_git_check() {
    local script_name="blackhost git check"
    local verbose=false
    local git_available=false

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
                blackhost_git_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Git Host Readiness Check"
    blackhost_info "This script does not install or change Git."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    blackhost_section "Git CLI"
    if blackhost_git_print_version; then
        git_available=true
        blackhost_info "Git binary: $(command -v git)"
    else
        blackhost_warn "Install Git before attempting source control workflows."
    fi

    if [ "$verbose" = true ] && [ "$git_available" = true ]; then
        blackhost_section "Git Context"
        blackhost_git_print_repo || true
        blackhost_git_print_identity || true
    fi

    blackhost_section "Summary"
    if [ "$git_available" = true ]; then
        blackhost_ok "Git host tooling is ready."
        blackhost_ack "Review the Git readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "Git host tooling is not ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh git install."
    blackhost_ack "Review the Git readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
