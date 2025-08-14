# Generic SLSA Provenance Guide

This guide explains how to use the generic SLSA workflow that works with any artifact type and provides SLSA Level 3 provenance generation and verification.

## Overview

The generic SLSA workflow (`generic-slsa.yml`) automatically detects your project type and generates appropriate SLSA provenance for:

- **Go binaries** (detected by `go.mod`)
- **Python packages** (detected by `pyproject.toml`, `setup.py`, or `setup.cfg`)
- **Node.js packages** (detected by `package.json`)
- **Generic artifacts** (any other project type with custom build commands)

## Quick Start

### 1. Add the Workflow

Copy the `generic-slsa.yml` workflow to your repository's `.github/workflows/` directory.

### 2. Trigger Provenance Generation

The workflow can be triggered in two ways:

#### Automatic (Tag-based)
Push a tag to trigger automatic detection and building:

```bash
# For any project type
git tag v1.0.0
git push origin v1.0.0

# Or use type-specific prefixes
git tag go-v1.0.0    # For Go projects
git tag py-v1.0.0    # For Python projects
git tag node-v1.0.0  # For Node.js projects
```

#### Manual (Workflow Dispatch)
Trigger manually with custom parameters:

1. Go to your repository's Actions tab
2. Select "Generic SLSA Provenance" workflow
3. Click "Run workflow"
4. Configure options:
   - **Artifact Type**: `auto`, `go`, `python`, `nodejs`, or `generic`
   - **Tag**: The tag to build (e.g., `v1.0.0`)
   - **Build Command**: Custom build command (for generic type)
   - **Artifact Pattern**: Pattern to match artifacts (for generic type)

### 3. Verify Provenance

Use the provided verification script:

```bash
# Auto-detect and verify
./verify_generic_slsa.sh -r owner/repo -t v1.0.0

# Specify artifact type
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -a python

# Verify existing files without downloading
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -v \
  -p ./artifact.whl -s ./provenance.intoto.jsonl
```

## Supported Project Types

### Go Projects

**Detection**: Presence of `go.mod` file

**Default Build**:
```bash
go build -o zobra-go-linux-amd64 main.go
GOOS=darwin GOARCH=amd64 go build -o zobra-go-darwin-amd64 main.go
GOOS=windows GOARCH=amd64 go build -o zobra-go-windows-amd64.exe main.go
```

**Artifacts**: `zobra-go-*` (cross-platform binaries)

### Python Projects

**Detection**: Presence of `pyproject.toml`, `setup.py`, or `setup.cfg`

**Default Build**:
```bash
python -m pip install --upgrade pip
pip install build
python -m build
```

**Artifacts**: `dist/*.whl` and `dist/*.tar.gz`

### Node.js Projects

**Detection**: Presence of `package.json`

**Default Build**:
```bash
npm install
npm run build
npm pack
```

**Artifacts**: `*.tgz`

### Generic Projects

**Detection**: No specific project files found, or manually specified

**Custom Build**: Specify your own build commands and artifact patterns

**Example for C/C++**:
- Build Command: `make && make install`
- Artifact Pattern: `bin/*`

**Example for Rust**:
- Build Command: `cargo build --release`
- Artifact Pattern: `target/release/*`

## Workflow Configuration

### Environment Variables

The workflow automatically configures build parameters based on detected project type:

| Variable | Go | Python | Node.js | Generic |
|----------|----|---------|---------|---------| 
| `setup_command` | Go setup | pip install build | npm install | Custom |
| `build_command` | Cross-platform build | python -m build | npm run build && npm pack | Custom |
| `artifact_pattern` | zobra-go-* | * | *.tgz | Custom |
| `artifact_path` | . | dist | . | Custom |

### Manual Override

You can override auto-detection by specifying parameters in workflow dispatch:

```yaml
# Example manual configuration for a Rust project
artifact_type: generic
build_command: "cargo build --release"
artifact_pattern: "target/release/myapp*"
```

## Verification Script Usage

The `verify_generic_slsa.sh` script provides comprehensive verification capabilities:

### Basic Usage

```bash
./verify_generic_slsa.sh -r owner/repo -t v1.0.0
```

### Advanced Options

```bash
# Specify artifact type (skip auto-detection)
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -a python

# Use custom source branch
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -b develop

# Verify without downloading (use existing files)
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -n

# Verify specific files only
./verify_generic_slsa.sh -r owner/repo -t v1.0.0 -v \
  -p ./my-artifact.bin -s ./provenance.intoto.jsonl
```

### Prerequisites

The verification script requires:

1. **slsa-verifier**: Install with:
   ```bash
   go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest
   ```

2. **GitHub CLI** (for downloading): Install from https://cli.github.com/

## Security Features

### SLSA Level 3 Compliance

The workflow provides SLSA Level 3 by ensuring:

- **Non-forgeable Provenance**: Uses official SLSA generator v2.1.0
- **Ephemeral Environment**: Fresh GitHub Actions runners
- **Cryptographic Verification**: Sigstore-based signatures
- **Transparency**: Public transparency log recording

### Provenance Contents

Each provenance file contains:

- **Builder Identity**: `slsa-framework/slsa-github-generator`
- **Source Repository**: Your GitHub repository
- **Build Parameters**: Environment, dependencies, commands
- **Artifact Hashes**: SHA256 checksums of all artifacts
- **Timestamp**: When the build occurred
- **Signature**: Cryptographic proof of authenticity

## Troubleshooting

### Common Issues

#### "No artifacts found"
- Check that your build command produces files
- Verify the artifact pattern matches your build output
- Use workflow dispatch with custom parameters

#### "Verification failed"
- Ensure the tag matches the build source
- Check that artifacts haven't been modified
- Verify the repository URL is correct

#### "Workflow not found"
- Ensure the workflow file is in `.github/workflows/`
- Check that the workflow has been committed to the repository
- Verify the workflow syntax is valid

### Debug Mode

Enable debug output in the verification script:

```bash
# Add -x for bash debug output
bash -x ./verify_generic_slsa.sh -r owner/repo -t v1.0.0
```

## Examples

### Example 1: Go Project

```bash
# Repository structure
.
├── go.mod
├── main.go
└── .github/workflows/generic-slsa.yml

# Trigger build
git tag go-v1.0.0
git push origin go-v1.0.0

# Verify
./verify_generic_slsa.sh -r myorg/myproject -t go-v1.0.0
```

### Example 2: Python Project

```bash
# Repository structure  
.
├── pyproject.toml
├── src/mypackage/
└── .github/workflows/generic-slsa.yml

# Trigger build
git tag py-v1.0.0
git push origin py-v1.0.0

# Verify
./verify_generic_slsa.sh -r myorg/myproject -t py-v1.0.0 -a python
```

### Example 3: Custom Build

```bash
# Manual workflow dispatch with:
# - artifact_type: generic
# - build_command: "make release"
# - artifact_pattern: "dist/*"

# Verify
./verify_generic_slsa.sh -r myorg/myproject -t v1.0.0 -a generic
```

## Integration with Existing Workflows

### Replacing Existing SLSA Workflows

If you have existing language-specific SLSA workflows, you can replace them with the generic workflow:

1. Remove old workflows (e.g., `go-slsa-build.yml`, `python-slsa.yml`)
2. Add `generic-slsa.yml`
3. Update your release process to use the new workflow

### Parallel Workflows

You can run the generic workflow alongside existing workflows for comparison:

1. Use different tag prefixes (e.g., `generic-v1.0.0` vs `v1.0.0`)
2. Compare provenance outputs
3. Gradually migrate to the generic workflow

## Best Practices

### Tagging Strategy

Use consistent tag naming:
- `v1.0.0` - Generic/auto-detect
- `go-v1.0.0` - Go-specific
- `py-v1.0.0` - Python-specific
- `node-v1.0.0` - Node.js-specific

### Artifact Naming

Use descriptive artifact names:
- Include version: `myapp-v1.0.0-linux-amd64`
- Include platform: `mypackage-1.0.0-py3-none-any.whl`
- Include architecture: `myapp-darwin-arm64`

### Verification in CI/CD

Integrate verification into your deployment pipeline:

```yaml
# Example GitHub Actions step
- name: Verify SLSA Provenance
  run: |
    ./verify_generic_slsa.sh -r ${{ github.repository }} -t ${{ github.ref_name }}
```

## Next Steps

1. **Test the workflow** with your project
2. **Customize build commands** if needed
3. **Integrate verification** into your deployment process
4. **Monitor provenance** in your supply chain
5. **Share with your team** and document your SLSA implementation

For more information about SLSA, visit: https://slsa.dev/
