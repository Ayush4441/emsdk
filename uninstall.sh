#!/usr/bin/env bash
# uninstall.sh - undoes setup.sh (Linux/macOS).
#
# Removes the proxy/ PATH registration that setup.sh added to your shell rc
# file(s). Does NOT remove the installed emsdk toolchain itself - use
# `./emsdk uninstall <version>` for that if you want it gone too.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_DIR="${ROOT_DIR}/proxy"

echo "==> Removing proxy/ from PATH (undoing setup.sh)..."

remove_block () {
    local rc="$1"
    [ -f "$rc" ] || return
    if grep -qF "# >>> emsdk on-demand proxy >>>" "$rc" 2>/dev/null; then
        awk '
            /# >>> emsdk on-demand proxy >>>/ {skip=1}
            skip && /# <<< emsdk on-demand proxy <<</ {skip=0; next}
            !skip
        ' "$rc" > "${rc}.emproxy.tmp" && mv "${rc}.emproxy.tmp" "$rc"
        echo "   - removed from $rc"
    else
        echo "   - not present in $rc, skipping"
    fi
}

case "$(uname -s)" in
    Darwin)
        remove_block "$HOME/.zprofile"
        remove_block "$HOME/.bash_profile"
        ;;
    *)
        remove_block "$HOME/.bashrc"
        remove_block "$HOME/.zshrc"
        remove_block "$HOME/.profile"
        ;;
esac

echo ""
echo "==> Done. Open a new terminal - 'emcc' etc. should no longer resolve"
echo "    to ${PROXY_DIR}."
echo ""
echo "    Note: this only undoes the PATH registration. It does not touch"
echo "    the installed emsdk toolchain itself (run"
echo "    '${ROOT_DIR}/emsdk uninstall <version>' if you want to remove that too)."
