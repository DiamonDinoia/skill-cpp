# Portability across compilers, platforms and configurations

Load when the code must build with more than one compiler or on more than one platform, when
adding a conditional compilation block, or when a defect appears on one target only.

## Write ISO C++ first

- Standard C++ is the portable subset. Every extension, builtin, intrinsic and pragma is a
  portability cost that needs justification and isolation.
- Isolate the non-portable part behind one interface, with a portable fallback and a test that
  compares the two. Never scatter the condition across call sites.
- Prefer a standard feature to a builtin. Bit operations, atomics, threads, filesystem, time and
  alignment all have standard spellings now.
- Prefer a feature-test macro (`__cpp_lib_*`, `__has_include`, `__has_cpp_attribute`) to a
  compiler-version check. The macro asks the question that matters.

## What actually differs

- Integer widths: only the minimum widths are guaranteed. `int` is 32-bit almost everywhere.
  `long` is 32-bit on Windows and 64-bit on most Unix systems. Use fixed-width types where the
  width is part of the contract, and `std::size_t` or `std::ptrdiff_t` for sizes.
- `char` signedness is implementation-defined. Use `unsigned char` or `std::byte` for bytes.
- Endianness: any binary format, network protocol or memory-mapped file needs an explicit byte
  order and an explicit conversion. `std::endian` (C++20) reports the platform's.
- Alignment and unaligned access: some targets fault, others are merely slow. Copy through
  `std::memcpy` rather than casting a pointer into a buffer.
- Struct layout and padding are not portable. Never write a struct to a file or a socket as raw
  bytes. Serialize field by field.
- The evaluation order of function arguments is unspecified, so two side effects in one
  expression may run in either order.
- Filesystem semantics: path separators, case sensitivity, path length limits, locking, and what
  an open file permits. Use the filesystem library, and never build a path by string
  concatenation.
- Text encoding: source encoding, execution encoding and the console encoding are three
  different things. Keep everything UTF-8 internally, convert at the boundary, and never assume
  one byte is one character.
- Line endings, environment variables, dynamic library naming and search rules, and the meaning
  of a "temporary directory" all differ.
- Standard library implementations differ in what they check, what they inline, their container
  growth factors, their hash functions, and their unordered iteration order. Never depend on
  unspecified behaviour that happens to be stable in one implementation.
- Floating point: contraction into fused multiply-add, x87 excess precision and fast-math
  defaults all differ. See `numerics.md`.

## Conditional compilation

- Put the condition in as few places as possible: one header defining a project macro, one
  implementation file per platform, or a build-system selection of source files.
- Prefer selecting a file in the build system over `#ifdef` blocks inside a function.
- Every branch of a conditional must compile somewhere in CI, or it is dead code that rots.
- Never nest platform, compiler and version conditions. The combination is untestable.
- Never define a macro that changes a class layout or an inline function's body differently
  between translation units. That is a one-definition-rule violation with silent consequences.
- Never key library behaviour on a test-only macro from a public header. The macro has to be a
  documented part of the interface, and it breaks other branches when they share one condition
  or a using-declaration set. Exercise the fallback by calling it directly from the test, not
  by suppressing the compiler or feature macro.
- Name project macros with a project prefix, never a leading underscore, and never redefine a
  standard or implementation macro.

## Compilers

- Build with at least two compilers in CI. Each diagnoses what the others miss, and the second
  one finds accidental extension use immediately.
- Enable the strictest conformance mode the toolchains offer, and disable the extension modes.
- Diagnostics and their spellings differ. Keep the warning configuration in one place with a
  per-compiler mapping rather than duplicating flag lists.
- The same source can be correct on one compiler and undefined on another. A divergence is a
  reason to look for undefined behaviour before blaming the compiler.

## Testing portability

- Build the CI matrix over the supported compilers, the supported standards, debug and release,
  plus one sanitizer job.
- Test on the target's byte order and word size when they differ from the development machine's,
  by cross-compiling and running under emulation if necessary.
- Pin the toolchain versions used for released artifacts, and record them with the artifact.
