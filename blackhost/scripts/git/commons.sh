#!/usr/bin/env bash

blackhost_git_cli_available() {
    command -v git >/dev/null 2>&1
}

blackhost_git_print_version() {
    if blackhost_git_cli_available; then
        blackhost_ok "$(git --version 2>&1)"
        return 0
    fi

    blackhost_fail "git is not available."
    return 1
}

blackhost_git_print_repo() {
    if blackhost_git_cli_available && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        blackhost_ok "Current directory is inside a Git worktree."
        blackhost_info "Repository root: $(git rev-parse --show-toplevel 2>/dev/null)"
        blackhost_info "Current branch: $(git branch --show-current 2>/dev/null || printf 'unknown')"
        return 0
    fi

    blackhost_warn "Current directory is not inside a Git worktree."
    return 1
}

blackhost_git_print_identity() {
    local name
    local email

    name="$(git config --global user.name 2>/dev/null || true)"
    email="$(git config --global user.email 2>/dev/null || true)"

    if [ -n "$name" ]; then
        blackhost_ok "Global git user.name: $name"
    else
        blackhost_warn "Global git user.name is not set."
    fi

    if [ -n "$email" ]; then
        blackhost_ok "Global git user.email: $email"
    else
        blackhost_warn "Global git user.email is not set."
    fi
}
