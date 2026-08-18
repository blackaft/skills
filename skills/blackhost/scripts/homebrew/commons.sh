#!/usr/bin/env bash

blackhost_homebrew_cli_available() {
    command -v brew >/dev/null 2>&1
}

blackhost_homebrew_print_version() {
    if blackhost_homebrew_cli_available; then
        blackhost_ok "$(brew --version 2>/dev/null | sed -n '1p')"
        return 0
    fi

    blackhost_fail "Homebrew is not available."
    return 1
}

blackhost_homebrew_print_prefix() {
    if blackhost_homebrew_cli_available; then
        blackhost_info "Homebrew binary: $(command -v brew)"
        blackhost_info "Homebrew prefix: $(brew --prefix 2>/dev/null || printf 'unknown')"
        return 0
    fi

    return 1
}
