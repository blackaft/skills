#!/usr/bin/env bash

blackhost_aws_auth_help() {
    cat <<'HELP'
blackhost aws auth

Starts AWS SSO browser authentication with explicit prompts.

Usage:
  scripts/core/init.sh [--json] aws auth [--profile default] [--configure] [--dry-run] [--yes]

Options:
  --json           Append a compact machine-readable result object.
  --profile VALUE  AWS profile to authenticate. Defaults to default.
  --configure      Run aws configure sso instead of aws sso login.
  --dry-run        Print the browser auth command without executing it.
  -y, --yes        Skip confirmation prompts.
  -h, --help       Show this help text.
HELP
}

blackhost_aws_auth() {
    local script_name="blackhost aws auth"
    local profile="default"
    local configure=false

    BLACKHOST_ASSUME_YES=false
    BLACKHOST_DRY_RUN=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --profile)
                shift
                profile="${1:-}"
                ;;
            --profile=*)
                profile="${1#--profile=}"
                ;;
            --configure)
                configure=true
                ;;
            --dry-run)
                BLACKHOST_DRY_RUN=true
                ;;
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -h|--help)
                blackhost_aws_auth_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $1" >&2
                return 2
                ;;
        esac
        shift
    done

    profile="${profile:-default}"

    blackhost_section "AWS CLI Browser Authentication"
    blackhost_info "This command starts AWS SSO browser-based authentication."
    blackhost_info "AWS profile: $profile"
    blackhost_info "Configure mode: $configure"
    blackhost_info "Dry-run mode: $BLACKHOST_DRY_RUN"
    blackhost_warn "AWS CLI may open a browser, or print a URL and code that you must use manually."
    blackhost_warn "Complete the browser validation, then return to this terminal for the final status."

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Authentication commands will be printed but not executed."
    elif ! blackhost_aws_cli_available; then
        blackhost_fail "AWS CLI is not installed."
        blackhost_warn "Run scripts/core/init.sh aws install first, then rerun this command."
        return 1
    fi

    if [ "$configure" = false ] && [ "$BLACKHOST_DRY_RUN" = false ] && blackhost_aws_identity_available "$profile"; then
        blackhost_ok "AWS CLI can already resolve caller identity for profile $profile."
        return 0
    fi

    if [ "$configure" = true ]; then
        if ! blackhost_confirm "Start AWS SSO profile configuration now?"; then
            blackhost_fail "AWS SSO configuration skipped."
            return 1
        fi
        blackhost_run_cmd aws configure sso --profile "$profile"
    else
        if ! blackhost_confirm "Start AWS SSO browser login now?"; then
            blackhost_fail "AWS SSO login skipped."
            return 1
        fi
        blackhost_run_cmd aws sso login --profile "$profile"
    fi

    blackhost_dry_run_summary "AWS CLI authentication"

    blackhost_section "Authentication Summary"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_ok "Dry-run completed. No browser authentication was started."
        blackhost_info "Run without --dry-run to authenticate."
    elif blackhost_aws_identity_available "$profile"; then
        blackhost_ok "AWS CLI authentication completed for profile $profile."
    else
        blackhost_fail "AWS CLI still cannot resolve caller identity for profile $profile."
        blackhost_warn "If this is a new SSO profile, run scripts/core/init.sh aws auth --profile $profile --configure first."
        return 1
    fi
}
