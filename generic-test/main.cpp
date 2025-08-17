#include <iostream>

int main() {
    std::cout << "Hello from generic SLSA test!" << std::endl;
    std::cout << "This simulates a C++ project that could be:" << std::endl;
    std::cout << "- Rust: cargo build --release" << std::endl;
    std::cout << "- Java: mvn package" << std::endl;
    std::cout << "- C++: make" << std::endl;
    return 0;
}
