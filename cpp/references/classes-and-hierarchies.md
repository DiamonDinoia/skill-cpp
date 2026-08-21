# Classes, hierarchies and polymorphism

Load when designing a type, adding a virtual function, reviewing an inheritance tree, or
choosing between inheritance and an alternative.

## What kind of type is this

- A value type behaves like an `int`: copyable, comparable, no identity beyond its value. Most
  types should be value types.
- An entity type has identity and a lifetime. It is usually non-copyable and held by reference
  or by a smart pointer.
- A bundle of data with no invariant is a `struct` with public members and no member functions
  beyond construction. No getters and setters that only forward.
- An invariant-holding type keeps data private, establishes the invariant in every constructor,
  and preserves it in every public member function. State the invariant once, in a comment or a
  debug `assert`.
- Never blend the two. A class with public data and an invariant has no invariant.

## Prefer the simpler mechanism

Order of preference for varying behaviour:

1. A parameter or a function object, with no new type.
2. A template, when the set of types is known at compile time.
3. A closed set of alternatives: `std::variant` plus `std::visit` (C++17).
4. An abstract interface and virtual dispatch, when the set is open or crosses a plugin or ABI
   boundary.
5. Inheritance of implementation, as a last resort.

Prefer composition to inheritance. Inherit to model a substitutable interface, not to reuse
code. A member gives the reuse without the coupling.

## Constructors and invariants

- Establish the invariant in the constructor. A two-phase `init()` creates a window where the
  object is invalid and every method must check.
- Delegate between constructors instead of duplicating the body.
- Mark single-argument constructors `explicit`. `explicit(bool)` (C++20) makes the decision
  conditional in a template.
- Never call a virtual function from a constructor or a destructor. The dynamic type is not
  yet, or no longer, the derived one.
- A constructor that can fail throws, or a factory returns `optional` or `expected`. Never
  leave a "valid" flag for the caller to check.

## Virtual functions

- A base class destructor is either public and virtual, which allows deletion through the base,
  or protected and non-virtual, which forbids it.
- Mark every override `override`, and `final` when further overriding would break the design.
  Never repeat `virtual` on an override.
- An override must not change the default arguments or the accessibility. Both resolve
  statically and surprise the reader.
- Keep the virtual interface small. When the invariant must hold across overrides, use the
  non-virtual interface idiom: public non-virtual functions check the pre- and postconditions
  and call private virtual hooks.
- An abstract interface has no data members and no state.
- `dynamic_cast` in application code usually means the interface is missing a function. It is
  legitimate at a plugin or deserialization boundary.

## Slicing and copying

- Copying a derived object through a base value slices it. Prevent it by making the base
  abstract, by deleting its copy operations, or by holding derived objects only through
  pointers.
- A polymorphic type that must be copied provides a virtual `clone()` returning
  `std::unique_ptr<Base>`.

## Layout, size and access

- Order members to reduce padding when the type is stored in bulk: largest alignment first.
  Verify with a `static_assert` on `sizeof` when the layout is part of a contract.
- `alignas` for over-aligned types, taken from the property that requires it, never from a
  hardcoded literal.
- Prefer `private` by default, and `protected` only for a hook a derived class must reach.
- A `friend` is part of the interface. Prefer a hidden friend for a type's operators.
- Expose behaviour, not storage. No getter and setter for every member.
- Empty base optimization and `[[no_unique_address]]` (C++20) remove the cost of stateless
  policy members.

## Class templates

- Keep the non-dependent parts of a class template in a non-template base, so they instantiate
  once instead of per parameter.
- Prefer a member function template over a converting constructor set for related
  instantiations.
- A class template's static data member is one object per instantiation.

## Comparison and hashing

- In C++20, default `operator==` and `operator<=>` when member-wise semantics are right, and
  write them when they are not.
- Before C++20, define `==` and `<` and derive the rest, or compare the members with
  `std::tie`.
- A key type for an unordered container needs a `std::hash` specialization consistent with its
  equality. Equal objects must hash equally.
- Comparison must be a strict weak ordering. A comparator that returns true for equal elements
  corrupts a sort and is undefined behaviour.
