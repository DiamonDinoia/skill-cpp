# Legacy code, C interop and modernization

Load when working in an old codebase, calling or exposing a C API, or planning a modernization
pass.

## Modernization policy

- Modernize the code you are already touching, in the same change, and stop there. A
  repository-wide sweep mixed with a behaviour change is unreviewable.
- Never churn for churn's sake. A change that neither fixes a defect, nor removes a hazard, nor
  simplifies, is cost without benefit.
- Prefer the lowest-churn fix that solves the problem. Three lines beat a sweep, and a targeted
  `using std::name` beats editing every call site.
- Never raise the project's language standard as a side effect. Propose it separately, with the
  compiler and CI versions that support it.
- Automate what can be automated: `clang-tidy` `modernize-*` with the fixes applied, then review
  the diff. Disable only the checks that fight a deliberate project idiom, and record which and
  why.
- Each mechanical pass is its own commit, separate from behaviour changes, so review can be
  mechanical too.

## Priority order when modernizing

1. Undefined behaviour and memory errors, which is what the sanitizers report.
2. Owning raw pointers, manual `new`/`delete`, manual cleanup paths to RAII.
3. C casts and unchecked conversions to named casts, or a redesigned type.
4. Macros to `constexpr` variables, `constexpr` functions, templates, `enum class`.
5. Manual loops to algorithms, index arithmetic to a span or a range.
6. Out-parameters and sentinel values to return values, `optional`, `expected`.
7. Formatting and naming, last and mechanically.

## Working safely in legacy code

- Characterize before changing. Add a test that captures the current behaviour, including the
  behaviour that looks wrong, then change.
- Match the surrounding style even when it is not the style preferred here. One file with two
  conventions is worse than one file with an old convention.
- Keep the change reviewable: separate the move, the rename and the edit.
- Wrap rather than rewrite. Put a modern interface around the legacy component, convert callers
  gradually, and delete the old one when nothing calls it.
- Delete dead code instead of maintaining it. Version control keeps the history.
- Never disable a test, a sanitizer, coverage or an assertion to make a problem go away. Fix it,
  or state the cost of keeping it.

## Calling C from C++

- Wrap the handle in an RAII type at the boundary, so no raw handle circulates beyond it.
  `std::unique_ptr` with a custom deleter covers the single-call release case.
- An opaque non-pointer handle wants a small RAII type of its own, not a `unique_ptr` forced to hold it as a pointer.
- Wrap a loaded-library handle in RAII, and never call into a library after it is unloaded.
- When teardown ordering is unclear, leak the library rather than unload it.
- Check every return code at the boundary and translate it once into the project's error
  strategy.
- Never let an exception propagate into a C callback or across a C ABI. Catch everything at the
  boundary function and translate to an error code.
- A C callback taking a `void*` context receives a pointer to a C++ object. The trampoline casts
  it back, and the object must outlive the registration.
- POSIX thread cancellation unwinds through C++ frames unpredictably; keep `pthread_cancel` away from C++ code.
- `std::out_ptr` and `std::inout_ptr` (C++23) adapt a smart pointer to a `T**` output parameter.
  Before that, use a local raw pointer and adopt it immediately.
- Embedding a C API with global state (CPython): include its header (`Python.h`) before any other.
- For such an API, acquire its global lock around its calls and release the lock around long C++-only work.
- Never hand Python an unmanaged pointer or reference to internal C++ state.
- Convert a C array or a pointer-plus-length pair to `std::span` at the C++ side of the boundary,
  immediately.
- Match the C header's types exactly, including signedness and width. Never assume `int` and
  `long` widths.

## Exposing C++ through a C ABI

- The exported functions are `extern "C"`, take and return only C types, and never throw.
- Represent an object as an opaque handle: a create function returning a pointer, a destroy
  function, and free functions taking the handle.
- State the ownership rules in the header: who frees, and with which function.
- Never export anything whose layout depends on the C++ standard library version.

## Mixed C and C++ builds

- A header shared with C uses `#ifdef __cplusplus` and `extern "C"`, and contains only what C
  can parse.
- Before sharing a type across the C boundary, `static_assert` `is_trivially_copyable` and `is_standard_layout` on it.
- C++ reuses tail padding, so the byte-copyable shape is not the natural one.
- C and C++ differ on `const`, on `union` type punning, and on implicit conversions from
  `void*`. Code that compiles as both is subject to the stricter reading.
- Link with the C++ driver when any translation unit is C++, so the runtime and the static
  initializers are linked in.
