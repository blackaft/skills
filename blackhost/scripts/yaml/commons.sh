#!/usr/bin/env bash

BLACKHOST_YAML_VENV_PATH="${BLACKHOST_YAML_VENV_PATH:-${BLACKHOST_LOCAL_ROOT:-$BLACKHOST_SKILL_ROOT/local}/.venv}"

blackhost_yaml_python_available() {
    command -v python3 >/dev/null 2>&1
}

blackhost_yaml_python_bin() {
    if [ -x "$BLACKHOST_YAML_VENV_PATH/bin/python" ]; then
        printf '%s\n' "$BLACKHOST_YAML_VENV_PATH/bin/python"
    else
        printf '%s\n' "python3"
    fi
}

blackhost_yaml_pip_available() {
    blackhost_yaml_python_available && python3 -m pip --version >/dev/null 2>&1
}

blackhost_yaml_pyyaml_available() {
    blackhost_yaml_python_available && "$(blackhost_yaml_python_bin)" -c 'import yaml' >/dev/null 2>&1
}

blackhost_yaml_print_python_version() {
    if blackhost_yaml_python_available; then
        blackhost_ok "$(python3 --version 2>&1)"
        return 0
    fi

    blackhost_fail "Python 3 is not available."
    return 1
}

blackhost_yaml_print_pip_version() {
    if blackhost_yaml_pip_available; then
        blackhost_ok "$(python3 -m pip --version 2>&1)"
        return 0
    fi

    blackhost_fail "pip is not available through python3 -m pip."
    return 1
}

blackhost_yaml_print_pyyaml_version() {
    if blackhost_yaml_pyyaml_available; then
        blackhost_ok "$("$(blackhost_yaml_python_bin)" -c 'import yaml; print("PyYAML " + getattr(yaml, "__version__", "unknown"))' 2>&1)"
        return 0
    fi

    blackhost_fail "PyYAML is not available to python3."
    return 1
}
