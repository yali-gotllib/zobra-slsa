# Generic SLSA Provenance Workflow

A comprehensive, language-agnostic GitHub Actions workflow that generates SLSA Level 3 provenance for any artifact type and provides verification using the official `slsa-verifier` tool.

## 🎯 Overview

This implementation provides a **single, universal workflow** that can:

- **Auto-detect** project types (Go, Python, Node.js, or generic)
- **Generate SLSA Level 3 provenance** using the official SLSA generator
- **Support any artifact type** with custom build commands
- **Verify provenance** using the official `slsa-verifier` tool
- **Work consistently** across all programming languages and frameworks

## 🚀 Quick Start

### 1. Add the Workflow

Copy [`generic-slsa.yml`](.github/workflows/generic-slsa.yml) to your repository's `.github/workflows/` directory.

### 2. Generate Provenance

```bash
# Automatic detection and build
git tag v1.0.0
git push origin v1.0.0
```

### 3. Verify Provenance

```bash
# Install slsa-verifier
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest

# Verify artifacts
./verify_generic_slsa.sh -r owner/repo -t v1.0.0
```

## 📁 Files Included

| File | Purpose |
|------|---------|
| [`.github/workflows/generic-slsa.yml`](.github/workflows/generic-slsa.yml) | Main workflow file - handles all artifact types |
| [`verify_generic_slsa.sh`](verify_generic_slsa.sh) | Verification script using slsa-verifier |
| [`GENERIC_SLSA_GUIDE.md`](GENERIC_SLSA_GUIDE.md) | Complete usage guide and documentation |
| [`EXAMPLE_USAGE.md`](EXAMPLE_USAGE.md) | Practical examples and troubleshooting |
| [`SLSA_REQUIREMENTS.md`](SLSA_REQUIREMENTS.md) | SLSA implementation requirements |

## 🔍 Supported Project Types

### Automatic Detection

The workflow automatically detects your project type:

| Project Type | Detection | Build Output |
|--------------|-----------|--------------|
| **Go** | `go.mod` present | Cross-platform binaries |
| **Python** | `pyproject.toml`, `setup.py`, or `setup.cfg` | Wheel and source distribution |
| **Node.js** | `package.json` present | NPM package (`.tgz`) |
| **Generic** | No specific files found | Custom build commands |

### Manual Override

You can override auto-detection using workflow dispatch parameters:

- **Artifact Type**: `auto`, `go`, `python`, `nodejs`, `generic`
- **Build Command**: Custom build command (for generic type)
- **Artifact Pattern**: Pattern to match artifacts (for generic type)

## 🛡️ Security Features

### SLSA Level 3 Compliance

✅ **Non-forgeable Provenance**: Uses official SLSA generator v2.1.0  
✅ **Ephemeral Environment**: Fresh GitHub Actions runners  
✅ **Cryptographic Verification**: Sigstore-based signatures  
✅ **Transparency**: Public transparency log recording  

### Provenance Contents

Each provenance file contains:
- Builder identity (SLSA generator)
- Source repository and commit
- Build environment and parameters
- Artifact hashes (SHA256)
- Cryptographic signature

## 📊 Workflow Architecture

```mermaid
graph TD
    A[Push Tag] --> B[Detect Project Type]
    B --> C{Project Type?}
    C -->|Go| D[Setup Go + Build Binaries]
    C -->|Python| E[Setup Python + Build Package]
    C -->|Node.js| F[Setup Node + Build Package]
    C -->|Generic| G[Custom Build Commands]
    D --> H[Generate Hashes]
    E --> H
    F --> H
    G --> H
    H --> I[SLSA Generator v2.1.0]
    I --> J[Sign Provenance]
    J --> K[Upload Artifacts + Provenance]
    K --> L[Verification with slsa-verifier]
```

## 🧪 Testing with Zobra Packages

This repository includes two test packages:

### Go Package (`zobra-go`)
- **Source**: [`main.go`](main.go)
- **Build**: Cross-platform binaries (Linux, macOS, Windows)
- **Trigger**: `git tag go-v1.0.0`

### Python Package (`zobra`)
- **Source**: [`zobra/`](zobra/) directory
- **Build**: Wheel and source distribution
- **Trigger**: `git tag py-v1.0.0`

## 📖 Usage Examples

### Basic Usage

```bash
# Auto-detect and verify
./verify_generic_slsa.sh -r owner/repo -t v1.0.0

# Specify artifact type
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -a python

# Verify existing files
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -v \
  -p ./artifact.whl -s ./provenance.intoto.jsonl
```

### Advanced Configuration

```yaml
# Manual workflow dispatch for Rust project
artifact_type: generic
build_command: "cargo build --release"
artifact_pattern: "target/release/myapp*"
```

### CI/CD Integration

```yaml
- name: Verify SLSA Provenance
  run: |
    ./verify_generic_slsa.sh -r ${{ github.repository }} -t ${{ github.ref_name }}
```

## 🔧 Prerequisites

### For Generation (GitHub Actions)
- Repository with the workflow file
- Appropriate permissions (actions: read, id-token: write, contents: write)

### For Verification (Local)
- [`slsa-verifier`](https://github.com/slsa-framework/slsa-verifier): `go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest`
- [GitHub CLI](https://cli.github.com/): For downloading artifacts

## 🆚 Comparison with Language-Specific Workflows

| Feature | Generic Workflow | Language-Specific |
|---------|------------------|-------------------|
| **Languages Supported** | All | Single language |
| **Maintenance** | Single workflow | Multiple workflows |
| **Consistency** | Same process for all | Different per language |
| **Flexibility** | High (custom builds) | Limited to language |
| **Security Level** | SLSA Level 3 | SLSA Level 3 |
| **Verification** | Universal tool | Universal tool |

## 🚨 Migration from Existing Workflows

### Step 1: Backup Existing Workflows
```bash
cp .github/workflows/go-slsa.yml .github/workflows/go-slsa.yml.backup
cp .github/workflows/python-slsa.yml .github/workflows/python-slsa.yml.backup
```

### Step 2: Add Generic Workflow
```bash
cp generic-slsa.yml .github/workflows/
```

### Step 3: Test with New Tags
```bash
git tag generic-v1.0.0
git push origin generic-v1.0.0
```

### Step 4: Verify Results
```bash
./verify_generic_slsa.sh -r owner/repo -t generic-v1.0.0
```

### Step 5: Remove Old Workflows (Optional)
```bash
rm .github/workflows/go-slsa.yml
rm .github/workflows/python-slsa.yml
```

## 📚 Documentation

- **[Complete Guide](GENERIC_SLSA_GUIDE.md)**: Detailed usage instructions
- **[Examples](EXAMPLE_USAGE.md)**: Practical examples and troubleshooting
- **[Requirements](SLSA_REQUIREMENTS.md)**: SLSA implementation details
- **[SLSA Framework](https://slsa.dev/)**: Official SLSA documentation

## 🤝 Contributing

1. Test the workflow with your project type
2. Report issues or suggest improvements
3. Share your custom build configurations
4. Help improve documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [SLSA Framework](https://slsa.dev/) for supply chain security standards
- [SLSA GitHub Generator](https://github.com/slsa-framework/slsa-github-generator) for the official generator
- [slsa-verifier](https://github.com/slsa-framework/slsa-verifier) for verification tools
- GitHub Actions for the CI/CD platform

---

**🎯 Ready to secure your supply chain?** Start with the [Quick Start](#-quick-start) guide above!
