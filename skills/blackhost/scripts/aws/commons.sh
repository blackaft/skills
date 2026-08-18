#!/usr/bin/env bash

blackhost_aws_cli_available() {
    command -v aws >/dev/null 2>&1
}

blackhost_aws_print_version() {
    if blackhost_aws_cli_available; then
        blackhost_ok "$(aws --version 2>&1 | sed -n '1p')"
        return 0
    fi

    blackhost_fail "AWS CLI is not available."
    return 1
}

blackhost_aws_identity_available() {
    local profile="${1:-default}"

    if [ "$profile" = "default" ]; then
        AWS_EC2_METADATA_DISABLED=true aws sts get-caller-identity --cli-connect-timeout 2 --cli-read-timeout 2 >/dev/null 2>&1
    else
        AWS_EC2_METADATA_DISABLED=true aws sts get-caller-identity --profile "$profile" --cli-connect-timeout 2 --cli-read-timeout 2 >/dev/null 2>&1
    fi
}

blackhost_aws_print_identity() {
    local profile="${1:-default}"

    if ! blackhost_aws_cli_available; then
        blackhost_fail "AWS CLI is not available."
        return 1
    fi

    if [ "$profile" = "default" ]; then
        AWS_EC2_METADATA_DISABLED=true aws sts get-caller-identity --cli-connect-timeout 2 --cli-read-timeout 2 --output text 2>/dev/null | sed 's/^/       /'
    else
        AWS_EC2_METADATA_DISABLED=true aws sts get-caller-identity --profile "$profile" --cli-connect-timeout 2 --cli-read-timeout 2 --output text 2>/dev/null | sed 's/^/       /'
    fi
}
