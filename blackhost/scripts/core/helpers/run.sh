#!/usr/bin/env bash

blackhost_init_paths() {
    local source_path="${1:-${BLACKHOST_ENTRYPOINT:-${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}}}"
    local source_dir

    source_dir="$(cd "$(dirname "$source_path")" && pwd)"

    if [ "$(basename "$source_dir")" = "blackhost" ]; then
        BLACKHOST_SKILL_ROOT="$source_dir"
        BLACKHOST_SCRIPT_ROOT="$BLACKHOST_SKILL_ROOT/scripts"
    else
        while [ "$source_dir" != "/" ] && [ "$(basename "$source_dir")" != "scripts" ]; do
            source_dir="$(dirname "$source_dir")"
        done

        if [ "$(basename "$source_dir")" != "scripts" ]; then
            printf '[FAIL] Could not resolve blackhost root from %s\n' "$source_path" >&2
            return 1
        fi

        BLACKHOST_SCRIPT_ROOT="$source_dir"
        BLACKHOST_SKILL_ROOT="$(dirname "$BLACKHOST_SCRIPT_ROOT")"
    fi

    export BLACKHOST_SCRIPT_ROOT
    export BLACKHOST_SKILL_ROOT
}

blackhost_detect_os() {
    BLACKHOST_OS_KERNEL="$(uname -s)"
    BLACKHOST_ARCH="$(uname -m)"
    BLACKHOST_OS="unknown"
    BLACKHOST_OS_FAMILY="unknown"
    BLACKHOST_OS_ID="unknown"
    BLACKHOST_OS_LIKE=""
    BLACKHOST_OS_VERSION_CODENAME=""
    BLACKHOST_OS_PRETTY="$BLACKHOST_OS_KERNEL"

    case "$BLACKHOST_OS_KERNEL" in
        Darwin)
            BLACKHOST_OS="macos"
            BLACKHOST_OS_FAMILY="darwin"
            BLACKHOST_OS_ID="macos"
            BLACKHOST_OS_PRETTY="macOS"
            ;;
        Linux)
            BLACKHOST_OS="linux"
            BLACKHOST_OS_FAMILY="linux"

            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                BLACKHOST_OS_ID="${ID:-unknown}"
                BLACKHOST_OS_LIKE="${ID_LIKE:-}"
                BLACKHOST_OS_VERSION_CODENAME="${VERSION_CODENAME:-}"
                BLACKHOST_OS_PRETTY="${PRETTY_NAME:-Linux}"
            else
                BLACKHOST_OS_PRETTY="Linux"
            fi
            ;;
        *)
            BLACKHOST_OS="$(printf '%s' "$BLACKHOST_OS_KERNEL" | tr '[:upper:]' '[:lower:]')"
            BLACKHOST_OS_FAMILY="unknown"
            ;;
    esac

    export BLACKHOST_OS_KERNEL
    export BLACKHOST_ARCH
    export BLACKHOST_OS
    export BLACKHOST_OS_FAMILY
    export BLACKHOST_OS_ID
    export BLACKHOST_OS_LIKE
    export BLACKHOST_OS_VERSION_CODENAME
    export BLACKHOST_OS_PRETTY
}

blackhost_os_is_debian_like() {
    case "$BLACKHOST_OS_ID $BLACKHOST_OS_LIKE" in
        *ubuntu*|*debian*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

blackhost_print_os() {
    printf 'BLACKHOST_OS=%s\n' "$BLACKHOST_OS"
    printf 'BLACKHOST_OS_FAMILY=%s\n' "$BLACKHOST_OS_FAMILY"
    printf 'BLACKHOST_OS_ID=%s\n' "$BLACKHOST_OS_ID"
    printf 'BLACKHOST_OS_LIKE=%s\n' "$BLACKHOST_OS_LIKE"
    printf 'BLACKHOST_OS_VERSION_CODENAME=%s\n' "$BLACKHOST_OS_VERSION_CODENAME"
    printf 'BLACKHOST_OS_PRETTY=%s\n' "$BLACKHOST_OS_PRETTY"
    printf 'BLACKHOST_ARCH=%s\n' "$BLACKHOST_ARCH"
}

blackhost_load_core() {
    # shellcheck disable=SC1091
    . "$BLACKHOST_SCRIPT_ROOT/core/helpers/terminal.sh"
    # shellcheck disable=SC1091
    . "$BLACKHOST_SCRIPT_ROOT/core/helpers/temp.sh"
    # shellcheck disable=SC1091
    . "$BLACKHOST_SCRIPT_ROOT/core/helpers/index.sh"
}

blackhost_identifier_to_function_fragment() {
    printf '%s' "$1" | tr '-' '_'
}

blackhost_package_names() {
    find "$BLACKHOST_SCRIPT_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name core -exec basename {} \; | sort
}

blackhost_package_command_names() {
    local package="$1"
    local package_dir="$BLACKHOST_SCRIPT_ROOT/$package"

    if [ ! -d "$package_dir" ]; then
        return 1
    fi

    find "$package_dir" -maxdepth 1 -type f -name '*.sh' ! -name commons.sh -exec basename {} .sh \; | sort
}

blackhost_join_lines() {
    local joined=""
    local item

    while IFS= read -r item; do
        if [ -z "$joined" ]; then
            joined="$item"
        else
            joined="$joined, $item"
        fi
    done

    printf '%s' "$joined"
}

blackhost_package_exists() {
    local package="$1"

    case "$package" in
        ''|*[!a-z0-9_-]*)
            return 1
            ;;
    esac

    [ -d "$BLACKHOST_SCRIPT_ROOT/$package" ]
}

blackhost_load_package() {
    local package="$1"
    local package_dir="$BLACKHOST_SCRIPT_ROOT/$package"
    local file

    if ! blackhost_package_exists "$package"; then
        return 1
    fi

    if [ -f "$package_dir/commons.sh" ]; then
        # shellcheck disable=SC1090
        . "$package_dir/commons.sh"
    fi

    for file in "$package_dir"/*.sh; do
        [ -e "$file" ] || continue
        [ "$(basename "$file")" = "commons.sh" ] && continue
        # shellcheck disable=SC1090
        . "$file"
    done
}

blackhost_help() {
    local package
    local commands

    cat <<'HELP'
blackhost

Host setup and configuration helper.

Usage:
  scripts/core/init.sh [--json] <package> <command> [options]
  scripts/core/init.sh [--json] <package> --help
  scripts/core/init.sh [--json] os
  scripts/core/init.sh [--json] --help

Global options:
  --json   Append a compact machine-readable result object.

Packages:
  os       Print detected host OS variables.
HELP

    for package in $(blackhost_package_names); do
        commands="$(blackhost_package_command_names "$package" | blackhost_join_lines)"
        printf '  %-8s %s\n' "$package" "$commands"
    done

    printf '\n'

    cat <<'HELP'
Examples:
  scripts/core/init.sh aws auth --dry-run
  scripts/core/init.sh aws install --dry-run
  scripts/core/init.sh docker check
  scripts/core/init.sh docker dockerise apps/site --dry-run
  scripts/core/init.sh docker run apps/site --open --yes
  scripts/core/init.sh docker install --dry-run
  scripts/core/init.sh docker update --prune
  scripts/core/init.sh gcloud auth --dry-run
  scripts/core/init.sh gcloud install --dry-run
  scripts/core/init.sh git check --verbose
  scripts/core/init.sh gh auth --dry-run
  scripts/core/init.sh homebrew install --dry-run
  scripts/core/init.sh php run apps/site --open --yes
  scripts/core/init.sh node run apps/site --open --yes
  scripts/core/init.sh python run apps/site --open --yes
  scripts/core/init.sh yaml install --dry-run
  scripts/core/init.sh php check --verbose
  scripts/core/init.sh python check --verbose
  scripts/core/init.sh --json python check --yes
HELP
}

blackhost_package_help() {
    local package="$1"
    local command

    printf 'blackhost %s\n\n' "$package"
    printf 'Usage:\n'
    printf '  scripts/core/init.sh [--json] %s <command> [options]\n\n' "$package"
    printf 'Commands:\n'

    for command in $(blackhost_package_command_names "$package"); do
        printf '  %s\n' "$command"
    done
}

blackhost_dispatch_and_report() {
    local package="$1"
    local command="$2"
    local function_name="$3"
    local had_errexit=false
    local exit_code
    local output_file

    shift 3

    case "$-" in
        *e*)
            had_errexit=true
            ;;
    esac

    output_file="$(blackhost_tmp_file blackhost-command-output)"

    set +e
    "$function_name" "$@" >"$output_file" 2>&1
    exit_code=$?
    cat "$output_file"

    if [ "$had_errexit" = true ]; then
        set -e
    else
        set +e
    fi

    blackhost_index_record "$package" "$command" "$exit_code" "$output_file"
    blackhost_info "Local status page updated: $BLACKHOST_INDEX_HTML_PATH"
    blackhost_index_open_html
    blackhost_json_result "$package" "$command" "$exit_code"
    return "$exit_code"
}

blackhost_run() {
    local package
    local command
    local package_fragment
    local command_fragment
    local function_name
    local filtered_args=()
    local expected

    BLACKHOST_JSON=false
    BLACKHOST_DRY_RUN=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --json)
                BLACKHOST_JSON=true
                ;;
            *)
                filtered_args+=("$1")
                ;;
        esac
        shift
    done

    set -- "${filtered_args[@]}"
    package="${1:-}"
    command="${2:-}"

    case "$package" in
        ""|-h|--help|help)
            blackhost_dispatch_and_report "core" "help" "blackhost_help"
            return $?
            ;;
        os)
            blackhost_dispatch_and_report "core" "os" "blackhost_print_os"
            return $?
            ;;
        *)
            if ! blackhost_package_exists "$package"; then
                expected="$(blackhost_package_names | blackhost_join_lines)"
                blackhost_fail "Unknown package: $package"
                blackhost_warn "Expected one of: ${expected:-none}, os."
                blackhost_warn "Run scripts/core/init.sh --help for usage."
                blackhost_json_result "$package" "${command:-unknown}" 2
                return 2
            fi

            blackhost_load_package "$package"
            shift
            command="${1:-}"

            case "$command" in
                ""|-h|--help|help)
                    blackhost_dispatch_and_report "$package" "help" "blackhost_package_help" "$package"
                    return $?
                    ;;
            esac

            case "$command" in
                *[!a-z0-9_-]*)
                    blackhost_fail "Invalid command name: $command"
                    blackhost_json_result "$package" "$command" 2
                    return 2
                    ;;
            esac

            package_fragment="$(blackhost_identifier_to_function_fragment "$package")"
            command_fragment="$(blackhost_identifier_to_function_fragment "$command")"
            function_name="blackhost_${package_fragment}_${command_fragment}"

            if ! type "$function_name" >/dev/null 2>&1; then
                expected="$(blackhost_package_command_names "$package" | blackhost_join_lines)"
                blackhost_fail "Unknown $package command: $command"
                blackhost_warn "Expected one of: ${expected:-none}."
                blackhost_warn "Run scripts/core/init.sh $package --help for usage."
                blackhost_json_result "$package" "$command" 2
                return 2
            fi

            shift
            blackhost_dispatch_and_report "$package" "$command" "$function_name" "$@"
            ;;
    esac
}

blackhost_bootstrap() {
    blackhost_init_paths "${1:-${BLACKHOST_ENTRYPOINT:-${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}}}"
    blackhost_detect_os
    blackhost_load_core
}
