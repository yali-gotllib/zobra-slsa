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

**Docker Hub:**
```bash
REGISTRY_USERNAME=your-docker-username
REGISTRY_PASSWORD=your-docker-password-or-token
```

**Google Container Registry (GCR) or Google Artifact Registry (GAR):**
```bash
GCR_SA_KEY=<service-account-json-content>
```

**Other Registries (ECR, ACR, etc.):**
```bash
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
# Secrets: GCR_SA_KEY=<service-account-json>
# Note: Uses _json_key authentication with service account
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
7. **Verification Output** - Provides ready-to-use verification command in build logs

### **Example Usage**

#### **Docker Hub Setup:**
```bash
# Copy workflow to your repository
cp .github/workflows/container-slsa.yml your-repo/.github/workflows/

# Configure Docker Hub secrets
gh secret set REGISTRY_USERNAME --body "your-docker-username"
gh secret set REGISTRY_PASSWORD --body "your-docker-password"

# Run manually via GitHub Actions UI
# Choose 'docker.io' registry and your image name
```

#### **Google Container Registry Setup:**
```bash
# 1. Create service account with minimal permissions
gcloud iam service-accounts create slsa-container-builder \
  --description="SLSA container provenance builder" \
  --display-name="SLSA Container Builder"

# 2. Grant minimal required permissions
PROJECT_ID="your-project-id"
SA_EMAIL="slsa-container-builder@${PROJECT_ID}.iam.gserviceaccount.com"

# For Google Container Registry (gcr.io)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

# For Google Artifact Registry (GAR) - use this instead of storage.admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer"

# 3. Create and download service account key
gcloud iam service-accounts keys create sa-key.json \
  --iam-account="${SA_EMAIL}"

# 4. Add service account key to GitHub secrets
gh secret set GCR_SA_KEY --body "$(cat sa-key.json)"

# 5. Clean up local key file
rm sa-key.json

# Run manually via GitHub Actions UI
# Choose 'gcr.io' registry and image name like 'your-project-id/your-app'
```

### **Verifying SLSA Provenance After Workflow Completion**

After the workflow completes successfully, you can verify the SLSA provenance:

#### **Step 1: Get Verification Command from Workflow Logs**
1. Go to your completed workflow run in GitHub Actions
2. Click on the **"build"** job
3. Look for the **"Output image and digest"** step
4. Copy the verification command that looks like:
```bash
🔍 VERIFICATION COMMAND:
slsa-verifier verify-image registry.com/username/app@sha256:abc123... \
  --source-uri github.com/username/repo \
  --source-branch main
```

#### **Step 2: Install slsa-verifier**
```bash
# Install the official SLSA verification tool
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest
```

#### **Step 3: Run Verification**
```bash
# Use the exact command from the workflow logs
slsa-verifier verify-image your-registry.com/username/app@sha256:digest \
  --source-uri github.com/username/repo \
  --source-branch main
```

#### **Expected Success Output:**
```
✓ Verified signature against tlog entry index XXXXXXX
✓ Verified build using builder "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v2.1.0"
✓ Verified container image built from "github.com/username/repo@refs/heads/main"

PASSED: SLSA verification passed
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

## 🔐 Google Cloud Permissions

### **Minimal Required Permissions**

#### **For Google Container Registry (gcr.io):**
- **`roles/storage.admin`** - Required for pushing images and attestations to GCS buckets that back GCR

#### **For Google Artifact Registry (GAR):**
- **`roles/artifactregistry.writer`** - More granular permission for GAR repositories
- **Alternative**: `roles/artifactregistry.repoAdmin` for full repository management

### **Permission Comparison:**
```bash
# Option 1: Google Container Registry (gcr.io) - Legacy
roles/storage.admin
  - storage.buckets.get
  - storage.objects.create
  - storage.objects.delete
  - storage.objects.get
  - storage.objects.list

# Option 2: Google Artifact Registry (GAR) - Recommended
roles/artifactregistry.writer
  - artifactregistry.repositories.downloadArtifacts
  - artifactregistry.repositories.uploadArtifacts
  - artifactregistry.repositories.get
  - artifactregistry.repositories.list
```

### **Security Best Practices:**
- **Use GAR over GCR** - More granular permissions and better security
- **Limit service account scope** - Only grant permissions to specific repositories if possible
- **Rotate service account keys** - Regularly rotate keys for security
- **Use Workload Identity** - Consider Workload Identity Federation for keyless authentication (advanced)

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
