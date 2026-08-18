#!/usr/bin/env bash

blackhost_homebrew_update_help() {
    cat <<'HELP'
blackhost homebrew update

Updates Homebrew metadata and installed formulae/casks with explicit prompts.

Usage:
  scripts/core/init.sh [--json] homebrew update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_homebrew_update() {
    local script_name="blackhost homebrew update"

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
                blackhost_homebrew_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Homebrew Update"
    blackhost_info "This script updates Homebrew metadata and installed Homebrew packages."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    elif ! blackhost_homebrew_cli_available; then
        blackhost_fail "Homebrew is not installed."
        blackhost_warn "Run scripts/core/init.sh homebrew install before scripts/core/init.sh homebrew update."
        return 1
    fi

    blackhost_homebrew_print_version || true

    if blackhost_confirm "Run brew update and brew upgrade now?"; then
        blackhost_run_cmd brew update
        blackhost_run_cmd brew upgrade
    else
        blackhost_warn "Homebrew update skipped."
    fi

    blackhost_dry_run_summary "Homebrew update"

    blackhost_section "Post-Update Check"
    blackhost_homebrew_print_version || true
}
