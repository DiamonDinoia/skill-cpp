# Reviewing C++

Load when the task is to review a change rather than to write one.

## Order of attention

Review in this order, and stop escalating once a class of defect is found. A correctness defect
makes style comments noise.

1. Does it do the right thing? Check the change against the stated goal. A correct implementation
   of the wrong requirement is the most expensive defect.
2. Correctness and undefined behaviour: lifetime, ownership, bounds, arithmetic, initialization,
   error paths, concurrency. See `pitfalls.md`.
3. Is it the simplest solution? Look for a smaller design, an existing utility, a standard
   algorithm, a deletion instead of an addition.
4. Interfaces. Once published, a signature is expensive to change: parameter passing, ownership,
   error strategy, `const`, `[[nodiscard]]`, `explicit`.
5. Tests. Does a test fail if the logic breaks? Are the boundaries and the failure paths covered?
6. Performance, only where it matters and only with evidence.
7. Naming and comments, last and cheap to fix.

## What to check, concretely

- Every new owner is RAII: no `new`, no `delete`, no owning raw pointer.
- Every view (`string_view`, `span`, iterator, reference) provably outlived by its source.
- Every new branch has a test, and every error path has a test.
- Every fallible call's result is used.
- Every loop's boundary: empty input, one element, the last element, an overflowing index.
- Every conversion: signedness, narrowing, floating point to integer.
- Every added parameter: is the passing mode right for the size and the role?
- Every new virtual function: destructor, `override`, and no call from a constructor.
- Every shared object in a concurrent path: what synchronizes it?
- Every new include in a header: is it needed there, and what does it cost consumers?
- Every new dependency: is it justified, and is it already covered by the standard library?
- Every removed check: why, and what replaced it?

## Reading a diff

- Read the interface change before the implementation. A header change affects everyone.
- Read the tests before the code when the change is behavioural. They state the intended
  contract.
- Look for what is absent from the diff: the error path that was not updated, the second call
  site of the changed function, the documentation of the changed behaviour, the test that should
  have been touched.
- A large diff with one stated purpose is usually several changes. Ask for the split rather than
  reviewing the mixture.
- A mechanical change (rename, format, move) should be reviewable mechanically. If it is mixed
  with a behaviour change, that is the first comment.
- A generator- or LLM-produced change arrives as a reviewable diff a programmer signs off on,
  never an invisible tooling pass; give its API boundaries and bounds discipline a second read.

## Writing the comments

- Say what is wrong and why it matters, concretely, at the line. "This dangles when the caller
  passes a temporary" beats "lifetime issue".
- Distinguish severity explicitly: a defect that must be fixed, a design concern to discuss, and
  a preference the author may ignore. Never let the third kind block the change.
- Propose the concrete alternative when there is one. A review that only rejects costs another
  round trip.
- Prefer the lowest-churn fix that resolves the concern.
- Never re-litigate a decision the project already made, and never ask for a rewrite in the
  reviewer's own style.
- One comment per issue, not per instance. If a pattern repeats, say so once and name the
  pattern.

## Receiving a review

- A repeated correction is a defect in the process, not in the reviewer. Apply the correction as
  a class, not as the single instance quoted.
- Disagree once, with the reason, then follow the decision.
- Fix, then re-run the checks the change touched, before asking for another pass.
