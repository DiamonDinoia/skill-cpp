# Tool checks and installing

Before the skill uses cppman or clang-tidy, it checks the tool. The same rule holds for
both. The only difference is the minimum version.

## The check

1. `command -v <tool>` finds the executable. If it fails, the tool is missing.
2. `<tool> --version` prints the version (cppman writes it to stderr). Compare it with the
   minimum below. Run the check:

   ```bash
   sh <skill dir>/references/tool-check-version.sh <tool> <min>
   ```

   The script stands next to this file. If `--version` gives a nonzero exit status, the
   check stops. Exit 0: the version is correct. Exit 1: the version is too low, the
   output has no version, or `--version` gave an error. Exit 2: the tool is missing.

## Minimum versions

| Tool | Minimum | Why |
|---|---|---|
| cppman | 0.5.9 | The oldest release that prints a page in a container test. 0.5.0 and 0.4.8 fail against the current cppreference.com pages; 0.5.9 works on Ubuntu 22.04 and 24.04. |
| clang-tidy | 18.1.1 | The oldest tested release whose checks catch all 3 test bugs in a container (narrowing, use after move of a `std::unique_ptr`, unused variable). 13 and 14 find only 2. 15 to 17 were not tested. |

## Missing or too old: ask the user first

If the tool is missing or older than the minimum, ASK THE USER before any install. State
the tool, the version found, and the minimum.

With a yes, install in user space only:

```bash
uv tool install <pkg>          # or: uv tool upgrade <pkg>
```

When uv is missing:

```bash
python3 -m pip install --user <pkg>==<version>
```

After the install, run `sh <skill dir>/references/tool-check-version.sh <tool> <min>`
again. If it still fails, for example when `~/.local/bin` is not first on `PATH`, tell the
user and do not run the lookup or the lint.

The PyPI package names are `cppman` and `clang-tidy`. If pip refuses with an
externally-managed-environment error (PEP 668), stop: install only in a venv or with the
distro package manager. Never escalate privileges. Never run a downloaded install script
outside the uv installer without asking the user first.

With a no, continue the task without the tool and say that the lookup or lint did not run.
