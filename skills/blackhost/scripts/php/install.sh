#!/usr/bin/env bash

blackhost_php_install_help() {
    cat <<'HELP'
blackhost php install

Installs PHP CLI, common PHP extensions, and Composer on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] php install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: installs php and composer formulae.
  Debian/Ubuntu Linux: installs PHP CLI, common extensions, Composer, unzip, and git through apt.
HELP
}

blackhost_php_install() {
    local script_name="blackhost php install"

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
                blackhost_php_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "PHP and Composer Installation"
    blackhost_info "This script installs PHP CLI tooling, Composer, and common PHP extensions for local development work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_php_cli_available && blackhost_composer_available; then
        blackhost_ok "PHP and Composer are already installed."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh php update if you want to refresh the installation."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_php_install_macos
            ;;
        linux)
            blackhost_php_install_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Install PHP and Composer manually for this host, then run scripts/core/init.sh php check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "PHP and Composer installation"
    blackhost_php_install_diagnostics
}

blackhost_php_install_macos() {
    blackhost_section "macOS Install Path"
    blackhost_info "Recommended local host path: PHP and Composer installed through Homebrew."

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Install Homebrew first from https://brew.sh, then rerun this script."
        return 1
    fi

    blackhost_ok "Homebrew is available at $(command -v brew)."

    if blackhost_confirm "Install PHP and Composer with Homebrew now?"; then
        blackhost_run_cmd brew install php composer
    else
        blackhost_fail "PHP and Composer install skipped."
        return 1
    fi
}

blackhost_php_install_linux() {
    blackhost_section "Linux Install Path"
    blackhost_info "Distribution: $BLACKHOST_OS_PRETTY"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic installation."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Install PHP and Composer manually, then run scripts/core/init.sh php check."
        return 1
    fi

    blackhost_warn "This path uses sudo and installs packages through apt."
    if ! blackhost_confirm "Install PHP CLI, common PHP extensions, Composer, unzip, and git now?"; then
        blackhost_fail "PHP and Composer install skipped."
        return 1
    fi

    blackhost_run_cmd sudo apt-get update
    blackhost_run_cmd sudo apt-get install -y php-cli php-common php-mbstring php-xml php-curl php-zip php-intl composer unzip git
}

blackhost_php_install_diagnostics() {
    blackhost_section "Post-Install Check"

    blackhost_php_print_version || true
    blackhost_composer_print_version || true

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "PHP and Composer installation dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh php check --verbose"
    elif blackhost_php_cli_available && blackhost_composer_available; then
        blackhost_ok "PHP and Composer install path completed."
        blackhost_info "Next step: scripts/core/init.sh php check --verbose"
    else
        blackhost_warn "PHP and Composer install path completed, but tooling is not fully ready yet."
        blackhost_warn "Review PATH and shell startup files, then run scripts/core/init.sh php check."
    fi
}
