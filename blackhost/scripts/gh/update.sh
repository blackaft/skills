#!/usr/bin/env bash

blackhost_gh_update_help() {
    cat <<'HELP'
blackhost gh update

Updates GitHub CLI on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] gh update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_gh_update() {
    local script_name="blackhost gh update"

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
                blackhost_gh_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "GitHub CLI Update"
    blackhost_info "This script updates GitHub CLI for local GitHub account and repository workflows."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    elif ! blackhost_gh_cli_available; then
        blackhost_fail "GitHub CLI is not installed."
        blackhost_warn "Run scripts/core/init.sh gh install before scripts/core/init.sh gh update."
        return 1
    fi

    blackhost_gh_print_version || true

    case "$BLACKHOST_OS" in
        macos)
            blackhost_gh_update_macos
            ;;
        linux)
            blackhost_gh_update_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Update GitHub CLI manually for this host, then run scripts/core/init.sh gh check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "GitHub CLI update"

    blackhost_section "Post-Update Check"
    blackhost_gh_print_version || true
}

blackhost_gh_update_macos() {
    blackhost_section "macOS Update Path"

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Update GitHub CLI manually, then run scripts/core/init.sh gh check."
        return 1
    fi

    if blackhost_confirm "Upgrade GitHub CLI with Homebrew now?"; then
        blackhost_run_cmd brew update
        blackhost_run_cmd brew upgrade gh
    else
        blackhost_warn "GitHub CLI upgrade skipped."
    fi
}

blackhost_gh_update_linux() {
    blackhost_section "Linux Update Path"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic update."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Update GitHub CLI manually, then run scripts/core/init.sh gh check."
        return 1
    fi

    blackhost_warn "This path uses sudo and upgrades packages through apt."
    if blackhost_confirm "Upgrade GitHub CLI now?"; then
        blackhost_run_cmd sudo apt-get update
        blackhost_run_cmd sudo apt-get install --only-upgrade -y gh
    else
        blackhost_warn "GitHub CLI upgrade skipped."
    fi
}
