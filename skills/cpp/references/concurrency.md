# Concurrency and parallelism

Load when writing or reviewing threads, atomics, locks, parallel loops, or data shared
between threads.

## Design first

- Prefer no sharing. Give each thread its own data and combine at the end: a partitioned
  computation needs no lock.
- Prefer immutable shared data. A `const` object shared between threads needs no
  synchronization, provided nothing casts the `const` away.
- Prefer a task-based interface to raw threads: a thread pool, `std::async`, a parallel
  algorithm. Raw threads are the assembly language of concurrency.
- Prefer message passing to shared mutable state where the structure allows it.
- Decide the model once, at module level. Mutexes sprinkled onto a sequential design give both
  bugs and poor scaling.

## The hard rules

- A data race is undefined behaviour, not a rare wrong value. Two accesses to one memory
  location from different threads, at least one a write, need a mutex, an atomic, or an
  ordering that makes them not concurrent.
- `volatile` is not atomic and gives no ordering. It is for memory-mapped hardware.
- `const` is not thread-safe. It means "does not modify the observable state", and a `const`
  member with a cache needs a mutex.
- `mutable` marks members that synchronization owns, such as the mutex itself; any other
  mutable member shared between threads is a smell.
- A "benign" race does not exist in the standard's model.

## Locks

- Always a scoped lock: `std::lock_guard`, `std::unique_lock`, `std::shared_lock`,
  `std::scoped_lock`. Never a bare `lock()`/`unlock()` pair.
- Name the guard. An unnamed temporary releases immediately.
- Take multiple locks with one `std::scoped_lock`, or in one documented global order.
  Inconsistent order is the classic deadlock.
- Keep the critical section short, and free of blocking calls, user code and callbacks.
- Group shared data with its mutex in one struct; the partitioning of what the lock protects
  stays visible to the reader.
- A spinlock is for a short, rarely contended section or a microsecond handoff on a dedicated
  core; elsewhere a sleeping mutex wins, and an idle worker sleeps on a condition variable
  instead of busy-waiting.
- Never wait on a condition variable without a predicate. Spurious wakeups are permitted.
- `std::recursive_mutex` usually means the public and private layers are not separated. Split
  them.
- `std::shared_mutex` pays off only when reads dominate and the critical sections amortize the
  more expensive lock.

## Atomics and memory order

- Default to `std::atomic<T>` with sequential consistency. It is correct, and readers can
  reason about it.
- A `std::atomic<T>` on a large type compiles but locks. Gate a hot-path atomic with
  `static_assert(std::atomic<T>::is_always_lock_free)`. Two atomics are not one: a check over
  separately loaded atomics races. Never `memory_order_consume`.
- Use acquire/release only with a written argument for why it suffices, and pair every release
  with the acquire that reads it.
- Relaxed ordering is for counters nobody uses to guard data: statistics, reference-count
  increments. Never for a flag that publishes data.
- Prefer `fetch_add`, `compare_exchange_weak` in a loop, and `std::atomic_ref` (C++20) for
  atomic access to an object that is not always shared.
- Lock-free is not automatically faster. A contended atomic serializes cache lines just as a
  lock does. Measure.
- When lock-free is the measured choice: design the data structure, not the algorithm; every
  reachable state must be valid, publish with CAS retry, reclaim safely. Never bolt a lock
  onto a lock-free structure - it downgrades the progress guarantee. Review and years of use
  do not vindicate lock-free code against the memory model.
- Read-mostly shared data fits RCU or a COW-plus-RCU / Left-Right pattern: wait-free reads,
  blocking writes, about twice the memory. Never block in a read-side critical section, never
  span a coroutine suspension point in one, wait a grace period after unlinking before
  freeing, and express the read-side with a scoped lock in a local scope.
- False sharing between unrelated atomics on one cache line destroys scaling. Separate them by
  the destructive interference size.

## Threads and tasks

- `std::jthread` (C++20) is the default: it joins on destruction and carries a stop token.
- A `std::thread` neither joined nor detached terminates the program. A detached thread must
  not reference anything shorter-lived than the program.
- `std::async` with the default policy may run synchronously, so pass `std::launch::async`
  when a thread is required. The returned future blocks in its destructor.
- Propagate exceptions across threads through the future, or catch and translate at the thread
  boundary. An escaping exception terminates.
- Coordinate with `std::latch`, `std::barrier` and `std::counting_semaphore` (C++20) instead
  of hand-rolled condition variable protocols.
- Never create a thread per work item. Size the pool from the hardware and the workload, and
  respect any external limit on the machine.
- Partition work by urgency: nothing slow on responsive threads, a dedicated thread for
  long-running tasks, a pool for everything else.

## Parallel algorithms

- The standard algorithms take an execution policy (C++17): `seq`, `unseq`, `par`,
  `par_unseq`. Adding `par` to a correct call is the cheapest parallelism available.
- The policy is a permission, not a promise. An implementation may run sequentially, and some
  need a linked backend.
- `par` requires race-free element operations. `par_unseq` also forbids synchronization in the
  body, locks and allocation included, because calls may interleave within a thread.
- Element access functions must not throw: an escaping exception terminates. Temporary
  storage may throw `bad_alloc`, so leave budget for it.
- `std::reduce` and `std::transform_reduce` parallelize where `std::accumulate` cannot. They
  require an associative, commutative operation, which reorders floating-point summation and
  changes the last digits.
- An index-based parallel loop suits work that varies per element. A naive equal split leaves
  threads idle.
- Parallelism has a fixed startup cost. Below a threshold the sequential version wins. Measure
  the crossover and branch on it.

## Coroutines for asynchrony

- `co_await` turns a chain of asynchronous operations into sequential code and removes nested
  callbacks and their state.
- The standard library provides the mechanism, not the execution context. The project supplies
  an event loop, thread pool or executor, and commits to one.
- A coroutine frame allocates unless elided, and each suspension is a scheduling decision. Use
  coroutines for I/O-bound and latency-bound work, not inside a hot numeric loop.
- A coroutine capturing a reference to a caller's temporary dangles. The frame outlives the
  expression that created it.
- Never make a blocking call in a coroutine on a cooperative scheduler: it starves every
  other task. Hold no lock and no thread-affine state across a suspension point; the
  resumption may be on a different thread.
- Generators and lazy sequences are in `lazy-evaluation-and-proxies.md`.

## Parallel loops and scaling

- Parallelize the outer loop, keep the inner loop vectorizable, give each thread a contiguous
  chunk.
- Measure the sequential baseline, then the scaling curve. A parallel version slower at low
  thread counts usually shares a cache line or allocates inside the loop.
- Parallel reductions change the summation order, so the result differs from the sequential
  one. Fix the test tolerance to the algorithm's error bound.
- Allocation inside a parallel region serializes on the allocator. Hoist it, or use per-thread
  buffers.

## Testing

- The thread sanitizer finds races that reviews and tests do not. Run it in CI on the
  concurrent tests.
- A concurrency test that passes once proves nothing. Run it repeatedly, under load, with the
  sanitizer.
- Prefer a deterministic test of the protocol to a timing-based one: a fake scheduler, an
  injected ordering.
