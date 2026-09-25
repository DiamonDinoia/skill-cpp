# Safety and security

Load when the code consumes untrusted input, crosses a trust boundary, handles credentials, or
when hardening a build.

## The safety profiles

The Core Guidelines define three safety properties, each mechanically checkable in part.

- Type safety: no access to an object through an unrelated type. No `reinterpret_cast` punning,
  no `union` read of the wrong member, no C varargs, no unchecked downcast.
- Bounds safety: no access outside an allocation. Use a container, a `std::span` or an index
  checked once. Never do raw pointer arithmetic across an unknown extent.
- Lifetime safety: no access to a destroyed or deallocated object. RAII owners, no owning raw
  pointers, no view outliving its source.

With RAII these give type and resource safety without garbage collection. Where a guideline
support library is already a dependency, its `not_null`, `narrow` and `narrow_cast` make the
remaining unchecked cases explicit. Where it is not, a small project equivalent does the same
job.

## Untrusted input

- Validate at the trust boundary, once, and convert to a validated type. After the boundary,
  code works with the validated type and does not re-check.
- Treat every length, offset, index and size in the input as hostile. Check the range before
  using it, and check that the arithmetic on it cannot overflow.
- Reject rather than repair. A parser that "fixes" malformed input creates a second dialect and
  a divergence between validator and consumer.
- Bound everything the input can allocate: element count, recursion depth, string length, total
  memory. An unbounded `resize` from an input field is a denial of service.
- Fuzz every parser in a sanitizer build. A fuzzer plus a sanitizer finds the class of defects
  unit tests do not.
- Deserialization is parsing. Never deserialize into a type that runs code, and version the
  format explicitly.

## The classic C++ vulnerability classes

| Class | Prevention |
|---|---|
| Buffer overflow | container or `span` with a checked index; never a raw pointer plus a trusted length |
| Use after free, dangling view | RAII ownership; no owning raw pointer; no view stored beyond its source |
| Integer overflow feeding an allocation or an index | check before the arithmetic; use a wider type; reject on overflow |
| Signed/unsigned confusion in a bounds check | one signedness at the boundary, conversion warnings as errors |
| Off-by-one at the end of a range | algorithms and ranges rather than hand-written index loops |
| Format string from input | `std::format` or `std::print` with a literal format; never a runtime format string from input |
| Command or path injection | no shell string concatenation; pass an argument vector; canonicalize and confine paths |
| Time-of-check to time-of-use on a path | open once and operate on the handle, not the name |
| Uninitialized memory disclosure | initialize every object; zero-fill buffers that cross a boundary |
| Unchecked error return | `[[nodiscard]]` on every fallible operation |

## Secrets and sensitive data

- Never log a credential, a key, a token or personal data. Redact at the logging boundary, not
  at each call site.
- Never put a secret in the source, a header, or a build file. Read it at run time from the
  environment the deployment controls.
- Zeroing a buffer at the end of a scope can be optimized away. Use the platform's explicit
  secure-zero function.
- Use a vetted cryptographic library. Never implement a primitive, and never invent a protocol.
- Compare secrets in constant time. A byte-by-byte comparison leaks the prefix length.

## Hardening the build

The widely recommended baseline for a released binary, from the OpenSSF compiler hardening
guidance:

- `-O2 -Wall -Wformat=2 -Wconversion -Wtrampolines -Wimplicit-fallthrough`, warnings as errors.
- `-D_FORTIFY_SOURCE=3` (with `-U_FORTIFY_SOURCE` first) and `-D_GLIBCXX_ASSERTIONS` for checked
  standard library operations.
- `-fstack-protector-strong`, `-fstack-clash-protection`, `-fstrict-flex-arrays=3`.
- Control-flow protection where the platform supports it, position-independent executables, and
  the linker's `relro`, `now`, `noexecstack` and `nodlopen` settings.
- Zero-initialize automatic variables where the toolchain offers it, so an uninitialized read is
  deterministic rather than a disclosure.
- MSVC has the equivalents: control-flow guard, buffer security checks, and the checked
  iterators of the standard library.

These cost a small amount of performance and remove whole classes of exploitable defects.
Measure the cost on the hot path before rejecting them, and keep the checked standard library
enabled in every build where the cost is acceptable.

## Verification

- Sanitizers in test builds, a fuzzer for every parser, static analysis in CI.
- A security-relevant change gets a test that demonstrates the rejection of the bad input, not
  only the acceptance of the good input.
- Review the dependency surface. Each dependency's defects are the project's defects, and a
  pinned, verified version is the minimum.
