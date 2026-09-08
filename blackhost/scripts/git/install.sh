#!/usr/bin/env bash

blackhost_git_install_help() {
    cat <<'HELP'
blackhost git install

Installs Git on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] git install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: installs git formula.
  Debian/Ubuntu Linux: installs git through apt.
HELP
}

blackhost_git_install() {
    local script_name="blackhost git install"

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
                blackhost_git_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Git Installation"
    blackhost_info "This script installs Git for local source control work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_git_cli_available; then
        blackhost_ok "Git is already installed."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh git update if you want to refresh the installation."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_git_install_macos
            ;;
        linux)
            blackhost_git_install_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Install Git manually for this host, then run scripts/core/init.sh git check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Git installation"

    blackhost_section "Post-Install Check"
    blackhost_git_print_version || true
}

blackhost_git_install_macos() {
    blackhost_section "macOS Install Path"

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Install Homebrew first from https://brew.sh, then rerun this script."
        return 1
    fi

    if blackhost_confirm "Install Git with Homebrew now?"; then
        blackhost_run_cmd brew install git
    else
        blackhost_fail "Git install skipped."
        return 1
    fi
}

blackhost_git_install_linux() {
    blackhost_section "Linux Install Path"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic installation."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Install Git manually, then run scripts/core/init.sh git check."
        return 1
    fi

    blackhost_warn "This path uses sudo and installs packages through apt."
    if ! blackhost_confirm "Install Git now?"; then
        blackhost_fail "Git install skipped."
        return 1
    fi

    blackhost_run_cmd sudo apt-get update
    blackhost_run_cmd sudo apt-get install -y git
}
