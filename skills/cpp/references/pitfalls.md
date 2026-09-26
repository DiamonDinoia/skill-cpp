# Undefined behaviour, lifetime and aliasing: the catalog

Load when reviewing risky code, or when debugging a miscompilation, an optimization-dependent
bug, a sanitizer report, or a result that changes with `-O2`.

Undefined behaviour is not "an unspecified result". The optimizer assumes it cannot happen and
deletes the code that would have handled it. A bug that appears only at `-O2`, only in one
compiler, or only after an unrelated edit is undefined behaviour until proven otherwise.

## Lifetime and access

- Reading an uninitialized object of built-in type. Initialize at declaration.
- Using an object after its lifetime ends: a returned reference to a local, a view over a
  temporary, a captured reference outliving the closure, a `string_view` over a destroyed
  string, a `span` over a resized vector.
- Lifetime extension by a `const&` binding covers the temporary bound directly, not one
  reached through a function call or member access. `const auto& r = f().member` extends
  nothing when `f` returns by value.
- Dereferencing a dangling or null pointer, a `this` that outlived its object included.
- Relational comparison of pointers is defined only within one array or object.
- Deleting through a base pointer whose destructor is not virtual.
- Double free, or freeing memory from a different allocator.
- Placement `new` over a live object, or reusing the old pointer afterwards outside the
  standard's laundering rules.
- Accessing a member of a partially constructed object, for example through a virtual call in
  a constructor.

## Iterator and reference invalidation

- `vector`: growth invalidates all iterators, pointers and references. `insert` and `erase`
  invalidate from the modification point on.
- `deque`: insertion at either end invalidates all iterators but keeps references valid.
  Insertion in the middle invalidates everything.
- `string`: as `vector`. Any non-const operation may invalidate `data()`.
- Node-based containers (`list`, `map`, `set`, `unordered_*`): erase invalidates only the
  erased element. Rehashing invalidates all iterators of an unordered container, not
  references.
- Never hold an iterator across a call that can modify the container, a callback the container
  invokes included.

## Type punning and aliasing

- Reading a stored value through a pointer of an unrelated type breaks strict aliasing.
  `char`, `unsigned char` and `std::byte` may alias anything, and that exemption is one-way.
- A `union` write followed by a read of a different member is not portable in C++, unlike C.
- The portable punning tools are `std::memcpy` and `std::bit_cast` (C++20).
- Never `memcmp` whole objects: padding bytes compare. Use it only when
  `std::has_unique_object_representations` (C++17) holds, else compare memberwise.
- `reinterpret_cast` changes the type of the pointer, never the type of the object.
- Prefer `memmove` when buffers may overlap; `memcpy`, `strcpy` and `strncpy` on overlapping buffers are undefined behaviour.
- Loading through a misaligned pointer is undefined even on hardware that tolerates it. Use
  `alignas` for over-aligned types and the aligned allocation forms.
- Never overlay a struct on raw wire bytes; `memcpy` the fields into a correctly aligned local instead.

## Arithmetic

- Signed overflow is undefined, unsigned wraps. The optimizer uses signed overflow to prove
  loop bounds, so a wrap that "works" in a debug build can vanish at `-O2`.
- Shifting by at or above the width, or shifting a negative value left, is undefined.
- Division and remainder by zero, and `INT_MIN / -1`, are undefined.
- Integer promotion widens narrow types to `int` before arithmetic, so
  `uint16_t a, b; a * b` overflows as `int`.
- Fully parenthesize every function-like macro parameter and the whole macro body, or the expanded text reparses at the caller's precedence.
- Mixed signed and unsigned comparison converts the signed operand to unsigned. Enable the
  sign-compare warning as an error.
- Narrowing a value that does not fit is implementation-defined for integers, undefined for
  floating point to integer. `{}` initialization rejects it at compile time.
- Converting a floating-point value outside the destination range, `NaN` included, is
  undefined.

## Floating point

Accuracy, tolerances, stability and reproducibility are in `numerics.md`. Here is the part
that is undefined or trap-shaped.

- Never compare with `==`. Compare against a tolerance chosen from the operands' magnitude and
  the number of operations, or compare in units in the last place.
- Addition is not associative. Reordering a reduction changes the result, so a vectorized or
  parallel reduction needs a tolerance derived from the algorithm, not a guess.
- `-ffast-math` and its components remove `NaN` and infinity handling, allow reassociation,
  and change comparison against `NaN`. Never let a fast-math translation unit define a test's
  reference result.
- x87 excess precision and multiply-add contraction change the last digits. Fix the tolerance
  to the algorithm's error bound, not to the compiler.
- Prefer the precision the problem needs. A wider type costs bandwidth and halves the vector
  width, a narrower one costs accuracy. Decide with an error analysis.

## Static initialization and linkage

- The initialization order of namespace-scope objects across translation units is unspecified,
  and a dependency between them is the static initialization order fiasco. Use a
  function-local `static`, which initializes on first use and is thread-safe since C++11.
- A function-local `static` in a template is one object per instantiation.
- The one-definition rule requires an inline function or template to have exactly the same
  definition in every translation unit. Different macros or flags per translation unit make
  two definitions, and the linker silently keeps one.
- An entity with internal linkage in a header becomes one copy per translation unit.
- Mixing translation units built with different standard versions, debug or sanitizer
  settings, or standard library versions is an ABI mismatch that links cleanly and crashes at
  run time.

## Concurrency

- A data race is undefined behaviour. Two accesses to one object from different threads, where
  one writes, need a mutex, an atomic, or a happens-before ordering.
- `volatile` is not an atomic and gives no ordering. Use `std::atomic`.
- Prefer sequentially consistent atomics. Use acquire/release only with a written argument for
  why it suffices, and never relaxed ordering for a flag guarding data.
- A benign-looking read of a `bool` written by another thread is still a race without an
  atomic.
- Never join or detach a thread twice, and never let a thread outlive an object it references.

## Tools that find these

Run the address, undefined-behaviour and thread sanitizers in the test build, or in a
sanitizer-only CI job when they cost too much by default. They find what review does not, and
they cost nothing when the tests already exist.
