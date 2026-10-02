# Lint with clang-tidy

Run this lint after the agent writes or edits C++ code. First do the tool check for
clang-tidy (`references/tool-check.md`, minimum 18.1.1).

## Find the compile database

The lint uses a compile database. First look for one in the project:

```bash
find . -name compile_commands.json -not -path './.git/*'
```

Give the directory that holds it to `-p`. Never configure a new build tree. Use the
project's configured build, with its preset, toolchain and options.

If no compile database exists, say so. For a CMake project, propose to add
`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` to the project's configure step or preset, not as a
separate command. Other build systems must export one (Meson writes one in its output
directory by default). If that is not possible, say so and do not lint.

## Run the lint

```bash
clang-tidy -p <dir-with-compile_commands.json> \
  --checks='-*,bugprone-use-after-move,clang-diagnostic-*,cppcoreguidelines-narrowing-conversions' \
  --extra-arg=-Wall \
  <file>
```

`--extra-arg=-Wall` is necessary: the unused-variable diagnostic is a compiler
diagnostic (`clang-diagnostic-*`) that clang-tidy shows only when `-Wall` is on.

Each diagnostic is one line: `file:line:col: warning: ... [check-name]`. The exit code
stays 0 for warnings, so grep the output for `warning:` and `error:` lines. Make the
code changes for each one and run the lint again until no `warning:` or `error:` line
stays.

The exit code stays 0 for warnings only. A nonzero exit code means clang-tidy reported a
problem it treats as an error (a compile error, or a warning promoted by
`WarningsAsErrors`). Report the full diagnostics and do not call the lint clean.

A use-after-move warning on an operation with no precondition (`clear()`, assignment,
`size()` on a standard type) can be correct. Read the code before a change.
