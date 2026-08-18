#!/usr/bin/env bash

blackhost_php_check_help() {
    cat <<'HELP'
blackhost php check

Checks whether the host is ready to run PHP and Composer workloads.

Usage:
  scripts/core/init.sh [--json] php check [--yes] [--verbose]

Options:
  --json         Append a compact machine-readable result object.
  -y, --yes      Do not pause for the final acknowledgement prompt.
  -v, --verbose  Print extra PHP and Composer diagnostic output when available.
  -h, --help     Show this help text.
HELP
}

blackhost_php_check() {
    local script_name="blackhost php check"
    local verbose=false
    local php_available=false
    local composer_available=false
    local extensions_available=false

    BLACKHOST_ASSUME_YES=false

    for arg in "$@"; do
        case "$arg" in
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -v|--verbose)
                verbose=true
                ;;
            -h|--help)
                blackhost_php_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "PHP Host Readiness Check"
    blackhost_info "This script does not install or change PHP or Composer."
    blackhost_info "It checks the local machine for PHP CLI, Composer, common PHP extensions, and basic runtime execution."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    blackhost_section "PHP CLI"
    if blackhost_php_print_version; then
        php_available=true
        blackhost_info "PHP binary: $(command -v php)"
    else
        blackhost_warn "Install PHP before attempting PHP application or Composer workflows."
    fi

    blackhost_section "Composer"
    if blackhost_composer_print_version; then
        composer_available=true
        blackhost_info "Composer binary: $(command -v composer)"
    else
        blackhost_warn "Install Composer before dependency installation or autoload generation."
    fi

    blackhost_section "PHP Extensions"
    if [ "$php_available" = true ]; then
        if blackhost_php_print_extensions; then
            extensions_available=true
        else
            blackhost_warn "Missing extensions may break common PHP frameworks and Composer packages."
        fi
    else
        blackhost_warn "Skipping extension checks because PHP CLI is unavailable."
    fi

    blackhost_section "Runtime Smoke Capability"
    if [ "$php_available" = true ]; then
        if php -r 'echo "PHP runtime executed successfully: " . PHP_VERSION . PHP_EOL;' >/dev/null 2>&1; then
            blackhost_ok "PHP can execute inline runtime code."
        else
            blackhost_fail "PHP CLI exists, but inline runtime execution failed."
        fi
    else
        blackhost_warn "Skipping runtime smoke test because PHP CLI is unavailable."
    fi

    if [ "$verbose" = true ] && [ "$php_available" = true ]; then
        blackhost_section "Verbose PHP Configuration"
        blackhost_php_print_ini || true
    fi

    if [ "$verbose" = true ] && [ "$composer_available" = true ]; then
        blackhost_section "Verbose Composer Configuration"
        composer config --list --global 2>/dev/null | sed 's/^/       /' || blackhost_warn "Could not read global Composer configuration."
    fi

    blackhost_section "Summary"
    if [ "$php_available" = true ] && [ "$composer_available" = true ] && [ "$extensions_available" = true ]; then
        blackhost_ok "PHP and Composer host tooling is ready."
        blackhost_ack "Review the PHP readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "PHP and Composer host tooling is not fully ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh php install or scripts/core/init.sh php update as appropriate."
    blackhost_ack "Review the PHP readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
