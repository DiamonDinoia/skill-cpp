# C++23 and later

Incremental over C++20, and the standard where library support lags the language most. Read
`cpp20.md` for the base rules; they still apply.

## Check support before use

The language mode says nothing about the library implementation. Test the feature-test macro
from `<version>` before depending on a C++23 library feature:

```cpp
#include <version>
#if defined(__cpp_lib_expected) && __cpp_lib_expected >= 202202L
```

`std::mdspan`, `std::print`, `std::flat_map`, `std::generator` and `import std` are the ones
most likely to be absent on an otherwise C++23 toolchain.

## New here, use these

| Feature | Replaces |
|---|---|
| `std::expected<T, E>` | `std::variant<T, E>`, error codes plus an out-parameter, exceptions on expected failures |
| monadic `std::optional` (`and_then`, `transform`, `or_else`) | nested `if (opt)` chains |
| deducing `this` (`auto&& self`) | CRTP, duplicated const and non-const overloads |
| `std::mdspan` | index arithmetic over a flat buffer written by hand |
| `std::print`, `std::println` | `std::cout << std::format(...)` |
| `ranges::to<Container>()` | manual loops to materialize a view |
| `std::flat_map`, `std::flat_set` | a sorted vector plus hand-written lookups |
| `std::generator` | hand-written iterator classes for lazy sequences |
| `if consteval` | `std::is_constant_evaluated()` and its `if constexpr` trap |
| multidimensional `operator[](i, j)` | `operator()` for element access |
| `std::to_underlying` | `static_cast<std::underlying_type_t<E>>` |
| `std::unreachable`, `[[assume(x)]]` | compiler-specific builtins for the same hints |
| `static operator()`, `static operator[]` | non-static call operators on stateless functors |
| `std::pair`/`std::tuple` of references reject temporaries | silently dangling reference tuples |
| `auto(x)`, `auto{x}` | `decay_copy` helpers |
| `std::byteswap`, `std::stacktrace` | hand-rolled byte swapping, platform backtrace code |
| `std::string::contains`, `std::ranges::starts_with` | `find` comparisons |
| more `constexpr` (`unique_ptr`, `cmath`, `to_chars`) | runtime initialization of tables |
| `std::move_only_function` | `std::function` forcing a copyable callable |
| `std::out_ptr`, `std::inout_ptr` | a raw local pointer adopted after a C call writes through `T**` |
| `std::forward_like` | hand-written value-category propagation for a member of a forwarded object |
| `std::start_lifetime_as` | `reinterpret_cast` over a byte buffer with no lifetime started |
| `std::ranges::fold_left`, `std::bind_back`, `std::spanstream` | `accumulate` with its ordering quirks, `bind`, `stringstream` over a fixed buffer |
| `size_t` literal suffix (`10uz`) | a cast to silence a sign-compare warning |
| `import std;` | including standard headers, where the toolchain supports it |

## C++26 and beyond

Treat anything beyond C++23 as opt-in, per feature, guarded by a feature-test macro, and only
when the project already compiles with the flag. Reflection, contracts, `std::execution` and
hazard pointers change design, so adopt them deliberately, not as a modernization sweep.

- Contract assertions replace `assert` and macro preconditions: they live in the
  declaration, and a comma or brace inside the predicate breaks the `assert` macro
  but never a contract assertion.
- Structure sender code as factories that return senders plus adaptors that transform
  them; free functions over member knobs keep the pipeline composable.
- Protect concurrently removable objects with hazard pointers: acquire and publish the
  hazard before access, and reclaim asynchronously on read-heavy domains.
- Call `sync_wait` at the top level of a sender flow only; every call blocks the
  calling thread until the whole flow completes.
- Where asynchronous work composes, adopt `std::execution` senders over `std::async`
  and bare futures: a future blocks on `get()` and chains nothing, while senders
  compose and keep concurrency structured behind one scheduler model.
- Reading an indeterminate automatic variable is erroneous behaviour, not undefined
  behaviour: a wrong value, not an unbounded one. Mark intentional scratch reads
  `[[indeterminate]]`.
- Select a pack element with pack indexing `Ts...[I]` instead of hand-rolled recursive
  templates.
- A structured binding may be the condition of `if`, `while`, `for` and `switch`
  directly; the condition tests the whole decomposed object, not one member.
- Constrain memberwise reflection to aggregates without base classes; member-by-member
  iteration across a base is where the layout surprises live.
- Where reflection answers a question at compile time, ship it as a `consteval`
  library, traits included, instead of reaching for compiler intrinsics or a new
  language feature.
- Make a task type sender-aware, so coroutines `co_await` sender chains directly
  instead of wrapping a blocking wait.

## Traps

- `std::expected` costs the value or the error plus a flag, and `operator*` on an unexpected
  value is undefined behaviour. Use `value()` when a throw is wanted, and keep `E` small.
- Monadic chains on `optional` and `expected` copy or move at each step. On a hot path, check
  what the chain compiles to.
- Deducing `this` changes name lookup inside the member, because members are reached through
  `self` instead of implicitly. A recursive lambda through `self` must not outlive its
  captures.
- `std::mdspan` is non-owning, like `span`. The layout and accessor policies are part of the
  type, so a default `layout_right` view over column-major data is silently wrong.
- `std::generator` and any coroutine allocate a frame and add an indirection per element.
- `[[assume]]` is a promise to the optimizer. A false assumption is undefined behaviour and the
  compiler will not warn.
- `std::flat_map` has vector complexity: fast lookup, linear insertion in the middle. Use it
  for lookup-heavy, insert-rare data only.
- `import std;` needs build-system support and a compiled module cache. Mixing it with an
  `#include` of the same headers in one translation unit is not portable.
- `std::aligned_storage` is deprecated. Use a project aligned-buffer type, or `alignas` on a
  plain byte array.

## Idiom notes

- `std::expected` is the default for expected failure, exceptions for the exceptional. Choose
  one per interface and keep it.
- Deducing `this` removes the const and non-const duplication of accessors, and replaces CRTP
  for mixins.
- Prefer `std::print` for output and diagnostics. It beats the stream chain on speed and checks
  the format string at compile time.
- Use `ranges::to` to end a view pipeline instead of an accumulate loop.
