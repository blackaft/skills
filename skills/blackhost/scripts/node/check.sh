#!/usr/bin/env bash

blackhost_node_check_help() {
    cat <<'HELP'
blackhost node check

Checks whether the host is ready to run Node.js, npm, and npx workloads.

Usage:
  scripts/core/init.sh [--json] node check [--yes] [--verbose]

Options:
  --json         Append a compact machine-readable result object.
  -y, --yes      Do not pause for the final acknowledgement prompt.
  -v, --verbose  Print extra Node.js, npm, and npx diagnostic output when available.
  -h, --help     Show this help text.
HELP
}

blackhost_node_check() {
    local script_name="blackhost node check"
    local verbose=false
    local node_available=false
    local npm_available=false
    local npx_available=false

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
                blackhost_node_check_help
                return 0
                ;;
            *)
                echo "[$script_name] Unknown option: $arg" >&2
                return 2
                ;;
        esac
    done

    blackhost_section "Node.js Host Readiness Check"
    blackhost_info "This script does not install or change Node.js, npm, or npx."
    blackhost_info "It checks the local machine for JavaScript runtime and package runner readiness."
    blackhost_info "Current directory: $(pwd)"
    blackhost_info "Detected OS: $BLACKHOST_OS_PRETTY"
    blackhost_info "Detected OS id: $BLACKHOST_OS_ID"
    blackhost_info "Detected architecture: $BLACKHOST_ARCH"

    blackhost_section "Node.js"
    if blackhost_node_print_version; then
        node_available=true
    else
        blackhost_warn "Install Node.js before attempting JavaScript application workflows."
    fi

    blackhost_section "npm"
    if blackhost_node_print_npm_version; then
        npm_available=true
    else
        blackhost_warn "Install npm before JavaScript dependency installation or package script workflows."
    fi

    blackhost_section "npx"
    if blackhost_node_print_npx_version; then
        npx_available=true
    else
        blackhost_warn "Install npx before one-off package runner workflows."
    fi

    blackhost_section "Runtime Smoke Capability"
    if [ "$node_available" = true ]; then
        if node -e 'process.stdout.write("Node.js runtime executed successfully: " + process.version + "\n")' >/dev/null 2>&1; then
            blackhost_ok "Node.js can execute inline runtime code."
        else
            blackhost_fail "Node.js exists, but inline runtime execution failed."
        fi
    else
        blackhost_warn "Skipping runtime smoke test because Node.js is unavailable."
    fi

    if [ "$verbose" = true ]; then
        blackhost_section "Verbose Node.js Tooling"
        blackhost_node_print_executable || true
        if [ "$npm_available" = true ]; then
            npm config list 2>/dev/null | sed 's/^/       /' || blackhost_warn "Could not read npm configuration."
        fi
    fi

    blackhost_section "Summary"
    if [ "$node_available" = true ] && [ "$npm_available" = true ] && [ "$npx_available" = true ]; then
        blackhost_ok "Node.js, npm, and npx host tooling is ready."
        blackhost_ack "Review the Node.js readiness result above. Press Enter to finish, or Ctrl+C to stop here."
        return 0
    fi

    blackhost_fail "Node.js host tooling is not fully ready."
    blackhost_warn "Recommended next step: run scripts/core/init.sh node install or scripts/core/init.sh node update as appropriate."
    blackhost_ack "Review the Node.js readiness result above. Press Enter to finish, or Ctrl+C to stop here."
    return 1
}
