#!/usr/bin/env bash

blackhost_node_install_help() {
    cat <<'HELP'
blackhost node install

Installs Node.js, npm, and npx on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] node install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: installs node formula, which includes npm and npx.
  Debian/Ubuntu Linux: installs nodejs and npm through apt.
HELP
}

blackhost_node_install() {
    local script_name="blackhost node install"

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
                blackhost_node_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Node.js Tooling Installation"
    blackhost_info "This script installs Node.js, npm, and npx for local JavaScript development work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_node_cli_available && blackhost_node_npm_available && blackhost_node_npx_available; then
        blackhost_ok "Node.js, npm, and npx are already installed."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh node update if you want to refresh the installation."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_node_install_macos
            ;;
        linux)
            blackhost_node_install_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Install Node.js manually for this host, then run scripts/core/init.sh node check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Node.js tooling installation"
    blackhost_node_install_diagnostics
}

blackhost_node_install_macos() {
    blackhost_section "macOS Install Path"
    blackhost_info "Recommended local host path: Node.js installed through Homebrew."

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Install Homebrew first from https://brew.sh, then rerun this script."
        return 1
    fi

    blackhost_ok "Homebrew is available at $(command -v brew)."

    if blackhost_confirm "Install Node.js with Homebrew now?"; then
        blackhost_run_cmd brew install node
    else
        blackhost_fail "Node.js install skipped."
        return 1
    fi
}

blackhost_node_install_linux() {
    blackhost_section "Linux Install Path"
    blackhost_info "Distribution: $BLACKHOST_OS_PRETTY"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic installation."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Install Node.js manually, then run scripts/core/init.sh node check."
        return 1
    fi

    blackhost_warn "This path uses sudo and installs packages through apt."
    if ! blackhost_confirm "Install Node.js and npm now?"; then
        blackhost_fail "Node.js install skipped."
        return 1
    fi

    blackhost_run_cmd sudo apt-get update
    blackhost_run_cmd sudo apt-get install -y nodejs npm
}

blackhost_node_install_diagnostics() {
    blackhost_section "Post-Install Check"

    blackhost_node_print_version || true
    blackhost_node_print_npm_version || true
    blackhost_node_print_npx_version || true

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Node.js installation dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh node check --verbose"
    elif blackhost_node_cli_available && blackhost_node_npm_available && blackhost_node_npx_available; then
        blackhost_ok "Node.js tooling install path completed."
        blackhost_info "Next step: scripts/core/init.sh node check --verbose"
    else
        blackhost_warn "Node.js install path completed, but tooling is not fully ready yet."
        blackhost_warn "Review PATH and shell startup files, then run scripts/core/init.sh node check."
    fi
}
