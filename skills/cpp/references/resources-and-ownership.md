# Resources, ownership and RAII

Load when allocating, freeing, designing an owner, handling a handle, or reviewing lifetime
and ownership.

## RAII

- Every resource is owned by an object whose destructor releases it: memory, file, socket,
  lock, handle, GPU buffer, transaction. The destructor is the only release path that survives
  an early return, a `break`, and an exception.
- The constructor acquires and establishes the invariant. If it cannot, it throws, or a factory
  returns `optional` or `expected`.
- A raw acquire/release pair in a function body is a defect. Wrap it once in a handle type and
  use the handle everywhere.
- Never write cleanup in a `catch` block that a destructor could do.

## Owners

- `std::unique_ptr` is the default owner: exclusive, movable, zero overhead over a raw pointer.
  A custom deleter carries a C API's `free`/`close`/`destroy` function.
- `std::shared_ptr` only when ownership is genuinely shared and the last owner is unknown. It
  costs an allocation, two atomic counters, and it hides the lifetime from the reader.
- The control block also costs code: libstdc++ instantiates a dispose/destroy vtable per
  pointee type, so many distinct `shared_ptr<T>` uses are measurable bloat. (C++11)
- `std::weak_ptr` breaks cycles and expresses "may be gone". A cycle of `shared_ptr` leaks.
- In an asynchronous chain, keep the object alive by capturing a `shared_ptr` in every
  handler; a self-vending class hands out `shared_from_this()`. Pass the `shared_ptr` by
  value only when the callee takes over lifetime. (C++11)
- Prefer a value member to any pointer. A container of values beats a container of pointers
  unless polymorphism or stable addresses are required.
- No `new` and no `delete` in application code. Use `std::make_unique`, `std::make_shared`, or
  a container.
- `make_shared` allocates the object and the control block together, but keeps the storage
  alive while a `weak_ptr` exists. For a large object with long-lived weak references, prefer
  `shared_ptr<T>(new T(...))`.
- A `unique_ptr` member makes the class move-only automatically. For pimpl, declare the
  destructor in the header and define it in the source file, where the pointee is complete.

## Non-owning views

- A raw pointer, a reference, an iterator, `std::string_view`, `std::span` and `std::mdspan`
  never own. They are parameters and locals, rarely members, and never return values over a
  temporary.
- A view must not outlive what it views, and must not survive an operation that reallocates the
  underlying container.
- Never store a `string_view` in a long-lived object unless the buffer's lifetime is proven and
  documented.
- Passing a view instead of a `const&` avoids a conversion at the call site. Where the callee
  stores the data a view forces a copy anyway, so take a `std::string` by value there.

## Special member functions

- Rule of zero: define none of the five. Let members own their resources and let the compiler
  generate correct copy, move and destruction. This is the target for almost every class.
- Rule of five: if any of destructor, copy constructor, copy assignment, move constructor or
  move assignment is declared, declare or `= delete` all five. Declaring one suppresses or
  deprecates the others.
- A user-declared destructor suppresses the implicit move operations, which silently turns
  every move in the program into a copy.
- `= default` in the class body keeps the type trivial. Outside the class body it does not.
- `= delete` documents a forbidden operation and produces a clear diagnostic.
- A polymorphic base class deletes or protects copy and move to prevent slicing.
- Move operations are `noexcept` and leave the source valid but unspecified. Self-move must not
  corrupt the object.
- Implement copy assignment by copy-and-swap (simple, strong guarantee, one extra allocation)
  or directly (faster, must handle self-assignment).

## Containers as owners

- `std::vector` is the default owner of a sequence: contiguous storage, geometric growth, freed
  on destruction.
- `reserve` before a known number of `push_back` calls. `shrink_to_fit` only when the peak is
  much larger than the steady state.
- A fixed-capacity stack container avoids the heap entirely for a small, bounded number of
  small objects.
- `emplace_back` to construct in place, `push_back` when a constructed object already exists,
  because `emplace` bypasses `explicit` checks.
- A container of `unique_ptr` is the standard way to own a polymorphic set.
- Never store references in a container. Store values, pointers, or `std::reference_wrapper`.

## Locks and other scoped state

- `std::lock_guard`, `std::unique_lock`, `std::shared_lock` and `std::scoped_lock`, never a
  bare `lock()`/`unlock()` pair.
- The same discipline applies to any paired state change: a stream flag, a signal mask, a
  working directory, a GPU context. Write a small scoped type once.
- Name every guard object. An unnamed temporary guard releases immediately and the bug is
  invisible.

## Interop with allocating C APIs

- Wrap the C handle in a `unique_ptr` with a stateless deleter, or in a purpose-built RAII
  class when release takes more than one call.
- Guard a custom deleter against an incomplete pointee with `static_assert(sizeof(T) > 0)`
  inside it. (C++11)
- Convert at the boundary. Take ownership on the way in, release it explicitly on the way out,
  and never let a raw handle circulate in the rest of the code.
- `std::out_ptr` and `std::inout_ptr` (C++23) adapt a smart pointer to a C function that writes
  through a `T**`.
