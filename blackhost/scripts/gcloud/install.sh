#!/usr/bin/env bash

blackhost_gcloud_install_help() {
    cat <<'HELP'
blackhost gcloud install

Installs Google Cloud CLI on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] gcloud install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: installs google-cloud-sdk cask.
  Debian/Ubuntu Linux: configures Google Cloud apt repository and installs google-cloud-cli.
HELP
}

blackhost_gcloud_install() {
    local script_name="blackhost gcloud install"

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
                blackhost_gcloud_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Google Cloud CLI Installation"
    blackhost_info "This script installs Google Cloud CLI for local Google Cloud account and deployment workflows."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_gcloud_cli_available; then
        blackhost_ok "Google Cloud CLI is already installed."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh gcloud update if you want to refresh the installation."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_gcloud_install_macos
            ;;
        linux)
            blackhost_gcloud_install_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Install Google Cloud CLI manually for this host, then run scripts/core/init.sh gcloud check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Google Cloud CLI installation"

    blackhost_section "Post-Install Check"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Google Cloud CLI installation dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh gcloud check --verbose"
    else
        blackhost_gcloud_print_version || true
    fi
}

blackhost_gcloud_install_macos() {
    blackhost_section "macOS Install Path"
    blackhost_info "Recommended local host path: Google Cloud CLI installed through Homebrew."

    if ! command -v brew >/dev/null 2>&1 && [ "$BLACKHOST_DRY_RUN" = false ]; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Install Homebrew first with scripts/core/init.sh homebrew install, then rerun this script."
        return 1
    fi

    if command -v brew >/dev/null 2>&1; then
        blackhost_ok "Homebrew is available at $(command -v brew)."
    else
        blackhost_warn "Homebrew is not available; dry-run will still print the install command."
    fi

    if blackhost_confirm "Install Google Cloud CLI with Homebrew now?"; then
        blackhost_run_cmd brew install --cask google-cloud-sdk
    else
        blackhost_fail "Google Cloud CLI install skipped."
        return 1
    fi
}

blackhost_gcloud_install_linux() {
    blackhost_section "Linux Install Path"
    blackhost_info "Distribution: $BLACKHOST_OS_PRETTY"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic installation."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Install Google Cloud CLI manually, then run scripts/core/init.sh gcloud check."
        return 1
    fi

    blackhost_warn "This path uses sudo, curl, gpg, and apt."
    if ! blackhost_confirm "Configure Google's apt repository and install Google Cloud CLI now?"; then
        blackhost_fail "Google Cloud CLI install skipped."
        return 1
    fi

    blackhost_run_cmd sudo apt-get update
    blackhost_run_cmd sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
    blackhost_run_shell "curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg"
    blackhost_run_shell 'echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null'
    blackhost_run_cmd sudo apt-get update
    blackhost_run_cmd sudo apt-get install -y google-cloud-cli
}
