# SLSA Provenance Workflows

Professional GitHub Actions workflows for generating **SLSA Level 3 provenance** for artifacts and container images.

## 🎯 Overview

This repository provides **production-ready workflows** that generate authentic SLSA (Supply-chain Levels for Software Artifacts) provenance using the **official SLSA framework**:

### **✅ Universal Artifact Workflow**
- **Auto-detects** programming languages (Go, Python, Node.js, Rust, Java, C#, etc.)
- **Automatically installs** missing build tools
- **Generates SLSA Level 3 provenance** for any artifact type
- **Works universally** across all languages and frameworks

### **✅ Professional Container Workflow**
- **Verified working** with GitHub Container Registry and Docker Hub
- **Registry-specific authentication** with proven SLSA attestation upload
- **Universal credential patterns** for major container registries
- **Production-ready** reliability with diagnostic verification

## 🚀 Quick Start

### 1. Choose Your Workflow

**For Artifacts (binaries, packages, libraries):**
```bash
cp .github/workflows/artifact-slsa.yml your-repo/.github/workflows/
```

**For Container Images:**
```bash
cp .github/workflows/container-slsa.yml your-repo/.github/workflows/
```

### 2. Configure Secrets (Container Workflow Only)

For non-GitHub registries, add these secrets to your repository:
- `REGISTRY_USERNAME` - Your registry username
- `REGISTRY_PASSWORD` - Your registry password/token

### 3. Run the Workflow

**Artifact Workflow:**
- Automatically triggers on releases
- Or run manually via GitHub Actions UI

**Container Workflow:**
- Run manually via GitHub Actions UI
- Choose registry and image name

## 📚 Documentation

- **[WORKFLOWS.md](WORKFLOWS.md)** - Complete workflow documentation and configuration
- **[VERIFICATION.md](VERIFICATION.md)** - How to verify SLSA provenance with slsa-verifier

## 🌟 Key Features

### **Universal Compatibility**
- **Any programming language** - Go, Python, Node.js, Rust, Java, C#, etc.
- **Any artifact type** - Binaries, packages, libraries, executables
- **Major container registries** - GitHub Container Registry ✅, Docker Hub ✅, Google Container Registry, Amazon ECR, Azure Container Registry

### **Professional Quality**
- **Official SLSA framework** - Uses `slsa-framework/slsa-github-generator`
- **SLSA Level 3 compliance** - Highest level of supply chain security
- **Production-ready** - Reliable, validated, enterprise-grade

### **Developer Experience**
- **Zero configuration** for most use cases
- **Auto-detection** of build tools and languages
- **Clear error messages** and validation
- **Comprehensive documentation**

## 🔐 Security Benefits

✅ **Tamper-proof provenance** - Cryptographically signed build metadata
✅ **Supply chain transparency** - Complete build environment details
✅ **Verification capability** - Prove artifacts are built from expected source
✅ **Compliance ready** - Meets enterprise security requirements

## 🧪 Demo Package

This repository also includes **Zobra** - a simple Python package for demonstrating SLSA provenance:

```python
import zobra

# Create a file with package information
zobra.dump_file('demo.txt')

# Read the file
content = zobra.read_file('demo.txt')
print(content)  # Shows package version and build info
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes with the workflows
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Ready to secure your supply chain with SLSA Level 3 provenance? Start with our universal workflows!** 🔐✨
