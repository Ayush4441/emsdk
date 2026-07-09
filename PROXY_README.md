# On-demand emsdk proxy

This adds a `proxy/` folder next to the normal emsdk files (`emsdk`,
`emsdk.py`, `emsdk_env.sh`, `emsdk_env.bat`, ...), plus `setup.sh` /
`setup.bat` at the repo root.

## Why

Normally you either `source ./emsdk_env.sh` once per terminal (environment
stays active for the whole session), or you re-source it every time you need
it. This gives you a third option: commands that **activate emsdk only for
the single call that needs it, then deactivate immediately**, without you
doing anything.

## What's in `proxy/`

One wrapper per tool, same name as the original:

```
emcc  em++  emar  emranlib  emnm  emsize  emstrip
emconfigure  emmake  emcmake  emrun
```

- `_proxy_core.sh` / `_proxy_core.bat` hold the shared activate/run/deactivate
  logic.
- Each `proxy/<tool>` (and `proxy/<tool>.bat` on Windows) is a thin script
  that just calls into the core with its own name.

Every call does exactly this:

1. **Activate** - source/call the real `emsdk_env.sh` / `emsdk_env.bat`.
2. **Run** - call the real tool (found on `PATH` after activation) with every
   argument forwarded untouched.
3. **Deactivate** - restore `PATH`, `EMSDK`, `EM_CONFIG`, etc. to exactly what
   they were before step 1.

Because each wrapper is its own process, step 3 would happen automatically
anyway once it exits - but it's done explicitly so the behavior is correct
and obvious even if a script here is ever sourced or reused.

## Setup

Run once, from the repo root:

- Linux / macOS: `./setup.sh`
- Windows: `setup.bat`

This will:

1. Run `emsdk install latest` and `emsdk activate latest` once, to fully
   install the real toolchain.
2. Make the `proxy/` scripts executable (Unix only).
3. Add `proxy/` to your `PATH` (shell rc file on Unix, user `PATH` on
   Windows via `setx`).

Open a new terminal afterward and just run tools normally:

```
emcc hello.c -o hello.wasm
em++ --version
emcmake cmake ..
```

Nothing stays "active" in your shell between calls.

## Uninstall

Run once, from the repo root:

- Linux / macOS: `./uninstall.sh`
- Windows: `uninstall.bat`

This removes the `proxy/` PATH registration that `setup.sh`/`setup.bat`
added (from your shell rc file(s) on Unix, from your user `PATH` on
Windows). It does **not** touch the installed emsdk toolchain itself - run
`./emsdk uninstall <version>` (or `emsdk.bat uninstall <version>`) for that
separately if you want it gone too.

## Adding another tool

Copy `proxy/emcc` (and `proxy/emcc.bat`), rename both to the new tool's name,
and change the tool name string inside from `"emcc"` / `emcc` to the new
name. That's the only thing that differs between wrappers.
