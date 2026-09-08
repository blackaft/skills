#!/usr/bin/env bash

blackhost_python_update_help() {
    cat <<'HELP'
blackhost python update

Updates Python 3, pip, and virtual environment support on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] python update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: upgrades python formula.
  Debian/Ubuntu Linux: upgrades python3, python3-pip, python3-venv, python3-dev, and build-essential through apt.
HELP
}

blackhost_python_update() {
    local script_name="blackhost python update"

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
                blackhost_python_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Python and pip Update"
    blackhost_info "This script updates Python 3, pip, and virtual environment support for local development work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    fi

    if ! blackhost_python_cli_available && ! blackhost_python_pip_available; then
        if [ "$BLACKHOST_DRY_RUN" = true ]; then
            blackhost_warn "Neither Python 3 nor pip is installed. Dry-run mode will still print the update path for review."
        else
            blackhost_fail "Neither Python 3 nor pip is installed."
            blackhost_warn "Run scripts/core/init.sh python install before scripts/core/init.sh python update."
            return 1
        fi
    fi

    if blackhost_python_cli_available; then
        blackhost_info "Current Python: $(python3 --version 2>&1)"
    else
        blackhost_warn "Python 3 is not installed. Update may not install missing packages; use python install if needed."
    fi

    if blackhost_python_pip_available; then
        blackhost_info "Current pip: $(python3 -m pip --version 2>&1)"
    else
        blackhost_warn "pip is not installed. Update may not install missing packages; use python install if needed."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_python_update_macos
            ;;
        linux)
            blackhost_python_update_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Update Python and pip manually for this host, then run scripts/core/init.sh python check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Python and pip update"
    blackhost_python_update_diagnostics
}

blackhost_python_update_macos() {
    blackhost_section "macOS Update Path"

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Update Python manually, then run scripts/core/init.sh python check."
        return 1
    fi

    if blackhost_confirm "Upgrade Python with Homebrew now?"; then
        blackhost_run_cmd brew update
        blackhost_run_cmd brew upgrade python
    else
        blackhost_warn "Python upgrade skipped."
    fi
}

blackhost_python_update_linux() {
    blackhost_section "Linux Update Path"
    blackhost_info "Distribution: $BLACKHOST_OS_PRETTY"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic update."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Update Python and pip manually, then run scripts/core/init.sh python check."
        return 1
    fi

    blackhost_warn "This path uses sudo and upgrades packages through apt."
    if blackhost_confirm "Upgrade Python 3, pip, venv support, headers, and build tools now?"; then
        blackhost_run_cmd sudo apt-get update
        blackhost_run_cmd sudo apt-get install --only-upgrade -y python3 python3-pip python3-venv python3-dev build-essential
    else
        blackhost_warn "Python and pip package upgrade skipped."
    fi
}

blackhost_python_update_diagnostics() {
    blackhost_section "Post-Update Diagnostics"

    blackhost_python_print_version || true
    blackhost_python_print_pip_version || true
    blackhost_python_print_module_checks || true

    blackhost_section "Next Step"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Python and pip update dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh python check --verbose"
    else
        blackhost_info "Run scripts/core/init.sh python check --verbose to confirm host readiness."
    fi
}
