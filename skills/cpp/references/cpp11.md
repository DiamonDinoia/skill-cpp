# C++11

The baseline of modern C++. Everything here is available; nothing from C++14 or later is.

## Use these

| Feature | Replaces |
|---|---|
| `auto` | repeated type names, iterator spelling |
| range-based `for` | index and iterator loops |
| lambdas | function objects, `std::bind`, free helper functions |
| `nullptr` | `0`, `NULL` |
| `enum class` | plain `enum` |
| `override`, `final` | comment-only override marking |
| `= default`, `= delete` | private undefined members to suppress copying |
| `std::unique_ptr`, `std::shared_ptr` | owning raw pointers, manual `delete` |
| move semantics, `std::move` | copy-and-swap workarounds, out-parameters |
| `std::array` | C arrays |
| `constexpr` | macro constants, magic numbers |
| `static_assert` | template tricks that fail with unreadable errors |
| variadic templates | overload sets per arity, C varargs |
| `<type_traits>` | hand-written trait classes |
| `<chrono>` | `clock()`, platform timers |
| `<thread>`, `<mutex>`, `<atomic>` | pthreads, platform threads |
| `std::tuple`, `std::tie` | out-parameters for multiple results |
| unordered containers | hand-rolled hash tables |
| non-member `std::begin`/`std::end` | `x.begin()` on containers only |
| trailing return types (`auto f() -> T`) | duplicated `decltype` return spellings |
| `noexcept` | `throw()` exception specifications |
| delegating constructors, non-static data member initializers | duplicated constructor bodies |
| ref-qualified members (`auto f() && -> T`) | a copy where a temporary could hand over its guts |
| explicit conversion operators | the safe-bool idiom |
| `alignas`, `alignof` | compiler-specific alignment attributes |
| `thread_local` | platform thread-local storage APIs |
| `<random>` | `rand()`, hand-rolled generators |
| `<regex>`, raw string literals | escaped pattern strings, external regex libraries |
| user-defined literals, `long long`, `char16_t`/`char32_t` | unit-less constants, platform 64-bit typedefs |
| inline namespaces | manual symbol versioning |
| `extern template` | the same template instantiated in every translation unit |
| `std::function`, `std::ref` | hand-written callback wrappers |

## Not available, use the fallback

| Missing until | Feature | Fallback in C++11 |
|---|---|---|
| C++14 | `std::make_unique` | `std::unique_ptr<T>(new T(...))`, wrapped once in a project helper |
| C++14 | generic lambda `[](auto x)` | a small local template functor, or an explicit parameter type |
| C++14 | lambda init-capture `[p = std::move(p)]` | capture a `shared_ptr`, or a hand-written functor with a member |
| C++14 | return type deduction for functions | trailing return type with `decltype` |
| C++14 | relaxed `constexpr` | a single `return` expression, recursion instead of a loop |
| C++14 | variable templates | a `static constexpr` member of a class template |
| C++14 | `std::foo_t` aliases | `typename std::foo<T>::type` |
| C++17 | `if constexpr` | tag dispatch, or `std::enable_if` overloads |
| C++17 | `std::optional`, `std::variant`, `std::string_view` | a sentinel value plus a documented contract; a `const char*`+length pair |
| C++17 | fold expressions | recursive variadic templates |
| C++17 | `[[nodiscard]]`, `[[maybe_unused]]` | compiler attributes such as `__attribute__((warn_unused_result))` behind one macro |
| C++17 | class template argument deduction | `make_*` factory functions |
| C++17 | inline variables | a function returning a `static` local, or a definition in one TU |
| C++20 | concepts | `static_assert` on traits, plus `std::enable_if` |

## Traps

- `constexpr` on a member function implies `const` in C++11 only. Code written for C++11 and
  compiled as C++14 changes meaning.
- A `constexpr` function body is a single `return` statement. No loop, no local variable.
- GCC and Clang extension builtins (`__builtin_popcount`, `__builtin_popcountll`) are constant
  expressions in a `constexpr` context, so a wrapper that forwards to them keeps `constexpr`
  at every standard. Verify with a compiler probe ("does
  `static_assert(__builtin_popcount(0xffu) == 8)` compile at the detected standard?"), never
  from a general assumption about extensions.
- `std::initializer_list` wins overload resolution against other constructors:
  `std::vector<int> v{3}` is one element, `std::vector<int> v(3)` is three.
- A `std::unique_ptr` member deletes the class's copy operations. For pimpl, declare the
  destructor in the header and define it in the source file.
- `auto` deduction strips references and `const`. Write `auto&`, `const auto&` or `auto&&`
  deliberately.
- `T&&` is a forwarding reference only when `T` is deduced. For a deduced parameter use
  `std::forward<T>`, never `std::move`.
- A lambda capturing by reference must not outlive what it captures. `[=]` in a member function
  captures `this`, not the members.
- `std::move` on a `const` object silently copies.
- `shared_ptr` control-block updates are atomic and are not free. Prefer `unique_ptr`.
- Declaring a destructor, a copy operation or an assignment suppresses the generated moves.
  Declare all five or none.
- Two `std::shared_ptr(new T)` arguments in one call leak if the other throws. Use
  `make_shared`.
- A container moves elements only when the move is `noexcept`, otherwise it copies.
- `std::thread` terminates the program if it is neither joined nor detached.
- Lambdas supersede `std::bind` from this standard onward. `bind` is harder to read, hides
  copies of the bound arguments and defeats inlining. Never write a new one.

## Idiom notes

- Enable move-only design: return by value, take sinks by value or by `T&&`.
- SFINAE with `std::enable_if` in the return type or a defaulted template parameter is the
  constraint mechanism. Put a `static_assert` with a readable message next to it.
- `std::function` allocates and prevents inlining, so use it at interface boundaries only. Take
  a template parameter for a callable inside hot code.
