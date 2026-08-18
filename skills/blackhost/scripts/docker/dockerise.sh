#!/usr/bin/env bash

blackhost_dockerise_help() {
    cat <<'HELP'
blackhost docker dockerise

Scaffolds Docker deployment files for a target app directory.

Usage:
  scripts/core/init.sh [--json] docker dockerise <target-dir> [--type auto|php-apache|static-nginx] [--port 8080] [--force] [--dry-run] [--yes]

Options:
  --json         Append a compact machine-readable result object.
  --type VALUE   Scaffold type. Defaults to auto.
  --port VALUE   Container port exposed by generated config. Defaults to 8080.
  --force        Allow overwriting generated files that already exist.
  --dry-run      Print planned files without writing them.
  -y, --yes      Skip confirmation prompts.
  -h, --help     Show this help text.

Detection:
  php-apache     Selected when index.php or composer.json is found.
  static-nginx   Selected when index.html is found and PHP indicators are absent.
HELP
}

blackhost_docker_dockerise_help() {
    blackhost_dockerise_help
}

blackhost_docker_dockerise() {
    blackhost_dockerise "$@"
}

blackhost_dockerise() {
    local script_name="blackhost docker dockerise"
    local target_dir=""
    local target_root
    local scaffold_type="auto"
    local detected_type
    local port="8080"
    local force=false
    local composer_dir=""

    BLACKHOST_ASSUME_YES=false
    BLACKHOST_DRY_RUN=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --type)
                shift
                scaffold_type="${1:-}"
                ;;
            --type=*)
                scaffold_type="${1#--type=}"
                ;;
            --port)
                shift
                port="${1:-}"
                ;;
            --port=*)
                port="${1#--port=}"
                ;;
            --force)
                force=true
                ;;
            --dry-run)
                BLACKHOST_DRY_RUN=true
                ;;
            -y|--yes)
                BLACKHOST_ASSUME_YES=true
                ;;
            -h|--help)
                blackhost_dockerise_help
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
        blackhost_dockerise_help
        return 2
    fi

    case "$scaffold_type" in
        auto|php-apache|static-nginx)
            ;;
        *)
            blackhost_fail "Unsupported dockerise type: $scaffold_type"
            blackhost_warn "Expected one of: auto, php-apache, static-nginx."
            return 2
            ;;
    esac

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
    composer_dir="$(blackhost_dockerise_find_composer_dir "$target_root")"

    if [ "$scaffold_type" = "auto" ]; then
        detected_type="$(blackhost_dockerise_detect_type "$target_root" "$composer_dir")"
    else
        detected_type="$scaffold_type"
    fi

    if [ -z "$detected_type" ]; then
        blackhost_fail "Could not detect a supported Docker scaffold for $target_root."
        blackhost_warn "Use --type php-apache or --type static-nginx if you know the intended runtime."
        return 1
    fi

    blackhost_section "Dockerise Target App"
    blackhost_info "Target directory: $target_root"
    blackhost_info "Requested type: $scaffold_type"
    blackhost_info "Selected type: $detected_type"
    blackhost_info "Container port: $port"
    blackhost_info "Overwrite existing files: $force"
    blackhost_info "Dry-run mode: $BLACKHOST_DRY_RUN"

    case "$detected_type" in
        php-apache)
            if [ -n "$composer_dir" ]; then
                blackhost_info "Composer directory: $composer_dir"
            else
                blackhost_warn "No composer.json found. Generated PHP Dockerfile will not include a Composer vendor stage."
            fi
            blackhost_dockerise_preflight_php_apache "$target_root" "$force" || return 1
            ;;
        static-nginx)
            blackhost_dockerise_preflight_static_nginx "$target_root" "$force" || return 1
            ;;
    esac

    if ! blackhost_confirm "Create Docker scaffold files in $target_root?"; then
        blackhost_fail "Dockerise scaffold skipped."
        return 1
    fi

    case "$detected_type" in
        php-apache)
            blackhost_dockerise_write_php_apache "$target_root" "$composer_dir" "$port"
            ;;
        static-nginx)
            blackhost_dockerise_write_static_nginx "$target_root" "$port"
            ;;
    esac

    blackhost_section "Dockerise Summary"
    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_ok "Dry-run completed. No files were written."
    else
        blackhost_ok "Docker scaffold files are ready."
    fi
    blackhost_info "Next step: inspect generated files, then run docker build from the target directory."
}

blackhost_dockerise_find_composer_dir() {
    local target_root="$1"
    local composer_file
    local composer_dir

    if [ -f "$target_root/composer.json" ]; then
        printf '.\n'
        return 0
    fi

    composer_file="$(find "$target_root" -maxdepth 4 -type f -name composer.json -not -path '*/vendor/*' | sort | sed -n '1p')"

    if [ -z "$composer_file" ]; then
        return 0
    fi

    composer_dir="$(dirname "${composer_file#$target_root/}")"
    printf '%s\n' "$composer_dir"
}

blackhost_dockerise_detect_type() {
    local target_root="$1"
    local composer_dir="$2"

    if [ -f "$target_root/index.php" ] || [ -n "$composer_dir" ]; then
        printf 'php-apache\n'
        return 0
    fi

    if [ -f "$target_root/index.html" ]; then
        printf 'static-nginx\n'
        return 0
    fi

    return 0
}

blackhost_dockerise_check_writable() {
    local file="$1"
    local force="$2"

    if [ -e "$file" ] && [ "$force" != true ]; then
        if [ "$BLACKHOST_DRY_RUN" = true ]; then
            blackhost_warn "Existing file would block a real write without --force: $file"
            return 0
        fi

        blackhost_fail "Refusing to overwrite existing file: $file"
        blackhost_warn "Rerun with --force if replacing this file is intentional."
        return 1
    fi

    return 0
}

blackhost_dockerise_preflight_php_apache() {
    local target_root="$1"
    local force="$2"

    blackhost_dockerise_check_writable "$target_root/Dockerfile" "$force" || return 1
    blackhost_dockerise_check_writable "$target_root/.dockerignore" "$force" || return 1
    blackhost_dockerise_check_writable "$target_root/docker/apache/ports.conf" "$force" || return 1
    blackhost_dockerise_check_writable "$target_root/docker/apache/000-default.conf" "$force" || return 1
}

blackhost_dockerise_preflight_static_nginx() {
    local target_root="$1"
    local force="$2"

    blackhost_dockerise_check_writable "$target_root/Dockerfile" "$force" || return 1
    blackhost_dockerise_check_writable "$target_root/.dockerignore" "$force" || return 1
    blackhost_dockerise_check_writable "$target_root/docker/nginx/default.conf.template" "$force" || return 1
}

blackhost_dockerise_write_file() {
    local file="$1"
    local content

    content="$(cat)"

    if [ "$BLACKHOST_DRY_RUN" = true ]; then
        blackhost_info "Would write: $file"
        printf '%s\n' "$content" | sed 's/^/       /'
        return 0
    fi

    mkdir -p "$(dirname "$file")"
    printf '%s\n' "$content" >"$file"
    blackhost_ok "Wrote $file"
}

blackhost_dockerise_write_php_apache() {
    local target_root="$1"
    local composer_dir="$2"
    local port="$3"

    blackhost_dockerise_write_php_dockerfile "$target_root" "$composer_dir" "$port"
    blackhost_dockerise_write_common_dockerignore "$target_root/.dockerignore"

    blackhost_dockerise_write_file "$target_root/docker/apache/ports.conf" <<EOF
Listen \${PORT}
EOF

    blackhost_dockerise_write_file "$target_root/docker/apache/000-default.conf" <<EOF
ServerName localhost

<VirtualHost *:\${PORT}>
    DocumentRoot /var/www/html

    ErrorLog /proc/self/fd/2
    CustomLog /proc/self/fd/1 combined

    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
        DirectoryIndex index.php index.html

        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} -f [OR]
        RewriteCond %{REQUEST_FILENAME} -d
        RewriteRule ^ - [L]
        RewriteRule ^ index.php [L]
    </Directory>

    <Directory /var/www/html/docker>
        Require all denied
    </Directory>
</VirtualHost>
EOF
}

blackhost_dockerise_write_php_dockerfile() {
    local target_root="$1"
    local composer_dir="$2"
    local port="$3"
    local composer_workdir="/app"
    local composer_copy_line=""
    local vendor_source=""
    local vendor_target=""

    if [ -n "$composer_dir" ]; then
        if [ "$composer_dir" != "." ]; then
            composer_workdir="/app/$composer_dir"
            vendor_source="/app/$composer_dir/vendor"
            vendor_target="/var/www/html/$composer_dir/vendor"

            if [ -f "$target_root/$composer_dir/composer.lock" ]; then
                composer_copy_line="COPY $composer_dir/composer.json $composer_dir/composer.lock ./"
            else
                composer_copy_line="COPY $composer_dir/composer.json ./"
            fi
        else
            vendor_source="/app/vendor"
            vendor_target="/var/www/html/vendor"

            if [ -f "$target_root/composer.lock" ]; then
                composer_copy_line="COPY composer.json composer.lock ./"
            else
                composer_copy_line="COPY composer.json ./"
            fi
        fi

        blackhost_dockerise_write_file "$target_root/Dockerfile" <<EOF
FROM composer:2 AS vendor

WORKDIR $composer_workdir
$composer_copy_line
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader

FROM php:8.3-apache AS runtime

ENV PORT=$port

WORKDIR /var/www/html

RUN a2enmod rewrite headers

COPY docker/apache/ports.conf /etc/apache2/ports.conf
COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY . /var/www/html
COPY --from=vendor $vendor_source $vendor_target

EXPOSE $port
EOF
    else
        blackhost_dockerise_write_file "$target_root/Dockerfile" <<EOF
FROM php:8.3-apache AS runtime

ENV PORT=$port

WORKDIR /var/www/html

RUN a2enmod rewrite headers

COPY docker/apache/ports.conf /etc/apache2/ports.conf
COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY . /var/www/html

EXPOSE $port
EOF
    fi
}

blackhost_dockerise_write_static_nginx() {
    local target_root="$1"
    local port="$2"

    blackhost_dockerise_write_file "$target_root/Dockerfile" <<EOF
FROM nginx:1.27-alpine

ENV PORT=$port

COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY . /usr/share/nginx/html

EXPOSE $port
EOF

    blackhost_dockerise_write_common_dockerignore "$target_root/.dockerignore"

    blackhost_dockerise_write_file "$target_root/docker/nginx/default.conf.template" <<EOF
server {
    listen \${PORT};
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
}

blackhost_dockerise_write_common_dockerignore() {
    local file="$1"

    blackhost_dockerise_write_file "$file" <<'EOF'
.env
.env.*
!.env.example
.DS_Store
.git
.gitignore
.dockerignore
Dockerfile
compose.yaml
docker-compose.yml
node_modules/
vendor/
*/vendor/
coverage/
tmp/
temp/
*.log
EOF
}
