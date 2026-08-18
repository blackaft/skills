#!/usr/bin/env bash

blackhost_node_update_help() {
    cat <<'HELP'
blackhost node update

Updates Node.js, npm, and npx on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] node update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: updates node formula.
  Debian/Ubuntu Linux: upgrades nodejs and npm through apt.
HELP
}

blackhost_node_update() {
    local script_name="blackhost node update"

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
                blackhost_node_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Node.js Tooling Update"
    blackhost_info "This script updates Node.js, npm, and npx for local JavaScript development work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    elif ! blackhost_node_cli_available; then
        blackhost_fail "Node.js is not installed."
        blackhost_warn "Run scripts/core/init.sh node install before scripts/core/init.sh node update."
        return 1
    fi

    blackhost_node_print_version || true
    blackhost_node_print_npm_version || true
    blackhost_node_print_npx_version || true

    case "$BLACKHOST_OS" in
        macos)
            blackhost_node_update_macos
            ;;
        linux)
            blackhost_node_update_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Update Node.js manually for this host, then run scripts/core/init.sh node check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Node.js tooling update"
    blackhost_node_update_diagnostics
}

blackhost_node_update_macos() {
    blackhost_section "macOS Update Path"

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Update Node.js manually, then run scripts/core/init.sh node check."
        return 1
    fi

    if blackhost_confirm "Upgrade Node.js with Homebrew now?"; then
        blackhost_run_cmd brew update
        blackhost_run_cmd brew upgrade node
    else
        blackhost_warn "Node.js upgrade skipped."
    fi
}

blackhost_node_update_linux() {
    blackhost_section "Linux Update Path"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic update."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Update Node.js manually, then run scripts/core/init.sh node check."
        return 1
    fi

    blackhost_warn "This path uses sudo and upgrades packages through apt."
    if blackhost_confirm "Upgrade Node.js and npm now?"; then
        blackhost_run_cmd sudo apt-get update
        blackhost_run_cmd sudo apt-get install --only-upgrade -y nodejs npm
    else
        blackhost_warn "Node.js upgrade skipped."
    fi
}

blackhost_node_update_diagnostics() {
    blackhost_section "Post-Update Check"

    blackhost_node_print_version || true
    blackhost_node_print_npm_version || true
    blackhost_node_print_npx_version || true

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Node.js update dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh node check --verbose"
    elif blackhost_node_cli_available && blackhost_node_npm_available && blackhost_node_npx_available; then
        blackhost_ok "Node.js tooling update path completed."
        blackhost_info "Next step: scripts/core/init.sh node check --verbose"
    else
        blackhost_warn "Node.js update path completed, but tooling is not fully ready yet."
        blackhost_warn "Review PATH and shell startup files, then run scripts/core/init.sh node check."
    fi
}
