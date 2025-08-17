# Generic SLSA Test Project

This is a test project to demonstrate the generic SLSA workflow with different build systems.

## Simulated Build Systems

### C++ (Current)
```bash
make all
```
Generates:
- `build/myapp` (executable)
- `build/libmylib.so` (shared library)

### Rust (Simulated)
```bash
cargo build --release
```
Would generate:
- `target/release/myapp` (executable)
- `target/release/libmylib.so` (shared library)

### Java (Simulated)
```bash
mvn package
```
Would generate:
- `target/myapp-1.0.0.jar` (executable JAR)
- `target/myapp-1.0.0-sources.jar` (source JAR)

## SLSA Workflow Testing

This project tests the generic SLSA workflow with:
- **Build Command**: `make all`
- **Artifact Pattern**: `build/*`
- **Expected SLSA Level**: 3
- **Verification**: Using official slsa-verifier
