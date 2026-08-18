#!/usr/bin/env bash
set -euo pipefail

BLACKHOST_ASSURANCE_ENTRYPOINT="${BASH_SOURCE[0]}"
BLACKHOST_ASSURANCE_DIR="$(cd "$(dirname "$BLACKHOST_ASSURANCE_ENTRYPOINT")" && pwd)"
BLACKHOST_SKILL_ROOT="$(dirname "$BLACKHOST_ASSURANCE_DIR")"
BLACKHOST_RUN="$BLACKHOST_SKILL_ROOT/scripts/core/init.sh"
BLACKHOST_ASSURANCE_LOG_PATH="${BLACKHOST_ASSURANCE_LOG_PATH:-$BLACKHOST_ASSURANCE_DIR/log.txt}"
export BLACKHOST_ASSURANCE_LOG_PATH
BLACKHOST_OPEN_INDEX=false
export BLACKHOST_OPEN_INDEX

if [ "${BLACKHOST_ASSURANCE_LOG_ACTIVE:-false}" != true ]; then
    : >"$BLACKHOST_ASSURANCE_LOG_PATH"
    BLACKHOST_ASSURANCE_LOG_ACTIVE=true
    export BLACKHOST_ASSURANCE_LOG_ACTIVE
    exec > >(tee "$BLACKHOST_ASSURANCE_LOG_PATH") 2>&1
fi

# shellcheck disable=SC1091
. "$BLACKHOST_SKILL_ROOT/scripts/core/helpers/run.sh"
blackhost_bootstrap "$BLACKHOST_RUN"

blackhost_assurance_section() {
    printf '\n'
    printf '%s\n' '------------------------------------------------------------------------'
    printf '%s\n' "$1"
    printf '%s\n' '------------------------------------------------------------------------'
}

blackhost_assurance_pass() {
    printf '[PASS] %s\n' "$1"
}

blackhost_assurance_fail() {
    printf '[FAIL] %s\n' "$1" >&2
}

blackhost_assurance_tmpdir() {
    mktemp -d "${TMPDIR:-/tmp}/blackhost-dry.XXXXXX"
}

blackhost_assurance_cleanup() {
    if [ -n "${BLACKHOST_ASSURANCE_TMPDIR:-}" ] && [ -d "$BLACKHOST_ASSURANCE_TMPDIR" ]; then
        rm -rf "$BLACKHOST_ASSURANCE_TMPDIR"
    fi
}

blackhost_assurance_assert_contains() {
    local file="$1"
    local expected="$2"

    if rg -F "$expected" "$file" >/dev/null 2>&1; then
        blackhost_assurance_pass "Found expected output: $expected"
        return 0
    fi

    blackhost_assurance_fail "Expected output was missing: $expected"
    sed 's/^/       /' "$file" >&2
    return 1
}

blackhost_assurance_assert_not_exists() {
    local path="$1"

    if [ -e "$path" ]; then
        blackhost_assurance_fail "Dry-run unexpectedly created: $path"
        return 1
    fi

    blackhost_assurance_pass "Confirmed dry-run did not create: $path"
}

blackhost_assurance_run_capture() {
    local name="$1"
    local output_file="$2"
    local exit_code

    shift 2

    blackhost_assurance_section "$name"
    printf '[INFO] Command: scripts/core/init.sh'
    printf ' %q' "$@"
    printf '\n'

    set +e
    bash "$BLACKHOST_RUN" "$@" >"$output_file" 2>&1
    exit_code=$?
    set -e

    if [ "$exit_code" -ne 0 ]; then
        blackhost_assurance_fail "$name exited $exit_code"
        sed 's/^/       /' "$output_file" >&2
        return "$exit_code"
    fi

    blackhost_assurance_pass "$name exited 0"
}

blackhost_assurance_expected_host() {
    case "$BLACKHOST_OS" in
        macos)
            return 0
            ;;
        linux)
            if blackhost_os_is_debian_like; then
                return 0
            fi
            ;;
    esac

    blackhost_assurance_fail "Unsupported host for dry-run assurance: $BLACKHOST_OS_PRETTY"
    return 1
}

blackhost_assurance_expected_command() {
    local package="$1"
    local action="$2"

    case "$BLACKHOST_OS:$package:$action" in
        macos:docker:install) printf 'brew install --cask docker\n' ;;
        macos:docker:update) printf 'brew upgrade --cask docker\n' ;;
        macos:aws:install) printf 'curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash\n' ;;
        macos:aws:update) printf 'aws update\n' ;;
        macos:gcloud:install) printf 'brew install --cask google-cloud-sdk\n' ;;
        macos:gcloud:update) printf 'brew upgrade --cask google-cloud-sdk\n' ;;
        macos:git:install) printf 'brew install git\n' ;;
        macos:git:update) printf 'brew upgrade git\n' ;;
        macos:gh:install) printf 'brew install gh\n' ;;
        macos:gh:update) printf 'brew upgrade gh\n' ;;
        macos:homebrew:install) printf '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"\n' ;;
        macos:homebrew:update) printf 'brew upgrade\n' ;;
        macos:php:install) printf 'brew install php composer\n' ;;
        macos:php:update) printf 'brew upgrade php composer\n' ;;
        macos:python:install) printf 'brew install python\n' ;;
        macos:python:update) printf 'brew upgrade python\n' ;;
        macos:yaml:install) printf 'python3 -m venv\n' ;;
        macos:yaml:update) printf 'python3 -m venv\n' ;;
        macos:node:install) printf 'brew install node\n' ;;
        macos:node:update) printf 'brew upgrade node\n' ;;
        linux:docker:install) printf 'apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin\n' ;;
        linux:docker:update) printf 'apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin\n' ;;
        linux:aws:install) printf 'curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash\n' ;;
        linux:aws:update) printf 'aws update\n' ;;
        linux:gcloud:install) printf 'apt-get install -y google-cloud-cli\n' ;;
        linux:gcloud:update) printf 'apt-get install --only-upgrade -y google-cloud-cli\n' ;;
        linux:git:install) printf 'apt-get install -y git\n' ;;
        linux:git:update) printf 'apt-get install --only-upgrade -y git\n' ;;
        linux:gh:install) printf 'apt-get install -y gh\n' ;;
        linux:gh:update) printf 'apt-get install --only-upgrade -y gh\n' ;;
        linux:homebrew:install) printf '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"\n' ;;
        linux:homebrew:update) printf 'brew upgrade\n' ;;
        linux:php:install) printf 'apt-get install -y php-cli php-common php-mbstring php-xml php-curl php-zip php-intl composer unzip git\n' ;;
        linux:php:update) printf 'apt-get install --only-upgrade -y php-cli php-common php-mbstring php-xml php-curl php-zip php-intl composer unzip git\n' ;;
        linux:python:install) printf 'apt-get install -y python3 python3-pip python3-venv python3-dev build-essential\n' ;;
        linux:python:update) printf 'apt-get install --only-upgrade -y python3 python3-pip python3-venv python3-dev build-essential\n' ;;
        linux:yaml:install) printf 'python3 -m venv\n' ;;
        linux:yaml:update) printf 'python3 -m venv\n' ;;
        linux:node:install) printf 'apt-get install -y nodejs npm\n' ;;
        linux:node:update) printf 'apt-get install --only-upgrade -y nodejs npm\n' ;;
        *)
            blackhost_assurance_fail "No expected command registered for $package $action on $BLACKHOST_OS"
            return 1
            ;;
    esac
}

blackhost_assurance_check_command_dry_run() {
    local package="$1"
    local action="$2"
    local expected
    local output_file

    expected="$(blackhost_assurance_expected_command "$package" "$action")"
    output_file="$BLACKHOST_ASSURANCE_TMPDIR/$package-$action.txt"

    blackhost_assurance_run_capture "$package $action dry-run" "$output_file" --json "$package" "$action" --dry-run --yes
    blackhost_assurance_assert_contains "$output_file" "$expected"
    blackhost_assurance_assert_contains "$output_file" "Dry-Run Summary"
    blackhost_assurance_assert_contains "$output_file" "No host or workspace changes were executed."
    blackhost_assurance_assert_contains "$output_file" '"schema":"blackhost.result"'
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

blackhost_assurance_check_docker_prune_dry_run() {
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/docker-update-prune.txt"

    blackhost_assurance_run_capture "docker update prune dry-run" "$output_file" --json docker update --dry-run --yes --prune
    blackhost_assurance_assert_contains "$output_file" "docker system prune"
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

blackhost_assurance_check_dockerise_dry_run() {
    local app_dir="$BLACKHOST_ASSURANCE_TMPDIR/static-app"
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/dockerise-static.txt"

    mkdir -p "$app_dir"
    printf '<!doctype html><title>blackhost dry-run</title>\n' >"$app_dir/index.html"
    app_dir="$(cd "$app_dir" && pwd)"

    blackhost_assurance_run_capture "dockerise static dry-run" "$output_file" --json docker dockerise "$app_dir" --type static-nginx --dry-run --yes
    blackhost_assurance_assert_contains "$output_file" "Would write: $app_dir/Dockerfile"
    blackhost_assurance_assert_contains "$output_file" "Dry-run completed. No files were written."
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
    blackhost_assurance_assert_not_exists "$app_dir/Dockerfile"
    blackhost_assurance_assert_not_exists "$app_dir/.dockerignore"
    blackhost_assurance_assert_not_exists "$app_dir/docker"
}

blackhost_assurance_check_docker_run_dry_run() {
    local app_dir="$BLACKHOST_ASSURANCE_TMPDIR/run-app"
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/docker-run.txt"

    mkdir -p "$app_dir"
    cat >"$app_dir/Dockerfile" <<'EOF'
FROM nginx:1.27-alpine
EXPOSE 8080
EOF
    app_dir="$(cd "$app_dir" && pwd)"

    blackhost_assurance_run_capture "docker run app dry-run" "$output_file" --json docker run "$app_dir" --dry-run --yes --open
    blackhost_assurance_assert_contains "$output_file" "docker build -t blackhost-run-app $app_dir"
    blackhost_assurance_assert_contains "$output_file" "docker run -d --name blackhost-run-app -p 8080:8080 blackhost-run-app"
    blackhost_assurance_assert_contains "$output_file" "http://localhost:8080"
    blackhost_assurance_assert_contains "$output_file" "No image was built, no container was started, and no browser was opened."
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

blackhost_assurance_check_php_run_dry_run() {
    local app_dir="$BLACKHOST_ASSURANCE_TMPDIR/php-app"
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/php-run.txt"

    mkdir -p "$app_dir"
    printf '<?php echo "blackhost";\n' >"$app_dir/index.php"
    app_dir="$(cd "$app_dir" && pwd)"

    blackhost_assurance_run_capture "php run app dry-run" "$output_file" --json php run "$app_dir" --port 8091 --dry-run --yes --open
    blackhost_assurance_assert_contains "$output_file" "php -S '127.0.0.1:8091' -t '$app_dir'"
    blackhost_assurance_assert_contains "$output_file" "http://127.0.0.1:8091"
    blackhost_assurance_assert_contains "$output_file" "No server was started and no browser was opened."
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

blackhost_assurance_check_python_run_dry_run() {
    local app_dir="$BLACKHOST_ASSURANCE_TMPDIR/python-app"
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/python-run.txt"

    mkdir -p "$app_dir"
    printf '<!doctype html><title>blackhost python</title>\n' >"$app_dir/index.html"
    app_dir="$(cd "$app_dir" && pwd)"

    blackhost_assurance_run_capture "python run app dry-run" "$output_file" --json python run "$app_dir" --port 8092 --dry-run --yes --open
    blackhost_assurance_assert_contains "$output_file" "python3 -m http.server '8092' --bind '127.0.0.1' --directory '$app_dir'"
    blackhost_assurance_assert_contains "$output_file" "http://127.0.0.1:8092"
    blackhost_assurance_assert_contains "$output_file" "No server was started and no browser was opened."
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

blackhost_assurance_check_node_run_dry_run() {
    local app_dir="$BLACKHOST_ASSURANCE_TMPDIR/node-app"
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/node-run.txt"

    mkdir -p "$app_dir"
    cat >"$app_dir/package.json" <<'EOF'
{
  "scripts": {
    "dev": "node -e \"setInterval(function(){}, 1000)\""
  }
}
EOF
    app_dir="$(cd "$app_dir" && pwd)"

    blackhost_assurance_run_capture "node run app dry-run" "$output_file" --json node run "$app_dir" --port 8093 --dry-run --yes --open
    blackhost_assurance_assert_contains "$output_file" "npm run 'dev' -- --host '127.0.0.1' --port '8093'"
    blackhost_assurance_assert_contains "$output_file" "http://127.0.0.1:8093"
    blackhost_assurance_assert_contains "$output_file" "No npm script was started and no browser was opened."
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

blackhost_assurance_check_yaml_run_dry_run() {
    local yaml_file="$BLACKHOST_ASSURANCE_TMPDIR/sample.yml"
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/yaml-run.txt"

    printf 'blackhost: true\n' >"$yaml_file"
    yaml_file="$(cd "$(dirname "$yaml_file")" && pwd)/$(basename "$yaml_file")"

    blackhost_assurance_run_capture "yaml run dry-run" "$output_file" --json yaml run "$yaml_file" --dry-run --yes
    blackhost_assurance_assert_contains "$output_file" " -c"
    blackhost_assurance_assert_contains "$output_file" "$yaml_file"
    blackhost_assurance_assert_contains "$output_file" "The YAML file was not parsed."
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

blackhost_assurance_check_gh_auth_dry_run() {
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/gh-auth.txt"

    blackhost_assurance_run_capture "gh auth dry-run" "$output_file" --json gh auth --dry-run --yes
    blackhost_assurance_assert_contains "$output_file" "gh auth login --hostname github.com --git-protocol https --web"
    blackhost_assurance_assert_contains "$output_file" "No browser authentication was started."
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

blackhost_assurance_check_gcloud_auth_dry_run() {
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/gcloud-auth.txt"

    blackhost_assurance_run_capture "gcloud auth dry-run" "$output_file" --json gcloud auth --dry-run --yes
    blackhost_assurance_assert_contains "$output_file" "gcloud auth login"
    blackhost_assurance_assert_contains "$output_file" "No browser authentication was started."
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

blackhost_assurance_check_aws_auth_dry_run() {
    local output_file="$BLACKHOST_ASSURANCE_TMPDIR/aws-auth.txt"

    blackhost_assurance_run_capture "aws auth dry-run" "$output_file" --json aws auth --dry-run --yes
    blackhost_assurance_assert_contains "$output_file" "aws sso login --profile default"
    blackhost_assurance_assert_contains "$output_file" "No browser authentication was started."
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'

    blackhost_assurance_run_capture "aws auth configure dry-run" "$output_file" --json aws auth --profile default --configure --dry-run --yes
    blackhost_assurance_assert_contains "$output_file" "aws configure sso --profile default"
    blackhost_assurance_assert_contains "$output_file" '"dry_run":true'
}

main() {
    blackhost_assurance_section "Blackhost Dry-Run Assurance"
    printf '[INFO] Skill root: %s\n' "$BLACKHOST_SKILL_ROOT"
    printf '[INFO] Detected OS: %s\n' "$BLACKHOST_OS_PRETTY"
    printf '[INFO] Detected architecture: %s\n' "$BLACKHOST_ARCH"

    blackhost_assurance_expected_host

    BLACKHOST_ASSURANCE_TMPDIR="$(blackhost_assurance_tmpdir)"
    trap blackhost_assurance_cleanup EXIT

    blackhost_assurance_check_command_dry_run aws install
    blackhost_assurance_check_command_dry_run aws update
    blackhost_assurance_check_command_dry_run docker install
    blackhost_assurance_check_command_dry_run docker update
    blackhost_assurance_check_docker_prune_dry_run
    blackhost_assurance_check_command_dry_run gcloud install
    blackhost_assurance_check_command_dry_run gcloud update
    blackhost_assurance_check_command_dry_run git install
    blackhost_assurance_check_command_dry_run git update
    blackhost_assurance_check_command_dry_run gh install
    blackhost_assurance_check_command_dry_run gh update
    blackhost_assurance_check_gh_auth_dry_run
    blackhost_assurance_check_gcloud_auth_dry_run
    blackhost_assurance_check_command_dry_run homebrew install
    blackhost_assurance_check_command_dry_run homebrew update
    blackhost_assurance_check_aws_auth_dry_run
    blackhost_assurance_check_command_dry_run php install
    blackhost_assurance_check_command_dry_run php update
    blackhost_assurance_check_command_dry_run python install
    blackhost_assurance_check_command_dry_run python update
    blackhost_assurance_check_command_dry_run yaml install
    blackhost_assurance_check_command_dry_run yaml update
    blackhost_assurance_check_command_dry_run node install
    blackhost_assurance_check_command_dry_run node update
    blackhost_assurance_check_dockerise_dry_run
    blackhost_assurance_check_docker_run_dry_run
    blackhost_assurance_check_php_run_dry_run
    blackhost_assurance_check_python_run_dry_run
    blackhost_assurance_check_node_run_dry_run
    blackhost_assurance_check_yaml_run_dry_run

    blackhost_assurance_section "Dry-Run Assurance Summary"
    blackhost_assurance_pass "All dry-run checks passed."
}

main "$@"
