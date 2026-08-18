#!/usr/bin/env bash

blackhost_docker_check_help() {
    cat <<'HELP'
blackhost docker check

Checks whether the host is ready to build and run Docker workloads.

Usage:
  scripts/core/init.sh [--json] docker check [--yes] [--verbose]

Options:
  --json         Append a compact machine-readable result object.
  -y, --yes      Do not pause for the final acknowledgement prompt.
  -v, --verbose  Print extra Docker diagnostic output when available.
  -h, --help     Show this help text.
HELP
}

blackhost_docker_check() {
    local script_name="blackhost docker check"
    local verbose=false
    local docker_available=false
    local daemon_available=false
    local compose_available=false
    local buildx_available=false
    local docker_version
    local docker_info_file
    local docker_info_error_file
    local docker_hello_file
    local docker_hello_error_file

    BLACKHOST_ASSUME_YES=false

    for arg in "$@"; do
        case "$arg" in
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -v|--verbose)
                verbose=true
                ;;
            -h|--help)
                blackhost_docker_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Docker Host Readiness Check"
    blackhost_info "This script does not install or change anything."
    blackhost_info "It checks the local machine for Docker CLI, daemon, Compose, Buildx, and basic runtime health."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    blackhost_section "Docker CLI"
    if blackhost_require_command docker; then
        docker_available=true
        docker_version="$(docker --version 2>/dev/null || true)"
        blackhost_ok "${docker_version:-Docker CLI responded, but version output was empty.}"
    else
        blackhost_warn "Install Docker before attempting local container builds."
    fi

    blackhost_section "Docker Daemon"
    if [ "$docker_available" = true ]; then
        docker_info_file="$(blackhost_tmp_file blackhost-docker-info)"
        docker_info_error_file="$(blackhost_tmp_file blackhost-docker-info-error)"

        if docker info >"$docker_info_file" 2>"$docker_info_error_file"; then
            daemon_available=true
            blackhost_ok "Docker daemon is reachable."
            blackhost_info "Active Docker context: $(docker context show 2>/dev/null || printf 'unknown')"
        else
            blackhost_fail "Docker CLI is installed, but the daemon is not reachable."
            blackhost_warn "On macOS, start Docker Desktop and wait until it reports that Docker is running."
            blackhost_warn "On Linux, check the docker service and current user's group membership."

            if [ -s "$docker_info_error_file" ]; then
                blackhost_warn "Docker daemon error:"
                sed 's/^/       /' "$docker_info_error_file"
            fi
        fi
    fi

    blackhost_section "Docker Compose"
    if blackhost_docker_print_compose_version; then
        compose_available=true
    fi

    blackhost_section "Docker Buildx"
    if blackhost_docker_print_buildx_version; then
        buildx_available=true
    fi

    blackhost_section "Runtime Smoke Capability"
    if [ "$daemon_available" = true ]; then
        blackhost_info "Running a tiny Docker container to confirm image pull and process execution."
        docker_hello_file="$(blackhost_tmp_file blackhost-docker-hello)"
        docker_hello_error_file="$(blackhost_tmp_file blackhost-docker-hello-error)"

        if docker run --rm hello-world >"$docker_hello_file" 2>"$docker_hello_error_file"; then
            blackhost_ok "Docker can pull and run containers."
        else
            blackhost_fail "Docker could not run the hello-world container."
            blackhost_warn "This may be a network, registry, daemon, or permissions issue."

            if [ -s "$docker_hello_error_file" ]; then
                sed 's/^/       /' "$docker_hello_error_file"
            fi
        fi
    else
        blackhost_warn "Skipping runtime smoke test because the daemon is unavailable."
    fi

    blackhost_section "Resource Snapshot"
    if [ "$daemon_available" = true ]; then
        docker system df 2>/dev/null || blackhost_warn "Could not read Docker disk usage."
    fi

    blackhost_docker_print_host_guidance

    if [ "$verbose" = true ] && [ "$daemon_available" = true ]; then
        blackhost_section "Verbose Docker Info"
        docker info
    fi

    blackhost_section "Summary"
    if [ "$docker_available" = true ] && [ "$daemon_available" = true ] && [ "$compose_available" = true ] && [ "$buildx_available" = true ]; then
        blackhost_ok "Docker host is ready for local site container work."
        blackhost_ack "Review the Docker readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "Docker host is not fully ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh docker install or scripts/core/init.sh docker update as appropriate."
    blackhost_ack "Review the Docker readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
