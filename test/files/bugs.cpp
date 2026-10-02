#include <memory>
#include <utility>

int main() {
    long long big = 3000000000LL;
    int narrow = big;                             // narrowing conversion
    auto p = std::make_unique<int>(42);
    auto q = std::move(p);
    int deref = *p;                               // use-after-move: p is null, undefined behaviour
    int unused_var = 42;                          // unused variable
    return narrow + deref + *q;
}
