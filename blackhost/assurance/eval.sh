#!/usr/bin/env bash
set -euo pipefail

BLACKHOST_ASSURANCE_ENTRYPOINT="${BASH_SOURCE[0]}"
BLACKHOST_ASSURANCE_DIR="$(cd "$(dirname "$BLACKHOST_ASSURANCE_ENTRYPOINT")" && pwd)"
BLACKHOST_SKILL_ROOT="$(dirname "$BLACKHOST_ASSURANCE_DIR")"
BLACKHOST_REPO_ROOT="$(cd "$BLACKHOST_SKILL_ROOT/../../.." && pwd)"
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

blackhost_assurance_section() {
    printf '\n'
    printf '========================================================================\n'
    printf '%s\n' "$1"
    printf '========================================================================\n'
}

blackhost_assurance_pass() {
    printf '[PASS] %s\n' "$1"
}

blackhost_assurance_fail() {
    printf '[FAIL] %s\n' "$1" >&2
}

blackhost_assurance_run() {
    local name="$1"
    local exit_code

    shift

    blackhost_assurance_section "$name"
    printf '[INFO] Command:'
    printf ' %q' "$@"
    printf '\n'

    set +e
    "$@"
    exit_code=$?
    set -e

    if [ "$exit_code" -ne 0 ]; then
        blackhost_assurance_fail "$name exited $exit_code"
        return "$exit_code"
    fi

    blackhost_assurance_pass "$name exited 0"
}

blackhost_assurance_json_validation() {
    blackhost_assurance_run "Validate skill.json" sh -c "python3 -m json.tool '$BLACKHOST_SKILL_ROOT/skill.json' >/dev/null"
    blackhost_assurance_run "Validate schemas/maintain.json" sh -c "python3 -m json.tool '$BLACKHOST_SKILL_ROOT/schemas/maintain.json' >/dev/null"
    blackhost_assurance_run "Validate schemas/eval.json" sh -c "python3 -m json.tool '$BLACKHOST_SKILL_ROOT/schemas/eval.json' >/dev/null"

    for file in "$BLACKHOST_SKILL_ROOT"/manifests/*.json "$BLACKHOST_SKILL_ROOT"/templates/*.json; do
        blackhost_assurance_run "Validate $(basename "$file")" sh -c "python3 -m json.tool '$file' >/dev/null"
    done
}

blackhost_assurance_package_contract_validation() {
    blackhost_assurance_run "Validate package manifests match package directories" ruby -rjson -e "
root='$BLACKHOST_SKILL_ROOT'
packages=Dir.children(File.join(root,'scripts')).select { |name| File.directory?(File.join(root,'scripts',name)) && name != 'core' }.sort
required=%w[script summary modules_dir modules commands routing dependencies safety notes]
skill=JSON.parse(File.read(File.join(root,'skill.json'))).fetch('blackhost/')
scripts=skill.fetch('scripts/')
core=JSON.parse(File.read(File.join(root,'manifests/core.json')))
core_packages=core.fetch('commands').fetch('package').fetch('packages')
routing=core.fetch('routing').fetch('packages')
packages.each do |package|
  manifest_path=File.join(root,'manifests',\"#{package}.json\")
  raise \"missing manifest for #{package}\" unless File.file?(manifest_path)
  manifest=JSON.parse(File.read(manifest_path))
  missing=required.reject { |key| manifest.key?(key) }
  raise \"#{package} manifest missing #{missing.join(', ')}\" unless missing.empty?
  raise \"skill.json missing scripts/#{package}/\" unless scripts.key?(\"#{package}/\")
  raise \"core package list missing #{package}\" unless core_packages.include?(package)
  raise \"core routing missing #{package}\" unless routing.key?(package)
end
"
}

blackhost_assurance_yaml_validation() {
    blackhost_assurance_run "Validate OpenAPI YAML" ruby -ryaml -e "YAML.load_file('$BLACKHOST_SKILL_ROOT/schemas/skill.openapi.yml')"
}

blackhost_assurance_metadata_validation() {
    blackhost_assurance_run "Validate VERSION" sh -c "test -f '$BLACKHOST_SKILL_ROOT/VERSION' && grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?$' '$BLACKHOST_SKILL_ROOT/VERSION'"
    blackhost_assurance_run "Validate CHANGELOG.md current version row" ruby -e "
version=File.read('$BLACKHOST_SKILL_ROOT/VERSION').strip
lines=File.readlines('$BLACKHOST_SKILL_ROOT/CHANGELOG.md', chomp: true)
header=lines.find { |line| line.start_with?('| Version | User | LLM | 240-Char Summary |') }
raise 'missing changelog header' unless header
row=lines.find { |line| line.start_with?(\"| #{version} |\") }
raise \"missing changelog row for #{version}\" unless row
cells=row.split('|').map(&:strip).reject(&:empty?)
raise 'expected Version/User/LLM/240-Char Summary' unless cells.length == 4
raise 'summary too long' if cells[3].length > 240
"
    blackhost_assurance_run "Validate LICENSE.md required notice" sh -c "test -f '$BLACKHOST_SKILL_ROOT/LICENSE.md' && rg -q '^Required Notice: Copyright Blackaft Associates \\(associates@blackaft\\.com\\)$' '$BLACKHOST_SKILL_ROOT/LICENSE.md'"
    blackhost_assurance_run "Validate local/index.html default browser route" sh -c "rg -q 'Every routed command refreshes' '$BLACKHOST_SKILL_ROOT/SKILL.md' && rg -q 'python3 -m webbrowser http://localhost:8765/index\\.html' '$BLACKHOST_SKILL_ROOT/SKILL.md' && rg -q 'system default browser' '$BLACKHOST_SKILL_ROOT/SKILL.md' && rg -q 'file://' '$BLACKHOST_SKILL_ROOT/SKILL.md' && rg -q 'blackhost_index_open_html' '$BLACKHOST_SKILL_ROOT/scripts/core/helpers/run.sh' && rg -q 'BLACKHOST_OPEN_INDEX=false' '$BLACKHOST_SKILL_ROOT/assurance/eval.sh' && rg -q 'BLACKHOST_OPEN_INDEX=false' '$BLACKHOST_SKILL_ROOT/assurance/dry.sh'"
    blackhost_assurance_run "Validate meta prompt capability table" sh -c "rg -q '\\| Capability \\| Meta Prompt \\| Command \\| Manifest \\| Mutates host \\|' '$BLACKHOST_SKILL_ROOT/SKILL.md' && rg -q 'blackhost run php app' '$BLACKHOST_SKILL_ROOT/SKILL.md' && rg -q 'blackhost install docker' '$BLACKHOST_SKILL_ROOT/SKILL.md'"
    blackhost_assurance_run "Validate SKILL.md package discovery frontmatter" ruby -ryaml -e "front=File.read('$BLACKHOST_SKILL_ROOT/SKILL.md').split('---',3)[1]; desc=YAML.safe_load(front).fetch('description'); ['AWS CLI','Google Cloud CLI','Homebrew','Node.js'].each { |needle| raise \"frontmatter missing #{needle}\" unless desc.include?(needle) }"
    blackhost_assurance_run "Validate SKILL.md has no unresolved TODO markers" sh -c "if rg -n 'TODO|FIXME' '$BLACKHOST_SKILL_ROOT/SKILL.md'; then exit 1; fi"
}

blackhost_assurance_shell_validation() {
    local file

    while IFS= read -r file; do
        blackhost_assurance_run "Shell syntax ${file#$BLACKHOST_REPO_ROOT/}" bash -n "$file"
done <<EOF
$(find "$BLACKHOST_SKILL_ROOT" -path "$BLACKHOST_SKILL_ROOT/local" -prune -o -type f -name '*.sh' -print | sort)
EOF
}

blackhost_assurance_route_smoke() {
    blackhost_assurance_run "Root help" bash "$BLACKHOST_RUN" --help
    blackhost_assurance_run "Root help JSON" bash "$BLACKHOST_RUN" --json --help
    blackhost_assurance_run "OS route" bash "$BLACKHOST_RUN" os
    blackhost_assurance_run "OS route JSON" bash "$BLACKHOST_RUN" --json os
    blackhost_assurance_run "AWS package help" bash "$BLACKHOST_RUN" aws --help
    blackhost_assurance_run "AWS auth help" bash "$BLACKHOST_RUN" aws auth --help
    blackhost_assurance_run "Docker package help" bash "$BLACKHOST_RUN" docker --help
    blackhost_assurance_run "Dockerise help" bash "$BLACKHOST_RUN" docker dockerise --help
    blackhost_assurance_run "Docker run help" bash "$BLACKHOST_RUN" docker run --help
    blackhost_assurance_run "Google Cloud CLI package help" bash "$BLACKHOST_RUN" gcloud --help
    blackhost_assurance_run "Google Cloud CLI auth help" bash "$BLACKHOST_RUN" gcloud auth --help
    blackhost_assurance_run "Git package help" bash "$BLACKHOST_RUN" git --help
    blackhost_assurance_run "GitHub CLI package help" bash "$BLACKHOST_RUN" gh --help
    blackhost_assurance_run "GitHub CLI auth help" bash "$BLACKHOST_RUN" gh auth --help
    blackhost_assurance_run "Homebrew package help" bash "$BLACKHOST_RUN" homebrew --help
    blackhost_assurance_run "PHP package help" bash "$BLACKHOST_RUN" php --help
    blackhost_assurance_run "PHP run help" bash "$BLACKHOST_RUN" php run --help
    blackhost_assurance_run "Python package help" bash "$BLACKHOST_RUN" python --help
    blackhost_assurance_run "Python run help" bash "$BLACKHOST_RUN" python run --help
    blackhost_assurance_run "YAML package help" bash "$BLACKHOST_RUN" yaml --help
    blackhost_assurance_run "YAML run help" bash "$BLACKHOST_RUN" yaml run --help
    blackhost_assurance_run "Node package help" bash "$BLACKHOST_RUN" node --help
    blackhost_assurance_run "Node check help" bash "$BLACKHOST_RUN" node check --help
    blackhost_assurance_run "Node run help" bash "$BLACKHOST_RUN" node run --help
    blackhost_assurance_run "Python check JSON" bash "$BLACKHOST_RUN" --json python check --yes
    blackhost_assurance_run "Node check JSON" bash "$BLACKHOST_RUN" --json node check --yes
    blackhost_assurance_run "AWS install dry-run" bash "$BLACKHOST_RUN" aws install --dry-run --yes
    blackhost_assurance_run "AWS update dry-run" bash "$BLACKHOST_RUN" aws update --dry-run --yes
    blackhost_assurance_run "Google Cloud CLI install dry-run" bash "$BLACKHOST_RUN" gcloud install --dry-run --yes
    blackhost_assurance_run "Google Cloud CLI update dry-run" bash "$BLACKHOST_RUN" gcloud update --dry-run --yes
    blackhost_assurance_run "Homebrew install dry-run" bash "$BLACKHOST_RUN" homebrew install --dry-run --yes
    blackhost_assurance_run "Homebrew update dry-run" bash "$BLACKHOST_RUN" homebrew update --dry-run --yes
    blackhost_assurance_run "Node install dry-run" bash "$BLACKHOST_RUN" node install --dry-run --yes
    blackhost_assurance_run "Node update dry-run" bash "$BLACKHOST_RUN" node update --dry-run --yes
}

blackhost_assurance_stale_paths() {
    blackhost_assurance_section "Stale Path Check"

    if rg -n 'scripts/docker\.sh|state\.sh' "$BLACKHOST_SKILL_ROOT" --glob '!schemas/eval.json' --glob '!assurance/eval.sh' --glob '!assurance/log.txt' --glob '!local/**'; then
        blackhost_assurance_fail "Found stale shortcut or state-module references."
        return 1
    fi

    blackhost_assurance_pass "No stale shortcut or state-module references found."
}

blackhost_assurance_index_artifacts() {
    blackhost_assurance_run "Generated local/index.json parses" sh -c "python3 -m json.tool '$BLACKHOST_SKILL_ROOT/local/index.json' >/dev/null"
    blackhost_assurance_run "Generated local/index.json includes Node tools" sh -c "python3 -c 'import json, sys; data=json.load(open(sys.argv[1])); tools=data[\"packages\"][\"node\"][\"tools\"]; assert all(name in tools for name in (\"node\", \"npm\", \"npx\"))' '$BLACKHOST_SKILL_ROOT/local/index.json'"
    blackhost_assurance_run "Generated local/index.json includes cloud and package-manager tools" sh -c "python3 -c 'import json, sys; data=json.load(open(sys.argv[1])); packages=data[\"packages\"]; assert \"aws\" in packages and \"aws\" in packages[\"aws\"][\"tools\"]; assert \"gcloud\" in packages and \"gcloud\" in packages[\"gcloud\"][\"tools\"]; assert \"homebrew\" in packages and \"brew\" in packages[\"homebrew\"][\"tools\"]' '$BLACKHOST_SKILL_ROOT/local/index.json'"
    blackhost_assurance_run "Generated local/index.html exists" test -f "$BLACKHOST_SKILL_ROOT/local/index.html"
    blackhost_assurance_run "Generated local/index.html includes Node tools" sh -c "rg -q '<td>Node.js</td><td>node</td>' '$BLACKHOST_SKILL_ROOT/local/index.html' && rg -q '<td>Node.js</td><td>npm</td>' '$BLACKHOST_SKILL_ROOT/local/index.html' && rg -q '<td>Node.js</td><td>npx</td>' '$BLACKHOST_SKILL_ROOT/local/index.html'"
    blackhost_assurance_run "Generated local/index.html includes cloud and package-manager tools" sh -c "rg -q '<td>AWS CLI</td><td>aws</td>' '$BLACKHOST_SKILL_ROOT/local/index.html' && rg -q '<td>Google Cloud CLI</td><td>gcloud</td>' '$BLACKHOST_SKILL_ROOT/local/index.html' && rg -q '<td>Homebrew</td><td>brew</td>' '$BLACKHOST_SKILL_ROOT/local/index.html'"
    blackhost_assurance_run "Generated local/index.html includes assurance log" sh -c "rg -q '<h2 class=\"h5\">Assurance Log</h2>' '$BLACKHOST_SKILL_ROOT/local/index.html' && rg -q 'assurance/log.txt' '$BLACKHOST_SKILL_ROOT/local/index.html'"
}

blackhost_assurance_openapi_package_coverage() {
    blackhost_assurance_run "OpenAPI exposes every package manifest and operation" ruby -ryaml -e "
root='$BLACKHOST_SKILL_ROOT'
api=YAML.load_file(File.join(root,'schemas/skill.openapi.yml'))
enum=api.fetch('paths').fetch('/manifests/{manifestName}').fetch('get').fetch('parameters')[0].fetch('schema').fetch('enum')
paths=api.fetch('paths').keys
manifests=api.fetch('x-blackhost').fetch('manifests')
filesystem_manifests=api.fetch('x-blackhost').fetch('filesystem').fetch('blackhost/').fetch('manifests/')
packages=Dir.children(File.join(root,'scripts')).select { |name| File.directory?(File.join(root,'scripts',name)) && name != 'core' }.sort
packages.each do |package|
  raise \"#{package} missing from manifest enum\" unless enum.include?(package)
  raise \"#{package} missing from x-blackhost manifests\" unless manifests.key?(package)
  raise \"#{package}.json missing from x-blackhost filesystem map\" unless filesystem_manifests.key?(\"#{package}.json\")
  Dir.children(File.join(root,'scripts',package)).grep(/\\.sh$/).map { |file| File.basename(file,'.sh') }.reject { |cmd| cmd == 'commons' }.sort.each do |command|
    path=\"/packages/#{package}/#{command}\"
    raise \"missing #{path}\" unless paths.include?(path)
  end
end
"
}

blackhost_assurance_log_artifact() {
    blackhost_assurance_run "Assurance log exists" test -s "$BLACKHOST_ASSURANCE_LOG_PATH"
}

blackhost_assurance_refresh_local_index() {
    if ! bash "$BLACKHOST_RUN" --json os >/dev/null 2>&1; then
        printf '[WARN] Could not refresh local/index.html after assurance completion.\n' >&2
    fi
}

blackhost_assurance_skill_validator() {
    local validator="/Users/geogkary/.codex/skills/.system/skill-creator/scripts/quick_validate.py"
    local python_bin="$BLACKHOST_SKILL_ROOT/local/.venv/bin/python"

    if [ ! -x "$python_bin" ]; then
        blackhost_assurance_section "Skill Creator Validator"
        printf '[WARN] Skipping skill-creator validator because %s is not available.\n' "$python_bin"
        printf '[WARN] Run scripts/core/init.sh yaml install --yes to create the managed validator environment.\n'
        return 0
    fi

    if [ ! -f "$validator" ]; then
        blackhost_assurance_section "Skill Creator Validator"
        printf '[WARN] Skipping skill-creator validator because %s is not available.\n' "$validator"
        return 0
    fi

    blackhost_assurance_run "Skill creator quick_validate" "$python_bin" "$validator" "$BLACKHOST_SKILL_ROOT"
}

main() {
    cd "$BLACKHOST_REPO_ROOT"

    blackhost_assurance_section "Blackhost Assurance"
    printf '[INFO] Repository root: %s\n' "$BLACKHOST_REPO_ROOT"
    printf '[INFO] Skill root: %s\n' "$BLACKHOST_SKILL_ROOT"

    blackhost_assurance_json_validation
    blackhost_assurance_package_contract_validation
    blackhost_assurance_yaml_validation
    blackhost_assurance_metadata_validation
    blackhost_assurance_shell_validation
    blackhost_assurance_route_smoke
    blackhost_assurance_stale_paths
    blackhost_assurance_run "Dry-run assurance" bash "$BLACKHOST_SKILL_ROOT/assurance/dry.sh"
    blackhost_assurance_index_artifacts
    blackhost_assurance_openapi_package_coverage
    blackhost_assurance_log_artifact
    blackhost_assurance_skill_validator

    blackhost_assurance_section "Assurance Summary"
    blackhost_assurance_pass "All blackhost assurance checks passed."
    blackhost_assurance_refresh_local_index
}

main "$@"
