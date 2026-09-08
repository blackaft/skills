#!/usr/bin/env bash

blackhost_git_update_help() {
    cat <<'HELP'
blackhost git update

Updates Git on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] git update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_git_update() {
    local script_name="blackhost git update"

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
                blackhost_git_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Git Update"
    blackhost_info "This script updates Git for local source control work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    elif ! blackhost_git_cli_available; then
        blackhost_fail "Git is not installed."
        blackhost_warn "Run scripts/core/init.sh git install before scripts/core/init.sh git update."
        return 1
    fi

    blackhost_git_print_version || true

    case "$BLACKHOST_OS" in
        macos)
            blackhost_git_update_macos
            ;;
        linux)
            blackhost_git_update_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Update Git manually for this host, then run scripts/core/init.sh git check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Git update"

    blackhost_section "Post-Update Check"
    blackhost_git_print_version || true
}

blackhost_git_update_macos() {
    blackhost_section "macOS Update Path"

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Update Git manually, then run scripts/core/init.sh git check."
        return 1
    fi

    if blackhost_confirm "Upgrade Git with Homebrew now?"; then
        blackhost_run_cmd brew update
        blackhost_run_cmd brew upgrade git
    else
        blackhost_warn "Git upgrade skipped."
    fi
}

blackhost_git_update_linux() {
    blackhost_section "Linux Update Path"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic update."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Update Git manually, then run scripts/core/init.sh git check."
        return 1
    fi

    blackhost_warn "This path uses sudo and upgrades packages through apt."
    if blackhost_confirm "Upgrade Git now?"; then
        blackhost_run_cmd sudo apt-get update
        blackhost_run_cmd sudo apt-get install --only-upgrade -y git
    else
        blackhost_warn "Git upgrade skipped."
    fi
}
