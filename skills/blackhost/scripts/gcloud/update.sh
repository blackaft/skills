#!/usr/bin/env bash

blackhost_gcloud_update_help() {
    cat <<'HELP'
blackhost gcloud update

Updates Google Cloud CLI on the local host with explicit prompts.

Usage:
  scripts/core/init.sh [--json] gcloud update [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --dry-run      Print commands without executing update steps.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Supported host paths:
  macOS with Homebrew: updates google-cloud-sdk cask.
  Debian/Ubuntu Linux: upgrades google-cloud-cli through apt.
HELP
}

blackhost_gcloud_update() {
    local script_name="blackhost gcloud update"

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
                blackhost_gcloud_update_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Google Cloud CLI Update"
    blackhost_info "This script updates Google Cloud CLI for local Google Cloud account and deployment workflows."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_warn "Dry-run mode is active. Update commands will be printed but not executed."
    elif ! blackhost_gcloud_cli_available; then
        blackhost_fail "Google Cloud CLI is not installed."
        blackhost_warn "Run scripts/core/init.sh gcloud install before scripts/core/init.sh gcloud update."
        return 1
    fi

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Skipping gcloud version probe in dry-run mode."
    else
        blackhost_gcloud_print_version || true
    fi

    case "$BLACKHOST_OS" in
        macos)
            blackhost_gcloud_update_macos
            ;;
        linux)
            blackhost_gcloud_update_linux
            ;;
        *)
            blackhost_fail "Unsupported operating system: $BLACKHOST_OS_KERNEL"
            blackhost_warn "Update Google Cloud CLI manually for this host, then run scripts/core/init.sh gcloud check."
            return 1
            ;;
    esac

    blackhost_dry_run_summary "Google Cloud CLI update"

    blackhost_section "Post-Update Check"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Google Cloud CLI update dry-run completed. Run without --dry-run to apply the printed commands."
        blackhost_info "Next review command: scripts/core/init.sh gcloud check --verbose"
    else
        blackhost_gcloud_print_version || true
    fi
}

blackhost_gcloud_update_macos() {
    blackhost_section "macOS Update Path"

    if ! command -v brew >/dev/null 2>&1 && [ "$BLACKHOST_DRY_RUN" = false ]; then
        blackhost_fail "Homebrew is not installed or not on PATH."
        blackhost_warn "Update Google Cloud CLI manually, then run scripts/core/init.sh gcloud check."
        return 1
    fi

    if ! command -v brew >/dev/null 2>&1; then
        blackhost_warn "Homebrew is not available; dry-run will still print the update command."
    fi

    if blackhost_confirm "Upgrade Google Cloud CLI with Homebrew now?"; then
        blackhost_run_cmd brew update
        blackhost_run_cmd brew upgrade --cask google-cloud-sdk
    else
        blackhost_warn "Google Cloud CLI upgrade skipped."
    fi
}

blackhost_gcloud_update_linux() {
    blackhost_section "Linux Update Path"

    if ! blackhost_os_is_debian_like; then
        blackhost_fail "Unsupported Linux distribution for automatic update."
        blackhost_warn "Supported automatic path is Debian/Ubuntu."
        blackhost_warn "Update Google Cloud CLI manually, then run scripts/core/init.sh gcloud check."
        return 1
    fi

    blackhost_warn "This path uses sudo and upgrades packages through apt."
    if blackhost_confirm "Upgrade Google Cloud CLI now?"; then
        blackhost_run_cmd sudo apt-get update
        blackhost_run_cmd sudo apt-get install --only-upgrade -y google-cloud-cli
    else
        blackhost_warn "Google Cloud CLI upgrade skipped."
    fi
}
