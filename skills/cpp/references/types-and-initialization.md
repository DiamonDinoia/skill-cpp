# Types, constants and initialization

Load when declaring variables, choosing a type, designing constants, or reviewing
initialization.

## Initialization

- Initialize every object at its declaration. Reading an uninitialized automatic object of
  built-in type is undefined behaviour.
- Prefer `{}`: it rejects narrowing and cannot be parsed as a function declaration. Two
  exceptions: a container size (`std::vector<int> v(100)`), and a type whose
  `std::initializer_list` constructor would hijack the call.
- `T x{};` value-initializes. `T x;` at block scope leaves a built-in member indeterminate.
- Prefer a default member initializer to repeating the value in every constructor.
- Initialize members in the member initializer list. Members initialize in declaration order,
  not in the order written. Enable the warning for the mismatch.
- Declare a variable at first use, in the smallest scope, with its initializer. A distant
  declaration invites an uninitialized read and a stale value.
- Prefer a function-local `static` to a namespace-scope object with a non-trivial constructor.
  It initializes on first use and avoids the static initialization order fiasco.

## `auto`

- Use `auto` where the type is obvious from the initializer, unutterable (a lambda, an
  iterator, a view), or pure noise.
- Write the type when it is the information the reader needs, when deduction would differ from
  the intent, or when an implicit conversion is wanted.
- `auto` strips references and top-level `const`. Write `auto&`, `const auto&`, `auto*` or
  `auto&&` deliberately.
- Proxy types break `auto`: `auto b = v[i]` on a `std::vector<bool>` deduces the proxy, and an
  expression-template library deduces a node that dangles. Force the type, or write
  `auto x = T{expr}`.
- `auto x = T{...}` gives one non-narrowing declaration committed to its type.

## `const` and `constexpr`

- `const` by default: locals, references, non-modifying member functions, pointers to data
  that must not change. It is a compile-time check and a statement of intent.
- East or west `const` is a project convention. Follow the file.
- `constexpr` for anything computable at compile time. A compile-time table costs nothing at
  run time and cannot drift from its generator.
- `constexpr` on a variable means "must be a constant expression", on a function "can be, if
  the arguments allow". `const` on a member function means "does not modify the observable
  state".
- `constinit` (C++20) forces constant initialization without constness. `consteval` forces
  compile-time-only evaluation.
- `mutable` only for a cache or a mutex inside a logically const object.
- A namespace-scope `constexpr` variable in a header is implicitly `inline` since C++17.
  Before that it needs a single definition or a function returning it.

## Enumerations

- Use `enum class`. A plain `enum` leaks its enumerators into the enclosing scope and converts
  to `int` silently.
- Specify the underlying type when the value crosses an ABI, a file format or a wire protocol:
  `enum class Kind : std::uint8_t`.
- Flags need an operator overload set or a bitset type. A raw `|` on `enum class` does not
  compile, which is the point.
- Convert with `static_cast<std::underlying_type_t<E>>(e)`, or `std::to_underlying` (C++23).
- A `Count` or `Max` sentinel is a `switch` maintenance trap. Prefer a `switch` without a
  `default`, so the compiler reports the unhandled enumerator.

## Integers, characters and pointers

- `std::size_t` for sizes and indices into standard containers, `std::ptrdiff_t` for
  differences, a fixed-width type (`std::int32_t`) when the width is part of the contract.
- Never mix signed and unsigned in a comparison or in arithmetic. Enable the sign-compare and
  conversion warnings as errors.
- Prefer a signed type for arithmetic that can go negative, loop counters that count down
  included.
- `char` signedness is implementation-defined. Use `unsigned char` or `std::byte` for raw
  bytes, `char` only for text.
- Use `nullptr`, never `0` or `NULL`.
- A raw pointer is a non-owning observer, may be null, and points to one object. Use a
  container, a reference or a span for the other cases.

## Casts and conversions

- Never write a C cast. It silently selects among `static_cast`, `const_cast` and
  `reinterpret_cast`.
- `static_cast` for value conversions and for navigating a hierarchy when the type is known,
  `dynamic_cast` when it is not and the check is needed.
- `const_cast` only to call a legacy API that is const-correct in behaviour but not in
  signature. Modifying an object declared `const` is undefined behaviour.
- `reinterpret_cast` only at a documented punning or ABI boundary, under the aliasing rules in
  `pitfalls.md`. `std::bit_cast` (C++20) or `std::memcpy` is the portable tool.
- Mark single-argument constructors and conversion operators `explicit` unless the implicit
  conversion is the design.
- Prefer a strong type to a bare arithmetic type where the unit or meaning matters. A distinct
  type turns a runtime mistake into a compile error.

## Statements and control flow

- Keep every name's scope minimal, and prefer an `if`/`switch` with an initializer (C++17) to
  a variable that leaks into the enclosing scope.
- Prefer a range-based `for` to an index loop, and an algorithm to either.
- Do not modify the loop variable inside the body, or the container being iterated.
- Prefer an early return to deep nesting. Beyond two or three levels, extract a function.
- A `switch` over an enumeration has no `default`, so the compiler reports a new enumerator.
  Mark intentional fallthrough with `[[fallthrough]]`.
- No `goto`, except to break out of a nested loop where no cleaner form exists, and never into
  a scope.
- One operation per statement. Two side effects on one object in one expression, or a side
  effect and a read of it, are undefined or unspecified depending on the form.
- Never rely on the evaluation order of function arguments. It is unspecified.
- Prefer `!=` to `<` for iterators, and a named predicate to a compound boolean condition.
- Never write an empty `catch`, an empty `if` body, or an unused result where the compiler
  warns.
- No magic constants in the flow. Name them `constexpr`, and derive one from another rather
  than repeating a value.

## Aggregates and containers of values

- `std::array` over a C array, a container or span over a pointer-plus-length pair.
- A small struct with named members beats `std::pair` or `std::tuple` in an interface.
  `.first` carries no meaning at the call site.
- Designated initializers (C++20) make an aggregate initialization self-documenting.
- `std::optional` for "maybe a value", never a sentinel such as `-1` or an empty string.
