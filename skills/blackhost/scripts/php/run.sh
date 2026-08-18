#!/usr/bin/env bash

blackhost_php_run_help() {
    cat <<'HELP'
blackhost php run

Starts a local PHP development server for a target directory, then optionally opens it in a browser.

Usage:
  scripts/core/init.sh [--json] php run <target-dir> [--host 127.0.0.1] [--port 8000] [--router FILE] [--open] [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --host VALUE   Host interface for php -S. Defaults to 127.0.0.1.
  --port VALUE   Local browser port. Defaults to 8000.
  --router FILE  Optional PHP router script path, relative to target-dir or absolute.
  --open         Open http://<host>:<port> after the server starts.
  --dry-run      Print commands without starting the server or opening the browser.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.
HELP
}

blackhost_php_run() {
    local script_name="blackhost php run"
    local target_dir=""
    local target_root
    local host="127.0.0.1"
    local port="8000"
    local router=""
    local router_path=""
    local open_browser=false
    local url
    local log_file
    local pid_file
    local server_pid

    BLACKHOST_ASSUME_YES=false
    BLACKHOST_DRY_RUN=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --host)
                shift
                host="${1:-}"
                ;;
            --host=*)
                host="${1#--host=}"
                ;;
            --port)
                shift
                port="${1:-}"
                ;;
            --port=*)
                port="${1#--port=}"
                ;;
            --router)
                shift
                router="${1:-}"
                ;;
            --router=*)
                router="${1#--router=}"
                ;;
            --open)
                open_browser=true
                ;;
            --dry-run)
                BLACKHOST_DRY_RUN=true
                ;;
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -h|--help)
                blackhost_php_run_help
                return 0
                ;;
            -*)
                echo "[$script_name] Unknown option: $1" >&2
                return 2
                ;;
            *)
                if [ -n "$target_dir" ]; then
                    echo "[$script_name] Unexpected argument: $1" >&2
                    return 2
                fi
                target_dir="$1"
                ;;
        esac
        shift
    done

    if [ -z "$target_dir" ]; then
        blackhost_php_run_help
        return 2
    fi

    case "$port" in
        ''|*[!0-9]*)
            blackhost_fail "Port must be numeric: $port"
            return 2
            ;;
    esac

    if [ ! -d "$target_dir" ]; then
        blackhost_fail "Target directory does not exist: $target_dir"
        return 1
    fi

    target_root="$(cd "$target_dir" && pwd)"
    url="http://$host:$port"
    log_file="${TMPDIR:-/tmp}/blackhost-php-${port}.log"
    pid_file="${TMPDIR:-/tmp}/blackhost-php-${port}.pid"

    if [ -n "$router" ]; then
        case "$router" in
            /*) router_path="$router" ;;
            *) router_path="$target_root/$router" ;;
        esac

        if [ ! -f "$router_path" ]; then
            blackhost_fail "Router file does not exist: $router_path"
            return 1
        fi
    fi

    blackhost_section "PHP Local App Run"
    blackhost_info "Target directory: $target_root"
    blackhost_info "Local URL: $url"
    blackhost_info "PHP host: $host"
    blackhost_info "PHP port: $port"
    blackhost_info "Router: ${router_path:-none}"
    blackhost_info "Log file: $log_file"
    blackhost_info "PID file: $pid_file"
    blackhost_info "Open browser: $open_browser"
    blackhost_info "Dry-run mode: $BLACKHOST_DRY_RUN"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Server and browser commands will be printed but not executed."
    elif ! blackhost_php_cli_available; then
        blackhost_fail "PHP CLI is not available."
        blackhost_warn "Run scripts/core/init.sh php install first, then rerun this command."
        return 1
    fi

    if ! blackhost_confirm "Start a local PHP server for this directory?"; then
        blackhost_fail "PHP local app run skipped."
        return 1
    fi

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        if [ -n "$router_path" ]; then
            blackhost_run_shell "cd '$target_root' && php -S '$host:$port' -t '$target_root' '$router_path' >'$log_file' 2>&1 & echo \$! >'$pid_file'"
        else
            blackhost_run_shell "cd '$target_root' && php -S '$host:$port' -t '$target_root' >'$log_file' 2>&1 & echo \$! >'$pid_file'"
        fi
    else
        if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" >/dev/null 2>&1; then
            blackhost_fail "A blackhost PHP server already appears to be running on this port with PID $(cat "$pid_file")."
            blackhost_warn "Stop it with: kill $(cat "$pid_file")"
            return 1
        fi

        if [ -n "$router_path" ]; then
            (
                cd "$target_root" || exit 1
                php -S "$host:$port" -t "$target_root" "$router_path" >"$log_file" 2>&1 &
                echo $! >"$pid_file"
            )
        else
            (
                cd "$target_root" || exit 1
                php -S "$host:$port" -t "$target_root" >"$log_file" 2>&1 &
                echo $! >"$pid_file"
            )
        fi
        server_pid="$(cat "$pid_file")"
        blackhost_ok "PHP server started with PID $server_pid."
    fi

    if [ "$open_browser" = true ]; then
        case "$BLACKHOST_OS" in
            macos)
                blackhost_run_cmd open "$url"
                ;;
            linux)
                if command -v xdg-open >/dev/null 2>&1; then
                    blackhost_run_cmd xdg-open "$url"
                else
                    blackhost_warn "xdg-open is not available. Open this URL manually: $url"
                fi
                ;;
            *)
                blackhost_warn "Open this URL manually: $url"
                ;;
        esac
    fi

    blackhost_dry_run_summary "PHP local app run"

    blackhost_section "PHP Local App Summary"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_ok "Dry-run completed. No server was started and no browser was opened."
        blackhost_info "Run without --dry-run to start the app."
    else
        blackhost_ok "Local PHP app is available at $url"
        blackhost_info "Stop it later with: kill $(cat "$pid_file")"
        blackhost_info "Server log: $log_file"
    fi
}
