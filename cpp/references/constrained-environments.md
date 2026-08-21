# Constrained environments and dialects

Load when the project disables exceptions or RTTI, forbids allocation, targets an embedded or
freestanding platform, has hard real-time deadlines, or compiles code for an accelerator.

The general rules still hold. What changes is which mechanisms are available, so the idiom
changes while the principle does not.

## Exceptions disabled

- The error strategy becomes a result type everywhere: `std::expected` (C++23),
  `std::optional`, or a project result type, returned and `[[nodiscard]]`.
- A constructor can no longer fail. Move the failing work into a static factory returning the
  result type, and keep the constructor trivial and total.
- Standard containers still allocate and would throw on failure. With exceptions disabled the
  implementation terminates instead. If termination is unacceptable, pre-reserve the allocation
  or use a non-throwing allocator.
- RAII is unaffected and becomes the only automatic cleanup, so it matters more.
- Never fake exceptions with `setjmp`/`longjmp`. It skips destructors.

## RTTI disabled

- No `dynamic_cast` and no `typeid`. Replace a downcast with a virtual function, a visitor, or a
  `std::variant` over a closed set.
- Where a type tag is genuinely needed, store an explicit enum or a static identifier in the base
  and check it. Keep the mapping in one place.

## No allocation

- Size everything at compile time: fixed-capacity containers, `std::array`, spans over
  caller-provided storage, and an arena reserved at startup.
- Take the buffer as a parameter rather than returning an owning container, so the caller owns
  the storage decision.
- Standard containers, `std::string`, `std::function` and coroutines allocate. Use fixed-capacity
  equivalents, a small-buffer callable, or a template parameter for the callable.
- `std::pmr` with a `monotonic_buffer_resource` over a static buffer keeps the standard
  containers while removing the global allocator. The resource must outlive every container using
  it.
- Verify the property rather than assuming it. An allocator that terminates on use, or a test
  that counts allocations, turns the rule into a check.

## Freestanding and embedded

- The freestanding subset provides the language and a small part of the library. Check what the
  toolchain actually ships before using a header.
- Startup cost and code size are first-class. Static initializers, virtual tables, exception
  tables and template instantiations all consume flash. `constexpr` initialization moves work out
  of startup.
- Memory-mapped registers are `volatile`, and `volatile` means "do not elide or reorder this
  access", not "atomic" and not "thread-safe".
- An interrupt handler shares data with the main flow: use an atomic, disable the interrupt
  around the access, or use a lock-free single-producer queue. The thread-safety rules apply even
  without threads.
- Integer widths, alignment requirements and unaligned access support vary more than on a desktop
  target. See `portability.md`.
- Keep the hardware-touching layer thin and testable, and test the logic above it on the host.

## Hard real-time

- The constraint is the worst case, not the average. Anything with unbounded or unpredictable
  cost is forbidden on the deadline path: allocation, exceptions, locks that can block, I/O, and
  any container operation that can reallocate.
- Pre-allocate, pre-touch and pre-warm. Reserve before the deadline path starts.
- Prefer wait-free or bounded lock-free structures for the handoff, and keep the deadline path
  free of anything a lower-priority thread can hold.
- Measure the tail, the maximum and the high percentiles. The mean is irrelevant to a deadline.

## Accelerator and device code

- Device dialects are subsets: no exceptions, no RTTI, a restricted standard library, restricted
  recursion, and their own rules for what may be captured or passed.
- Keep the algorithm in host-testable code and the device-specific parts thin, so correctness is
  testable without the device.
- The data movement usually dominates. Measure transfers and occupancy before tuning arithmetic,
  and keep the layout coalesced for the device's access pattern.
- Portability layers exist. If one is already a project dependency, use it rather than writing a
  second dialect by hand.

## Stating the constraint

Record the constraint once, in the build configuration and in the project's documentation, then
enforce it mechanically: the flag that disables the feature, a test that fails when an allocation
happens, a static analysis rule. A constraint that lives only in a reviewer's memory is not a
constraint.
