# Reading generated code as evidence

Load when the question is what the compiler actually emitted: vectorization, inlining, spills,
dispatch, a cost model, or an optimization that "should" have happened.

## When codegen is the right evidence

- A localized change whose effect is smaller than benchmark noise.
- A vectorization, inlining, unrolling or devirtualization question.
- A claim about instruction count, register pressure or spilling.
- A result that differs between compilers or optimization levels.

For anything larger than a loop, profile first. When a gap resists explanation, a profile finds
the cause faster than another round of static reasoning.

## The rules that keep a codegen finding honest

- A static count is what was emitted, never what ran. Executed work comes from differencing
  retired-instruction counters between two runs, not from counting lines in a listing.
- The finding must reproduce under the project's own compile line. Flags, architecture target,
  `NDEBUG`, link-time optimization and the surrounding translation unit all change the output.
  A snippet compiled in isolation with different flags proves nothing about the project.
- Read the code in its calling context. A function examined alone shows spills and moves that
  vanish once it is inlined into the real caller, and hides the register pressure the real
  caller creates.
- Symbol names lie. Optimizers emit clones with decorated suffixes for constant propagation,
  partial inlining and argument promotion, so a diff matched by symbol name pairs the wrong
  functions or misses a body entirely. Match by content, and resolve call targets explicitly.
- A helper written as a capturing lambda can be outlined into such a clone, so the work
  disappears from the function being read and reappears elsewhere.
- Verify the model against the object. Before believing a mechanism, confirm the instruction
  the model predicts is present in the emitted code.
- Ask the compiler directly. Optimization reports answer "did it vectorize", "did it unswitch"
  and "why was this not inlined" in a second, and cost less than reading a listing. Note that
  "the compiler did X" is not "X was profitable".

## Cost models and counters

- A static cost model assumes every load hits the first-level cache. The ratio between measured
  and modelled cycles is therefore the memory-stall factor, which is information, not a bug in
  the model.
- Instruction count is not cost. On hardware where multiply, add and fused multiply-add share
  issue ports, "saves N multiplications" means nothing until restated as port pressure.
- When counting instructions with a pattern, account for the real mnemonic spelling. Fused and
  masked forms carry operand-order and predicate infixes that a naive pattern misses, and the
  resulting count is silently zero or low.
- Port pressure, dependency chains and issue width explain more than raw counts. A loop with a
  serial dependency is latency-bound, so unrolling it helps. An element-wise loop gains nothing
  from unrolling and pays in register pressure and spills.
- Masking is not free in every context. A masked store into a read-modify-write loop can break
  store-to-load forwarding, which no instruction-cost model shows.

## Common findings and what they actually mean

| Observation | Reading |
|---|---|
| spills and reloads in the loop body | register pressure: too many live values, often from unrolling or an inlined dispatch chain |
| scalar code where vectors were expected | aliasing, an unknown trip count, control flow in the body, or a call the compiler could not inline |
| an unexpected `memset` before a loop that overwrites everything | value-initialization waste, but only a finding if the `memset` is really emitted |
| the same body duplicated many times | a dispatch tree pasted into every call site by an always-inline wrapper |
| a call that survives at the highest optimization level | the definition was not visible, or the compiler judged it unprofitable |
| a virtual call that disappears | devirtualization: `final` where the design allows, or the static type already fixes the target (C++11) |
| identical object size after a source change | link-time folding of duplicate instantiations. Measure the final binary, not the object files |

## Turning a codegen finding into a change

- Prefer the change that removes the cause: hoist the invariant, split the dispatch into its own
  function so the arm chain has its own stack frame, mark the destination pointer `__restrict`,
  give the compiler a compile-time trip count.
- When two variants tie on measured performance, keep the one with fewer live values and fewer
  registers. It composes better when inlined into a larger caller.
- A codegen improvement is not a result until it shows up in a measurement. Confirm with a
  profile or a benchmark that follows `benchmarking.md`.
- Record the compiler, the version, the flags and the target with any codegen claim. Without
  them the claim is not reproducible and does not transfer to another compiler.
