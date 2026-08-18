#!/usr/bin/env bash

blackhost_homebrew_install_help() {
    cat <<'HELP'
blackhost homebrew install

Installs Homebrew on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] homebrew install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS: runs the official Homebrew install script.
  Linux: runs the official Homebrew install script.
HELP
}

blackhost_homebrew_install() {
    local script_name="blackhost homebrew install"

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
                blackhost_homebrew_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Homebrew Installation"
    blackhost_info "This script installs Homebrew for local package-manager workflows."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_homebrew_cli_available; then
        blackhost_ok "Homebrew is already installed."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh homebrew update if you want to refresh Homebrew."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    case "$BLACKHOST_OS" in
        macos|linux)
            blackhost_homebrew_install_unix
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Install Homebrew manually for this host, then run scripts/core/init.sh homebrew check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Homebrew installation"

    blackhost_section "Post-Install Check"
    blackhost_homebrew_print_version || true
    blackhost_homebrew_print_prefix || true
}

blackhost_homebrew_install_unix() {
    blackhost_section "Official Install Path"
    blackhost_warn "The Homebrew installer explains what it will do and may prompt during execution."

    if [ "$BLACKHOST_DRY_RUN" = false ] && ! command -v curl >/dev/null 2>&1; then
        blackhost_fail "curl is not installed or not on PATH."
        blackhost_warn "Install curl first, then rerun this script."
        return 1
    fi

    if blackhost_confirm "Run the official Homebrew install script now?"; then
        blackhost_run_shell '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    else
        blackhost_fail "Homebrew install skipped."
        return 1
    fi
}
