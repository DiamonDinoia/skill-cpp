# Source files, physical design and ABI

Load when adding or organizing headers, deciding what goes in which file, designing a library
boundary, or fixing include and link problems.

## Header and source split

- A header declares the interface. Put in it only what callers need: declarations, templates,
  `inline` and `constexpr` functions. Everything else goes in the source file.
- Include what you use, in every file, and never rely on a transitive include.
- Include only what you use. Every extra include costs compile time for every consumer and
  triggers a rebuild on every change.
- Forward declare a type when only a pointer or a reference to it appears in the header.
- Order includes so each header proves it is self-contained: own header, project, third party,
  standard.
- Use `#pragma once`, or include guards named after the project and the path. Never a name
  starting with an underscore.
- No `using namespace` in a header, ever. A targeted `using std::name` is the low-churn
  alternative anywhere.
- Never define a non-inline function or a non-`constexpr` variable in a header.
- A header must compile on its own. Enforce it with a test that includes each header alone.

## Namespaces

- Put everything in a project namespace. Nothing at global scope except `main`.
- Use a nested `detail` namespace for entities that are public only because the language
  requires it, and do not document them as interface.
- Never open namespace `std`, except to specialize a template the standard permits for a
  user-defined type.
- Put every entity local to a `.cpp` file in an anonymous namespace: helpers, constants,
  types. That removes the symbol from the object file, lets the compiler inline and delete
  freely, and prevents accidental linkage. `static` on a free function does the same for one
  function.
- Never use an unnamed namespace in a header. It produces a distinct entity per translation
  unit.
- Inline namespaces version an ABI. Use them deliberately, not for convenience.

## The one-definition rule

- An inline function, a template and a class must have the same definition in every
  translation unit that uses them.
- Different macros, flags, or standard version per translation unit produce two definitions.
  The linker keeps one silently and the program misbehaves.
- Build every translation unit of one binary with the same standard version, sanitizer
  settings and standard library.
- An entity with internal linkage in a header becomes one copy per translation unit. A
  `static` local inside an inline function is shared, which is usually what is wanted.

## Compile-time hygiene

- The physical dependency graph decides the rebuild cost. Break it with forward declarations,
  interface classes and the pimpl idiom.
- Pimpl removes the private members from the header at the cost of one indirection and one
  allocation. Declare the destructor in the header, define it in the source file.
- Precompiled headers and a compilation cache reduce the cost of what remains. Neither fixes a
  bad dependency graph.
- Measure before and after: total build time, and the rebuild cost of touching the most central
  header.
- Modules (C++20) fix this properly once the compiler, build system and IDE all support them.
- The full set of build-speed levers is in `compile-speed.md`.

## Library boundaries and ABI

- A shared library's ABI is a contract. Class layout, virtual table layout, inline function
  bodies, exception types and the standard library version all leak across it.
- Anything inline is baked into the caller, so changing it takes effect only after the caller
  is rebuilt.
- Export as little as possible and hide the rest with visibility settings. A smaller export
  table links faster and loads faster.
- Never expose standard library types across a boundary that must stay ABI-stable between
  compiler versions.
- Never let an exception cross a C ABI boundary. Catch and translate there.
- Version the ABI explicitly when it must stay stable, and record what a change breaks.

## Evolving a published interface

- Once an interface has users, changing it costs them. Decide early what is public and keep the
  rest in a `detail` namespace or out of the header.
- Add rather than change: a new overload, function or type. Removing or altering a signature
  breaks compilation. Altering behaviour behind an unchanged signature breaks silently, which
  is worse.
- Deprecate before removing. Mark with `[[deprecated("use X")]]`, keep it for a stated period,
  and remove it in a release that says so.
- Version what matters: a semantic version for the API, an explicit soname or inline namespace
  for the ABI. Record what a version bump promises.
- A default argument, an inline function body and a class layout are all part of what callers
  compiled against. Changing them requires rebuilding every consumer.
- Document the contract next to the declaration: ownership, preconditions, error strategy,
  thread safety, and complexity where it is part of the promise.
- Provide a migration note, and an automated fix where possible, when a change is unavoidable.

## Build system

- Declare dependencies per target with the correct visibility: interface requirements
  propagate to consumers, implementation requirements do not.
- Set the language standard as a target property, not a global flag, and let it propagate.
- Keep warnings, sanitizers and optimization settings in one place, and never let a
  subdirectory silently relax them.
- A generated file is a build artifact. Generate it into the build tree, never the source tree.
- Every dependency costs build time, adds attackable code and constrains versions. Check
  whether the standard library or an existing dependency already covers the need.
