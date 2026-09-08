#!/usr/bin/env bash

blackhost_docker_cli_available() {
    command -v docker >/dev/null 2>&1
}

blackhost_docker_daemon_reachable() {
    blackhost_docker_cli_available && docker info >/dev/null 2>&1
}

blackhost_docker_compose_available() {
    if blackhost_docker_cli_available && docker compose version >/dev/null 2>&1; then
        return 0
    fi

    command -v docker-compose >/dev/null 2>&1
}

blackhost_docker_buildx_available() {
    blackhost_docker_cli_available && docker buildx version >/dev/null 2>&1
}

blackhost_docker_print_host_guidance() {
    case "$BLACKHOST_OS" in
        macos)
            blackhost_info "macOS note: Docker Desktop owns the Linux VM resources. Check Docker Desktop settings if builds are slow."
            ;;
        linux)
            if groups 2>/dev/null | grep -qw docker; then
                blackhost_ok "Current user appears to be in the docker group."
            else
                blackhost_warn "Current user does not appear to be in the docker group."
                blackhost_warn "You may need sudo for Docker commands, or to add the user to the docker group and log in again."
            fi
            ;;
    esac
}

blackhost_docker_print_compose_version() {
    local output_file
    local error_file

    output_file="$(blackhost_tmp_file blackhost-docker-compose)"
    error_file="$(blackhost_tmp_file blackhost-docker-compose-error)"

    if blackhost_docker_cli_available && docker compose version >"$output_file" 2>"$error_file"; then
        blackhost_ok "$(cat "$output_file")"
        return 0
    fi

    if command -v docker-compose >/dev/null 2>&1; then
        blackhost_ok "$(docker-compose --version)"
        blackhost_warn "Legacy docker-compose is installed. Prefer Docker Compose v2 through 'docker compose'."
        return 0
    fi

    blackhost_fail "Docker Compose is not available."
    blackhost_warn "The site workflow expects Docker Compose v2 for local orchestration."
    return 1
}

blackhost_docker_print_buildx_version() {
    local output_file
    local error_file

    output_file="$(blackhost_tmp_file blackhost-docker-buildx)"
    error_file="$(blackhost_tmp_file blackhost-docker-buildx-error)"

    if blackhost_docker_cli_available && docker buildx version >"$output_file" 2>"$error_file"; then
        blackhost_ok "$(cat "$output_file")"
        return 0
    fi

    blackhost_fail "Docker Buildx is not available."
    blackhost_warn "Buildx is recommended for production image builds and multi-platform publishing."
    return 1
}

blackhost_docker_wait_for_daemon() {
    local attempts="${1:-60}"
    local delay="${2:-2}"

    for _ in $(seq 1 "$attempts"); do
        if blackhost_docker_daemon_reachable; then
            return 0
        fi

        sleep "$delay"
    done

    return 1
}
