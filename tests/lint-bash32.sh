#!/bin/bash
#
# Reject bash 4+ constructs, so the CLI keeps running on macOS.
#
# macOS ships bash 3.2.57 and always will -- Apple froze it in 2007 over GPLv3
# -- and every script here starts `#!/bin/bash`, which on a Mac is that 3.2.
#
# This is a grep and not a `bash -n` run ON PURPOSE. `bash -n` parses a script
# containing `mapfile` without complaint and fails only at runtime, which is
# exactly how `zeltro configure` shipped broken to macOS: every syntax check
# passed, and it died on a real Mac with "mapfile: command not found".
#
#   ./tests/lint-bash32.sh
#
# Exits non-zero on the first violation, listing every one.
set -u

cd "$(dirname "$0")/.." || exit 1

# Comments are stripped before matching: the fixes for these very constructs
# name them in explanatory comments, and a lint that trips over its own
# rationale would just get disabled.
FILES=$(find src -name '*.sh' -type f; ls src/zeltro install-*.sh 2>/dev/null)

fail=0
check() {
    local label="$1" pattern="$2" hits
    hits=$(for f in $FILES; do
        sed 's/#.*//' "$f" | grep -nE "$pattern" | sed "s|^|$f:|"
    done)
    if [ -n "$hits" ]; then
        echo "FAIL: $label (bash 4+, unavailable on macOS)"
        echo "$hits" | sed 's/^/    /'
        fail=1
    fi
}

check "mapfile / readarray"      '\b(mapfile|readarray)[[:space:]]'
check "associative arrays"       '(declare|local|typeset)[[:space:]]+-[A-Za-z]*A'
check "namerefs"                 '(declare|local|typeset)[[:space:]]+-[A-Za-z]*n[[:space:]]'
check "case conversion \${v,,}"  '\$\{[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?(,,|\^\^|,|\^)'
check "negative array index"     '\$\{[A-Za-z_][A-Za-z0-9_]*\[-[0-9]'
check "coproc"                   '^[[:space:]]*coproc[[:space:]]'
check "|& pipe"                  '\|&'
check "&>> append redirect"      '&>>'
check "globstar"                 'shopt[[:space:]]+-s[[:space:]]+globstar'

# Not a bash 4 construct, but a bash 4 *semantic*: `source X || true` suspends
# errexit for the sourced file on bash 4+, and does NOT on 3.2 — the failing
# command aborts the caller anyway. It cost a silent "Setup failed" on macOS
# that reproduced nowhere on Linux. Toggle `set +e` / `set -e` explicitly.
check "source guarded by || true" '^[[:space:]]*(source|\.)[[:space:]]+[^|]*\|\|[[:space:]]*true'

if [ "$fail" = "0" ]; then
    echo "OK: no bash 4+ constructs found ($(echo "$FILES" | wc -w | tr -d ' ') files checked)"
fi
exit $fail
