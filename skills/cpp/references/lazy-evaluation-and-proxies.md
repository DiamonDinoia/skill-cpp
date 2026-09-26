# Lazy evaluation, proxy objects, views and generators

Load when a computation produces temporaries that are immediately discarded, when a pipeline of
transformations materializes intermediate containers, or when designing a type that should
compute only what is asked for.

## The idea

Compute at the point of use, not at the point of expression. That removes work the result never
needed and the temporaries that carry it.

Three mechanisms, in increasing cost of implementation:

1. Views: a lazy, non-owning range that produces elements on demand.
2. Proxy objects: an unnamed intermediate type that captures the operands and does the work
   only when converted to the result type.
3. Generators, meaning coroutines: a function that yields elements one at a time, keeping its
   state in a frame instead of a container.

## Views (C++20 ranges)

- A view pipeline (`filter`, `transform`, `take`, `drop`, `join`, `chunk`) evaluates per
  element, on demand, allocating nothing. It replaces a chain of intermediate vectors.
- Composition is the point. One pass over the data replaces one pass per stage.
- A view does not own. Never build a pipeline over a temporary container, and never store a view
  whose source can be destroyed or reallocated.
- Generic code over ranges (C++20) must expect a proxy `reference`: never take an element's address, never assume a real lvalue.
- Viewing an Eigen buffer with `std::mdspan`: the default `layout_right` silently transposes it; Eigen is column-major, use `layout_left`. (C++23)
- Never pass a temporary view pipeline to a parallel range algorithm: `transform_view` is not a `borrowed_range`, and the iterators dangle. (C++20)
- `filter_view::begin` is not constant time and caches its first result, so a filtered view
  passed around is not free to re-traverse.
- Views cost compile time and are much slower than a plain loop in an unoptimized build. Check
  both when the code is hot and the debug build matters.
- Materialize deliberately with `ranges::to` (C++23) or an explicit loop, once, at the end.
- Writing a view: `begin()`/`end()` plus `ranges::view_interface` (C++20); specialize
  `std::iter_swap` for a proxy iterator so mutating algorithms work.
- At an adaptor boundary, apply `std::views::all` to convert any incoming range into a view.

## Proxy objects

A proxy captures the operands of an expression and defers the work.

- The comparison that never needs the expensive operation: comparing lengths compares the
  squared lengths, and the square root happens only if a length itself is requested.
- The concatenation that never materializes: a proxy holding two strings answers `size()`,
  comparisons and a single write into a destination without allocating the joined string.
- The expression template: an arithmetic expression over vectors or matrices builds a tree of
  proxies, and one fused loop evaluates it on assignment, with no temporary per operator.

Rules for writing one:

- The proxy must be unnamed in practice. Return it from `operator+` or a member, and convert or
  assign immediately.
- `auto x = a + b;` binds the proxy, not the result. That is the standard dangling trap, because
  the proxy holds references to operands that may not survive. Constrain the proxy so it is hard
  to store, and document it.
- Provide the conversion to the concrete result type so the common use is transparent.
- Never reach for expression templates before a profile shows the temporaries. They are a large
  amount of machinery, they degrade error messages and compile time, and a plain fused loop is
  often clearer and equally fast.

## Generators and coroutines

- A coroutine that yields values (`std::generator` in C++23, a hand-written generator before it)
  expresses a lazy sequence with a straight-line body. No iterator class, no explicit state
  machine.
- Use it for a producer whose state is awkward to hold in an iterator: a parser, a tree
  traversal, a stream of records.
- Each coroutine allocates a frame unless the compiler elides it, and each element costs a
  suspend and resume. That is fine for I/O and parsing, and usually not fine inside a hot
  numeric loop.
- Asynchronous coroutines (`co_await`) express a chain of asynchronous operations as sequential
  code, replacing nested callbacks. They need an execution context, an event loop, a thread pool
  or an executor, which the standard library does not yet provide, so the project chooses one
  and commits.
- A coroutine that captures a reference to a caller's temporary dangles. The frame outlives the
  expression that created it.
- Never let a coroutine's exception escape unnoticed. The promise type decides what happens, and
  a silent swallow is easy to write by accident.

## When laziness is the wrong answer

- The whole result is needed anyway, so laziness adds indirection for nothing.
- The consumer traverses the sequence more than once, so recomputation happens per pass.
- The elements are cheap and the pipeline is short, so a plain loop is simpler and faster.
- The code is hot and the development build is unoptimized, where the abstraction penalty is
  real.

Measure both forms when the choice matters. The lazy version wins on allocations and total work.
The eager version wins on simplicity and repeated traversal.
