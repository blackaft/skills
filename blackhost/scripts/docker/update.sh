#!/usr/bin/env bash

blackhost_docker_update_help() {
    cat <<'HELP'
blackhost docker update

Updates Docker tooling on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] docker update [--dry-run] [--yes] [--prune]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  --prune        Prompt to run Docker system cleanup after the update.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: upgrades Docker Desktop cask.
  Debian/Ubuntu Linux: upgrades Docker Engine, Compose plugin, and Buildx plugin through apt.
HELP
}

blackhost_docker_update() {
    local script_name="blackhost docker update"
    local prune=false

    BLACKHOST_ASSUME_YES=false
    BLACKHOST_DRY_RUN=false

    for arg in "$@"; do
        case "$arg" in
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            --dry-run)
                BLACKHOST_DRY_RUN=true
                ;;
            --prune)
                prune=true
                ;;
            -h|--help)
                blackhost_docker_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Docker Update"
    blackhost_info "This script updates Docker tooling for local build and runtime work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    fi

    if blackhost_docker_cli_available; then
        blackhost_info "Current Docker CLI: $(docker --version 2>/dev/null || printf 'version unavailable')"
    else
        if [ "$BLACKHOST_DRY_RUN" = true ]; then
            blackhost_warn "Docker is not installed. Dry-run mode will still print the update path for review."
        else
            blackhost_fail "Docker is not installed."
            blackhost_warn "Run scripts/core/init.sh docker install before scripts/core/init.sh docker update."
            return 1
        fi
    fi

    if blackhost_docker_daemon_reachable; then
        blackhost_ok "Docker daemon is reachable before update."
        blackhost_info "Active Docker context: $(docker context show 2>/dev/null || printf 'unknown')"
    else
        blackhost_warn "Docker daemon is not reachable before update."
        blackhost_warn "The update can still refresh installed packages, but final runtime checks may fail until the daemon starts."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_docker_update_macos
            ;;
        linux)
            blackhost_docker_update_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Update Docker manually for this host, then run scripts/core/init.sh docker check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Docker update"
    blackhost_docker_update_diagnostics

    if [ "$prune" = true ]; then
        blackhost_docker_update_prune
    fi

    blackhost_section "Next Step"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Docker update dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh docker check --verbose"
    else
        blackhost_info "Run scripts/core/init.sh docker check --verbose to confirm host readiness."
    fi
}

blackhost_docker_update_macos() {
    blackhost_section "macOS Update Path"

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Update Docker Desktop manually, then run scripts/core/init.sh docker check."
        return 1
    fi

    if ! brew list --cask docker >/dev/null 2>&1; then
        if [ "$BLACKHOST_DRY_RUN" = true ]; then
            blackhost_warn "Docker Desktop cask is not installed through Homebrew. Dry-run mode will still print the update commands."
        else
            blackhost_fail "Docker Desktop cask is not installed through Homebrew."
            blackhost_warn "Use scripts/core/init.sh docker install or update Docker Desktop manually."
            return 1
        fi
    fi

    if blackhost_confirm "Upgrade Docker Desktop with Homebrew now?"; then
        blackhost_run_cmd brew update
        blackhost_run_cmd brew upgrade --cask docker
    else
        blackhost_warn "Docker Desktop upgrade skipped."
    fi

    if blackhost_confirm "Open Docker Desktop after update?"; then
        blackhost_run_cmd open -a Docker
    fi
}

blackhost_docker_update_linux() {
    blackhost_section "Linux Update Path"
    blackhost_info "Distribution: $BLACKHOST_OS_PRETTY"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic update."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Update Docker manually, then run scripts/core/init.sh docker check."
        return 1
    fi

    blackhost_warn "This path uses sudo and upgrades Docker packages through apt."
    if blackhost_confirm "Upgrade Docker Engine, Compose plugin, and Buildx plugin now?"; then
        blackhost_run_cmd sudo apt-get update
        blackhost_run_cmd sudo apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        blackhost_warn "Docker package upgrade skipped."
    fi
}

blackhost_docker_update_diagnostics() {
    blackhost_section "Post-Update Diagnostics"

    if blackhost_docker_cli_available; then
        docker --version || true
    fi

    blackhost_docker_print_compose_version || true
    blackhost_docker_print_buildx_version || true

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Docker daemon state was not changed because this was a dry-run."
    elif blackhost_docker_daemon_reachable; then
        blackhost_ok "Docker daemon is reachable after update."
        docker system df || true
    else
        blackhost_warn "Docker daemon is not reachable after update."
        blackhost_warn "Start Docker Desktop or the Linux docker service, then run scripts/core/init.sh docker check."
    fi
}

blackhost_docker_update_prune() {
    blackhost_section "Optional Docker Cleanup"
    blackhost_warn "Docker cleanup can remove stopped containers, unused networks, dangling images, and build cache."
    blackhost_warn "This does not remove named volumes unless Docker changes default behavior, but review the prompt carefully."

    if blackhost_confirm "Run 'docker system prune' now?"; then
        if [ "$BLACKHOST_DRY_RUN" = true ]; then
            blackhost_run_cmd docker system prune
        elif blackhost_docker_daemon_reachable; then
            blackhost_run_cmd docker system prune
        else
            blackhost_fail "Cannot prune because Docker daemon is not reachable."
        fi
    else
        blackhost_warn "Docker cleanup skipped."
    fi
}
