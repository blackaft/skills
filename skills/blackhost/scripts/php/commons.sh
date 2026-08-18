#!/usr/bin/env bash

blackhost_php_cli_available() {
    command -v php >/dev/null 2>&1
}

blackhost_composer_available() {
    command -v composer >/dev/null 2>&1
}

blackhost_php_extension_available() {
    local extension="$1"

    blackhost_php_cli_available && php -m 2>/dev/null | grep -Fixi "$extension" >/dev/null
}

blackhost_php_print_version() {
    if blackhost_php_cli_available; then
        blackhost_ok "$(php --version | sed -n '1p')"
        return 0
    fi

    blackhost_fail "PHP CLI is not available."
    return 1
}

blackhost_composer_print_version() {
    if blackhost_composer_available; then
        blackhost_ok "$(composer --version 2>/dev/null | sed -n '1p')"
        return 0
    fi

    blackhost_fail "Composer is not available."
    return 1
}

blackhost_php_print_ini() {
    if blackhost_php_cli_available; then
        php --ini 2>/dev/null | sed 's/^/       /'
        return 0
    fi

    blackhost_warn "Skipping php --ini because PHP CLI is unavailable."
    return 1
}

blackhost_php_print_extensions() {
    local missing=false
    local extension

    for extension in json mbstring openssl curl xml zip intl; do
        if blackhost_php_extension_available "$extension"; then
            blackhost_ok "PHP extension available: $extension"
        else
            missing=true
            blackhost_fail "PHP extension missing: $extension"
        fi
    done

    if [ "$missing" = true ]; then
        return 1
    fi

    return 0
}
