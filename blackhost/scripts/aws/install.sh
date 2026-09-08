#!/usr/bin/env bash

blackhost_aws_install_help() {
    cat <<'HELP'
blackhost aws install

Installs AWS CLI v2 on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] aws install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS: runs the official AWS CLI v2 install script for the current user.
  Linux: runs the official AWS CLI v2 install script for the current user.
HELP
}

blackhost_aws_install() {
    local script_name="blackhost aws install"

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
                blackhost_aws_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "AWS CLI Installation"
    blackhost_info "This script installs AWS CLI v2 for local AWS account and deployment workflows."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_aws_cli_available; then
        blackhost_ok "AWS CLI is already installed."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh aws update if you want to refresh the installation."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    case "$BLACKHOST_OS" in
        macos|linux)
            blackhost_aws_install_unix
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Install AWS CLI manually for this host, then run scripts/core/init.sh aws check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "AWS CLI installation"

    blackhost_section "Post-Install Check"
    blackhost_aws_print_version || true
}

blackhost_aws_install_unix() {
    blackhost_section "Official Install Path"
    blackhost_info "Recommended local host path: AWS CLI v2 official install script for the current user."

    if [ "$BLACKHOST_DRY_RUN" = false ] && ! command -v curl >/dev/null 2>&1; then
        blackhost_fail "curl is not installed or not on PATH."
        blackhost_warn "Install curl first, then rerun this script."
        return 1
    fi

    if blackhost_confirm "Run the official AWS CLI v2 install script now?"; then
        blackhost_run_shell 'curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash'
    else
        blackhost_fail "AWS CLI install skipped."
        return 1
    fi
}
