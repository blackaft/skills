#!/usr/bin/env bash

blackhost_gh_install_help() {
    cat <<'HELP'
blackhost gh install

Installs GitHub CLI on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] gh install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: installs gh formula.
  Debian/Ubuntu Linux: configures GitHub CLI apt repository and installs gh.
HELP
}

blackhost_gh_install() {
    local script_name="blackhost gh install"

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
                blackhost_gh_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "GitHub CLI Installation"
    blackhost_info "This script installs GitHub CLI for local GitHub account and repository workflows."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_gh_cli_available; then
        blackhost_ok "GitHub CLI is already installed."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh gh update if you want to refresh the installation."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_gh_install_macos
            ;;
        linux)
            blackhost_gh_install_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Install GitHub CLI manually for this host, then run scripts/core/init.sh gh check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "GitHub CLI installation"

    blackhost_section "Post-Install Check"
    blackhost_gh_print_version || true
}

blackhost_gh_install_macos() {
    blackhost_section "macOS Install Path"

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Install Homebrew first from https://brew.sh, then rerun this script."
        return 1
    fi

    if blackhost_confirm "Install GitHub CLI with Homebrew now?"; then
        blackhost_run_cmd brew install gh
    else
        blackhost_fail "GitHub CLI install skipped."
        return 1
    fi
}

blackhost_gh_install_linux() {
    blackhost_section "Linux Install Path"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic installation."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Install GitHub CLI manually, then run scripts/core/init.sh gh check."
        return 1
    fi

    blackhost_warn "This path uses sudo, curl, and apt."
    if ! blackhost_confirm "Configure the GitHub CLI apt repository and install gh now?"; then
        blackhost_fail "GitHub CLI install skipped."
        return 1
    fi

    blackhost_run_cmd sudo mkdir -p -m 755 /etc/apt/keyrings
    blackhost_run_shell "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null"
    blackhost_run_cmd sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    blackhost_run_shell 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null'
    blackhost_run_cmd sudo apt-get update
    blackhost_run_cmd sudo apt-get install -y gh
}
