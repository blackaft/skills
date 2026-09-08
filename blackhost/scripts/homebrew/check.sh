#!/usr/bin/env bash

blackhost_homebrew_check_help() {
    cat <<'HELP'
blackhost homebrew check

Checks whether the host is ready for Homebrew package-manager workflows.

Usage:
  scripts/core/init.sh [--json] homebrew check [--yes] [--verbose]

Options:
  --json         Append a compact machine-readable result object.
  -y, --yes      Do not pause for the final acknowledgement prompt.
  -v, --verbose  Print Homebrew prefix and doctor diagnostics when available.
  -h, --help     Show this help text.
HELP
}

blackhost_homebrew_check() {
    local script_name="blackhost homebrew check"
    local verbose=false
    local brew_available=false

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
                blackhost_homebrew_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Homebrew Host Readiness Check"
    blackhost_info "This script does not install, update, or change Homebrew."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    blackhost_section "Homebrew"
    if blackhost_homebrew_print_version; then
        brew_available=true
        blackhost_homebrew_print_prefix || true
    else
        blackhost_warn "Install Homebrew before using Homebrew-backed package workflows."
    fi

    if [ "$verbose" = true ] && [ "$brew_available" = true ]; then
        blackhost_section "Verbose Homebrew Diagnostics"
        brew doctor 2>&1 | sed 's/^/       /' || blackhost_warn "brew doctor reported warnings."
    fi

    blackhost_section "Summary"
    if [ "$brew_available" = true ]; then
        blackhost_ok "Homebrew host tooling is ready."
        blackhost_ack "Review the Homebrew readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "Homebrew host tooling is not ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh homebrew install."
    blackhost_ack "Review the Homebrew readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
