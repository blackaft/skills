#!/usr/bin/env bash

blackhost_package_check_help() {
    cat <<'HELP'
blackhost package check

Checks whether the host is ready to run package workloads.

Usage:
  scripts/core/init.sh [--json] package check [--yes] [--verbose]

Options:
  --json         Append a compact machine-readable result object.
  -y, --yes      Do not pause for the final acknowledgement prompt.
  -v, --verbose  Print extra diagnostic output when available.
  -h, --help     Show this help text.
HELP
}

blackhost_package_check() {
    local script_name="blackhost package check"
    local verbose=false
    local package_available=false

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
                blackhost_package_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Package Host Readiness Check"
    blackhost_info "This script does not install or change anything."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    blackhost_section "Package CLI"
    if blackhost_package_print_version; then
        package_available=true
    fi

    if [ "$verbose" = true ]; then
        blackhost_section "Verbose Diagnostics"
        blackhost_info "Add package-specific diagnostics here."
    fi

    blackhost_section "Summary"
    if [ "$package_available" = true ]; then
        blackhost_ok "Package host tooling is ready."
        blackhost_ack "Review the readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "Package host tooling is not fully ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh package install or scripts/core/init.sh package update as appropriate."
    blackhost_ack "Review the readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
