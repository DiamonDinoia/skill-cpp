# C++20

Constraints, ranges and compile-time computation become first class. Read `cpp17.md` for the
base rules, which still apply.

## New here, use these

| Feature | Replaces |
|---|---|
| concepts, `requires` | `enable_if`, SFINAE, unconstrained templates with unreadable errors |
| abbreviated templates `void f(std::integral auto x)` | explicit template parameter lists |
| ranges and views | iterator-pair calls, hand-written filter/transform loops |
| `std::span` | pointer-plus-length parameters, array-to-pointer decay |
| `std::format` | `iostream` formatting, `printf` format-string bugs |
| three-way comparison `<=>`, `= default` | six hand-written comparison operators |
| designated initializers `{.a = 1}` | positional aggregate initialization |
| templated lambdas `[]<class T>(T x)` | `auto` parameters plus `decltype` gymnastics |
| `constexpr` virtual, `constexpr` allocation, `constexpr` algorithms | runtime tables, macro tables |
| `consteval`, `constinit` | `constexpr` plus a hope about when it runs |
| `[[nodiscard]]` with a reason string | a comment explaining why the result matters |
| `<bit>`: `bit_cast`, `popcount`, `countl_zero`, `has_single_bit`, `bit_width` | `memcpy` punning, compiler builtins behind macros |
| `<numbers>` math constants | `M_PI` and other non-portable macros |
| `std::jthread`, `std::stop_token` | `std::thread` plus a manual join and a stop flag |
| `std::atomic_ref`, atomic wait/notify, `std::latch`, `std::barrier`, `std::counting_semaphore` | condition-variable boilerplate |
| `std::source_location` | `__FILE__` / `__LINE__` macros |
| `using enum` | repeated enum qualification |
| two's complement signed integers mandated | sign-magnitude and ones'-complement portability folklore |
| `[[likely]]`, `[[unlikely]]` | compiler-specific `__builtin_expect` |
| `std::to_array`, `std::ssize`, `std::midpoint`, `std::lerp` | hand-written helpers, overflow-prone `(a+b)/2` |
| `std::cmp_less`, `cmp_greater` and friends | mixed-sign integer comparison through a common type |
| `starts_with`, `ends_with` on strings; `contains` on the associative containers | `substr` and `find` comparisons, `find(k) != end()` |
| `std::erase`, `std::erase_if` | the erase-remove idiom |
| range-`for` with initializer | a temporary leaking into the enclosing scope |
| `explicit(bool)` | duplicated constructors |
| `constexpr` `std::vector` and `std::string` | a `constexpr` array plus a hand-written size |
| `std::assume_aligned` | compiler-specific alignment hints |
| `std::bind_front` | `std::bind` |
| `std::make_shared` for arrays, `std::make_unique_for_overwrite` | `shared_ptr<T[]>(new T[n])`, value-initializing a buffer about to be overwritten |
| `std::atomic<std::shared_ptr<T>>` | the free `atomic_load`/`atomic_store` on shared pointers |
| `[[no_unique_address]]` | empty base optimization by inheritance |
| parenthesized aggregate initialization, `std::identity`, `char8_t` | `emplace` failing on aggregates, identity lambdas |
| modules, coroutines | headers, callback state machines, with the caveats below |

## Still missing, fallbacks

| Missing until | Feature | Fallback in C++20 |
|---|---|---|
| C++23 | `std::expected` | `std::variant<T, E>`, or a project result type |
| C++23 | `std::mdspan` | an index-computing view over a flat buffer, or `std::span` plus strides |
| C++23 | deducing `this` | CRTP, or const/non-const overload pairs |
| C++23 | `std::print` | `std::format` into a stream |
| C++23 | `ranges::to` | build the container from `ranges::begin`/`end`, or a manual loop |
| C++23 | `std::flat_map` | a sorted `std::vector<std::pair<K,V>>` with `lower_bound` |
| C++23 | `std::to_underlying` | `static_cast<std::underlying_type_t<E>>(e)` |
| C++23 | `if consteval` | `std::is_constant_evaluated()`, with the trap below |

## Traps

- `std::is_constant_evaluated()` inside an `if constexpr` is always `true`. Use a plain `if`,
  or `if consteval` once C++23 is available.
- A `constexpr` function must not contain a `static` or `thread_local` local. Move the table to
  namespace or class scope, or return it by value.
- `constexpr` allocation must not escape constant evaluation. Memory allocated at compile
  time must be freed at compile time.
- A view does not own. Never store a `views::filter` pipeline over a temporary container, and
  remember `filter_view::begin` is not `O(1)` and caches.
- Ranges and views cost build time, and an unoptimized build runs a view pipeline much slower
  than the equivalent loop. Check both the debug cost and the assembly on hot paths.
- `std::span` is non-owning and unchecked. Use the `std::dynamic_extent` default only when the
  size is genuinely dynamic, because a fixed extent gives the optimizer more.
- A defaulted `<=>` orders members lexicographically, which is rarely the intended ordering for
  a domain type. Define `operator==` separately when equality is cheaper.
- Concept subsumption follows the atomic constraints, not the names. Two concepts spelled
  differently do not order overloads unless one is expressed in terms of the other.
- A coroutine frame usually allocates, and a coroutine capturing a reference to a caller's
  temporary dangles. Never put a coroutine on a hot path without measuring.
- Adopt modules only when the whole toolchain handles them, the build system and the IDE
  included.
- `std::format` diagnoses a bad format string at compile time only when the string is a literal
  or `constexpr`.

## Idiom notes

- Constrain every template with a concept. Prefer a named concept for the project's requirement
  over an ad-hoc `requires` clause repeated at each call.
- Replace trait-driven overload sets with a concept plus `if constexpr`.
- Prefer a compile-time table built by a `consteval` function to runtime initialization.
- Prefer `std::span` for a contiguous parameter, with the extent as a template parameter when
  the size is known.
- `std::jthread` is the default thread: it joins on destruction and carries a stop token.
