#!/usr/bin/env bash

blackhost_yaml_check_help() {
    cat <<'HELP'
blackhost yaml check

Checks whether Python can import PyYAML for YAML-backed tooling.

Usage:
  scripts/core/init.sh [--json] yaml check [--yes] [--verbose]

Options:
  --json         Append a compact machine-readable result object.
  -y, --yes      Do not pause for the final acknowledgement prompt.
  -v, --verbose  Print Python and PyYAML import details when available.
  -h, --help     Show this help text.
HELP
}

blackhost_yaml_check() {
    local script_name="blackhost yaml check"
    local verbose=false
    local python_available=false
    local pip_available=false
    local pyyaml_available=false

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
                blackhost_yaml_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "YAML Host Readiness Check"
    blackhost_info "This script does not install or change YAML tooling."
    blackhost_info "It checks python3, pip, and PyYAML import readiness."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"
    blackhost_info "Managed virtualenv: $BLACKHOST_YAML_VENV_PATH"
    blackhost_info "YAML Python: $(blackhost_yaml_python_bin)"

    blackhost_section "Python 3"
    if blackhost_yaml_print_python_version; then
        python_available=true
        blackhost_info "Python binary: $(command -v python3)"
    else
        blackhost_warn "Install Python 3 before attempting YAML package workflows."
    fi

    blackhost_section "pip"
    if blackhost_yaml_print_pip_version; then
        pip_available=true
    else
        blackhost_warn "Install pip before attempting PyYAML installation."
    fi

    blackhost_section "PyYAML"
    if blackhost_yaml_print_pyyaml_version; then
        pyyaml_available=true
    else
        blackhost_warn "Install PyYAML before running YAML-backed Python validators."
    fi

    if [ "$verbose" = true ] && [ "$pyyaml_available" = true ]; then
        blackhost_section "Verbose PyYAML Details"
        "$(blackhost_yaml_python_bin)" -c 'import yaml; print("       file=" + str(getattr(yaml, "__file__", ""))); print("       version=" + str(getattr(yaml, "__version__", "")))'
    fi

    blackhost_section "Summary"
    if [ "$python_available" = true ] && [ "$pip_available" = true ] && [ "$pyyaml_available" = true ]; then
        blackhost_ok "YAML tooling is ready."
        blackhost_ack "Review the YAML readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "YAML tooling is not fully ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh yaml install."
    blackhost_ack "Review the YAML readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
