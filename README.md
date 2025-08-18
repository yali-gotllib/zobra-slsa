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
- **Verified working** with GitHub Container Registry, Docker Hub, and Google Container Registry
- **Registry-specific authentication** with proven SLSA attestation upload
- **Production-ready** reliability with diagnostic verification
- **Auto-generated verification commands** for easy SLSA provenance verification

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

**For Docker Hub:**
- `REGISTRY_USERNAME` - Your Docker Hub username
- `REGISTRY_PASSWORD` - Your Docker Hub password/token

**For Google Container Registry/Artifact Registry:**
- `GCR_SA_KEY` - Service account JSON key content

**For GitHub Container Registry:**
- No additional secrets needed (uses GITHUB_TOKEN)

### 3. Run the Workflow

**Artifact Workflow:**
- Automatically triggers on releases
- Or run manually via GitHub Actions UI

**Container Workflow:**
- Run manually via GitHub Actions UI
- Choose registry and image name

### 4. Verify SLSA Provenance

After your workflow completes successfully, verify the SLSA provenance to ensure supply chain security:

#### **For Container Images:**

1. **Get verification command from workflow logs:**
   ```bash
   # Go to: Workflow Run → "build" job → "Output image and digest" step
   # Copy the auto-generated command that looks like:
   slsa-verifier verify-image registry.com/username/app@sha256:digest \
     --source-uri github.com/username/repo \
     --source-branch main
   ```

2. **Install slsa-verifier:**
   ```bash
   go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest
   ```

3. **Run verification:**
   ```bash
   # Paste and run the command from step 1
   # Expected output: "PASSED: SLSA verification passed"
   ```

#### **For Artifacts:**

1. **Download artifacts from GitHub release:**
   ```bash
   gh release download v1.0.0 --repo your-org/your-repo
   ```

2. **Verify with slsa-verifier:**
   ```bash
   slsa-verifier verify-artifact your-artifact.tar.gz \
     --provenance-path your-artifact.tar.gz.intoto.jsonl \
     --source-uri github.com/your-org/your-repo \
     --source-tag v1.0.0
   ```

**For detailed verification instructions and troubleshooting, see [VERIFICATION.md](VERIFICATION.md).**

## 📚 Documentation

- **[WORKFLOWS.md](WORKFLOWS.md)** - Complete workflow documentation and configuration
- **[VERIFICATION.md](VERIFICATION.md)** - Detailed verification guide with examples and troubleshooting

## 🌟 Key Features

### **Universal Compatibility**
- **Any programming language** - Go, Python, Node.js, Rust, Java, C#, etc.
- **Any artifact type** - Binaries, packages, libraries, executables
- **Major container registries** - GitHub Container Registry ✅, Docker Hub ✅, Google Container Registry ✅

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
