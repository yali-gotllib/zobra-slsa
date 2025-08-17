# SLSA Workflows Documentation

Complete documentation for the Universal Artifact and Professional Container SLSA workflows.

## 🔧 Universal Artifact Workflow

**File:** `.github/workflows/artifact-slsa.yml`

### **Purpose**
Generates SLSA Level 3 provenance for any artifact type (binaries, packages, libraries) with automatic language detection and build tool installation.

### **Supported Languages**
- **Go** - Detects `go.mod`, runs `go build`
- **Python** - Detects `pyproject.toml`/`setup.py`, runs `python -m build`
- **Node.js** - Detects `package.json`, runs `npm run build` or `npm pack`
- **Rust** - Detects `Cargo.toml`, runs `cargo build --release`
- **Java** - Detects `pom.xml`/`build.gradle`, runs Maven/Gradle
- **C#** - Detects `.csproj`/`.sln`, runs `dotnet build`
- **Generic** - Custom build commands for any language

### **Configuration**

#### **Automatic Mode (Recommended)**
```yaml
# Triggers automatically on releases
# No configuration needed - auto-detects everything
```

#### **Manual Mode**
```yaml
# Run via GitHub Actions UI with custom parameters:
# - build_command: Custom build command (optional)
# - artifact_path: Path to built artifacts (optional)
```

### **How It Works**
1. **Language Detection** - Scans for project files (`go.mod`, `package.json`, etc.)
2. **Tool Installation** - Automatically installs missing build tools
3. **Build Execution** - Runs appropriate build commands
4. **Artifact Collection** - Gathers built artifacts
5. **Provenance Generation** - Creates SLSA Level 3 attestation

### **Example Usage**
```bash
# Copy to your repository
cp .github/workflows/artifact-slsa.yml your-repo/.github/workflows/

# Create a release to trigger automatic SLSA generation
git tag v1.0.0
git push origin v1.0.0
```

## 🐳 Professional Container Workflow

**File:** `.github/workflows/container-slsa.yml`

### **Purpose**
Generates SLSA Level 3 provenance for container images with support for major container registries.

### **Supported Registries**

#### **Tier 1: Full SLSA Support (Verified Working)**
- **GitHub Container Registry (ghcr.io)** - Native GitHub integration, works out-of-the-box
- **Docker Hub (docker.io)** - ✅ **CONFIRMED WORKING** with `compile-generator: true` parameter
- **Google Container Registry (gcr.io)** - Google Cloud Platform, uses same pattern as Docker Hub

#### **Tier 2: Cloud Provider Registries (Expected to Work)**
- **Amazon ECR** - AWS container registry, uses universal credential pattern
- **Azure Container Registry** - Microsoft Azure registry, uses universal credential pattern

### **Configuration**

#### **Secrets Setup**
For non-GitHub registries, configure these repository secrets:

```bash
# Required for docker.io, gcr.io, ECR, ACR
REGISTRY_USERNAME=your-username
REGISTRY_PASSWORD=your-password-or-token
```

#### **Registry-Specific Examples**

**Docker Hub:**
```yaml
registry: docker.io
image_name: username/myapp
# Secrets: REGISTRY_USERNAME, REGISTRY_PASSWORD
# Note: Uses compile-generator: true for proper attestation upload
```

**Google Container Registry:**
```yaml
registry: gcr.io
image_name: project-id/myapp
# Secrets: REGISTRY_USERNAME=_json_key, REGISTRY_PASSWORD=<service-account-json>
```

**Amazon ECR:**
```yaml
registry: 123456789012.dkr.ecr.us-west-2.amazonaws.com
image_name: myapp
# Secrets: REGISTRY_USERNAME=AWS, REGISTRY_PASSWORD=<ecr-token>
```

**Azure Container Registry:**
```yaml
registry: myregistry.azurecr.io
image_name: myapp
# Secrets: REGISTRY_USERNAME, REGISTRY_PASSWORD
```

### **Workflow Inputs**
- **registry** - Container registry URL (dropdown selection)
- **image_name** - Full image name (e.g., `username/myapp`)
- **tag** - Image tag (default: `container-v1.0.0`)
- **dockerfile_path** - Path to Dockerfile (default: `./Dockerfile`)
- **build_context** - Docker build context (default: `.`)

### **How It Works**
1. **Registry Validation** - Ensures registry is supported
2. **Authentication** - Registry-specific credential handling
3. **Container Build** - Builds and pushes container image
4. **Provenance Generation** - Creates SLSA Level 3 attestation with `compile-generator: true` for non-GitHub registries
5. **Attestation Upload** - Uploads provenance to registry (verified working for Docker Hub)
6. **Diagnostic Check** - Verifies attestation was successfully uploaded

### **Example Usage**
```bash
# Copy to your repository
cp .github/workflows/container-slsa.yml your-repo/.github/workflows/

# Configure secrets (for non-GitHub registries)
gh secret set REGISTRY_USERNAME --body "your-username"
gh secret set REGISTRY_PASSWORD --body "your-password"

# Run manually via GitHub Actions UI
# Choose registry and image name
```

## 🔐 Security Features

### **SLSA Level 3 Compliance**
Both workflows generate **SLSA Level 3** provenance with:
- **Build isolation** - Runs in ephemeral GitHub-hosted runners
- **Provenance authenticity** - Cryptographically signed attestations
- **Non-falsifiable** - Immutable build metadata
- **Comprehensive** - Complete build environment details

### **Verification Capability**
All generated provenance can be verified using:
- **slsa-verifier** - Official SLSA verification tool
- **GitHub CLI** - For GitHub-hosted artifacts
- **Cosign** - For container image attestations

### **Transparency**
- **Public transparency logs** - All attestations recorded in Rekor
- **Audit trail** - Complete build process documentation
- **Source verification** - Links artifacts to source repository

## 🛠️ Advanced Configuration

### **Custom Build Commands**
For the artifact workflow, you can specify custom build commands:

```yaml
# Manual trigger with custom build
build_command: "make release"
artifact_path: "dist/*"
```

### **Multi-Architecture Containers**
The container workflow supports multi-architecture builds:

```yaml
# Dockerfile with multi-arch support
FROM --platform=$BUILDPLATFORM golang:1.21 AS builder
# ... build steps ...
```

### **Private Repositories**
Both workflows work with private repositories:
- **Automatic detection** - Workflows detect repository visibility
- **Appropriate permissions** - Uses correct token scopes
- **Private attestations** - Respects repository privacy settings

## 📋 Troubleshooting

### **Common Issues**

#### **Artifact Workflow**
- **Build tool not found** - Workflow auto-installs, but check build logs
- **No artifacts found** - Verify artifact_path pattern
- **Permission denied** - Ensure workflow has necessary permissions

#### **Container Workflow**
- **Registry authentication failed** - Check REGISTRY_USERNAME/REGISTRY_PASSWORD secrets
- **Image push failed** - Verify registry URL and permissions
- **Attestation upload failed** - Ensure registry supports attestations

### **Debug Steps**
1. **Check workflow logs** - Look for specific error messages
2. **Verify secrets** - Ensure credentials are correctly configured
3. **Test locally** - Try build commands locally first
4. **Check permissions** - Verify repository and registry permissions

## 🔄 Workflow Updates

### **Keeping Workflows Current**
- **Monitor releases** - Watch for SLSA generator updates
- **Test changes** - Validate in development repositories first
- **Update references** - Keep workflow versions current

### **Version Pinning**
Both workflows use pinned versions for security:
```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
```

Update these references when new versions are released.

---

**For verification instructions, see [VERIFICATION.md](VERIFICATION.md)**
