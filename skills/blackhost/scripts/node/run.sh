#!/usr/bin/env bash

blackhost_node_run_help() {
    cat <<'HELP'
blackhost node run

Starts a local Node.js package script for a target app directory, then optionally opens it in a browser.

Usage:
  scripts/core/init.sh [--json] node run <target-dir> [--script dev] [--host 127.0.0.1] [--port 5173] [--open] [--dry-run] [--yes]

Options:
  --json          Append a compact machine-readable result object.
  --script VALUE  npm script to run. Defaults to the first available dev, start, or serve script.
  --host VALUE    Host value passed to the npm script after --. Defaults to 127.0.0.1.
  --port VALUE    Local browser port passed to the npm script after --. Defaults to 5173.
  --open          Open http://<host>:<port> after the process starts.
  --dry-run       Print commands without starting the process or opening the browser.
  -y, --yes       Skip confirmation prompts.
  -h, --help      Show this help text.
HELP
}

blackhost_node_run() {
    local script_name="blackhost node run"
    local target_dir=""
    local target_root
    local package_json
    local npm_script=""
    local host="127.0.0.1"
    local port="5173"
    local open_browser=false
    local url
    local log_file
    local pid_file
    local tmp_root
    local server_pid

    BLACKHOST_ASSUME_YES=false
    BLACKHOST_DRY_RUN=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --script)
                shift
                npm_script="${1:-}"
                ;;
            --script=*)
                npm_script="${1#--script=}"
                ;;
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
                blackhost_node_run_help
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
        blackhost_node_run_help
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
    package_json="$target_root/package.json"

    if [ ! -f "$package_json" ]; then
        blackhost_fail "package.json does not exist in target directory: $package_json"
        blackhost_warn "Use scripts/core/init.sh python run for a plain static directory, or add package.json first."
        return 1
    fi

    if [ -z "$npm_script" ]; then
        if blackhost_node_cli_available; then
            npm_script="$(blackhost_node_detect_run_script "$package_json" || true)"
        fi

        if [ -z "$npm_script" ]; then
            if [ "$BLACKHOST_DRY_RUN" = true ]; then
                npm_script="dev"
                blackhost_warn "Could not auto-detect an npm script. Dry-run will show the conventional dev script path."
            else
                blackhost_fail "Could not auto-detect an npm script named dev, start, or serve."
                blackhost_warn "Rerun with --script <name> after checking package.json."
                return 1
            fi
        fi
    fi

    if [ "$BLACKHOST_DRY_RUN" = false ] && ! blackhost_node_cli_available; then
        blackhost_fail "Node.js is not available."
        blackhost_warn "Run scripts/core/init.sh node install first, then rerun this command."
        return 1
    fi

    if [ "$BLACKHOST_DRY_RUN" = false ] && ! blackhost_node_package_script_exists "$package_json" "$npm_script"; then
        blackhost_fail "package.json does not define an npm script named: $npm_script"
        blackhost_warn "Rerun with --script <name> after checking package.json."
        return 1
    fi

    url="http://$host:$port"
    tmp_root="${TMPDIR:-/tmp}"
    tmp_root="${tmp_root%/}"
    log_file="$tmp_root/blackhost-node-${port}.log"
    pid_file="$tmp_root/blackhost-node-${port}.pid"

    blackhost_section "Node.js Local App Run"
    blackhost_info "Target directory: $target_root"
    blackhost_info "package.json: $package_json"
    blackhost_info "npm script: $npm_script"
    blackhost_info "Local URL: $url"
    blackhost_info "Node host: $host"
    blackhost_info "Node port: $port"
    blackhost_info "Log file: $log_file"
    blackhost_info "PID file: $pid_file"
    blackhost_info "Open browser: $open_browser"
    blackhost_info "Dry-run mode: $BLACKHOST_DRY_RUN"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. npm and browser commands will be printed but not executed."
    elif ! blackhost_node_npm_available; then
        blackhost_fail "npm is not available."
        blackhost_warn "Run scripts/core/init.sh node install first, then rerun this command."
        return 1
    fi

    if ! blackhost_confirm "Start this local Node.js app with npm?"; then
        blackhost_fail "Node.js local app run skipped."
        return 1
    fi

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_run_shell "cd '$target_root' && npm run '$npm_script' -- --host '$host' --port '$port' >'$log_file' 2>&1 & echo \$! >'$pid_file'"
    else
        if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" >/dev/null 2>&1; then
            blackhost_fail "A blackhost Node.js process already appears to be running on this port with PID $(cat "$pid_file")."
            blackhost_warn "Stop it with: kill $(cat "$pid_file")"
            return 1
        fi

        (
            cd "$target_root" || exit 1
            npm run "$npm_script" -- --host "$host" --port "$port" >"$log_file" 2>&1 &
            echo $! >"$pid_file"
        )
        server_pid="$(cat "$pid_file")"
        blackhost_ok "Node.js app process started with PID $server_pid."
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

    blackhost_dry_run_summary "Node.js local app run"

    blackhost_section "Node.js Local App Summary"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_ok "Dry-run completed. No npm script was started and no browser was opened."
        blackhost_info "Run without --dry-run to start the app."
    else
        blackhost_ok "Local Node.js app command is running for $url"
        blackhost_info "Stop it later with: kill $(cat "$pid_file")"
        blackhost_info "Process log: $log_file"
    fi
}
