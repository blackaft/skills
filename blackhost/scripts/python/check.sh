#!/usr/bin/env bash

blackhost_python_check_help() {
    cat <<'HELP'
blackhost python check

Checks whether the host is ready to run Python and pip workloads.

Usage:
  scripts/core/init.sh [--json] python check [--yes] [--verbose]

Options:
  --json         Append a compact machine-readable result object.
  -y, --yes      Do not pause for the final acknowledgement prompt.
  -v, --verbose  Print extra Python and pip diagnostic output when available.
  -h, --help     Show this help text.
HELP
}

blackhost_python_check() {
    local script_name="blackhost python check"
    local verbose=false
    local python_available=false
    local pip_available=false
    local modules_available=false

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
                blackhost_python_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Python Host Readiness Check"
    blackhost_info "This script does not install or change Python or pip."
    blackhost_info "It checks the local machine for Python 3, pip, venv support, and basic runtime execution."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    blackhost_section "Python 3"
    if blackhost_python_print_version; then
        python_available=true
        blackhost_info "Python binary: $(command -v python3)"
    else
        blackhost_warn "Install Python 3 before attempting Python application or pip workflows."
    fi

    blackhost_section "pip"
    if blackhost_python_print_pip_version; then
        pip_available=true
    else
        blackhost_warn "Install pip before Python dependency installation workflows."
    fi

    blackhost_section "Python Standard Modules"
    if [ "$python_available" = true ]; then
        if blackhost_python_print_module_checks; then
            modules_available=true
        else
            blackhost_warn "Missing standard modules may break package installation, TLS downloads, SQLite-backed tools, or virtual environments."
        fi
    else
        blackhost_warn "Skipping standard module checks because Python 3 is unavailable."
    fi

    blackhost_section "Runtime Smoke Capability"
    if [ "$python_available" = true ]; then
        if python3 -c 'import sys; print("Python runtime executed successfully: " + sys.version.split()[0])' >/dev/null 2>&1; then
            blackhost_ok "Python can execute inline runtime code."
        else
            blackhost_fail "Python 3 exists, but inline runtime execution failed."
        fi
    else
        blackhost_warn "Skipping runtime smoke test because Python 3 is unavailable."
    fi

    if [ "$verbose" = true ] && [ "$python_available" = true ]; then
        blackhost_section "Verbose Python Configuration"
        blackhost_python_print_executable || true
        python3 -m site 2>/dev/null | sed 's/^/       /' || blackhost_warn "Could not read Python site configuration."
    fi

    if [ "$verbose" = true ] && [ "$pip_available" = true ]; then
        blackhost_section "Verbose pip Configuration"
        python3 -m pip config list 2>/dev/null | sed 's/^/       /' || blackhost_warn "Could not read pip configuration."
    fi

    blackhost_section "Summary"
    if [ "$python_available" = true ] && [ "$pip_available" = true ] && [ "$modules_available" = true ]; then
        blackhost_ok "Python and pip host tooling is ready."
        blackhost_ack "Review the Python readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "Python and pip host tooling is not fully ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh python install or scripts/core/init.sh python update as appropriate."
    blackhost_ack "Review the Python readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
