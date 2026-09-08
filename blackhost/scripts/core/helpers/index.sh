#!/usr/bin/env bash

BLACKHOST_LOCAL_ROOT="${BLACKHOST_LOCAL_ROOT:-$BLACKHOST_SKILL_ROOT/local}"
BLACKHOST_INDEX_PATH="${BLACKHOST_INDEX_PATH:-$BLACKHOST_LOCAL_ROOT/index.json}"
BLACKHOST_INDEX_HTML_PATH="${BLACKHOST_INDEX_HTML_PATH:-$BLACKHOST_LOCAL_ROOT/index.html}"
BLACKHOST_INDEX_URL="${BLACKHOST_INDEX_URL:-http://localhost:8765/index.html}"
BLACKHOST_INDEX_SERVER_HOST="${BLACKHOST_INDEX_SERVER_HOST:-127.0.0.1}"
BLACKHOST_INDEX_SERVER_PORT="${BLACKHOST_INDEX_SERVER_PORT:-8765}"
BLACKHOST_INDEX_SERVER_PID_PATH="${BLACKHOST_INDEX_SERVER_PID_PATH:-$BLACKHOST_LOCAL_ROOT/index-server.pid}"
BLACKHOST_INDEX_SERVER_LOG_PATH="${BLACKHOST_INDEX_SERVER_LOG_PATH:-$BLACKHOST_LOCAL_ROOT/index-server.log}"
BLACKHOST_ASSURANCE_LOG_PATH="${BLACKHOST_ASSURANCE_LOG_PATH:-$BLACKHOST_SKILL_ROOT/assurance/log.txt}"

blackhost_now_utc() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

blackhost_json_string() {
    awk '
        BEGIN { printf "\"" }
        {
            gsub(/\\/, "\\\\")
            gsub(/"/, "\\\"")
            gsub(/\t/, "\\t")
            gsub(/\r/, "\\r")
            if (NR > 1) {
                printf "\\n"
            }
            printf "%s", $0
        }
        END { printf "\"" }
    '
}

blackhost_html_escape() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

blackhost_tool_available_json() {
    local command_name="$1"

    if command -v "$command_name" >/dev/null 2>&1; then
        printf 'true'
    else
        printf 'false'
    fi
}

blackhost_tool_version_json() {
    local version_output

    version_output="$("$@" 2>/dev/null | sed -n '1p' || true)"
    blackhost_json_string <<EOF
$version_output
EOF
}

blackhost_tool_version_text() {
    "$@" 2>/dev/null | sed -n '1p' || true
}

blackhost_yaml_python_bin_for_index() {
    if [ -x "$BLACKHOST_LOCAL_ROOT/.venv/bin/python" ]; then
        printf '%s\n' "$BLACKHOST_LOCAL_ROOT/.venv/bin/python"
    else
        printf '%s\n' "python3"
    fi
}

blackhost_index_write_json() {
    local package="$1"
    local command="$2"
    local exit_code="$3"
    local output_file="$4"
    local now="$5"
    local status="error"
    local terminal_output_json
    local docker_available
    local docker_compose_available=false
    local docker_buildx_available=false
    local php_available
    local composer_available
    local git_available
    local brew_available
    local gh_available
    local gh_auth_available=false
    local gcloud_available
    local gcloud_auth_available=false
    local aws_available
    local aws_profile_available=false
    local python_available
    local pip_available=false
    local venv_available=false
    local node_available
    local npm_available
    local npx_available
    local pyyaml_available=false
    local yaml_python_bin
    local docker_version_json
    local docker_compose_version_json
    local docker_buildx_version_json
    local php_version_json
    local composer_version_json
    local git_version_json
    local brew_version_json
    local gh_version_json
    local gh_auth_version_json
    local gcloud_version_json
    local gcloud_auth_version_json
    local aws_version_json
    local aws_profile_version_json
    local python_version_json
    local pip_version_json
    local venv_version_json
    local node_version_json
    local npm_version_json
    local npx_version_json
    local pyyaml_version_json
    local index_tmp

    if [ "$exit_code" -eq 0 ]; then
        status="ok"
    fi

    terminal_output_json="$(blackhost_json_string <"$output_file")"

    docker_available="$(blackhost_tool_available_json docker)"
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker_compose_available=true
    elif command -v docker-compose >/dev/null 2>&1; then
        docker_compose_available=true
    fi
    if command -v docker >/dev/null 2>&1 && docker buildx version >/dev/null 2>&1; then
        docker_buildx_available=true
    fi

    php_available="$(blackhost_tool_available_json php)"
    composer_available="$(blackhost_tool_available_json composer)"
    git_available="$(blackhost_tool_available_json git)"
    brew_available="$(blackhost_tool_available_json brew)"
    gh_available="$(blackhost_tool_available_json gh)"
    if command -v gh >/dev/null 2>&1 && gh auth status --hostname github.com >/dev/null 2>&1; then
        gh_auth_available=true
    fi
    gcloud_available="$(blackhost_tool_available_json gcloud)"
    if [ -f "${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/configurations/config_default" ] && sed -n 's/^[[:space:]]*account[[:space:]]*=[[:space:]]*//p' "${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/configurations/config_default" | sed -n '1p' | grep -q .; then
        gcloud_auth_available=true
    fi
    aws_available="$(blackhost_tool_available_json aws)"
    if { [ -f "$HOME/.aws/config" ] && awk '/^\[default\]/{ found=1 } END { exit !found }' "$HOME/.aws/config"; } || { [ -f "$HOME/.aws/credentials" ] && awk '/^\[default\]/{ found=1 } END { exit !found }' "$HOME/.aws/credentials"; }; then
        aws_profile_available=true
    fi
    python_available="$(blackhost_tool_available_json python3)"
    if command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1; then
        pip_available=true
    fi
    if command -v python3 >/dev/null 2>&1 && python3 -m venv --help >/dev/null 2>&1; then
        venv_available=true
    fi
    node_available="$(blackhost_tool_available_json node)"
    npm_available="$(blackhost_tool_available_json npm)"
    npx_available="$(blackhost_tool_available_json npx)"
    yaml_python_bin="$(blackhost_yaml_python_bin_for_index)"
    if command -v python3 >/dev/null 2>&1 && "$yaml_python_bin" -c 'import yaml' >/dev/null 2>&1; then
        pyyaml_available=true
    fi

    docker_version_json="$(blackhost_tool_version_json docker --version)"
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker_compose_version_json="$(blackhost_tool_version_json docker compose version)"
    elif command -v docker-compose >/dev/null 2>&1; then
        docker_compose_version_json="$(blackhost_tool_version_json docker-compose --version)"
    else
        docker_compose_version_json="$(printf '' | blackhost_json_string)"
    fi
    if command -v docker >/dev/null 2>&1 && docker buildx version >/dev/null 2>&1; then
        docker_buildx_version_json="$(blackhost_tool_version_json docker buildx version)"
    else
        docker_buildx_version_json="$(printf '' | blackhost_json_string)"
    fi
    php_version_json="$(blackhost_tool_version_json php --version)"
    composer_version_json="$(blackhost_tool_version_json composer --version)"
    git_version_json="$(blackhost_tool_version_json git --version)"
    brew_version_json="$(blackhost_tool_version_json brew --version)"
    gh_version_json="$(blackhost_tool_version_json gh --version)"
    if command -v gcloud >/dev/null 2>&1; then
        gcloud_version_json="$(printf '%s\n' 'available; version not probed during index refresh' | blackhost_json_string)"
    else
        gcloud_version_json="$(printf '' | blackhost_json_string)"
    fi
    if [ "$gh_auth_available" = true ]; then
        gh_auth_version_json="$(printf '%s\n' 'authenticated for github.com' | blackhost_json_string)"
    else
        gh_auth_version_json="$(printf '' | blackhost_json_string)"
    fi
    if [ "$gcloud_auth_available" = true ]; then
        gcloud_auth_version_json="$(sed -n 's/^[[:space:]]*account[[:space:]]*=[[:space:]]*//p' "${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/configurations/config_default" | sed -n '1p' | blackhost_json_string)"
    else
        gcloud_auth_version_json="$(printf '' | blackhost_json_string)"
    fi
    aws_version_json="$(blackhost_tool_version_json aws --version)"
    if [ "$aws_profile_available" = true ]; then
        aws_profile_version_json="$(printf '%s\n' 'default profile configured; identity not probed during index refresh' | blackhost_json_string)"
    else
        aws_profile_version_json="$(printf '' | blackhost_json_string)"
    fi
    python_version_json="$(blackhost_tool_version_json python3 --version)"
    pip_version_json="$(blackhost_tool_version_json python3 -m pip --version)"
    if [ "$venv_available" = true ]; then
        venv_version_json="$(printf '%s\n' 'available through python3 -m venv' | blackhost_json_string)"
    else
        venv_version_json="$(printf '' | blackhost_json_string)"
    fi
    node_version_json="$(blackhost_tool_version_json node --version)"
    npm_version_json="$(blackhost_tool_version_json npm --version)"
    npx_version_json="$(blackhost_tool_version_json npx --version)"
    if [ "$pyyaml_available" = true ]; then
        pyyaml_version_json="$(blackhost_tool_version_json "$yaml_python_bin" -c 'import yaml; print("PyYAML " + getattr(yaml, "__version__", "unknown"))')"
    else
        pyyaml_version_json="$(printf '' | blackhost_json_string)"
    fi

    mkdir -p "$(dirname "$BLACKHOST_INDEX_PATH")"
    index_tmp="$(mktemp "$(dirname "$BLACKHOST_INDEX_PATH")/index.json.XXXXXX")"

    cat >"$index_tmp" <<EOF
{
    "schema": {
        "name": "blackhost.local_index",
        "version": "0.1.0"
    },
    "updated_at": "$now",
    "local_root": "local/",
    "host": {
        "os": "$(blackhost_json_escape "${BLACKHOST_OS:-unknown}")",
        "os_id": "$(blackhost_json_escape "${BLACKHOST_OS_ID:-unknown}")",
        "os_pretty": "$(blackhost_json_escape "${BLACKHOST_OS_PRETTY:-unknown}")",
        "arch": "$(blackhost_json_escape "${BLACKHOST_ARCH:-unknown}")"
    },
    "last_action": {
        "package": "$(blackhost_json_escape "$package")",
        "command": "$(blackhost_json_escape "$command")",
        "status": "$status",
        "exit_code": $exit_code,
        "dry_run": $BLACKHOST_DRY_RUN,
        "ran_at": "$now",
        "terminal_output": $terminal_output_json
    },
    "packages": {
        "docker": {
            "checked_at": "$now",
            "tools": {
                "docker": {
                    "available": $docker_available,
                    "version": $docker_version_json
                },
                "docker_compose": {
                    "available": $docker_compose_available,
                    "version": $docker_compose_version_json
                },
                "docker_buildx": {
                    "available": $docker_buildx_available,
                    "version": $docker_buildx_version_json
                }
            }
        },
        "php": {
            "checked_at": "$now",
            "tools": {
                "php": {
                    "available": $php_available,
                    "version": $php_version_json
                },
                "composer": {
                    "available": $composer_available,
                    "version": $composer_version_json
                }
            }
        },
        "git": {
            "checked_at": "$now",
            "tools": {
                "git": {
                    "available": $git_available,
                    "version": $git_version_json
                }
            }
        },
        "homebrew": {
            "checked_at": "$now",
            "tools": {
                "brew": {
                    "available": $brew_available,
                    "version": $brew_version_json
                }
            }
        },
        "gh": {
            "checked_at": "$now",
            "tools": {
                "gh": {
                    "available": $gh_available,
                    "version": $gh_version_json
                },
                "auth_github_com": {
                    "available": $gh_auth_available,
                    "version": $gh_auth_version_json
                }
            }
        },
        "gcloud": {
            "checked_at": "$now",
            "tools": {
                "gcloud": {
                    "available": $gcloud_available,
                    "version": $gcloud_version_json
                },
                "auth": {
                    "available": $gcloud_auth_available,
                    "version": $gcloud_auth_version_json
                }
            }
        },
        "aws": {
            "checked_at": "$now",
            "tools": {
                "aws": {
                    "available": $aws_available,
                    "version": $aws_version_json
                },
                "profile_default": {
                    "available": $aws_profile_available,
                    "version": $aws_profile_version_json
                }
            }
        },
        "python": {
            "checked_at": "$now",
            "tools": {
                "python3": {
                    "available": $python_available,
                    "version": $python_version_json
                },
                "pip": {
                    "available": $pip_available,
                    "version": $pip_version_json
                },
                "venv": {
                    "available": $venv_available,
                    "version": $venv_version_json
                }
            }
        },
        "node": {
            "checked_at": "$now",
            "tools": {
                "node": {
                    "available": $node_available,
                    "version": $node_version_json
                },
                "npm": {
                    "available": $npm_available,
                    "version": $npm_version_json
                },
                "npx": {
                    "available": $npx_available,
                    "version": $npx_version_json
                }
            }
        },
        "yaml": {
            "checked_at": "$now",
            "tools": {
                "pyyaml": {
                    "available": $pyyaml_available,
                    "version": $pyyaml_version_json
                }
            }
        }
    }
}
EOF

    mv "$index_tmp" "$BLACKHOST_INDEX_PATH"
}

blackhost_index_render_html() {
    local package="$1"
    local command="$2"
    local exit_code="$3"
    local output_file="$4"
    local now="$5"
    local status_class="danger"
    local status_text="error"
    local terminal_html
    local assurance_log_html="assurance/log.txt has not been generated yet."
    local docker_version
    local php_version
    local composer_version
    local git_version
    local brew_version
    local gh_version
    local gh_auth_text="not authenticated"
    local gcloud_version
    local gcloud_auth_text="not authenticated"
    local aws_version
    local aws_profile_text="not configured"
    local python_version
    local pip_version
    local node_version
    local npm_version
    local npx_version
    local pyyaml_version
    local yaml_python_bin
    local index_html_tmp

    if [ "$exit_code" -eq 0 ]; then
        status_class="success"
        status_text="ok"
    fi

    terminal_html="$(blackhost_html_escape <"$output_file")"
    if [ -f "$BLACKHOST_ASSURANCE_LOG_PATH" ]; then
        assurance_log_html="$(blackhost_html_escape <"$BLACKHOST_ASSURANCE_LOG_PATH")"
    fi
    docker_version="$(blackhost_tool_version_text docker --version)"
    php_version="$(blackhost_tool_version_text php --version)"
    composer_version="$(blackhost_tool_version_text composer --version)"
    git_version="$(blackhost_tool_version_text git --version)"
    brew_version="$(blackhost_tool_version_text brew --version)"
    gh_version="$(blackhost_tool_version_text gh --version)"
    if command -v gh >/dev/null 2>&1 && gh auth status --hostname github.com >/dev/null 2>&1; then
        gh_auth_text="authenticated for github.com"
    fi
    if command -v gcloud >/dev/null 2>&1; then
        gcloud_version="available; version not probed during index refresh"
    else
        gcloud_version=""
    fi
    if [ -f "${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/configurations/config_default" ] && sed -n 's/^[[:space:]]*account[[:space:]]*=[[:space:]]*//p' "${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/configurations/config_default" | sed -n '1p' | grep -q .; then
        gcloud_auth_text="$(sed -n 's/^[[:space:]]*account[[:space:]]*=[[:space:]]*//p' "${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/configurations/config_default" | sed -n '1p')"
    fi
    aws_version="$(blackhost_tool_version_text aws --version)"
    if { [ -f "$HOME/.aws/config" ] && awk '/^\[default\]/{ found=1 } END { exit !found }' "$HOME/.aws/config"; } || { [ -f "$HOME/.aws/credentials" ] && awk '/^\[default\]/{ found=1 } END { exit !found }' "$HOME/.aws/credentials"; }; then
        aws_profile_text="default profile configured; identity not probed during index refresh"
    fi
    python_version="$(blackhost_tool_version_text python3 --version)"
    pip_version="$(blackhost_tool_version_text python3 -m pip --version)"
    node_version="$(blackhost_tool_version_text node --version)"
    npm_version="$(blackhost_tool_version_text npm --version)"
    npx_version="$(blackhost_tool_version_text npx --version)"
    yaml_python_bin="$(blackhost_yaml_python_bin_for_index)"
    pyyaml_version="$(blackhost_tool_version_text "$yaml_python_bin" -c 'import yaml; print("PyYAML " + getattr(yaml, "__version__", "unknown"))')"
    index_html_tmp="$(mktemp "$(dirname "$BLACKHOST_INDEX_HTML_PATH")/index.html.XXXXXX")"

    cat >"$index_html_tmp" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Blackhost Local Index</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    body { background: #f8f9fa; }
    pre { white-space: pre-wrap; word-break: break-word; }
    .terminal { background: #111827; color: #f9fafb; border-radius: .5rem; padding: 1rem; }
  </style>
</head>
<body>
  <main class="container py-4">
    <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-4">
      <div>
        <h1 class="h3 mb-1">Blackhost Local Index</h1>
        <p class="text-secondary mb-0">Last updated $now</p>
      </div>
      <span class="badge text-bg-$status_class align-self-md-start">Last command: $status_text</span>
    </div>

    <section class="row g-3 mb-4">
      <div class="col-md-3"><div class="border bg-white rounded p-3 h-100"><div class="text-secondary small">OS</div><div>$(printf '%s' "${BLACKHOST_OS_PRETTY:-unknown}" | blackhost_html_escape)</div></div></div>
      <div class="col-md-3"><div class="border bg-white rounded p-3 h-100"><div class="text-secondary small">Architecture</div><div>$(printf '%s' "${BLACKHOST_ARCH:-unknown}" | blackhost_html_escape)</div></div></div>
      <div class="col-md-3"><div class="border bg-white rounded p-3 h-100"><div class="text-secondary small">Package</div><div>$(printf '%s' "$package" | blackhost_html_escape)</div></div></div>
      <div class="col-md-3"><div class="border bg-white rounded p-3 h-100"><div class="text-secondary small">Command</div><div>$(printf '%s' "$command" | blackhost_html_escape)</div></div></div>
    </section>

    <section class="mb-4">
      <h2 class="h5">Observed Tooling</h2>
      <div class="table-responsive bg-white border rounded">
        <table class="table table-sm mb-0 align-middle">
          <thead><tr><th>Package</th><th>Tool</th><th>Version</th></tr></thead>
          <tbody>
            <tr><td>Docker</td><td>docker</td><td><code>$(printf '%s' "${docker_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>PHP</td><td>php</td><td><code>$(printf '%s' "${php_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>PHP</td><td>composer</td><td><code>$(printf '%s' "${composer_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>Git</td><td>git</td><td><code>$(printf '%s' "${git_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>Homebrew</td><td>brew</td><td><code>$(printf '%s' "${brew_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>GitHub CLI</td><td>gh</td><td><code>$(printf '%s' "${gh_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>GitHub CLI</td><td>auth</td><td><code>$(printf '%s' "$gh_auth_text" | blackhost_html_escape)</code></td></tr>
            <tr><td>Google Cloud CLI</td><td>gcloud</td><td><code>$(printf '%s' "${gcloud_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>Google Cloud CLI</td><td>auth</td><td><code>$(printf '%s' "$gcloud_auth_text" | blackhost_html_escape)</code></td></tr>
            <tr><td>AWS CLI</td><td>aws</td><td><code>$(printf '%s' "${aws_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>AWS CLI</td><td>profile</td><td><code>$(printf '%s' "$aws_profile_text" | blackhost_html_escape)</code></td></tr>
            <tr><td>Python</td><td>python3</td><td><code>$(printf '%s' "${python_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>Python</td><td>pip</td><td><code>$(printf '%s' "${pip_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>Node.js</td><td>node</td><td><code>$(printf '%s' "${node_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>Node.js</td><td>npm</td><td><code>$(printf '%s' "${npm_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>Node.js</td><td>npx</td><td><code>$(printf '%s' "${npx_version:-missing}" | blackhost_html_escape)</code></td></tr>
            <tr><td>YAML</td><td>PyYAML</td><td><code>$(printf '%s' "${pyyaml_version:-missing}" | blackhost_html_escape)</code></td></tr>
          </tbody>
        </table>
      </div>
    </section>

    <section class="mb-4">
      <h2 class="h5">Terminal Output</h2>
      <pre class="terminal">$terminal_html</pre>
    </section>

    <section>
      <h2 class="h5">Assurance Log</h2>
      <p class="text-secondary small mb-2">Raw output from <code>assurance/log.txt</code>.</p>
      <pre class="terminal">$assurance_log_html</pre>
    </section>
  </main>
</body>
</html>
EOF

    mv "$index_html_tmp" "$BLACKHOST_INDEX_HTML_PATH"
}

blackhost_index_record() {
    local package="$1"
    local command="$2"
    local exit_code="$3"
    local output_file="$4"
    local now

    now="$(blackhost_now_utc)"

    blackhost_index_write_json "$package" "$command" "$exit_code" "$output_file" "$now"
    blackhost_index_render_html "$package" "$command" "$exit_code" "$output_file" "$now"
}

blackhost_index_server_running() {
    local pid

    if [ ! -f "$BLACKHOST_INDEX_SERVER_PID_PATH" ]; then
        return 1
    fi

    pid="$(cat "$BLACKHOST_INDEX_SERVER_PID_PATH" 2>/dev/null || true)"
    case "$pid" in
        ''|*[!0-9]*)
            return 1
            ;;
    esac

    kill -0 "$pid" >/dev/null 2>&1
}

blackhost_index_start_server() {
    local pid

    mkdir -p "$BLACKHOST_LOCAL_ROOT"

    if blackhost_index_server_running; then
        return 0
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        blackhost_warn "Could not open local status page automatically because python3 is not available."
        return 1
    fi

    python3 -m http.server "$BLACKHOST_INDEX_SERVER_PORT" --bind "$BLACKHOST_INDEX_SERVER_HOST" --directory "$BLACKHOST_LOCAL_ROOT" >"$BLACKHOST_INDEX_SERVER_LOG_PATH" 2>&1 &
    pid=$!
    printf '%s\n' "$pid" >"$BLACKHOST_INDEX_SERVER_PID_PATH"
    sleep 1

    if blackhost_index_server_running; then
        blackhost_info "Local status server: $BLACKHOST_INDEX_URL"
        return 0
    fi

    blackhost_warn "Could not start local status server on $BLACKHOST_INDEX_SERVER_HOST:$BLACKHOST_INDEX_SERVER_PORT."
    blackhost_warn "Review $BLACKHOST_INDEX_SERVER_LOG_PATH for details."
    return 1
}

blackhost_index_open_html() {
    if [ "${BLACKHOST_OPEN_INDEX:-true}" != true ]; then
        return 0
    fi

    blackhost_index_start_server || return 0

    if command -v python3 >/dev/null 2>&1; then
        python3 -m webbrowser "$BLACKHOST_INDEX_URL" >/dev/null 2>&1 &
        blackhost_info "Opened local status page in the system default browser: $BLACKHOST_INDEX_URL"
        return 0
    fi

    blackhost_warn "Could not trigger the system default browser because python3 is not available."
}
