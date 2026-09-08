#!/usr/bin/env bash

blackhost_gcloud_cli_available() {
    command -v gcloud >/dev/null 2>&1
}

blackhost_gcloud_print_version() {
    if blackhost_gcloud_cli_available; then
        blackhost_ok "$(gcloud --version 2>/dev/null | sed -n '1p')"
        return 0
    fi

    blackhost_fail "Google Cloud CLI (gcloud) is not available."
    return 1
}

blackhost_gcloud_active_account() {
    local config_root="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}"
    local config_file="$config_root/configurations/config_default"

    if [ -f "$config_file" ]; then
        sed -n 's/^[[:space:]]*account[[:space:]]*=[[:space:]]*//p' "$config_file" | sed -n '1p'
    fi
}

blackhost_gcloud_auth_available() {
    blackhost_gcloud_active_account | grep -q .
}

blackhost_gcloud_print_auth_status() {
    local account

    account="$(blackhost_gcloud_active_account)"
    if [ -n "$account" ]; then
        blackhost_ok "Google Cloud CLI active account: $account"
        return 0
    fi

    blackhost_fail "Google Cloud CLI has no active account."
    return 1
}

blackhost_gcloud_print_config() {
    if blackhost_gcloud_cli_available; then
        gcloud config list --format='text' 2>/dev/null | sed 's/^/       /' || blackhost_warn "Could not read gcloud configuration."
    fi
}
