#!/usr/bin/env bash

blackhost_package_install_help() {
    cat <<'HELP'
blackhost package install

Installs package tooling on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] package install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_package_install() {
    local script_name="blackhost package install"

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
                blackhost_package_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Package Installation"
    blackhost_info "This script installs package tooling for local development work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_package_cli_available; then
        blackhost_ok "Package tooling is already installed."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh package update if you want to refresh the installation."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    case "$BLACKHOST_OS" in
        macos)
            if blackhost_confirm "Install package tooling on macOS now?"; then
                blackhost_run_cmd package-manager install package
            else
                blackhost_fail "Package install skipped."
                return 1
            fi
            ;;
        linux)
            if blackhost_confirm "Install package tooling on Linux now?"; then
                blackhost_run_cmd sudo package-manager install package
            else
                blackhost_fail "Package install skipped."
                return 1
            fi
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Package installation"
}
