# The standard library

Load when choosing a container, writing a loop, handling strings, formatting, or reaching for
a hand-written utility.

## First rule

Know the library before writing anything. A hand-rolled equivalent of a standard component is
slower to write, wrong at the boundaries, and untested. Search the library, then a dependency
the project already has, then write code.

## Containers

| Need | Container |
|---|---|
| default sequence | `std::vector` |
| fixed size known at compile time | `std::array` |
| stable addresses under growth, front insertion | `std::deque` |
| stable addresses and iterators under any modification, splicing | `std::list`, `std::forward_list` |
| ordered lookup, range queries | `std::map`, `std::set` |
| average-constant lookup, no order | `std::unordered_map`, `std::unordered_set` |
| lookup-heavy, insert-rare, cache-friendly | sorted `std::vector`, or `std::flat_map` (C++23) |
| small, bounded, hot | a fixed `std::array` plus a size, or a small-buffer type |

- `std::vector` is contiguous and prefetch-friendly, and it beats node-based containers on
  iteration even when the asymptotics say otherwise. Measure before choosing a node-based one.
- `std::deque` gives cheap front and back operations and random access, at the cost of one
  indirection per access.
- `reserve` before a known number of insertions. Growth reallocates and invalidates.
- `std::map` and `std::unordered_map` allocate per node and scatter memory. `unordered_*` with
  the default hash is not fast, so profile before assuming.
- When output depends on iteration order: never iterate an unordered container directly, sort
  with a total predicate over all fields, and detect hidden order dependence by shuffling the
  input first.
- Prefer `emplace`, `try_emplace` and `insert_or_assign` to find-then-insert double lookups.
- To erase from a container whose order does not matter, swap the element to the back and
  erase it there: constant time instead of shifting.
- `std::vector<bool>` is a proxy container, not a container of `bool`. Use `std::vector<char>`
  or a bitset when the proxy causes trouble.
- `operator[]` is unchecked and `at()` throws. Use `at()` when an index may be out of range,
  `operator[]` for proven in-range hot paths.
- A priority queue over a vector beats a sorted container when only the extremum is needed.
  `nth_element` beats both when a partition is enough.
- Small values stay inline in a `std::string` and in a small-buffer container. Wrapping a small
  value in a pointer defeats that.
- Invalidation rules are in `pitfalls.md`. Layout, cache behaviour and allocators are in
  `memory-and-allocators.md`.

## Algorithms

- Reach for a named algorithm before writing a loop. It states intent and is already correct at
  the boundaries: `find`, `find_if`, `any_of`, `all_of`, `count_if`, `transform`, `copy_if`,
  `accumulate` / `reduce`, `sort`, `stable_sort`, `partial_sort`, `nth_element`, `lower_bound`,
  `equal_range`, `unique`, `rotate`, `partition`, `min_element`, `clamp`.
- A trivial loop - at most two lines, one conditional, no `continue` - may stay raw;
  anything bigger belongs in an algorithm call or its own function.
- `std::sort` needs a strict weak ordering. A comparator returning true for equal elements is
  undefined behaviour.
- Never treat container iterators as pointers; the typedef may become a class. Compare
  iterators with `!=`, not `<`: only random-access iterators support `<`.
- Removal algorithms do not remove. `remove`/`remove_if` shift and return the new end. Use
  `std::erase`/`std::erase_if` (C++20), or the erase-remove idiom before that.
- `std::accumulate` with `logical_and` or `logical_or` does not short-circuit;
  `all_of`/`any_of`/`none_of` do.
- When the destination overlaps the end of the source, use `std::copy_backward`, not
  `std::copy`.
- Output algorithms such as `std::transform` overwrite the destination range. Resize the
  destination, or write through an insert iterator (`std::back_inserter`).
- Use `nth_element` or `partial_sort` when a full sort is not needed. Take the weakest
  algorithm that works: it states the most precise intent. A function object passed to an
  algorithm must not modify the elements it is called on. Multi-key ordering: `stable_sort`
  by the least-influential key first. `minmax_element` computes both extrema in one pass.
- Ranges (C++20) remove the iterator-pair boilerplate and compose, at a cost in build time and
  unoptimized-build speed. Views are lazy and non-owning, so never build one over a temporary.
- Parallel algorithms (C++17) need a linked backend on some implementations and a race-free
  predicate.

## Strings

- `std::string` owns. `std::string_view` observes and is not null-terminated.
- Take a `std::string_view` when the function only reads, a `std::string` by value when it
  stores.
- To build a string in a loop, `reserve` then `append`. Never concatenate with `+` in a loop.
- `std::format` (C++20) for formatting, `std::print` (C++23) for output. Before C++20, a
  stream, or the fmt library if the project already has it. `printf` is not type-safe.
- Specialize `std::formatter` for a project type with `parse()` and `format()`, and throw
  `std::format_error` from `parse()` on a bad specifier.
- `std::from_chars` and `std::to_chars` (C++17) are the fast, locale-independent,
  allocation-free conversions. `stoi`, `atoi` and `stringstream` are slower and
  locale-dependent. They give an exact floating-point round trip: print with `max_digits10`
  digits, parse back with `from_chars`. When accepting input, take the value only when the
  returned pointer consumed the whole token.
- Avoid `std::endl`, which flushes. Use `'\n'`.
- Locale-dependent functions are a correctness hazard in data processing. State the locale, or
  avoid them.

## Utilities

- `std::optional`, `std::variant`, `std::any` (C++17) mean "maybe", "one of a closed set" and
  "anything, erased". Prefer the first two. `any` is rarely the right answer.
- `std::tuple` and `std::pair` for a plumbing return, a named struct for an interface.
- `std::span` (C++20) and `std::mdspan` (C++23) for contiguous and multidimensional views.
- `<chrono>` for all time. Never an `int` of unspecified units: the type carries the unit.
  `steady_clock` for stopwatches, `system_clock` for calendars; `high_resolution_clock` is an
  alias - avoid it. Leave the type system only knowingly: `duration_cast` names a truncation,
  `count()` belongs at the I/O boundary.
- `<random>` for randomness. Seed a named engine explicitly, never call `rand()`, and remember
  distributions are stateful and not portable across implementations. Never range-map with
  modulo; `uniform_int_distribution` owns uniformity.
- `<bit>` (C++20) for `bit_cast`, `popcount`, `countl_zero`, `has_single_bit` and `bit_width`,
  replacing compiler builtins behind macros.
- `<numeric>` for `accumulate`, `reduce`, `inner_product`, `gcd`, `lcm`, `midpoint`, `iota` and
  the scans.
- `<filesystem>` (C++17) for paths. It throws by default and has `error_code` overloads.
- `std::move`, `std::forward`, `std::exchange`, `std::swap`, `std::as_const` and
  `std::to_underlying` remove hand-written equivalents.
- Never `std::bind`. Use a lambda, or `std::bind_front` (C++20).
- `std::function` allocates and blocks inlining, so use it at interface boundaries only, and
  `std::move_only_function` (C++23) for move-only callables.

## Streams and I/O

- Streams are convenient and slow. For hot I/O, format into a buffer and write once.
- `std::ios::sync_with_stdio(false)` matters only when C and C++ I/O are not mixed.
- Never parse with `operator>>` when the format must be validated. Check the stream state after
  every extraction, or use a parser.

## When not to use the library

- A profile shows the standard component is the bottleneck and a narrower contract permits a
  faster one: a fixed-capacity container with no allocation, an open-addressing map for a known
  key distribution.
- The platform lacks the component, or the project bans exceptions or allocation on the path.

In both cases keep the standard interface, keep the standard version behind a build flag for
differential testing, and document the narrower contract.
