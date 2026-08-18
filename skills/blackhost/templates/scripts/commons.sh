#!/usr/bin/env bash

blackhost_package_cli_available() {
    command -v package >/dev/null 2>&1
}

blackhost_package_print_version() {
    if blackhost_package_cli_available; then
        blackhost_ok "$(package --version 2>&1 | sed -n '1p')"
        return 0
    fi

    blackhost_fail "package is not available."
    return 1
}

