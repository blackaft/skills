#!/usr/bin/env bash

blackhost_docker_run_help() {
    cat <<'HELP'
blackhost docker run

Builds and runs a Dockerised app locally, then optionally opens it in a browser.

Usage:
  scripts/core/init.sh [--json] docker run <target-dir> [--port 8080] [--container-port 8080] [--image NAME] [--name NAME] [--no-build] [--open] [--dry-run] [--yes]

Options:
  --json                  Append a compact machine-readable result object.
  --port VALUE            Local browser port. Defaults to 8080.
  --container-port VALUE  Container port exposed by the app. Defaults to the first Dockerfile EXPOSE value, then 8080.
  --image NAME            Docker image tag. Defaults to blackhost-<target-dir-name>.
  --name NAME             Container name. Defaults to blackhost-<target-dir-name>.
  --no-build              Skip docker build and run the existing image tag.
  --open                  Open http://localhost:<port> after the container starts.
  --dry-run               Print commands without building, replacing, running, or opening anything.
  -y, --yes               Skip confirmation prompts.
  -h, --help              Show this help text.

Use this after docker dockerise has created a Dockerfile for the target app.
HELP
}

blackhost_docker_run() {
    local script_name="blackhost docker run"
    local target_dir=""
    local target_root
    local port="8080"
    local container_port=""
    local image_name=""
    local container_name=""
    local build=true
    local open_browser=false
    local url

    BLACKHOST_ASSUME_YES=false
    BLACKHOST_DRY_RUN=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --port)
                shift
                port="${1:-}"
                ;;
            --port=*)
                port="${1#--port=}"
                ;;
            --container-port)
                shift
                container_port="${1:-}"
                ;;
            --container-port=*)
                container_port="${1#--container-port=}"
                ;;
            --image)
                shift
                image_name="${1:-}"
                ;;
            --image=*)
                image_name="${1#--image=}"
                ;;
            --name)
                shift
                container_name="${1:-}"
                ;;
            --name=*)
                container_name="${1#--name=}"
                ;;
            --no-build)
                build=false
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
                blackhost_docker_run_help
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
        blackhost_docker_run_help
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

    if [ ! -f "$target_root/Dockerfile" ]; then
        blackhost_fail "No Dockerfile found in $target_root."
        blackhost_warn "Run scripts/core/init.sh docker dockerise $target_root --dry-run first, then apply it when ready."
        return 1
    fi

    if [ -z "$container_port" ]; then
        container_port="$(awk 'toupper($1) == "EXPOSE" { print $2; exit }' "$target_root/Dockerfile" | sed 's/[^0-9].*$//')"
        container_port="${container_port:-8080}"
    fi

    case "$container_port" in
        ''|*[!0-9]*)
            blackhost_fail "Container port must be numeric: $container_port"
            return 2
            ;;
    esac

    if [ -z "$image_name" ]; then
        image_name="blackhost-$(printf '%s' "$(basename "$target_root")" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_.-' '-')"
    fi

    if [ -z "$container_name" ]; then
        container_name="$image_name"
    fi

    url="http://localhost:$port"

    blackhost_section "Docker Local App Run"
    blackhost_info "Target directory: $target_root"
    blackhost_info "Image tag: $image_name"
    blackhost_info "Container name: $container_name"
    blackhost_info "Local URL: $url"
    blackhost_info "Port mapping: $port:$container_port"
    blackhost_info "Build before run: $build"
    blackhost_info "Open browser: $open_browser"
    blackhost_info "Dry-run mode: $BLACKHOST_DRY_RUN"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Docker and browser commands will be printed but not executed."
    elif ! blackhost_docker_daemon_reachable; then
        blackhost_fail "Docker daemon is not reachable."
        blackhost_warn "Start Docker Desktop or the Linux docker service, then rerun this command."
        return 1
    fi

    if ! blackhost_confirm "Build and run this app locally with Docker?"; then
        blackhost_fail "Docker local app run skipped."
        return 1
    fi

    if [ "$build" = true ]; then
        blackhost_run_cmd docker build -t "$image_name" "$target_root"
    fi

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_run_cmd docker rm -f "$container_name"
    elif docker ps -a --format '{{.Names}}' | grep -Fx "$container_name" >/dev/null 2>&1; then
        blackhost_warn "A container named $container_name already exists."
        if blackhost_confirm "Replace existing container $container_name?"; then
            blackhost_run_cmd docker rm -f "$container_name"
        else
            blackhost_fail "Existing container kept; cannot start a new one with the same name."
            return 1
        fi
    fi

    blackhost_run_cmd docker run -d --name "$container_name" -p "$port:$container_port" "$image_name"

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

    blackhost_dry_run_summary "Docker local app run"

    blackhost_section "Docker Local App Summary"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_ok "Dry-run completed. No image was built, no container was started, and no browser was opened."
        blackhost_info "Run without --dry-run to start the app."
    else
        blackhost_ok "Container started."
        blackhost_info "Open $url in your browser."
        blackhost_info "Stop it later with: docker rm -f $container_name"
    fi
}
