#!/usr/bin/env bash

blackhost_docker_install_help() {
    cat <<'HELP'
blackhost docker install

Installs Docker tooling on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] docker install [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing installation steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: installs Docker Desktop cask.
  Debian/Ubuntu Linux: installs Docker Engine, Compose plugin, and Buildx plugin through Docker's apt repository.
HELP
}

blackhost_docker_install() {
    local script_name="blackhost docker install"

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
            -h|--help)
                blackhost_docker_install_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Docker Installation"
    blackhost_info "This script installs Docker tooling for local build and runtime work."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Installation commands will be printed but not executed."
    fi

    if blackhost_docker_daemon_reachable; then
        blackhost_ok "Docker is already installed and the daemon is reachable."
        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Use scripts/core/init.sh docker update if you want to refresh the installation."
            return 0
        fi
        blackhost_warn "Dry-run mode will still print the install path for review."
    fi

    if blackhost_docker_cli_available; then
        blackhost_warn "Docker CLI is already installed, but the daemon is not reachable."
        blackhost_warn "If Docker Desktop is installed, start it before reinstalling."
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_docker_install_macos
            ;;
        linux)
            blackhost_docker_install_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Install Docker manually for this host, then run scripts/core/init.sh docker check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Docker installation"

    blackhost_section "Post-Install Check"
    if blackhost_docker_cli_available; then
        docker --version || true
    fi

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Docker installation dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh docker check --verbose"
    elif blackhost_docker_daemon_reachable; then
        blackhost_ok "Docker install path completed successfully."
        blackhost_info "Next step: scripts/core/init.sh docker check --verbose"
    else
        blackhost_warn "Docker install path completed, but Docker is not fully ready yet."
        blackhost_warn "Start the daemon/Desktop, refresh group membership if needed, then run scripts/core/init.sh docker check."
    fi
}

blackhost_docker_install_macos() {
    blackhost_section "macOS Install Path"
    blackhost_info "Recommended local host path: Docker Desktop installed through Homebrew."

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Install Homebrew first from https://brew.sh, then rerun this script."
        return 1
    fi

    blackhost_ok "Homebrew is available at $(command -v brew)."

    if brew list --cask docker >/dev/null 2>&1 && [ "$BLACKHOST_DRY_RUN" = false ]; then
        blackhost_ok "Docker Desktop cask is already installed."
    elif blackhost_confirm "Install Docker Desktop with Homebrew now?"; then
        blackhost_run_cmd brew install --cask docker
    else
        blackhost_fail "Docker Desktop install skipped."
        return 1
    fi

    blackhost_section "macOS Startup Prompt"
    blackhost_warn "Docker Desktop must be started once before the Docker daemon is reachable."

    if blackhost_confirm "Open Docker Desktop now?"; then
        blackhost_run_cmd open -a Docker

        if [ "$BLACKHOST_DRY_RUN" = false ]; then
            blackhost_info "Waiting briefly for Docker Desktop to start. This can take longer on first launch."

            if blackhost_docker_wait_for_daemon 60 2; then
                blackhost_ok "Docker daemon is reachable."
            fi
        else
            blackhost_info "Dry-run mode: skipping Docker Desktop startup wait."
        fi
    fi

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode: Docker state is unchanged."
    elif blackhost_docker_daemon_reachable; then
        blackhost_ok "Docker installation is ready."
    else
        blackhost_warn "Docker is installed, but the daemon is not reachable yet."
        blackhost_warn "Finish Docker Desktop onboarding, then run scripts/core/init.sh docker check."
    fi
}

blackhost_docker_install_linux() {
    blackhost_section "Linux Install Path"
    blackhost_info "Distribution: $BLACKHOST_OS_PRETTY"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic installation."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Install Docker manually, then run scripts/core/init.sh docker check."
        return 1
    fi

    if [ -z "$BLACKHOST_OS_VERSION_CODENAME" ]; then
        blackhost_fail "Could not determine Debian/Ubuntu codename."
        blackhost_warn "Install Docker manually from Docker's official Linux documentation."
        return 1
    fi

    blackhost_warn "This path uses sudo and modifies apt sources."
    if ! blackhost_confirm "Install Docker Engine, Compose plugin, and Buildx plugin from Docker's apt repository?"; then
        blackhost_fail "Docker install skipped."
        return 1
    fi

    blackhost_run_cmd sudo install -m 0755 -d /etc/apt/keyrings
    blackhost_run_shell "curl -fsSL https://download.docker.com/linux/$BLACKHOST_OS_ID/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
    blackhost_run_cmd sudo chmod a+r /etc/apt/keyrings/docker.gpg
    blackhost_run_shell "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$BLACKHOST_OS_ID $BLACKHOST_OS_VERSION_CODENAME stable\" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null"
    blackhost_run_cmd sudo apt-get update
    blackhost_run_cmd sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    if blackhost_confirm "Add current user '$USER' to the docker group for non-sudo Docker commands?"; then
        blackhost_run_cmd sudo usermod -aG docker "$USER"
        blackhost_warn "Group membership changes require a new login shell or full logout/login."
    fi

    if blackhost_docker_daemon_reachable; then
        blackhost_ok "Docker daemon is reachable."
    else
        blackhost_warn "Docker was installed, but the daemon is not reachable in this shell."
        blackhost_warn "Try: sudo systemctl enable --now docker"
    fi
}
