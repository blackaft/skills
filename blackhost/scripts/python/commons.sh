#!/usr/bin/env bash

blackhost_python_cli_available() {
    command -v python3 >/dev/null 2>&1
}

blackhost_python_pip_available() {
    blackhost_python_cli_available && python3 -m pip --version >/dev/null 2>&1
}

blackhost_python_venv_available() {
    blackhost_python_cli_available && python3 -m venv --help >/dev/null 2>&1
}

blackhost_python_print_version() {
    if blackhost_python_cli_available; then
        blackhost_ok "$(python3 --version 2>&1)"
        return 0
    fi

    blackhost_fail "Python 3 is not available."
    return 1
}

blackhost_python_print_pip_version() {
    if blackhost_python_pip_available; then
        blackhost_ok "$(python3 -m pip --version 2>&1)"
        return 0
    fi

    blackhost_fail "pip is not available through python3 -m pip."
    return 1
}

blackhost_python_print_executable() {
    if blackhost_python_cli_available; then
        python3 -c 'import sys; print("       executable=" + sys.executable); print("       version=" + sys.version.replace("\n", " "))'
        return 0
    fi

    blackhost_warn "Skipping Python executable details because Python 3 is unavailable."
    return 1
}

blackhost_python_print_module_checks() {
    local missing=false
    local module

    for module in ensurepip json ssl sqlite3 venv; do
        if python3 -c "import ${module}" >/dev/null 2>&1; then
            blackhost_ok "Python module available: $module"
        else
            missing=true
            blackhost_fail "Python module missing: $module"
        fi
    done

    if [ "$missing" = true ]; then
        return 1
    fi

    return 0
}

