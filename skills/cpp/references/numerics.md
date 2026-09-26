# Numerical code

Load when the code computes with floating point or with integers that can overflow, when
comparing numerical results, or when a result differs between runs, threads, compilers or
optimization levels.

`pitfalls.md` covers what is undefined behaviour. This file covers what is well-defined and
still wrong.

## The floating-point model

- A binary floating-point number carries a relative error of at most half an ulp. Decimal
  fractions such as `0.1` are not representable, so a decimal result needs a decimal type or
  fixed-point arithmetic.
- Addition and multiplication are commutative but not associative, so the result depends on the
  order of operations. Vectorization, parallel reduction, a different loop structure and a
  compiler transformation all change the last digits legitimately.
- Catastrophic cancellation: subtracting two nearly equal numbers keeps the error and loses the
  significant digits. Reformulate the expression rather than adding precision.
- Fused multiply-add computes with one rounding instead of two. It is usually more accurate and
  always different. The compiler may or may not contract, and the controlling flag differs per
  compiler.
- Special values are part of the model: signed zero, infinities, quiet `NaN`. `NaN` is
  unordered, so every comparison with `NaN` except `!=` is false.
- Denormals are slow on some hardware and flushed to zero by some flags, which changes results
  near zero.

## Comparing results

- Never compare with `==`, and never with a constant epsilon pulled from a tutorial.
- Choose the tolerance from the algorithm: the number of operations, the condition number of
  the problem, and the magnitudes involved. State the bound and where it came from.
- Prefer a relative comparison for large magnitudes, an absolute one near zero, and a combined
  form when the range spans both.
- Comparing in units in the last place is the right tool when the question is "how many
  representable numbers apart".
- The reference for a test must be an independent oracle: an analytical result, a
  higher-precision computation, or a second implementation. Comparing an implementation to
  itself proves only that it is deterministic.
- A reference implementation must never be compiled with fast-math, and must never be the
  optimized code under test.

## Accuracy techniques

- Sum with compensation (Kahan or Neumaier) when adding many values of similar magnitude, or
  sum pairwise. A blocked or vectorized reduction sums pairwise already, which is why its result
  is often more accurate than the naive loop.
- Prefer a stable formulation: the stable quadratic root, `log1p` and `expm1` near zero,
  `hypot` for a norm, Horner evaluation for a polynomial.
- Scale to avoid overflow and underflow in intermediate results.
- Choose the precision the problem needs. Higher precision costs bandwidth and halves the
  vector width, lower precision costs accuracy. Decide with an error analysis, not by habit.
- Mixed precision is legitimate: accumulate in a wider type than the data.

## Determinism and reproducibility

- Bitwise reproducibility across runs requires a fixed operation order: a fixed thread count and
  partitioning, no atomic accumulation, no work stealing over floating-point reductions.
- For reproducible parallel sums, prefer fixed-precision integer arithmetic; higher-precision
  floating point still reorders.
- Bitwise reproducibility across compilers or machines also requires controlling contraction,
  vector width and the library implementations of transcendental functions, which are not
  standardized.
- Decide which level the project promises, write it down, and test it. Promising bitwise
  equality across platforms is usually a mistake, promising a documented error bound is not.
- A parallel result that differs from the sequential one in the last digits is expected, not a
  defect. Compare against the tolerance, not the sequential bits.

## Integer arithmetic

- Signed overflow is undefined, unsigned wraps. Check before the operation rather than detecting
  after it.
- Use a wider type for an intermediate product, or a checked-arithmetic helper, when the
  operands come from input.
- Integer division truncates toward zero, and the remainder takes the sign of the dividend. Use
  a floor-division helper when a modulus must be non-negative.
- Converting a floating-point value to an integer truncates, and is undefined outside the range.
  Round explicitly, then check the range.
- Prefer exact integer arithmetic where the domain is exact: counts, indices, money in minor
  units. Never represent money as a binary floating-point value.

## Random numbers

- Seed a named engine explicitly, and record the seed with the result. An unseeded or
  time-seeded engine makes a failure unreproducible.
- Distributions are stateful and their output is not portable across implementations. When
  cross-implementation reproducibility matters, implement the transformation from raw bits
  explicitly.
- Per-thread generators need distinct, non-overlapping streams. Sharing one generator across
  threads is both a race and a correlation.
