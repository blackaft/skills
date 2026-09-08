#!/usr/bin/env bash

blackhost_gh_cli_available() {
    command -v gh >/dev/null 2>&1
}

blackhost_gh_print_version() {
    if blackhost_gh_cli_available; then
        blackhost_ok "$(gh --version 2>/dev/null | sed -n '1p')"
        return 0
    fi

    blackhost_fail "GitHub CLI (gh) is not available."
    return 1
}

blackhost_gh_auth_available() {
    local hostname="${1:-github.com}"

    blackhost_gh_cli_available && gh auth status --hostname "$hostname" >/dev/null 2>&1
}

blackhost_gh_print_auth_status() {
    local hostname="${1:-github.com}"

    if ! blackhost_gh_cli_available; then
        blackhost_fail "Cannot inspect GitHub auth because gh is not installed."
        return 1
    fi

    if gh auth status --hostname "$hostname"; then
        blackhost_ok "GitHub CLI is authenticated for $hostname."
        return 0
    fi

    blackhost_fail "GitHub CLI is not authenticated for $hostname."
    return 1
}
