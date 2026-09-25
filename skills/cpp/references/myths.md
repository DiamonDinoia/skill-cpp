# Myths, non-rules and misapplied advice

Load when a rule is being applied mechanically, when a review comment cites a maxim, or when a
"best practice" contradicts the measurement.

## Rules that are not rules

- "One return per function." An early return for a precondition or a trivial case is clearer than
  a nested flow and a result variable. RAII already handles the cleanup that motivated the rule.
- "Never use `goto`." Almost never. The one defensible use is breaking out of a nested loop where
  the alternatives are worse. Never jump into a scope.
- "Never use macros." Prefer `constexpr`, templates and `enum class`. The preprocessor remains
  the only tool for include guards, conditional compilation, and the few cases that need its
  token or source-location behaviour.
- "Always use `auto`." Use it where the type is obvious, unutterable or noise. Write the type when
  the type is the information, or when deduction would give the wrong one.
- "Never use raw pointers." A non-owning, nullable observer is exactly what a raw pointer is for.
  The rule is against owning raw pointers.
- "Never inherit." Inherit to model a substitutable interface. The rule is against inheritance of
  implementation for reuse.
- "Never use exceptions." They are the right tool for exceptional failure in a codebase that
  enables them, and the wrong one for expected failure. The decision is per project, made once.
- "Comments are always good." A comment restating the code is negative value: one more thing to
  keep true.
- "Hungarian notation", "one class per file", "getters and setters for every member" are
  conventions from other eras or other languages, not from C++.

## Performance folklore

- "`++i` is faster than `i++`." For an `int` the compiler emits the same code. It matters for a
  non-trivial iterator, where the postfix form makes a copy.
- "`inline` makes it faster." `inline` is a linkage rule, not an optimization request. The
  compiler decides inlining, and can only do so when it sees the body.
- "Passing by `const&` is always cheaper." Not for a type that fits in a register or two. The
  indirection costs more than the copy and blocks optimizations.
- "Move is always cheap." Moving a `std::array`, or a type with no move constructor, copies.
  Moving a small value is the same as copying it.
- "Returning by value copies." Copy elision is mandatory since C++17 for a prvalue, and
  `std::move` on a returned local blocks it.
- "`std::shared_ptr` is the safe default." It is two atomic operations, an allocation, a cycle
  hazard and an unclear lifetime. `unique_ptr` or a value is the default.
- "Lock-free is faster than a mutex." A contended atomic serializes cache lines just as a lock
  does, and the code is far harder to get right.
- "Virtual calls are the bottleneck." An indirect call costs a few cycles, a cache miss costs
  hundreds. Measure before devirtualizing.
- "Unsigned for anything non-negative." Unsigned arithmetic wraps, breaks reverse loops, and mixes
  badly with signed values in comparisons. Use signed for arithmetic, unsigned where the
  standard's interface already is.
- "`float` is faster than `double`." It is when bandwidth or vector width dominates, not when
  conversions are inserted around it. Pick the precision the problem needs.
- "The compiler will vectorize it." It will, under conditions: no aliasing, simple control flow, a
  known trip count. Verify in the assembly or the optimization report.
- "Optimizing early is the root of all evil." The quotation is about micro-optimizing before
  measuring. Choosing the right algorithm, data layout and type up front is design, and it is the
  expensive thing to change later.
- "Custom allocators speed things up." Only after the profile shows the allocator. The default one
  is good.
- "More threads means faster." Beyond the point where memory bandwidth or a shared line
  saturates, more threads is slower. Measure the scaling curve.

## Correctness folklore

- "It works, so it is correct." Undefined behaviour works until the compiler, the flags or the
  surrounding code changes.
- "The sanitizer is being pedantic." Sanitizers do not report false positives for the errors they
  detect. The report is the defect.
- "It compiles without warnings, so it is fine." Warnings catch a subset. Sanitizers, tests and
  static analysis catch different subsets.
- "A test passed, so the code is covered." A test that asserts nothing, or asserts only on a path
  that did not run, proves nothing.
- "It is faster, I timed it once." One timing, uninterleaved, without a control, measures the
  machine's state as much as the change.
- "`volatile` makes it thread-safe." It does not. `std::atomic` does.
- "`const` means thread-safe." It means "does not modify the observable state".

## How to use this file

When a maxim is invoked, ask what it protects against, and whether that hazard is present here. A
rule applied where its hazard does not exist adds cost with no benefit, and the cost is usually
complexity, which is what every rule here was written to reduce.
