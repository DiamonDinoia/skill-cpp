# Writing vectorized code

Load when writing or reviewing a kernel meant to use the machine's vector units: explicit
vector types, an instruction-set dispatch, a batch loop, a tail, or anything targeting a
specific instruction set.

`performance.md` decides whether the kernel is worth vectorizing at all. This file is how to
write it once that is decided.

## Try the compiler first

- An auto-vectorized loop that reaches the same throughput is the better answer: no dispatch,
  no fallback, no second implementation to test. Read the vectorization report before writing
  anything by hand.
- Give the compiler what it needs: a contiguous access pattern, a computable trip count, no
  aliasing between source and destination, no early exit, no call it cannot inline, and
  arithmetic it may reassociate.
- Write vector code only when the report says it failed and the reason cannot be removed.

## Express it portably

- Write the kernel against one portable vector abstraction, a library type or a project
  wrapper, parameterized by element type and lane count. Never spread instruction-set `#ifdef`
  gates through the algorithm. Each gate doubles the code to read, test and keep in step.
- Where an intrinsic is unavoidable, isolate it behind a single named operation with a scalar
  definition of the same name, and test the two against each other on the same inputs.
- Keep the algorithm one function templated on the vector width, never a hand-written kernel
  per width. A per-size copy is a correctness liability, and the sizes chosen are never the
  ones the next machine wants.
- Loop structure that must be unrolled or specialized per lane count belongs in a compile-time
  loop over the width, not in duplicated bodies.

## Width, dispatch and fallback

- The lane count is a property of the element type and the target, not a literal. Derive it.
  Never write `8` because the development machine has that width.
- A kernel that only vectorizes at the widest available width leaves narrow machines and small
  problem sizes scalar. Match the width to the work: a short inner loop is better served by a
  narrower vector than by a masked wide one.
- Resolve runtime dispatch on the detected instruction set once, not per call. A dispatch tree
  pasted into every call site by an always-inline wrapper multiplies code size and pollutes the
  caller's register allocation. Give the dispatch its own function.
- Every vector path ships with a scalar path, and a test comparing them element-wise on the
  same inputs, including the sizes that exercise the tail.
- The dispatch decision is testable. Force each arm from the test and assert which arm ran.

## Data layout is most of the win

- Structure of arrays for anything a vector loop touches one field of. An array of structures
  forces a gather, and a gather is not a vector load.
- Interleaved complex data needs no shuffle when the algorithm can be restated on the real and
  imaginary parts directly, where the multiply becomes fused multiply-add pairs. Check the
  mathematics before adding a permutation.
- Vector-typed elements of a generic container are usually a pessimization: they add a
  conversion at every boundary and hide copies. Keep the storage plain and load into vectors at
  the point of use.
- Align the data to the widest load in use, taking the alignment from a property of the type
  rather than a hardcoded number. Unaligned loads are cheap on current hardware, split cache
  lines are not.

## Traps

- Hidden copies destroy the result. Audit for a by-value parameter, a temporary at a call
  boundary and a range-based loop over a materialized view before believing any speedup.
- Masking is not free. A masked store inside a read-modify-write loop can break
  store-to-load forwarding, which no instruction-cost model shows.
- A mask that depends only on template parameters belongs at compile time, as a constant in the
  instruction stream rather than a value computed per call.
- Unrolling helps only a loop with a serial dependency. An element-wise loop gains nothing and
  pays in register pressure and spills.
- The tail is where the bugs are. Test the size one element past a full batch, one short of it,
  zero, and one.
- An overlapped recompute of the tail beats a serial remainder loop where the buffer allows it.
- Reassociation changes results. A vectorized reduction sums in a different order than the
  scalar one. The difference is legitimate, and the test's tolerance must come from the error
  bound, not from what the scalar version happened to produce.
- A wider instruction set is not automatically faster. Frequency behaviour, port counts and the
  memory bound decide. Measure on the target, per width.

## Evidence

A SIMD claim needs three things: the emitted code showing the intended instructions
(`asm-and-codegen.md`), a measurement against the scalar path under the rules in
`benchmarking.md`, and an equivalence test against that same scalar path.
