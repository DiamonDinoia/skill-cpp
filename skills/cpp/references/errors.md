# Errors, exceptions and contracts

Load when choosing an error strategy, writing a `throw` or a `catch`, reviewing exception
safety, or adding a precondition check.

## Choose one strategy per interface

| Failure kind | Mechanism |
|---|---|
| Programming error, a broken precondition | assertion in debug, then a hard fail. Do not "handle" it |
| Expected failure: parse error, not found, would block | a result type: `std::optional`, `std::expected` (C++23), or a project result type |
| Exceptional failure: resource exhaustion, invariant broken at run time | an exception |
| Unrecoverable: corrupted state, failed invariant in a destructor path | terminate |

State the strategy in the interface and keep it. An interface that sometimes throws and
sometimes returns a status forces every caller to handle both.

## Exceptions

- Throw by value, catch by `const&`. Catching by value slices.
- Derive from `std::exception`, or a project base derived from it. Carry enough context to
  diagnose without re-deriving it at the catch site.
- Throw for a broken invariant, never for control flow. The cost of throwing is large and
  unbounded, so an exception on an expected hot path is a performance defect.
- Never let an exception escape a destructor. Destructors are implicitly `noexcept`, and it
  calls `std::terminate` during unwinding.
- `catch (...)` is legitimate only at a thread boundary, a plugin boundary, or `main`, and only
  if it logs and rethrows or terminates deliberately. Swallowing is a defect.
- Never use exceptions across a C ABI boundary. Catch and translate there.
- With exceptions disabled, the result-type strategy is the only option. Say so explicitly
  rather than mixing.
- A `noexcept` function that throws terminates. Mark `noexcept` only where the guarantee is
  real: move operations, `swap`, destructors, simple accessors.
- The Lakos rule: no `noexcept` on a narrow contract, even when every in-contract call never throws; document the non-throwing instead.

## Exception safety guarantees

Every function offers one of these, and the guarantee is part of the interface.

- Nothrow: cannot fail. Required for destructors, `swap`, move operations, and anything a
  container relies on during reallocation.
- Strong: on failure the state is unchanged, as if the call never happened. Do the work on a
  copy and commit with a nothrow operation, usually a `swap` or a move.
- Basic: on failure the invariants hold and nothing leaks, but the state may have changed. The
  minimum acceptable guarantee.
- None: not acceptable in new code.

Practical rules:

- Do the work that can throw first, and commit with operations that cannot throw.
- Never leave an object half-updated across a call that can throw. RAII covers the resource
  half.
- A container gives the strong guarantee on reallocation only when the element's move
  constructor is `noexcept`. Otherwise it copies.
- Write the guarantee down for any function that is not trivially nothrow.

## Result types

- `std::optional<T>` when the failure carries no information beyond "nothing".
- `std::expected<T, E>` (C++23) when the caller needs the reason. Before C++23, a
  `std::variant<T, E>` or a project type of the same shape.
- For a generic visitor over a `std::variant`, `static_assert` invocability with every alternative before forwarding it.
- The diagnostic moves from instantiation depth to one line.
- Mark such a return `[[nodiscard]]`, otherwise the error is silently discardable.
- Keep the error type small and cheap to move. No heap-allocated string on the hot failure
  path.
- `std::error_code` is the right type at a system-call boundary. A domain error is a domain
  type.
- Monadic chaining (`and_then`, `transform`, `or_else`) removes nested `if` checks at the cost
  of a move per step.

## Preconditions, assertions and invariants

- `assert` disappears under `NDEBUG`. A precondition that must hold in a release build needs a
  real check that throws, returns an error, or terminates.
- An assertion must have no side effect. Under `NDEBUG` the expression is not evaluated.
- A parameter honoured only inside an `assert` does nothing in a release build, which is a
  silent behaviour change between build types.
- Prefer making a precondition impossible to violate over documenting it: a strong type, a
  constructor that validates once, a narrower parameter type.
- Check invariants at the module boundary, not at every internal call.
- Prefer a compile-time check: `static_assert` with a message, a concept, or a type that cannot
  represent the invalid state.

## Failure paths are code

- Test the failure paths. An untested `catch` block or error branch is a defect waiting for
  production.
- Inject failure in tests: a throwing allocator, a failing mock, a truncated input.
- Sanitizers and a leak checker verify that the failure path releases what the success path
  released.
