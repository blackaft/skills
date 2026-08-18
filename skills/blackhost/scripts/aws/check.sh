#!/usr/bin/env bash

blackhost_aws_check_help() {
    cat <<'HELP'
blackhost aws check

Checks whether the host is ready for AWS CLI workflows.

Usage:
  scripts/core/init.sh [--json] aws check [--profile default] [--yes] [--verbose]

Options:
  --json           Append a compact machine-readable result object.
  --profile VALUE  AWS profile to inspect. Defaults to default.
  -y, --yes        Do not pause for the final acknowledgement prompt.
  -v, --verbose    Print AWS CLI configuration details when available.
  -h, --help       Show this help text.
HELP
}

blackhost_aws_check() {
    local script_name="blackhost aws check"
    local profile="default"
    local verbose=false
    local cli_available=false
    local identity_available=false

    BLACKHOST_ASSUME_YES=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --profile)
                shift
                profile="${1:-}"
                ;;
            --profile=*)
                profile="${1#--profile=}"
                ;;
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -v|--verbose)
                verbose=true
                ;;
            -h|--help)
                blackhost_aws_check_help
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

    blackhost_section "AWS CLI Host Readiness Check"
    blackhost_info "This script does not install, update, or authenticate AWS CLI."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"
    blackhost_info "AWS profile: $profile"

    blackhost_section "AWS CLI"
    if blackhost_aws_print_version; then
        cli_available=true
        blackhost_info "aws binary: $(command -v aws)"
    else
        blackhost_warn "Install AWS CLI before attempting AWS workflows."
    fi

    blackhost_section "Identity"
    if [ "$cli_available" = true ] && blackhost_aws_identity_available "$profile"; then
        identity_available=true
        blackhost_ok "AWS CLI can resolve caller identity for profile $profile."
        blackhost_aws_print_identity "$profile" || true
    elif [ "$cli_available" = true ]; then
        blackhost_fail "AWS CLI cannot resolve caller identity for profile $profile."
        blackhost_warn "Run scripts/core/init.sh aws auth --profile $profile to start AWS SSO browser authentication."
    else
        blackhost_warn "Skipping identity check because AWS CLI is unavailable."
    fi

    if [ "$verbose" = true ] && [ "$cli_available" = true ]; then
        blackhost_section "Verbose AWS CLI Configuration"
        if [ "$profile" = "default" ]; then
            aws configure list 2>/dev/null | sed 's/^/       /' || blackhost_warn "Could not read AWS configuration."
        else
            aws configure list --profile "$profile" 2>/dev/null | sed 's/^/       /' || blackhost_warn "Could not read AWS configuration."
        fi
    fi

    blackhost_section "Summary"
    if [ "$cli_available" = true ] && [ "$identity_available" = true ]; then
        blackhost_ok "AWS CLI host tooling is ready."
        blackhost_ack "Review the AWS CLI readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "AWS CLI host tooling is not fully ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh aws install or scripts/core/init.sh aws auth as appropriate."
    blackhost_ack "Review the AWS CLI readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
