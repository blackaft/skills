#!/usr/bin/env bash

blackhost_php_update_help() {
    cat <<'HELP'
blackhost php update

Updates PHP CLI, common PHP extensions, and Composer on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] php update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: upgrades php and composer formulae.
  Debian/Ubuntu Linux: upgrades PHP CLI, common extensions, Composer, unzip, and git through apt.
HELP
}

blackhost_php_update() {
    local script_name="blackhost php update"

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
                blackhost_php_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "PHP and Composer Update"
    blackhost_info "This script updates PHP CLI tooling, Composer, and common PHP extensions for local development work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    fi

    if ! blackhost_php_cli_available && ! blackhost_composer_available; then
        if [ "$BLACKHOST_DRY_RUN" = true ]; then
            blackhost_warn "Neither PHP nor Composer is installed. Dry-run mode will still print the update path for review."
        else
            blackhost_fail "Neither PHP nor Composer is installed."
            blackhost_warn "Run scripts/core/init.sh php install before scripts/core/init.sh php update."
            return 1
        fi
    fi

    if blackhost_php_cli_available; then
        blackhost_info "Current PHP CLI: $(php --version 2>/dev/null | sed -n '1p')"
    else
        blackhost_warn "PHP CLI is not installed. Update may not install missing packages; use php install if needed."
    fi

    if blackhost_composer_available; then
        blackhost_info "Current Composer: $(composer --version 2>/dev/null | sed -n '1p')"
    else
        blackhost_warn "Composer is not installed. Update may not install missing packages; use php install if needed."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_php_update_macos
            ;;
        linux)
            blackhost_php_update_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Update PHP and Composer manually for this host, then run scripts/core/init.sh php check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "PHP and Composer update"
    blackhost_php_update_diagnostics
}

blackhost_php_update_macos() {
    blackhost_section "macOS Update Path"

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Update PHP and Composer manually, then run scripts/core/init.sh php check."
        return 1
    fi

    if blackhost_confirm "Upgrade PHP and Composer with Homebrew now?"; then
        blackhost_run_cmd brew update
        blackhost_run_cmd brew upgrade php composer
    else
        blackhost_warn "PHP and Composer upgrade skipped."
    fi
}

blackhost_php_update_linux() {
    blackhost_section "Linux Update Path"
    blackhost_info "Distribution: $BLACKHOST_OS_PRETTY"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic update."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Update PHP and Composer manually, then run scripts/core/init.sh php check."
        return 1
    fi

    blackhost_warn "This path uses sudo and upgrades packages through apt."
    if blackhost_confirm "Upgrade PHP CLI, common PHP extensions, Composer, unzip, and git now?"; then
        blackhost_run_cmd sudo apt-get update
        blackhost_run_cmd sudo apt-get install --only-upgrade -y php-cli php-common php-mbstring php-xml php-curl php-zip php-intl composer unzip git
    else
        blackhost_warn "PHP and Composer package upgrade skipped."
    fi
}

blackhost_php_update_diagnostics() {
    blackhost_section "Post-Update Diagnostics"

    blackhost_php_print_version || true
    blackhost_composer_print_version || true
    blackhost_php_print_extensions || true

    blackhost_section "Next Step"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "PHP and Composer update dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh php check --verbose"
    else
        blackhost_info "Run scripts/core/init.sh php check --verbose to confirm host readiness."
    fi
}
