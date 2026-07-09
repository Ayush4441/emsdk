#!/usr/bin/env bash
# setup.sh - one-shot installer for this emsdk fork and its on-demand
# "proxy" command wrappers (Linux & macOS).
#
# What it does:
#   1. Installs & activates the latest emsdk toolchain (once, on this machine)
#   2. Makes every proxy/<tool> wrapper executable
#   3. Adds this repo's proxy/ directory to your PATH via your shell rc file
#
# After this, running e.g.:
#     emcc foo.c -o foo.wasm
# will silently activate the emsdk environment, run the real emcc, then
# silently deactivate again - you never need to `source emsdk_env.sh`
# yourself or leave emsdk permanently active in your shell.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_DIR="${ROOT_DIR}/proxy"

echo "==> emsdk fork located at: ${ROOT_DIR}"

cd "${ROOT_DIR}"
if [ ! -x "./emsdk" ]; then
    echo "!! Could not find an executable ./emsdk in ${ROOT_DIR}." >&2
    echo "!! Is this script sitting at the root of an emsdk checkout?" >&2
    exit 1
fi

echo "==> Installing latest emsdk (this can take a while the first time)..."
./emsdk install latest

echo "==> Activating latest emsdk..."
./emsdk activate latest

echo "==> Making proxy/ wrappers executable..."
chmod +x "${PROXY_DIR}"/_proxy_core.sh
chmod +x "${PROXY_DIR}"/emcc "${PROXY_DIR}"/em++ "${PROXY_DIR}"/emar \
         "${PROXY_DIR}"/emranlib "${PROXY_DIR}"/emconfigure "${PROXY_DIR}"/emmake \
         "${PROXY_DIR}"/emcmake "${PROXY_DIR}"/emrun "${PROXY_DIR}"/emnm \
         "${PROXY_DIR}"/emsize "${PROXY_DIR}"/emstrip

add_to_rc () {
    local rc="$1"
    local marker="# >>> emsdk on-demand proxy >>>"
    if [ -f "$rc" ] && grep -qF "$marker" "$rc" 2>/dev/null; then
        echo "   - already present in $rc, skipping"
        return
    fi
    {
        echo ""
        echo "$marker"
        echo "export PATH=\"${PROXY_DIR}:\$PATH\""
        echo "# <<< emsdk on-demand proxy <<<"
    } >> "$rc"
    echo "   - added to $rc"
}

echo "==> Registering proxy/ on PATH..."
case "$(uname -s)" in
    Darwin)
        # macOS: zsh is default since Catalina, but cover bash too
        touch "$HOME/.zprofile"
        add_to_rc "$HOME/.zprofile"
        [ -f "$HOME/.bash_profile" ] && add_to_rc "$HOME/.bash_profile"
        ;;
    *)
        # Linux and everything else
        [ -f "$HOME/.bashrc" ] && add_to_rc "$HOME/.bashrc"
        [ -f "$HOME/.zshrc" ] && add_to_rc "$HOME/.zshrc"
        touch "$HOME/.profile"
        add_to_rc "$HOME/.profile"
        ;;
esac

echo ""
echo "==> Done. Open a new terminal (or 'source' your rc file) and try:"
echo "       emcc --version"
echo ""
echo "    emcc, em++, emar, etc. will now activate emsdk on demand for each"
echo "    call and deactivate again right after - nothing stays active in"
echo "    your shell in between."
