#!/usr/bin/env bash

blackhost_gh_auth_help() {
    cat <<'HELP'
blackhost gh auth

Starts browser-based GitHub CLI authentication and waits for the user to complete it.

Usage:
  scripts/core/init.sh [--json] gh auth [--hostname github.com] [--git-protocol https|ssh] [--scopes SCOPE_LIST] [--dry-run] [--yes]

Options:
  --json                Append a compact machine-readable result object.
  --hostname VALUE      GitHub hostname to authenticate. Defaults to github.com.
  --git-protocol VALUE  Git protocol gh should configure: https or ssh. Defaults to https.
  --scopes VALUE        Optional comma-separated OAuth scopes to request.
  --dry-run             Print the browser auth command without executing it.
  -y, --yes             Skip confirmation prompts.
  -h, --help            Show this help text.
HELP
}

blackhost_gh_auth() {
    local script_name="blackhost gh auth"
    local hostname="github.com"
    local git_protocol="https"
    local scopes=""

    BLACKHOST_ASSUME_YES=false
    BLACKHOST_DRY_RUN=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --hostname)
                shift
                hostname="${1:-}"
                ;;
            --hostname=*)
                hostname="${1#--hostname=}"
                ;;
            --git-protocol)
                shift
                git_protocol="${1:-}"
                ;;
            --git-protocol=*)
                git_protocol="${1#--git-protocol=}"
                ;;
            --scopes)
                shift
                scopes="${1:-}"
                ;;
            --scopes=*)
                scopes="${1#--scopes=}"
                ;;
            --dry-run)
                BLACKHOST_DRY_RUN=true
                ;;
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -h|--help)
                blackhost_gh_auth_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $1" >&2
                return 2
                ;;
        esac
        shift
    done

    hostname="${hostname:-github.com}"
    case "$git_protocol" in
        https|ssh)
            ;;
        *)
            blackhost_fail "Unsupported git protocol: $git_protocol"
            blackhost_warn "Expected https or ssh."
            return 2
            ;;
    esac

    blackhost_section "GitHub CLI Browser Authentication"
    blackhost_info "This command starts GitHub CLI browser-based authentication."
    blackhost_info "GitHub hostname: $hostname"
    blackhost_info "Git protocol: $git_protocol"
    blackhost_info "Scopes: ${scopes:-default}"
    blackhost_info "Dry-run mode: $BLACKHOST_DRY_RUN"
    blackhost_warn "GitHub CLI may print a one-time code and open a browser, or ask you to open a URL manually."
    blackhost_warn "Complete the browser validation, then return to this terminal for the final status."

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Authentication commands will be printed but not executed."
    elif ! blackhost_gh_cli_available; then
        blackhost_fail "GitHub CLI is not installed."
        blackhost_warn "Run scripts/core/init.sh gh install first, then rerun this command."
        return 1
    fi

    if blackhost_gh_auth_available "$hostname" && [ "$BLACKHOST_DRY_RUN" = false ]; then
        blackhost_ok "GitHub CLI is already authenticated for $hostname."
        return 0
    fi

    if ! blackhost_confirm "Start GitHub browser authentication now?"; then
        blackhost_fail "GitHub authentication skipped."
        return 1
    fi

    if [ -n "$scopes" ]; then
        blackhost_run_cmd gh auth login --hostname "$hostname" --git-protocol "$git_protocol" --web --scopes "$scopes"
    else
        blackhost_run_cmd gh auth login --hostname "$hostname" --git-protocol "$git_protocol" --web
    fi

    blackhost_dry_run_summary "GitHub CLI authentication"

    blackhost_section "Authentication Summary"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_ok "Dry-run completed. No browser authentication was started."
        blackhost_info "Run without --dry-run to authenticate."
    elif blackhost_gh_auth_available "$hostname"; then
        blackhost_ok "GitHub CLI authentication completed for $hostname."
    else
        blackhost_fail "GitHub CLI still is not authenticated for $hostname."
        blackhost_warn "Review the gh output above and rerun scripts/core/init.sh gh auth."
        return 1
    fi
}
