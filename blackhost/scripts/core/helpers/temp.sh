#!/usr/bin/env bash

BLACKHOST_TMP_FILES="${BLACKHOST_TMP_FILES:-}"

blackhost_tmp_file() {
    local name="${1:-blackhost}"
    local file

    file="$(mktemp -t "$name.XXXXXX")"
    BLACKHOST_TMP_FILES="${BLACKHOST_TMP_FILES}${file}
"
    printf '%s\n' "$file"
}

blackhost_cleanup_tmp_files() {
    local file

    if [ -z "$BLACKHOST_TMP_FILES" ]; then
        return 0
    fi

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        [ -f "$file" ] && rm -f "$file"
    done <<EOF
$BLACKHOST_TMP_FILES
EOF
}

trap blackhost_cleanup_tmp_files EXIT
