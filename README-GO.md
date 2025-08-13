# Zobra Go - SLSA Demonstration Package

A simple Go package demonstrating **official SLSA Level 3 provenance** generation using the trusted SLSA Go builder.

## 🎯 Purpose

This package demonstrates:
- ✅ **Official SLSA Go builder** usage
- ✅ **Trusted provenance generation** 
- ✅ **slsa-verifier acceptance** (should show PASSED!)
- ✅ **Complete SLSA workflow** for Go packages

## 🚀 Usage

```bash
# Run the program
go run main.go

# Show version
go run main.go version

# Show package info  
go run main.go info

# Say hello
go run main.go hello SLSA
```

## 🔒 SLSA Implementation

This package uses the **official SLSA Go builder**:
- **Builder**: `slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@v1.10.0`
- **Status**: ✅ **Trusted** by slsa-verifier
- **Level**: SLSA Level 3
- **Format**: Official SLSA provenance

## 🛠️ Building with SLSA

### Trigger Build

```bash
# Create and push a tag
git tag go-v1.0.0
git push origin go-v1.0.0

# Or trigger manually
gh workflow run "Official Go SLSA Builder" --field tag=go-v1.0.0
```

### Verification

After the build completes:

```bash
# Download artifacts
gh release download go-v1.0.0 --repo yali-gotllib/zobra-slsa

# Verify with slsa-verifier (should show PASSED!)
slsa-verifier verify-artifact zobra-go_go-v1.0.0_linux_amd64.tar.gz \
  --provenance-path zobra-go_go-v1.0.0_linux_amd64.tar.gz.intoto.jsonl \
  --source-uri github.com/yali-gotllib/zobra-slsa \
  --source-tag go-v1.0.0
```

## 🆚 Comparison with Python

| Aspect | Python (zobra) | Go (zobra-go) |
|--------|----------------|---------------|
| **Builder** | Generic generator | Official Go builder |
| **Trusted** | ❌ No | ✅ Yes |
| **slsa-verifier** | FAILED (expected) | PASSED (expected) |
| **Provenance** | Valid SLSA | Valid SLSA |
| **Security** | High | High |

## 🎉 Expected Results

When using the official Go builder:
- ✅ **Build**: Successful compilation for multiple platforms
- ✅ **Provenance**: Official SLSA Level 3 attestation
- ✅ **Verification**: `slsa-verifier` shows **PASSED**
- ✅ **Trust**: Accepted by all SLSA tools

This demonstrates the difference between using official builders vs. generators!
