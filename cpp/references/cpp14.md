# C++14

C++11 plus the corrections that make C++11 pleasant. Read `cpp11.md` for the base rules and
traps; they all still apply.

## New here, use these

| Feature | Replaces |
|---|---|
| `std::make_unique` | `unique_ptr<T>(new T(...))`; also fixes the argument-evaluation leak |
| generic lambdas `[](auto x)` | one-off functor templates |
| lambda init-capture `[p = std::move(p)]` | shared_ptr workarounds to move into a lambda |
| function return type deduction (`auto f()`) | duplicated trailing `decltype` return types |
| `decltype(auto)` | wrong-by-default `auto` in perfect-forwarding wrappers |
| relaxed `constexpr` (loops, locals, branches) | recursion-only compile-time code |
| variable templates | `static constexpr` members of trait class templates |
| `std::foo_t` alias templates | `typename std::foo<T>::type` |
| `std::exchange` | read-then-assign pairs, hand-written move assignment |
| binary literals, digit separators (`0b1010'0110`) | hex plus a comment |
| `std::integer_sequence` | hand-rolled index packs for tuple expansion |
| `[[deprecated]]` | comments nobody reads |
| transparent comparators (`std::less<>`) | temporary key construction on lookup |
| `std::rbegin`, `std::rend`, `std::cbegin`, `std::cend` | member-only reverse and const iteration |
| `std::shared_timed_mutex` | a plain mutex where reads dominate |
| `std::quoted` | manual quoting and escaping in stream I/O |
| sized deallocation | a slower `operator delete` for user allocators |

## Still missing, fallbacks

| Missing until | Feature | Fallback in C++14 |
|---|---|---|
| C++17 | `if constexpr` | tag dispatch, `enable_if` overloads, or a class-template specialization |
| C++17 | structured bindings | `std::tie`, or named accessors |
| C++17 | `std::optional`, `std::variant`, `std::any` | sentinel plus documented contract; a tagged union behind one class |
| C++17 | `std::string_view` | `const std::string&` at boundaries, or a pointer-plus-length struct |
| C++17 | fold expressions | recursive variadics, or the initializer-list expansion trick |
| C++17 | class template argument deduction | `make_*` factories, easy to write with return type deduction |
| C++17 | inline variables | `constexpr` variable templates, or a function with a `static` local |
| C++17 | `[[nodiscard]]`, `[[maybe_unused]]`, `[[fallthrough]]` | compiler-specific attributes behind one macro |
| C++17 | guaranteed copy elision | rely on RVO and on move constructors; keep them `noexcept` |
| C++20 | concepts | `enable_if` plus a `static_assert` with a readable message |

## Traps

- `constexpr` no longer implies `const` on member functions, so code moved from C++11 changes
  meaning silently.
- `auto` return type deduction strips references. A forwarding wrapper needs `decltype(auto)`,
  and so does a getter that must return a reference.
- `decltype(auto)` on a parenthesized expression returns a reference:
  `decltype(auto) f() { return (x); }` returns a dangling `T&` for a local `x`.
- A function with a deduced return type cannot be used before its definition is visible, so it
  must live in a header.
- A generic lambda's `auto` parameter is a template parameter. Forward it with
  `std::forward<decltype(x)>(x)`.
- Init-capture creates a data member of the closure, so modifying it needs a `mutable`
  lambda.
- A relaxed `constexpr` function still cannot contain a `static` local or a `try` block.

## Idiom notes

- `std::make_unique` is the default way to build an owner. `new` should not appear.
- Return type deduction plus generic lambdas make small factory and adaptor helpers cheap.
  Prefer them to hand-written functor classes.
- Alias templates (`using foo_t = typename foo<T>::type`) keep template code readable. Expose
  `_t` aliases from project traits.
