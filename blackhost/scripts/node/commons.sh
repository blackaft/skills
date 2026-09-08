#!/usr/bin/env bash

blackhost_node_cli_available() {
    command -v node >/dev/null 2>&1
}

blackhost_node_npm_available() {
    command -v npm >/dev/null 2>&1
}

blackhost_node_npx_available() {
    command -v npx >/dev/null 2>&1
}

blackhost_node_print_version() {
    if blackhost_node_cli_available; then
        blackhost_ok "Node.js: $(node --version)"
        return 0
    fi

    blackhost_fail "Node.js is not available on PATH."
    return 1
}

blackhost_node_print_npm_version() {
    if blackhost_node_npm_available; then
        blackhost_ok "npm: $(npm --version)"
        return 0
    fi

    blackhost_fail "npm is not available on PATH."
    return 1
}

blackhost_node_print_npx_version() {
    if blackhost_node_npx_available; then
        blackhost_ok "npx: $(npx --version)"
        return 0
    fi

    blackhost_fail "npx is not available on PATH."
    return 1
}

blackhost_node_print_executable() {
    blackhost_node_cli_available && blackhost_info "node binary: $(command -v node)"
    blackhost_node_npm_available && blackhost_info "npm binary: $(command -v npm)"
    blackhost_node_npx_available && blackhost_info "npx binary: $(command -v npx)"
}

blackhost_node_package_script_exists() {
    local package_json="$1"
    local script_name="$2"

    if ! blackhost_node_cli_available; then
        return 1
    fi

    node -e '
const fs = require("fs");
const packageJson = process.argv[1];
const scriptName = process.argv[2];
const data = JSON.parse(fs.readFileSync(packageJson, "utf8"));
process.exit(data.scripts && Object.prototype.hasOwnProperty.call(data.scripts, scriptName) ? 0 : 1);
' "$package_json" "$script_name" >/dev/null 2>&1
}

blackhost_node_detect_run_script() {
    local package_json="$1"

    if ! blackhost_node_cli_available; then
        return 1
    fi

    node -e '
const fs = require("fs");
const packageJson = process.argv[1];
const data = JSON.parse(fs.readFileSync(packageJson, "utf8"));
const scripts = data.scripts || {};
const selected = ["dev", "start", "serve"].find((name) => Object.prototype.hasOwnProperty.call(scripts, name));
if (!selected) process.exit(1);
console.log(selected);
' "$package_json" 2>/dev/null
}
