# Memory: hierarchy, layout and allocators

Load when the work is allocation, custom allocators, cache behaviour, data layout, alignment,
or memory footprint.

## The hierarchy decides the speed

- A register access, an L1 hit, an L3 hit and a main-memory access differ by orders of
  magnitude. Most "slow code" waits for memory instead of computing.
- The unit of transfer is the cache line, not the byte. Touching one byte pulls the whole line,
  and touching every 64th byte wastes the entire bandwidth.
- Hardware prefetchers follow linear forward and backward strides. A pointer chase defeats
  them, an indexed array does not.
- Virtual memory adds page-table lookups. A large working set thrashes the TLB even when the
  data is in cache. Huge pages help when the footprint is large and the access is scattered.
- So shrink the working set, access it in order, and keep the fields used together next to each
  other. That ordering beats any instruction-level change.

## Layout

- Array of structures when a loop touches most fields of one element. Structure of arrays when
  a loop touches one field of many elements, which also gives the vectorizer contiguous lanes.
- Split hot fields from cold fields. A rarely used debug string inside a hot record costs a
  cache line on every iteration.
- Order members by decreasing alignment to remove padding. Check with a `static_assert` on
  `sizeof` when the size matters.
- Prefer indices to pointers in a large structure. A 32-bit index is half the size of a pointer
  and survives reallocation.
- Prefer a flat contiguous container to a node-based one. A `std::map` traversal is a pointer
  chase with an allocation per node, while a sorted `std::vector` or a flat map is one stream.
- Padding to a cache line prevents false sharing between threads and wastes memory everywhere
  else. Apply it only to the shared, contended object.

## Stack, heap and lifetime

- Stack allocation is a pointer bump and always beats the heap. Prefer automatic storage, and
  prefer a small fixed buffer to a heap allocation on a hot path.
- The stack is small and its exhaustion is undefined behaviour, so bound any stack buffer at
  compile time and never size it from untrusted input.
- Heap allocation is a synchronized, variable-cost operation. Count allocations before
  optimizing arithmetic, because the allocation is usually the cost.
- Hoist allocations out of loops, reuse buffers across iterations, and `reserve` to a known
  size.
- Small-object and small-string optimizations keep short values inline. Wrapping a small value
  in a pointer defeats them.
- Alignment comes from the requirement, never a hardcoded literal: the vector width, the
  atomic, the hardware. Over-aligned types need the aligned allocation forms.

## Allocators

- Reach for a custom allocator only after the profile shows allocation cost or fragmentation.
  The default allocator is good.
- The useful shapes, in order of how often they pay off:
  - Arena, or bump allocator: allocate from a block, free everything at once. Ideal for a phase
    with a known end.
  - Pool, or free list: fixed-size blocks for many same-sized objects. Removes size-class
    search and fragmentation.
  - Stack allocator: strictly nested lifetimes, released in reverse order.
  - Per-thread arena: removes the allocator's synchronization from a parallel loop.
- `std::pmr` (C++17) is the standard plumbing: `monotonic_buffer_resource` over a stack or
  static buffer, `unsynchronized_pool_resource` for pools, and `std::pmr::vector` and friends
  carrying the resource at run time instead of in the type. A polymorphic resource costs one
  indirection per allocation and keeps the container type stable.
- A classic `Allocator` template parameter changes the container's type, which spreads through
  every signature. Prefer `pmr` unless the indirection is measured to matter.
- An allocator must be stateless-comparable or carry propagation traits correctly. Getting
  those wrong produces containers that free with the wrong resource.
- Whatever the allocator, keep the ownership model unchanged. The container still owns, and the
  resource must outlive every container using it.

## Measuring memory

- Count allocations and peak footprint, not only time. Instrument the allocator or use a heap
  profiler, and treat allocations per operation as a first-class metric.
- Cache misses, TLB misses and bandwidth are hardware counters. Read them before rewriting a
  loop for locality, because a miss-free loop will not improve from better layout.
- A microbenchmark with a warm, small working set hides every memory effect the production path
  has. Size the benchmark's data to the real workload.
- Memory savings that push the working set below a cache level produce a step change in time.
  Report both numbers.
