#!/usr/bin/env bash

blackhost_python_install_help() {
    cat <<'HELP'
blackhost python install

Installs Python 3, pip, and virtual environment support on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] python install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: installs python formula, including pip.
  Debian/Ubuntu Linux: installs python3, python3-pip, python3-venv, python3-dev, and build-essential through apt.
HELP
}

blackhost_python_install() {
    local script_name="blackhost python install"

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
                blackhost_python_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Python and pip Installation"
    blackhost_info "This script installs Python 3, pip, and virtual environment support for local development work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_python_cli_available && blackhost_python_pip_available && blackhost_python_venv_available; then
        blackhost_ok "Python 3, pip, and venv support are already installed."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh python update if you want to refresh the installation."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_python_install_macos
            ;;
        linux)
            blackhost_python_install_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Install Python and pip manually for this host, then run scripts/core/init.sh python check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Python and pip installation"
    blackhost_python_install_diagnostics
}

blackhost_python_install_macos() {
    blackhost_section "macOS Install Path"
    blackhost_info "Recommended local host path: Python installed through Homebrew."

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Install Homebrew first from https://brew.sh, then rerun this script."
        return 1
    fi

    blackhost_ok "Homebrew is available at $(command -v brew)."

    if blackhost_confirm "Install Python with Homebrew now?"; then
        blackhost_run_cmd brew install python
    else
        blackhost_fail "Python install skipped."
        return 1
    fi
}

blackhost_python_install_linux() {
    blackhost_section "Linux Install Path"
    blackhost_info "Distribution: $BLACKHOST_OS_PRETTY"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic installation."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Install Python and pip manually, then run scripts/core/init.sh python check."
        return 1
    fi

    blackhost_warn "This path uses sudo and installs packages through apt."
    if ! blackhost_confirm "Install Python 3, pip, venv support, headers, and build tools now?"; then
        blackhost_fail "Python and pip install skipped."
        return 1
    fi

    blackhost_run_cmd sudo apt-get update
    blackhost_run_cmd sudo apt-get install -y python3 python3-pip python3-venv python3-dev build-essential
}

blackhost_python_install_diagnostics() {
    blackhost_section "Post-Install Check"

    blackhost_python_print_version || true
    blackhost_python_print_pip_version || true

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Python and pip installation dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh python check --verbose"
    elif blackhost_python_cli_available && blackhost_python_pip_available; then
        blackhost_ok "Python and pip install path completed."
        blackhost_info "Next step: scripts/core/init.sh python check --verbose"
    else
        blackhost_warn "Python and pip install path completed, but tooling is not fully ready yet."
        blackhost_warn "Review PATH and shell startup files, then run scripts/core/init.sh python check."
    fi
}
