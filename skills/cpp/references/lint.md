# Lint with clang-tidy

Run this lint after the agent writes or edits C++ code. First do the tool check for
clang-tidy (`references/tool-check.md`, minimum 22.1.0).

## Find the compile database

The lint uses a compile database. First look for one in the project:

```bash
find . -name compile_commands.json -not -path './.git/*'
```

Give the directory that holds it to `-p`. If the project uses CMake and has none,
configure the project one time with:

```bash
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .
```

Do not overwrite `CMAKE_CXX_FLAGS`. `-Wall` goes in the clang-tidy call below. If the
project does not use CMake, its build system must export a compile database (Meson
writes one in its output directory by default). If that is not possible, say so and do
not lint.

## Run the lint

```bash
clang-tidy -p <dir-with-compile_commands.json> \
  --checks='bugprone-use-after-move,clang-diagnostic-*,cppcoreguidelines-narrowing-conversions' \
  --extra-arg=-Wall \
  <file>
```

`--extra-arg=-Wall` is necessary: the unused-variable diagnostic is a compiler
diagnostic (`clang-diagnostic-*`) that clang-tidy shows only when `-Wall` is on.

Each diagnostic is one line: `file:line:col: warning: ... [check-name]`. The exit code
stays 0 for warnings, so grep the output for `warning:` and `error:` lines. Make the
code changes for each one and run the lint again until no `warning:` or `error:` line
stays.
