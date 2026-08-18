#!/usr/bin/env bash

blackhost_package_update_help() {
    cat <<'HELP'
blackhost package update

Updates package tooling on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] package update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_package_update() {
    local script_name="blackhost package update"

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
                blackhost_package_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Package Update"
    blackhost_info "This script updates package tooling for local development work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    fi

    if ! blackhost_package_cli_available; then
        if [ "$BLACKHOST_DRY_RUN" = true ]; then
            blackhost_warn "Package tooling is not installed. Dry-run mode will still print the update path for review."
        else
            blackhost_fail "Package tooling is not installed."
            blackhost_warn "Run scripts/core/init.sh package install before scripts/core/init.sh package update."
            return 1
        fi
    fi

    case "$BLACKHOST_OS" in
        macos)
            if blackhost_confirm "Update package tooling on macOS now?"; then
                blackhost_run_cmd package-manager update
                blackhost_run_cmd package-manager upgrade package
            else
                blackhost_warn "Package update skipped."
            fi
            ;;
        linux)
            if blackhost_confirm "Update package tooling on Linux now?"; then
                blackhost_run_cmd sudo package-manager update
                blackhost_run_cmd sudo package-manager install --only-upgrade package
            else
                blackhost_warn "Package update skipped."
            fi
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Package update"
}
