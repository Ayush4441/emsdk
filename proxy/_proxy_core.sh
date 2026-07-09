#!/usr/bin/env bash
# _proxy_core.sh
#
# Shared logic used by every proxy/<tool> wrapper (emcc, em++, emar, ...).
# NOT meant to be run directly - it is sourced by the thin per-tool scripts
# sitting next to it in this same proxy/ directory.
#
# What it does, every time a wrapped tool is called:
#   1. ACTIVATE   - source the real emsdk_env.sh so PATH/EMSDK/EM_CONFIG etc.
#                   point at the real toolchain
#   2. RUN        - call the real tool (found via PATH after activation)
#                   with every argument forwarded untouched
#   3. DEACTIVATE - restore PATH/EMSDK/EM_CONFIG/etc. back to whatever they
#                   were before step 1, then return the tool's exit code
#
# Because each proxy/<tool> script is its own process, steps 1-3 would be
# thrown away automatically once it exits anyway - the explicit save/restore
# below just makes that guarantee literal, so this stays correct even if a
# script here is ever sourced instead of executed, or extended to call more
# than one tool in a row.

_emproxy_run() {
    local tool_name="$1"
    shift

    # proxy/ is always a sibling of the emsdk core files (emsdk, emsdk.py,
    # emsdk_env.sh, ...). Resolve that root relative to this file, not the
    # caller's cwd, so it works no matter where you run the command from.
    local proxy_dir
    proxy_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local emsdk_root
    emsdk_root="$(cd "${proxy_dir}/.." && pwd)"

    if [ ! -f "${emsdk_root}/emsdk_env.sh" ]; then
        echo "emsdk proxy: could not find emsdk_env.sh in '${emsdk_root}'" >&2
        echo "emsdk proxy: (expected proxy/ to be a sibling of the emsdk root)" >&2
        return 127
    fi

    # ---- snapshot everything emsdk_env.sh is going to touch ----
    local _saved_path="${PATH-}"
    local _saved_emsdk="${EMSDK-}"
    local _saved_emsdk_node="${EMSDK_NODE-}"
    local _saved_emsdk_python="${EMSDK_PYTHON-}"
    local _saved_em_config="${EM_CONFIG-}"
    local _saved_java_home="${JAVA_HOME-}"

    # ---- 1. ACTIVATE ----
    # shellcheck disable=SC1091
    source "${emsdk_root}/emsdk_env.sh" > /dev/null 2>&1

    # Resolve the *real* tool now that emsdk's directories are prepended to
    # PATH. Strip proxy_dir out of the lookup first so we can never end up
    # calling ourselves again, even if PATH ordering was ever off.
    local lookup_path="${PATH}"
    lookup_path="${lookup_path//${proxy_dir}:/}"
    lookup_path="${lookup_path//:${proxy_dir}/}"
    local real_tool
    real_tool="$(PATH="${lookup_path}" command -v -- "${tool_name}" 2>/dev/null || true)"

    local status=0
    if [ -z "${real_tool}" ]; then
        echo "emsdk proxy: '${tool_name}' was not found even after activating emsdk" >&2
        echo "emsdk proxy: is emsdk installed/activated? try: ${emsdk_root}/emsdk install latest && ${emsdk_root}/emsdk activate latest" >&2
        status=127
    else
        # ---- 2. RUN ----
        "${real_tool}" "$@"
        status=$?
    fi

    # ---- 3. DEACTIVATE ----
    export PATH="${_saved_path}"
    export EMSDK="${_saved_emsdk}"
    export EMSDK_NODE="${_saved_emsdk_node}"
    export EMSDK_PYTHON="${_saved_emsdk_python}"
    export EM_CONFIG="${_saved_em_config}"
    export JAVA_HOME="${_saved_java_home}"

    return "${status}"
}
