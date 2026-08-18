#!/usr/bin/env bash

BLACKHOST_ASSUME_YES="${BLACKHOST_ASSUME_YES:-false}"
BLACKHOST_DRY_RUN="${BLACKHOST_DRY_RUN:-false}"
BLACKHOST_JSON="${BLACKHOST_JSON:-false}"

blackhost_section() {
    printf '\n'
    printf '========================================================================\n'
    printf '%s\n' "$1"
    printf '========================================================================\n'
}

blackhost_info() {
    printf '[INFO] %s\n' "$1"
}

blackhost_ok() {
    printf '[ OK ] %s\n' "$1"
}

blackhost_warn() {
    printf '[WARN] %s\n' "$1"
}

blackhost_fail() {
    printf '[FAIL] %s\n' "$1"
}

blackhost_dry_run_summary() {
    local scope="${1:-Dry-run}"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_section "$scope Dry-Run Summary"
        blackhost_warn "No host or workspace changes were executed."
        blackhost_info "Any readiness output after this point reflects the current host state only."
    fi
}

blackhost_json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

blackhost_json_result() {
    local package="$1"
    local command="$2"
    local exit_code="$3"
    local status="error"

    if [ "$BLACKHOST_JSON" != true ]; then
        return 0
    fi

    if [ "$exit_code" -eq 0 ]; then
        status="ok"
    fi

    printf '{"schema":"blackhost.result","version":"0.1.0","package":"%s","command":"%s","status":"%s","exit_code":%s,"dry_run":%s,"os":"%s","os_id":"%s","os_pretty":"%s","arch":"%s"}\n' \
        "$(blackhost_json_escape "$package")" \
        "$(blackhost_json_escape "$command")" \
        "$status" \
        "$exit_code" \
        "$BLACKHOST_DRY_RUN" \
        "$(blackhost_json_escape "${BLACKHOST_OS:-unknown}")" \
        "$(blackhost_json_escape "${BLACKHOST_OS_ID:-unknown}")" \
        "$(blackhost_json_escape "${BLACKHOST_OS_PRETTY:-unknown}")" \
        "$(blackhost_json_escape "${BLACKHOST_ARCH:-unknown}")"
}

blackhost_confirm() {
    local prompt="$1"

    if [ "$BLACKHOST_ASSUME_YES" = true ]; then
        blackhost_info "$prompt"
        blackhost_info "Auto-confirmed because --yes was provided."
        return 0
    fi

    printf '\n%s [y/N] ' "$prompt"
    read -r answer

    case "$answer" in
        y|Y|yes|YES)
            return 0
            ;;
        *)
            blackhost_warn "User declined: $prompt"
            return 1
            ;;
    esac
}

blackhost_ack() {
    local prompt="${1:-Press Enter to finish, or Ctrl+C to stop here.}"

    if [ "$BLACKHOST_ASSUME_YES" = true ]; then
        return 0
    fi

    printf '\n%s' "$prompt"
    read -r _
}

blackhost_run_cmd() {
    printf '+'
    printf ' %q' "$@"
    printf '\n'

    if [ "$BLACKHOST_DRY_RUN" = false ]; then
        "$@"
    fi
}

blackhost_run_shell() {
    local command="$1"

    printf '+ %s\n' "$command"

    if [ "$BLACKHOST_DRY_RUN" = false ]; then
        bash -lc "$command"
    fi
}

blackhost_require_command() {
    local command_name="$1"

    if command -v "$command_name" >/dev/null 2>&1; then
        blackhost_ok "$command_name is available at $(command -v "$command_name")"
        return 0
    fi

    blackhost_fail "$command_name is not available on PATH."
    return 1
}
