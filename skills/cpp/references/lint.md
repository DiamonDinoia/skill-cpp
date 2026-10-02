# Lint with clang-tidy

Run this lint after the agent writes or edits C++ code. First do the tool check for
clang-tidy (`references/tool-check.md`, minimum 22.1.0)

The lint uses a compile database. Configure the project one time with:

```bash
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_FLAGS='-Wall' .
```

`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` writes `build/compile_commands.json`. `-Wall` is
necessary: the unused-variable diagnostic is a compiler warning (`clang-diagnostic-*`)
that clang-tidy shows only when the compile flags have `-Wall`.

Lint one file:

```bash
clang-tidy -p build \
  --checks='bugprone-use-after-move,clang-diagnostic-*,cppcoreguidelines-narrowing-conversions' \
  <file>
```

Each diagnostic is one line: `file:line:col: warning: ... [check-name]`. The exit code
stays 0 for warnings, so grep the output for `warning:` and `error:` lines. Make the code
changes for each one and run the lint again until no `warning:` or `error:` line stays.

If the project has no compile database (`build/compile_commands.json` is missing), say so
and give the cmake configure line above.

## Why not clangd --check or the MCP server

`clangd --check=<file>` prints only a total error count (`All checks completed, N errors`)
and no warning text, so the agent learns nothing from it. The clangd MCP language server
prints real diagnostics but uses a Go toolchain, a daemon and a `.clangd` file for each
workspace, and in testing it caught 2 of the 3 bugs the clang-tidy command catches. One
tool, one command, no daemon: use clang-tidy.
