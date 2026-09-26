# Templates and generic programming

Load when writing or reviewing a template, a concept, a trait or a metafunction, or when
compile time or code size grows.

## Design

- Write the generic version once, parameterized. A hand-written specialization per size, type
  or architecture is duplicated logic that drifts.
- Inside a class template definition, the bare template name names the current instantiation; do not repeat the parameter list.
- A template expresses an algorithm over a requirement, not a set of type-specific tricks.
- Prefer a function template to a class template when there is no state.
- A function template cannot be stored or addressed; only its instantiations exist.
- Keep the interface small and the requirements explicit. A requirement that is hard to state
  means the abstraction is wrong.
- Cleverness that hides the dataflow is complexity, not skill. A reader must see which code
  runs for a given instantiation.

## Constraining

- Constrain every template. An unconstrained one accepts wrong types and reports the error
  deep inside the instantiation.
- The mechanism follows the standard: concepts (C++20), `if constexpr` plus traits and a
  `static_assert` (C++17), `std::enable_if` at the overload level plus a `static_assert` for
  the message (C++11/14).
- Name the requirement. A named concept or trait documents the contract and is reusable. An
  inline `requires` clause repeated at each call site is not.
- Constrain the general template rather than adding a competing overload. A
  forwarding-reference overload wins every inexact match unless constrained.
- Prefer a concept over a tag type, and a tag type over an integral flag.
- In a requires-expression, brace a compound requirement's expression before `-> Type`; a nested predicate needs its own `requires`. (C++20)
- A requires-clause cannot hang on a non-template.
- A concept checks syntax, not semantics: `std::totally_ordered` accepts a type that violates the ordering axioms. (C++20)
- Do not validate semantic requirements at construction through a concept.

## Compile-time branching

- `if constexpr` (C++17) is the default compile-time branch, replacing tag dispatch and most
  SFINAE chains.
- It discards a branch only inside a template. In a non-template function both branches must
  compile.
- Before C++17, use tag dispatch or `enable_if` overloads, never a runtime `if` on a
  compile-time property.
- Prefer a compile-time table (`constexpr` array, `consteval` generator) to a runtime switch
  when the inputs are known.
- Template recursion is a last resort. Fold expressions (C++17), pack expansion and
  `std::index_sequence` cover most of it.

## Compile-time programming

- Move work to compile time when the inputs are known there: a lookup table, a parsed format
  string, a hash of a literal, a dispatch decision, a unit conversion.
- `constexpr` means "may run at compile time", `consteval` (C++20) means "must", `constinit`
  means "initialized at compile time, still mutable". Use `consteval` when a runtime fallback
  would be a silent performance loss.
- `if consteval` (C++23) selects the compile-time implementation.
  `std::is_constant_evaluated()` does the same before it, and must not appear inside
  `if constexpr`, where it is always true.
- Traits are compile-time functions over types: query with `_v`, transform with `_t`, and
  prefer a concept when the answer is a requirement rather than a fact.
- Compile-time strings and hashes turn a runtime string comparison into an integer one. Keep
  the runtime path for anything that is not a literal.
- When a mask, shuffle pattern, index list or predicate is a function of template parameters,
  build it `constexpr` so it becomes an immediate, instead of computing it per call and
  trusting the optimizer to hoist it.
- Do not restate a compile-time constant at runtime. A `constexpr` value is usable directly:
  `if constexpr (kOdd)`, `f<kOdd>()`, `arr[kOdd]`. Wrapping it, unwrapping a trait's
  `::value`, or copying it into a local adds names without information.
- Prefer a template parameter to an integral-constant tag object. From C++20, `auto` as a
  non-type template parameter and a lambda with an explicit template parameter list express
  the same thing with no helper type.
- On finding such a redundancy, fix the whole class of it, then grep the tree to prove none is
  left.
- Compile-time work is paid in build time. Weigh both and measure: `compile-speed.md`.

## Instantiation cost

- Every distinct instantiation is separate code, with its own object size, compile time and
  instruction cache footprint. Per size, per type and per call site multiplies quickly.
- Factor the type-independent part into a non-template function or base. Only the part that
  depends on the parameter stays generic.
- `extern template` suppresses instantiation in every translation unit but one.
- An always-inline wrapper around a dispatch tree pastes the tree at every call site. Measure
  the object size, not only the runtime.
- Measure build time per translation unit before and after. A refactor that doubles the build
  is a cost, not a win.
- A `static` local in a template is one object per instantiation, so a once-only flag inside a
  template does not do what the name suggests.

## Deduction and forwarding

- `T&&` is a forwarding reference only when `T` is deduced in that same declaration. In a
  class template's member function the class parameter is already fixed, so `T&&` is an rvalue
  reference.
- Forward with `std::forward<T>(x)` exactly once, at the point of use. Forwarding twice reads
  a moved-from object.
- A generic lambda's `auto` parameter is a template parameter. Forward it with
  `std::forward<decltype(x)>(x)`.
- Class template argument deduction (C++17) can deduce a surprising type. Write deduction
  guides for project types.
- Deduction ignores implicit conversions, so a call that "should" work often needs an explicit
  template argument or a constrained overload.
- A braced-init-list argument to a deduced parameter is a non-deduced context: deduction fails. (C++11)
- Declare the return of an expression `auto`, not `T`, when operators may yield another type (`string_view + string_view` yields `string`).
- Pin the type assumption with `static_assert(std::is_same_v<...>)` when it matters.

## Specialization and customization

- Prefer overloading a function template to specializing it. Full specialization does not
  participate in overload resolution the way readers expect, and partial specialization of a
  function template does not exist.
- Customize through a trait class, a concept-constrained overload found by ADL, or a
  customization point object. Require users to specialize a class template only where the
  design documents that as the extension mechanism.
- Specializing a standard template is allowed for `std::hash` and a few others, for a
  user-defined type only.
- Otherwise leave the standard alone: no specialization, forward declaration, address taking or detection idioms against standard entities.
- Two-phase lookup binds a non-dependent name at definition, so a dependent call must be
  visible at definition or found by ADL at instantiation. Prefix dependent types with
  `typename`, dependent templates with `template`.

## Diagnostics

- Put a `static_assert` with a readable message at the top of a template whose requirement
  the constraint cannot express.
- A `static_assert` whose condition is not template-dependent fires at definition, even in a discarded `if constexpr` branch. (C++17)
- Make the condition dependent (a `dependent_false<T>` trait) when it must wait for instantiation.
- Never put a `static_assert` in a function a requires-expression must evaluate.
- Fail at the interface, not deep inside a helper. A concept on the entry point gives a
  one-line error, a failure three levels down gives a page.
- When a template error is unreadable, reduce it: instantiate the failing type explicitly in
  a small file.
