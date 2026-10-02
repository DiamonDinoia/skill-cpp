#include <string>
#include <utility>

int main() {
    long long big = 3000000000LL;
    int narrow = big;                             // narrowing conversion
    std::string s = "hello";
    std::string t = std::move(s);
    int len = static_cast<int>(s.size());         // use-after-move: reads moved-from s
    int unused_var = 42;                          // unused variable
    return narrow + len;
}
