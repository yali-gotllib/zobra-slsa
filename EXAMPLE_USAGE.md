# Generic SLSA Workflow - Example Usage

This document provides practical examples of using the generic SLSA workflow with the Zobra packages.

## Quick Demo

### 1. Setup

First, ensure you have the required tools:

```bash
# Install slsa-verifier (required for verification)
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest

# Install GitHub CLI (required for downloading artifacts)
# Visit: https://cli.github.com/
```

### 2. Trigger SLSA Provenance Generation

#### Option A: Automatic (Tag-based)

```bash
# For Go project (auto-detected by go.mod)
git tag go-v1.0.0
git push origin go-v1.0.0

# For Python project (auto-detected by pyproject.toml)
git tag py-v1.0.0  
git push origin py-v1.0.0

# Generic version tag (auto-detects project type)
git tag v1.0.0
git push origin v1.0.0
```

#### Option B: Manual Workflow Dispatch

1. Go to your repository's Actions tab
2. Select "Generic SLSA Provenance" workflow
3. Click "Run workflow"
4. Configure:
   - **Artifact Type**: `auto` (or specify `go`, `python`, `nodejs`, `generic`)
   - **Tag**: `v1.0.0`
   - **Build Command**: (only for generic type)
   - **Artifact Pattern**: (only for generic type)

### 3. Verify SLSA Provenance

#### Basic Verification

```bash
# Auto-detect project type and verify
./verify_generic_slsa.sh -r owner/repo -t v1.0.0

# Specify artifact type explicitly
./verify_generic_slsa.sh -r owner/repo -t go-v1.0.0 -a go
./verify_generic_slsa.sh -r owner/repo -t py-v1.0.0 -a python
```

#### Advanced Verification

```bash
# Use custom source branch
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -b develop

# Verify without downloading (use existing files)
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -n

# Verify specific files only
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -v \
  -p ./my-artifact.bin -s ./provenance.intoto.jsonl
```

## Example Outputs

### Successful Go Build

```
🔐 Generic SLSA Provenance Verification
==================================================
ℹ️  Repository: owner/repo
ℹ️  Tag: go-v1.0.0
ℹ️  Artifact Type: go
ℹ️  Source Branch: main

ℹ️  Checking prerequisites...
✅ slsa-verifier found: slsa-verifier version v2.7.1
✅ GitHub CLI found: gh version 2.32.1

🐍 Detected Go project (go.mod found)
✅ Using artifact type: go

📥 Downloading artifacts from GitHub Actions...
ℹ️  Finding workflow run for tag go-v1.0.0...
✅ Found workflow run ID: 12345 (workflow: generic-slsa.yml)
✅ Artifacts downloaded successfully

✅ Found 3 artifact file(s):
./zobra-go-linux-amd64
./zobra-go-darwin-amd64  
./zobra-go-windows-amd64.exe

🔐 SLSA Verification Results
==================================================

ℹ️  Verifying artifact: zobra-go-linux-amd64
ℹ️  Running: slsa-verifier verify-artifact "zobra-go-linux-amd64" --provenance-path "generic-slsa-provenance-go.intoto.jsonl" --source-uri github.com/owner/repo --source-tag "go-v1.0.0"

Verified build using builder "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0"
Verifying artifact zobra-go-linux-amd64: PASSED
PASSED: SLSA verification passed

✅ ✅ VERIFICATION PASSED for zobra-go-linux-amd64

🔐 Verification Summary
==================================================
ℹ️  Repository: github.com/owner/repo
ℹ️  Tag: go-v1.0.0
ℹ️  Artifact Type: go
ℹ️  Total Artifacts: 3
ℹ️  Successful Verifications: 3
✅ 🎉 ALL VERIFICATIONS PASSED!
✅ Supply chain integrity verified for all artifacts
```

### Successful Python Build

```
🔐 Generic SLSA Provenance Verification
==================================================
ℹ️  Repository: owner/repo
ℹ️  Tag: py-v1.0.0
ℹ️  Artifact Type: python

🐍 Detected Python project (pyproject.toml found)
✅ Using artifact type: python

📥 Downloading artifacts from GitHub Actions...
✅ Found workflow run ID: 12346 (workflow: generic-slsa.yml)
✅ Artifacts downloaded successfully

✅ Found 2 artifact file(s):
./dist/zobra-1.0.0-py3-none-any.whl
./dist/zobra-1.0.0.tar.gz

🔐 SLSA Verification Results
==================================================

ℹ️  Verifying artifact: zobra-1.0.0-py3-none-any.whl
Verified build using builder "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0"
Verifying artifact zobra-1.0.0-py3-none-any.whl: PASSED
PASSED: SLSA verification passed

✅ ✅ VERIFICATION PASSED for zobra-1.0.0-py3-none-any.whl

ℹ️  Verifying artifact: zobra-1.0.0.tar.gz
Verified build using builder "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0"
Verifying artifact zobra-1.0.0.tar.gz: PASSED
PASSED: SLSA verification passed

✅ ✅ VERIFICATION PASSED for zobra-1.0.0.tar.gz

🔐 Verification Summary
==================================================
ℹ️  Total Artifacts: 2
ℹ️  Successful Verifications: 2
✅ 🎉 ALL VERIFICATIONS PASSED!
```

## Workflow Configuration Examples

### Go Project Configuration

The workflow automatically detects Go projects and configures:

```yaml
# Auto-generated configuration for Go
setup_command: "echo 'Setting up Go...'"
build_command: "go build -o zobra-go-linux-amd64 main.go && GOOS=darwin GOARCH=amd64 go build -o zobra-go-darwin-amd64 main.go && GOOS=windows GOARCH=amd64 go build -o zobra-go-windows-amd64.exe main.go"
artifact_pattern: "zobra-go-*"
artifact_path: "."
```

### Python Project Configuration

```yaml
# Auto-generated configuration for Python
setup_command: "python -m pip install --upgrade pip && pip install build"
build_command: "python -m build"
artifact_pattern: "*"
artifact_path: "dist"
```

### Custom Generic Configuration

For projects not automatically detected, use manual workflow dispatch:

```yaml
# Manual configuration for Rust project
artifact_type: generic
build_command: "cargo build --release"
artifact_pattern: "target/release/myapp*"
```

## Integration Examples

### CI/CD Pipeline Integration

```yaml
# .github/workflows/deploy.yml
name: Deploy with SLSA Verification

on:
  release:
    types: [published]

jobs:
  verify-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install slsa-verifier
        run: |
          go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest
      
      - name: Verify SLSA Provenance
        run: |
          ./verify_generic_slsa.sh -r ${{ github.repository }} -t ${{ github.ref_name }}
      
      - name: Deploy Verified Artifacts
        run: |
          echo "Deploying verified artifacts..."
          # Your deployment logic here
```

### Docker Integration

```dockerfile
# Dockerfile with SLSA verification
FROM golang:1.21 AS verifier

# Install slsa-verifier
RUN go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest

# Copy verification script
COPY verify_generic_slsa.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/verify_generic_slsa.sh

# Verify artifacts before using them
RUN verify_generic_slsa.sh -r owner/repo -t v1.0.0 -v \
    -p /path/to/artifact -s /path/to/provenance.intoto.jsonl

FROM alpine:latest
# Copy verified artifacts
COPY --from=verifier /verified/artifacts /app/
```

## Troubleshooting Examples

### Common Issues and Solutions

#### Issue: "No artifacts found matching pattern"

```bash
# Debug: Check what files were actually built
ls -la
ls -la dist/  # for Python projects

# Solution: Adjust artifact pattern in workflow dispatch
# For example, if your build creates files like "myapp-v1.0.0-*"
artifact_pattern: "myapp-v1.0.0-*"
```

#### Issue: "Verification failed"

```bash
# Debug: Check provenance contents
cat provenance.intoto.jsonl | jq .

# Common causes:
# 1. Tag mismatch - ensure tag used for build matches verification
# 2. Repository mismatch - ensure repository URL is correct
# 3. Artifact modification - ensure artifacts haven't been changed

# Solution: Use exact same parameters as build
./verify_generic_slsa.sh -r exact/repo -t exact-tag
```

#### Issue: "Workflow not found"

```bash
# Debug: Check available workflows
gh run list --repo owner/repo --limit 10

# Solution: Ensure workflow file is committed and pushed
git add .github/workflows/generic-slsa.yml
git commit -m "Add generic SLSA workflow"
git push origin main
```

## Best Practices

### 1. Consistent Tagging

```bash
# Use semantic versioning
git tag v1.0.0
git tag v1.0.1
git tag v1.1.0

# Use type prefixes for clarity
git tag go-v1.0.0    # Go-specific
git tag py-v1.0.0    # Python-specific
git tag node-v1.0.0  # Node.js-specific
```

### 2. Automated Verification

```bash
# Add to your release script
#!/bin/bash
set -e

TAG="v1.0.0"
REPO="owner/repo"

echo "Creating release..."
git tag "$TAG"
git push origin "$TAG"

echo "Waiting for build to complete..."
sleep 300  # Wait 5 minutes for build

echo "Verifying SLSA provenance..."
./verify_generic_slsa.sh -r "$REPO" -t "$TAG"

echo "Release verified and ready!"
```

### 3. Multi-Platform Verification

```bash
# Verify all platforms for Go projects
./verify_generic_slsa.sh -r owner/repo -t go-v1.0.0

# This will verify:
# - zobra-go-linux-amd64
# - zobra-go-darwin-amd64  
# - zobra-go-windows-amd64.exe
```

## Next Steps

1. **Try the workflow** with your own project
2. **Customize build commands** for your specific needs
3. **Integrate verification** into your deployment pipeline
4. **Monitor and audit** your supply chain security
5. **Share with your team** and establish SLSA practices

For more detailed information, see:
- [GENERIC_SLSA_GUIDE.md](./GENERIC_SLSA_GUIDE.md) - Complete usage guide
- [SLSA_REQUIREMENTS.md](./SLSA_REQUIREMENTS.md) - SLSA implementation requirements
- [Official SLSA Documentation](https://slsa.dev/) - SLSA framework details
