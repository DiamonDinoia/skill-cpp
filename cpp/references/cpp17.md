# C++17

The standard that removes most template boilerplate. Read `cpp11.md` and `cpp14.md` for the
base rules; they still apply.

## New here, use these

| Feature | Replaces |
|---|---|
| `if constexpr` | tag dispatch, `enable_if` overload chains, most SFINAE |
| fold expressions `(f(args) && ...)` | recursive variadic templates |
| class template argument deduction | `make_*` factory functions |
| structured bindings `auto [a, b] = ...` | `std::tie`, `.first` / `.second` |
| init-statement in `if` / `switch` | a variable leaking into the enclosing scope |
| inline variables | header constants defined in one TU, or accessor functions |
| `constexpr` lambdas | separate `constexpr` helper functions |
| `[[nodiscard]]`, `[[maybe_unused]]`, `[[fallthrough]]` | macros and casts to `void` |
| `std::string_view` | `const std::string&` parameters that force allocation |
| `std::optional` | sentinel values, out-parameter plus `bool` |
| `std::variant`, `std::visit` | tagged unions, virtual hierarchies for closed sets |
| `std::byte` | `char`/`unsigned char` for raw memory |
| `std::filesystem` | platform path handling |
| parallel algorithms (`std::execution::par`) | hand-rolled thread pools for simple loops |
| `std::apply`, `std::invoke` | index-sequence expansion, callable dispatch by hand |
| `std::clamp`, `std::gcd`, `std::lcm`, `std::reduce`, `std::*_scan` | hand-written equivalents |
| `std::size`, `std::data`, `std::empty` | `sizeof(a)/sizeof(a[0])` |
| `std::foo_v` trait variables | `std::foo<T>::value` |
| nested namespaces `namespace a::b {}` | nested blocks |
| aligned `new`, `std::launder`, `std::aligned_alloc` | platform allocation for over-aligned types |
| `emplace_back` returning a reference; `try_emplace`, `insert_or_assign`; node splicing | find-then-insert double lookups |
| guaranteed copy elision | reliance on a move constructor for factory returns |
| `std::from_chars`, `std::to_chars` | `stoi`, `atoi`, `stringstream`: slower, allocating, locale-dependent |
| `std::scoped_lock`, `std::shared_mutex` | nested `lock_guard`s in a fixed order; a plain mutex for read-heavy data |
| `std::as_const` | a `const_cast` to select the const overload |
| `std::void_t`, `std::conjunction`, `std::disjunction`, `std::is_invocable` | hand-rolled detection idioms |
| `std::not_fn`, `std::sample`, `std::launder` | `std::not1`/`not2`, hand-written sampling |
| `std::hardware_destructive_interference_size` | a hardcoded cache line size |
| `__has_include` | build-system probes for an optional header |
| aggregate initialization with base classes | a constructor that only forwards |
| `std::uncaught_exceptions()` | the singular, unreliable `uncaught_exception()` |

## Still missing, fallbacks

| Missing until | Feature | Fallback in C++17 |
|---|---|---|
| C++20 | concepts | `if constexpr` plus traits; `enable_if` at the overload level; `static_assert` for the message |
| C++20 | ranges and views | algorithms on iterator pairs; a small pipeline by hand |
| C++20 | `std::span` | a `pointer, size` struct, or `gsl::span` |
| C++20 | `std::format` | a stream, or `fmt::format` from the fmt library |
| C++20 | `<=>` | write the six comparison operators, or generate them from a `tie` |
| C++20 | `<bit>` (`bit_cast`, `popcount`, `countl_zero`) | `memcpy` for type punning; compiler builtins behind one wrapper |
| C++20 | `constinit`, `consteval` | `constexpr` plus a comment about the initialization order |
| C++20 | `std::jthread` | `std::thread` plus a joining wrapper and a stop flag |
| C++23 | `std::expected` | `std::variant<T, Error>`, or `std::optional` plus a separate error channel |
| C++23 | `std::mdspan` | an index-computing accessor class over a flat buffer |

## Traps

- `std::string_view` does not own and is not null-terminated. Never store one that outlives its
  buffer, never return one over a temporary, and never pass one to a C API expecting a
  terminated string.
- `std::optional` costs the value plus a flag, and `operator*` on an empty one is undefined
  behaviour. Use `value()` when a throw is wanted.
- `std::variant` can become valueless by exception. Keep alternatives `noexcept`-movable.
- Structured bindings copy by default. Write `auto&` or `const auto&` to bind in place. A
  binding name is not a variable and a lambda cannot capture it before C++20.
- `if constexpr` discards a branch only inside a template. In a non-template function both
  branches must compile.
- Class template argument deduction can pick a surprising type: `std::pair p{"a", "b"}` deduces
  `const char*`. Write deduction guides for project types.
- Parallel algorithms need a linked backend on some implementations, and the predicate must be
  race-free. An unsynchronized capture is undefined behaviour.
- `std::filesystem` throws by default. The `error_code` overloads do not.
- Inline variables have one address across translation units, but their initialization order
  across translation units is still unspecified.

## Idiom notes

- `if constexpr` is the default compile-time branch. It replaces most trait-driven overload
  sets and makes the dataflow readable.
- Take a string parameter as `std::string_view` when the function only reads it, and as
  `std::string` by value when it stores it.
- Prefer `std::optional<T>` as a return type over an out-parameter plus a `bool`.
- Use `std::variant` plus `std::visit` for a closed set of alternatives, and virtual dispatch
  for an open set.
