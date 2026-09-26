# Functions, interfaces, overloads and operators

Load when designing or reviewing a function signature, an overload set, an operator, or a
public API.

## Parameter passing (Core Guidelines F.15 to F.21)

| Role | Signature | Notes |
|---|---|---|
| in, cheap to copy | `void f(T v)` | built-ins, small trivially copyable types, a `string_view`, a `span` |
| in, expensive to copy | `void f(const T& v)` | never for a type that fits in a register or two |
| in-out | `void f(T& v)` | the call site shows the modification only through the name |
| will move from | `void f(T&& v)` plus `std::move` in the body | the sink overload |
| forward | `template <class TP> void f(TP&& v)` plus `std::forward<TP>` | only when the value category must be preserved |
| out | return it | `return`, not an output parameter |

- Return values, not output parameters. Guaranteed copy elision (C++17) and move semantics
  make returning by value cheap. Return a small named struct for several results.
- "Pass by value and move" fits a one-argument constructor sink. On a hot path with a copy
  already in hand, an overload pair (`const T&` and `T&&`) saves one move.
- Take a `std::shared_ptr` by value only to share or transfer ownership. A function that only
  uses the object takes a reference to the object.
- Never transfer ownership through a raw pointer or reference (I.11). Return a
  `std::unique_ptr`.
- Do not pass an array as a single pointer (I.13). Pass a span, or a container reference.
- An optional parameter is `std::optional<T>` or an overload, never a magic value.
- Default arguments are one overload with one body, cannot be overridden virtually, and are
  baked into the caller. Prefer an overload when the behaviour differs.

## Return values

- `[[nodiscard]]` when discarding the result is a bug: a factory, a `try_*` function, an error
  status, a pure query.
- Never return a pointer or reference to a local (F.43), and never a view over a temporary.
- Return a `T*` only to indicate a position or an optional non-owning result, and document
  that null is possible.
- Prefer a value or a `std::optional` to an out-parameter plus a `bool`.
- Trivial types return in registers. A non-trivial type such as `std::unique_ptr` forces the
  ABI to pass a hidden output pointer, and the call site gains destruction bookkeeping - one
  more reason to keep special members defaulted.
- A getter returning a reference exposes the invariant. Return by value for a cheap type, by
  `const&` for an expensive one, and consider not exposing the member at all.
- Never return `const T&` to a parameter: a temporary argument binds to it and the result
  dangles at the end of the full expression.

## `noexcept`, `explicit`, `const`

- `noexcept` on move constructors, move assignment, `swap` and destructors. Containers select
  the move path only when the move cannot throw.
- `noexcept` elsewhere only when the guarantee is real and permanent. It is part of the
  interface, removing it later breaks callers, and a throw from a `noexcept` function calls
  `std::terminate`.
- Every member function that does not modify the observable state is `const`. Thread safety is
  a separate decision, which `const` does not promise.
- Ref-qualified members (`auto value() && -> T`) let a temporary hand over its guts instead of
  copying.

## Overload resolution, ADL and name lookup

- An overload set does one thing at different types. Overloads that behave differently need
  different names.
- Delete the `const T&&` overload: the set then rejects temporaries at the call site. Nothing
  in a move or forward path takes `const T&&`. (C++11)
- Prefer overloading to a runtime `switch` on a type tag, and a template to a long overload
  set of identical bodies.
- ADL finds functions in the namespace of the argument types. That is what makes `swap(a, b)`
  and `begin(x)` extensible: call them unqualified after `using std::swap;`, never as
  `std::swap(a, b)`.
- Define a free function that is part of a type's interface as a hidden friend inside the
  class. It is findable only by ADL, so it neither pollutes the overload set nor slows lookup.
- A derived-class member hides all base overloads of that name. Re-expose them with
  `using Base::f;`.
- A template argument makes implicit conversion unavailable in deduction, so a template plus
  non-template overload pair rarely does what the author expects.
- Never mix default arguments with a same-named overload, and never mix a function template
  with ordinary overloads of the same name: the wrong candidate wins without a diagnostic.
- Top-level `const` on a by-value parameter is not part of the signature; it cannot form an
  overload.
- Never add a forwarding-reference overload to a set that also takes a concrete type. The
  forwarding one wins every non-exact match. Constrain it.
- Prefer a `= delete` (C++11) overload to a constraint that merely removes a candidate when the call
  would dangle: deletion still participates in the set and surfaces the offending call
  instead of silently reselecting another overload.

## Value categories

- An lvalue has identity, a prvalue is a pure value, an xvalue is an expiring lvalue. `T&&`
  binds to rvalues, and a named `T&&` parameter is itself an lvalue.
- `std::move` is a cast, `std::forward` a conditional cast. Use `std::move` on a concrete
  `T&&` and on a local going into a sink, `std::forward` only on a deduced parameter.
- Never `std::move` a local or by-value parameter into the `return` of a function returning by
  value: it blocks copy elision on the local, and the parameter moves implicitly anyway. Move
  explicitly only when returning a member or other subobject, which no implicit move covers.
- `std::move` on a `const` object copies silently.
- A forwarding wrapper must return a true rvalue for an rvalue and the same reference for
  an lvalue. Anything else binds a dangling reference. (C++11)
- A moved-from object is valid but unspecified. Do not read it. Assign or destroy it.

## Operators

- Overload an operator only for its conventional meaning. If the reader has to look it up, use
  a named function.
- Overload symmetrically and completely: `==` implies `!=` before C++20, `<` implies the rest
  of the ordering, `+` implies `+=` and is defined in terms of it.
- In C++20 define `operator==` and `operator<=>` and let the compiler synthesize the rest. A
  defaulted `<=>` compares members lexicographically in declaration order, rarely the intended
  domain ordering.
- Define binary arithmetic and stream operators as non-members so the left operand converts
  symmetrically. Define compound assignment as a member.
- `operator<<` and `operator>>` take the stream by reference and return it. A manipulator such
  as `std::setw` applies to one insertion only, so a multi-field `operator<<` cannot honour
  the caller's width.
- Never overload `&&`, `||` or `,`. Overloading removes short-circuiting and sequencing.
- An `operator[]` or `operator*` that can fail needs a documented precondition, checked in a
  debug build.

## Lambdas and callables

- A lambda is the default callable. `std::bind` is obsolete: a lambda is clearer, cheaper and
  composes.
- Capture explicitly. `[=]` and `[&]` hide what the closure holds, and `[=]` in a member
  function captures `this`, not the members. Since C++17, capture `*this` by value when the
  copy is intended.
- A captureless lambda converts to a function pointer; any capture prevents it. `[=]` never
  captures globals, and writing a global in a simple-capture is ill-formed. (C++11)
- Per-copy mutable state in a lambda wants init-capture (C++14) plus `mutable`; a `static` local
  inside the lambda is shared state.
- A lambda stored beyond the enclosing scope must not capture by reference.
- Pass an overloaded or templated callable to an algorithm through a generic lambda (C++14) that
  forwards: overload resolution then happens inside the body, not at the call site.
- Use a template parameter for a callable inside hot code. `std::function` allocates and
  prevents inlining, so it belongs at an interface boundary. `std::move_only_function`
  (C++23) handles the move-only case.

## API design

- The interface states its preconditions, its ownership and its error strategy. If a comment
  is needed to explain the parameter order, the types are wrong.
- Make invalid states unrepresentable: strong types, an enum, a constructor that validates
  once, a factory returning `optional` or `expected`.
- Keep the interface minimal and complete: everything a caller needs, nothing a caller can
  build from the rest.
- A function short enough to read at a glance needs no section comments. If it needs them,
  split it.
