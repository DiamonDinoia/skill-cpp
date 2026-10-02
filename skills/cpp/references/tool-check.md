# Tool checks and installing

Before the skill uses cppman or clang-tidy, it checks the tool. The same rule holds for
both. The only difference is the minimum version.

## The check

1. `command -v <tool>` finds the executable. If it fails, the tool is missing.
2. `<tool> --version` prints the version. Compare it with the minimum below. A `sort -V`
   check works for both:

   ```bash
   [ "$(printf '%s\n' "$MIN" "$(clang-tidy --version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)" | sort -V | head -1)" = "$MIN" ]
   ```

   Replace `$MIN` and the tool name. The test prints nothing and sets the exit code: 0 is
   new enough, 1 is too old.

## Minimum versions

| Tool | Minimum | Why |
|---|---|---|
| cppman | 0.5.9 | The oldest release that prints a page in a container test. 0.5.0 and 0.4.8 fail against the current cppreference.com pages; 0.5.9 works on Ubuntu 22.04 and 24.04. |
| clang-tidy | 22.1.0 | The oldest release whose checks catch all test bugs in a container: 21.1.0 and older miss use-after-move (clang-tidy 13 and 14 find only 2 of the 3 bugs). |

## Missing or too old: ask the user first

If the tool is missing or older than the minimum, ASK THE USER before any install. State
the tool, the version found, and the minimum.

With a yes, install in user space only:

```bash
uv tool install <pkg>          # or: uv tool upgrade <pkg>
```

When uv is missing:

```bash
python3 -m pip install --user --upgrade <pkg>
```

The PyPI package names are `cppman` and `clang-tidy`. If pip refuses with an
externally-managed-environment error (PEP 668), ask the user again before
`--break-system-packages` is used. Never use sudo. Never run `curl | sh` outside the uv
installer without asking the user first.

With a no, continue the task without the tool and say that the lookup or lint did not run.
