# SLSA Implementation Requirements

This document outlines the comprehensive requirements for generating and verifying SLSA Level 3 provenance for **all artifact types**: binaries, packages, and container images.

## Overview

SLSA (Supply-chain Levels for Software Artifacts) provides cryptographic proof of how software was built. This implementation covers three approaches:

1. **Universal Generic Workflow**: Auto-detects project type and works for all programming languages
2. **Artifact-Specific Workflows**: Language-specific implementations (Go, Python, Node.js, etc.)
3. **Container Image Workflows**: Docker/OCI container provenance generation

All approaches provide the same **SLSA Level 3 security guarantees** with official verification tools.

## Table of Contents

- [Universal Generic Workflow](#universal-generic-workflow)
- [Artifact Generation Requirements](#artifact-generation-requirements)
- [Container Image Requirements](#container-image-requirements)
- [Verification Requirements](#verification-requirements)
- [SLSA Level 3 Compliance](#slsa-level-3-compliance)
- [Troubleshooting](#troubleshooting)

## Universal Generic Workflow

The **recommended approach** is a single universal workflow that automatically detects project types and generates SLSA provenance for any artifact.

### Key Features

- **Auto-Detection**: Automatically identifies Go, Python, Node.js, or generic projects
- **Universal**: Single workflow for all programming languages
- **Flexible**: Supports custom build commands for any project type
- **Consistent**: Same security guarantees across all artifact types

### Complete Generic Workflow

```yaml
name: Generic SLSA Provenance

on:
  push:
    tags:
      - 'v*'        # Generic version tags
      - 'go-v*'     # Go-specific tags
      - 'py-v*'     # Python-specific tags
      - 'node-v*'   # Node.js-specific tags
  workflow_dispatch:
    inputs:
      artifact_type:
        description: 'Type of artifact to build'
        required: false
        default: 'auto'
        type: choice
        options: [auto, go, python, nodejs, generic]
      tag:
        description: 'Tag to generate provenance for'
        required: false
        default: ''
      build_command:
        description: 'Custom build command (for generic type)'
        required: false
        default: ''
      artifact_pattern:
        description: 'Pattern to match artifacts (for generic type)'
        required: false
        default: '*'

permissions: read-all

jobs:
  # Auto-detect project type and configure build parameters
  detect:
    runs-on: ubuntu-latest
    outputs:
      artifact_type: ${{ steps.detect.outputs.artifact_type }}
      build_command: ${{ steps.detect.outputs.build_command }}
      setup_command: ${{ steps.detect.outputs.setup_command }}
      artifact_pattern: ${{ steps.detect.outputs.artifact_pattern }}
      artifact_path: ${{ steps.detect.outputs.artifact_path }}
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.tag || github.ref }}

      - name: Detect project type and configure build
        id: detect
        run: |
          set -euo pipefail

          # Use manual input if provided
          if [ "${{ github.event.inputs.artifact_type }}" != "auto" ] && [ "${{ github.event.inputs.artifact_type }}" != "" ]; then
            ARTIFACT_TYPE="${{ github.event.inputs.artifact_type }}"
          else
            # Auto-detect based on files present
            if [ -f "go.mod" ]; then
              ARTIFACT_TYPE="go"
            elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ]; then
              ARTIFACT_TYPE="python"
            elif [ -f "package.json" ]; then
              ARTIFACT_TYPE="nodejs"
            else
              ARTIFACT_TYPE="generic"
            fi
          fi

          # Configure build parameters based on type
          case "$ARTIFACT_TYPE" in
            "go")
              echo "setup_command=echo 'Setting up Go...'" >> "$GITHUB_OUTPUT"
              echo "build_command=go build -o myapp-linux-amd64 main.go && GOOS=darwin GOARCH=amd64 go build -o myapp-darwin-amd64 main.go && GOOS=windows GOARCH=amd64 go build -o myapp-windows-amd64.exe main.go" >> "$GITHUB_OUTPUT"
              echo "artifact_pattern=myapp-*" >> "$GITHUB_OUTPUT"
              echo "artifact_path=." >> "$GITHUB_OUTPUT"
              ;;
            "python")
              echo "setup_command=python -m pip install --upgrade pip && pip install build" >> "$GITHUB_OUTPUT"
              echo "build_command=python -m build" >> "$GITHUB_OUTPUT"
              echo "artifact_pattern=*" >> "$GITHUB_OUTPUT"
              echo "artifact_path=dist" >> "$GITHUB_OUTPUT"
              ;;
            "nodejs")
              echo "setup_command=npm install" >> "$GITHUB_OUTPUT"
              echo "build_command=npm run build && npm pack" >> "$GITHUB_OUTPUT"
              echo "artifact_pattern=*.tgz" >> "$GITHUB_OUTPUT"
              echo "artifact_path=." >> "$GITHUB_OUTPUT"
              ;;
            "generic")
              BUILD_CMD="${{ github.event.inputs.build_command }}"
              PATTERN="${{ github.event.inputs.artifact_pattern }}"
              echo "setup_command=echo 'Generic setup - no specific setup required'" >> "$GITHUB_OUTPUT"
              echo "build_command=${BUILD_CMD:-echo 'No build command specified'}" >> "$GITHUB_OUTPUT"
              echo "artifact_pattern=${PATTERN:-*}" >> "$GITHUB_OUTPUT"
              echo "artifact_path=." >> "$GITHUB_OUTPUT"
              ;;
          esac

          echo "artifact_type=$ARTIFACT_TYPE" >> "$GITHUB_OUTPUT"

  # Build artifacts based on detected/specified type
  build:
    needs: [detect]
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      hashes: ${{ steps.hash.outputs.hashes }}
      artifact_type: ${{ needs.detect.outputs.artifact_type }}
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.tag || github.ref }}

      # Setup environment based on artifact type
      - name: Setup Go
        if: needs.detect.outputs.artifact_type == 'go'
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Setup Python
        if: needs.detect.outputs.artifact_type == 'python'
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'

      - name: Setup Node.js
        if: needs.detect.outputs.artifact_type == 'nodejs'
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      # Run setup commands
      - name: Setup dependencies
        run: ${{ needs.detect.outputs.setup_command }}

      # Build artifacts
      - name: Build artifacts
        run: ${{ needs.detect.outputs.build_command }}

      # Generate hashes for SLSA provenance
      - name: Generate subject hashes
        id: hash
        run: |
          set -euo pipefail
          cd "${{ needs.detect.outputs.artifact_path }}"
          echo "hashes=$(sha256sum ${{ needs.detect.outputs.artifact_pattern }} | base64 -w0)" >> "$GITHUB_OUTPUT"

      # Upload artifacts for later verification
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: generic-slsa-artifacts-${{ needs.detect.outputs.artifact_type }}
          path: ${{ needs.detect.outputs.artifact_path }}/${{ needs.detect.outputs.artifact_pattern }}

  # Generate SLSA provenance using the official generic generator
  provenance:
    needs: [build]
    permissions:
      actions: read   # To read the workflow path
      id-token: write # To sign the provenance
      contents: write # To add assets to a release
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
    with:
      base64-subjects: "${{ needs.build.outputs.hashes }}"
      upload-assets: true
      upload-tag-name: ${{ github.event.inputs.tag || github.ref_name }}
      provenance-name: "generic-slsa-provenance-${{ needs.build.outputs.artifact_type }}.intoto.jsonl"
```

## Artifact Generation Requirements

For language-specific implementations, create a GitHub Actions workflow with two jobs:

1. **Build Job**: Compiles artifacts and generates hashes
2. **Provenance Job**: Calls the SLSA generic generator

### Required Components

#### SLSA Generator
```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
```

#### Build Job Template
```yaml
build:
  runs-on: ubuntu-latest
  outputs:
    hashes: ${{ steps.hash.outputs.hashes }}
  steps:
    - uses: actions/checkout@v4
    - name: Setup Environment
      # Language-specific setup (Python, Go, Node.js, etc.)
    - name: Build Artifacts
      # Language-specific build commands
    - name: Generate Hashes
      id: hash
      run: |
        echo "hashes=$(sha256sum * | base64 -w0)" >> "$GITHUB_OUTPUT"
    - name: Upload Artifacts
      uses: actions/upload-artifact@v4
      with:
        name: build-artifacts
        path: ./*
```

#### Provenance Job Template
```yaml
provenance:
  needs: [build]
  permissions:
    actions: read
    id-token: write
    contents: write
  uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
  with:
    base64-subjects: "${{ needs.build.outputs.hashes }}"
    upload-assets: true
    upload-tag-name: ${{ github.ref_name }}
    provenance-name: "slsa-provenance.intoto.jsonl"
```

### Language-Specific Build Examples

#### Python
```yaml
- name: Set up Python
  uses: actions/setup-python@v4
  with:
    python-version: '3.9'
- name: Build Package
  run: |
    pip install build
    python -m build
```

#### Go
```yaml
- name: Set up Go
  uses: actions/setup-go@v4
  with:
    go-version: '1.21'
- name: Build Binary
  run: go build -o myapp main.go
```

#### Node.js
```yaml
- name: Set up Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '18'
- name: Build Package
  run: |
    npm install
    npm run build
    npm pack
```

## Container Image Requirements

Container images require a different workflow approach using the SLSA container generator.

### Complete Container Workflow

```yaml
name: Container SLSA Build

on:
  push:
    tags:
      - 'container-v*'
  workflow_dispatch:
    inputs:
      tag:
        description: 'Tag to generate provenance for'
        required: true
        default: 'container-v1.0.0'

permissions: read-all

env:
  IMAGE_REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Build and push container image
  build:
    permissions:
      contents: read
      packages: write
    outputs:
      image: ${{ steps.image.outputs.image }}
      digest: ${{ steps.digest.outputs.digest }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the repository
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Authenticate Docker
        uses: docker/login-action@v3
        with:
          registry: ${{ env.IMAGE_REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.IMAGE_REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=tag
            type=raw,value=${{ github.event.inputs.tag }},enable={{is_default_branch}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v6
        id: build
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

      - name: Install crane
        uses: imjasonh/setup-crane@v0.4

      - name: Get image digest
        id: digest
        run: |
          tag=$(echo "${{ steps.meta.outputs.tags }}" | head -1)
          digest=$(crane digest "$tag")
          echo "digest=$digest" >> "$GITHUB_OUTPUT"

      - name: Output image
        id: image
        run: |
          image_name="${IMAGE_REGISTRY}/${IMAGE_NAME}"
          echo "image=$image_name" >> "$GITHUB_OUTPUT"

  # Generate SLSA provenance for container
  provenance:
    needs: [build]
    permissions:
      actions: read # for detecting the Github Actions environment
      id-token: write # for creating OIDC tokens for signing
      packages: write # for uploading attestations
    if: startsWith(github.ref, 'refs/tags/') || github.event_name == 'workflow_dispatch'
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@v2.1.0
    with:
      image: ${{ needs.build.outputs.image }}
      digest: ${{ needs.build.outputs.digest }}
      registry-username: ${{ github.actor }}
    secrets:
      registry-password: ${{ secrets.GITHUB_TOKEN }}
```

### Container-Specific Requirements

#### Container Registry
- **GitHub Container Registry**: `ghcr.io` (recommended)
- **Docker Hub**: `docker.io`
- **Other OCI registries**: Any OCI-compatible registry

#### Required Tools
- **Docker Buildx**: For multi-platform builds
- **Crane**: For getting image digests
- **Registry Authentication**: Proper credentials for pushing

#### Container Generator
```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@v2.1.0
```

#### Key Differences from Artifacts
- **No hash generation**: Container digest is used instead
- **Registry integration**: Provenance attached to container registry
- **Immutable references**: Uses SHA256 digest for verification
- **OCI compliance**: Works with any OCI-compatible registry

### Critical Requirements

#### Version Constraints
- SLSA Generator: v1.10.0 (compatible with slsa-verifier v2.6.0)
- GitHub Actions: Use v4 versions (v3 deprecated)
- Checkout: actions/checkout@v4
- Upload Artifact: actions/upload-artifact@v4

#### Permissions
The provenance job requires specific permissions:
```yaml
permissions:
  actions: read      # Read workflow path
  id-token: write    # Sign provenance
  contents: write    # Upload to releases (artifacts)
  packages: write    # Upload to registry (containers)
```

#### Hash Generation (Artifacts Only)
Must use this exact format:
```bash
sha256sum * | base64 -w0
```

## Verification Requirements

### Prerequisites

#### Install slsa-verifier
```bash
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest
```

#### Install Additional Tools (for containers)
```bash
# Install crane for getting container digests
go install github.com/google/go-containerregistry/cmd/crane@latest

# Install GitHub CLI for downloading artifacts
# Visit: https://cli.github.com/
```

### Artifact Verification

#### Required Files
- Built artifact (binary, package, etc.)
- SLSA provenance file (.intoto.jsonl)
- Source repository information

#### Verification Command
```bash
slsa-verifier verify-artifact [artifact-file] \
  --provenance-path [provenance-file.intoto.jsonl] \
  --source-uri github.com/[owner]/[repository] \
  --source-branch [branch-name]
```

#### Success Indicators
A successful verification shows:
```
Verified build using builder "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0"
Verifying artifact [artifact-file]: PASSED
PASSED: SLSA verification passed
```

### Container Verification

#### Required Information
- Container image with digest (immutable reference)
- Source repository information
- No separate provenance file needed (attached to registry)

#### Get Container Digest
```bash
# Get the digest for immutable reference
crane digest ghcr.io/owner/repository:tag

# Example output: sha256:713348ed5132c5e8d51401039c444469d35ecbdfee0b587dd4d3fd5b5e2cd473
```

#### Verification Command
```bash
slsa-verifier verify-image [image@digest] \
  --source-uri github.com/[owner]/[repository] \
  --source-tag [tag-name]
```

#### Example
```bash
slsa-verifier verify-image \
  ghcr.io/owner/repository@sha256:713348ed5132c5e8d51401039c444469d35ecbdfee0b587dd4d3fd5b5e2cd473 \
  --source-uri github.com/owner/repository \
  --source-tag container-v1.0.0
```

#### Success Indicators
A successful container verification shows:
```
Verified build using builder "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v2.1.0"
PASSED: SLSA verification passed
```

### Universal Verification Script

For automated verification of any artifact type, use the provided verification script:

```bash
# Auto-detect and verify any artifact type
./verify_generic_slsa.sh -r owner/repository -t v1.0.0

# Specify artifact type
./verify_generic_slsa.sh -r owner/repository -t v1.0.0 -a python

# Verify existing files without downloading
./verify_generic_slsa.sh -r owner/repository -t v1.0.0 -v \
  -p ./artifact.whl -s ./provenance.intoto.jsonl
```

### Verification Parameters

#### Source URI
- Format: `github.com/owner/repository`
- Must match the repository where artifacts were built

#### Source Reference
- Use `--source-branch main` for main branch builds
- Use `--source-tag v1.0.0` for tagged releases
- Must match the actual source used in build

#### Container-Specific
- **Immutable Reference**: Must use digest, not tag
- **Registry Access**: May require authentication for private registries
- **Provenance Location**: Attached to container registry, not separate file

## SLSA Level 3 Compliance

This implementation provides SLSA Level 3 by ensuring:

### Non-forgeable Provenance
- Signing keys managed by SLSA framework
- User builds cannot access or modify signing process
- All provenance fields generated by trusted builder

### Ephemeral and Isolated Environment
- GitHub Actions provides fresh VMs per build
- No cross-build contamination
- No persistent state between builds

### Cryptographic Verification
- Digital signatures via Sigstore
- Transparency log recording
- Tamper-evident provenance

## Troubleshooting

### Common Issues

#### Artifact Verification Issues

**"Untrusted reusable workflow"**
- Cause: Using SLSA generator version < v2.1.0
- Solution: Update to v2.1.0 or later

**"Invalid ref" errors**
- Cause: Mismatch between provenance source and verification parameters
- Solution: Ensure --source-branch or --source-tag matches build source

**"No artifacts found matching pattern"**
- Cause: Build command doesn't produce expected files
- Solution: Check artifact_pattern in workflow configuration

**Build failures**
- Cause: Using deprecated GitHub Actions (v3)
- Solution: Update all actions to v4 versions

#### Container Verification Issues

**"The image is mutable"**
- Cause: Using tag instead of digest for verification
- Solution: Use `crane digest` to get SHA256 digest and verify with `image@digest`

**"Failed to get provenance"**
- Cause: Provenance not attached to registry or registry access issues
- Solution: Check registry permissions and provenance attachment

**Authentication errors**
- Cause: Private registry requires authentication
- Solution: Authenticate with registry before verification

#### Universal Workflow Issues

**Wrong project type detected**
- Cause: Multiple project files present (e.g., both go.mod and package.json)
- Solution: Use manual workflow dispatch with specific artifact_type

**Generic build fails**
- Cause: No build_command specified for generic type
- Solution: Provide custom build_command in workflow dispatch

### Builder ID Verification

#### Artifact Provenance
The provenance must show the generic SLSA generator as builder:
```
https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0
```

#### Container Provenance
The provenance must show the container SLSA generator as builder:
```
https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v2.1.0
```

If it shows your workflow instead, update the SLSA generator version.

## Benefits

### Universal Approach
- **Single Generic Workflow**: Auto-detects and builds any project type
- **Consistent Security**: Same SLSA Level 3 guarantees across all artifacts
- **Unified Verification**: Single `slsa-verifier` tool for all artifact types
- **Multi-Platform Support**: Works with binaries, packages, and containers

### Production Ready
- **Enterprise-Grade Security**: Cryptographic proof of build integrity
- **Global Verification**: Anyone can verify artifacts independently
- **Registry Integration**: Container provenance attached to registries
- **Transparency Logging**: All signatures recorded in public logs

### Maintenance Benefits
- **Official Generators**: Actively maintained by SLSA framework
- **No Language Dependencies**: Generic approach eliminates language-specific builders
- **Stable Implementation**: Reliable and battle-tested in production
- **Future-Proof**: Supports new languages and artifact types automatically

### Comprehensive Coverage

#### Artifact Types Supported
- **Go Binaries**: Cross-platform executable files
- **Python Packages**: Wheels (.whl) and source distributions (.tar.gz)
- **Node.js Packages**: NPM packages (.tgz)
- **Container Images**: Docker/OCI containers with registry integration
- **Generic Artifacts**: Any build output with custom commands

#### Security Features
- **SLSA Level 3 Compliance**: Highest practical security level
- **Non-Forgeable Provenance**: Cryptographically signed by trusted builders
- **Ephemeral Environments**: Fresh, isolated build environments
- **Immutable Artifacts**: Tamper-evident with cryptographic hashes
- **Supply Chain Transparency**: Full build-to-deployment verification

## Quick Start Guide

### 1. Choose Your Approach

**Recommended: Universal Generic Workflow**
- Copy the complete generic workflow above
- Supports auto-detection for Go, Python, Node.js, and custom builds
- Single workflow for all project types

**Alternative: Artifact-Specific Workflow**
- Use language-specific templates for specialized needs
- More control over build process
- Separate workflows per language

**Container Images: Container-Specific Workflow**
- Required for Docker/OCI container images
- Integrates with container registries
- Supports multi-platform builds

### 2. Trigger Provenance Generation

```bash
# For universal workflow
git tag v1.0.0
git push origin v1.0.0

# For language-specific
git tag go-v1.0.0    # Go projects
git tag py-v1.0.0    # Python projects
git tag node-v1.0.0  # Node.js projects

# For containers
git tag container-v1.0.0
git push origin container-v1.0.0
```

### 3. Verify Artifacts

```bash
# Install verifier
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest

# Verify artifacts
slsa-verifier verify-artifact artifact.bin \
  --provenance-path provenance.intoto.jsonl \
  --source-uri github.com/owner/repo \
  --source-tag v1.0.0

# Verify containers (get digest first)
crane digest ghcr.io/owner/repo:tag
slsa-verifier verify-image ghcr.io/owner/repo@sha256:digest \
  --source-uri github.com/owner/repo \
  --source-tag container-v1.0.0
```

### 4. Integrate into CI/CD

```yaml
# Add verification to deployment pipeline
- name: Verify SLSA Provenance
  run: |
    slsa-verifier verify-artifact ${{ github.workspace }}/artifact \
      --provenance-path ${{ github.workspace }}/provenance.intoto.jsonl \
      --source-uri github.com/${{ github.repository }} \
      --source-tag ${{ github.ref_name }}
```

This comprehensive implementation provides **complete SLSA Level 3 security** for all modern software artifacts with minimal maintenance overhead and maximum flexibility.
