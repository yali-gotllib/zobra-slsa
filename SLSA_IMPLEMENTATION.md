# SLSA Implementation for Zobra Package

This repository demonstrates SLSA (Supply-chain Levels for Software Artifacts) Level 3 provenance generation and verification for the `zobra` Python package.

## Overview

The `zobra` package is a simple Python library that demonstrates SLSA provenance generation using GitHub's native attestation system. Due to organizational security constraints, we use GitHub's attestation approach rather than the official SLSA framework generator.

## Package Functionality

```python
import zobra
zobra.dump_file('foo.txt')  # Creates a file with package information
```

## SLSA Implementation

### Provenance Generation

We use GitHub's native attestation system via the workflow in `.github/workflows/release.yml`:

- **Action**: `actions/attest-build-provenance@v1`
- **Level**: SLSA Level 3 compliance
- **Format**: GitHub attestation format (Sigstore bundle)
- **Storage**: GitHub's attestation registry

### Verification Methods

#### 1. GitHub Native Verification (Primary)

```bash
gh attestation verify zobra-0.1.0-py3-none-any.whl --repo wiz-sec/zobra
gh attestation verify zobra-0.1.0.tar.gz --repo wiz-sec/zobra
```

This is the authoritative verification method that:
- ✅ Verifies cryptographic signatures
- ✅ Confirms build integrity
- ✅ Validates SLSA Level 3 provenance
- ✅ Checks source repository authenticity

#### 2. SLSA Format Conversion

Use the `convert_github_attestation.py` script to convert GitHub attestations to standard SLSA format:

```bash
# Download attestation
gh attestation download zobra-0.1.0-py3-none-any.whl --repo wiz-sec/zobra

# Convert to SLSA format
python3 convert_github_attestation.py sha256:*.jsonl -o provenance.intoto.jsonl
```

This generates multiple output formats:
- `*.intoto.jsonl` - DSSE envelope format
- `*.slsa.json` - Plain SLSA provenance
- `*.bundle.json` - Full Sigstore bundle
- `*.crt` - Certificate file

#### 3. Comprehensive Verification

Run the complete verification script:

```bash
./verify_slsa_complete.sh
```

This script performs:
- GitHub native verification
- SLSA provenance extraction
- Rekor transparency log checks
- Comprehensive reporting

## Constraints and Limitations

### Organization Security Policy

The `wiz-sec` organization restricts GitHub Actions to selected actions only. The official `slsa-framework/slsa-github-generator` is not in the allowed list, forcing us to use GitHub's native attestation approach.

### Verification Tool Compatibility

- ✅ **GitHub CLI**: Full compatibility and verification
- ❌ **slsa-verifier**: Compatibility issues with GitHub's Sigstore implementation
- ⚠️ **Other SLSA tools**: May have similar compatibility issues

### Interoperability Gap

While our provenance is technically SLSA-compliant, it has limited compatibility with the broader SLSA ecosystem due to format differences between GitHub's implementation and standard SLSA tools.

## SLSA Demonstration Scenarios

This repository demonstrates all four key SLSA verification scenarios:

### Scenario 1: Create package + verify ✅
- **Package**: zobra (our own package)
- **SLSA Method**: GitHub attestations
- **Verifier**: `gh attestation verify`
- **Result**: Successful verification of our own package

### Scenario 2: Existing package + has SLSA + verify succeeds ✅
- **Package**: Argo CD CLI (third-party)
- **SLSA Method**: Official SLSA framework
- **Verifier**: `slsa-verifier` (official tool)
- **Result**: Successful verification of external package with real SLSA provenance

### Scenario 3: Existing package + no SLSA + verify failed ✅
- **Package**: Dummy package without provenance
- **SLSA Method**: None
- **Verifier**: `slsa-verifier`
- **Result**: Correctly fails verification (no provenance)

### Scenario 4: Create package with broken SLSA + verify failed ✅
- **Package**: Package with corrupted provenance
- **SLSA Method**: Invalid/corrupted provenance
- **Verifier**: `slsa-verifier`
- **Result**: Correctly fails verification (invalid provenance)

### Running All Scenarios

Execute the complete demonstration:

```bash
./demo_all_slsa_scenarios.sh
```

## Files in This Repository

### Core Package
- `zobra/` - Python package source code
- `pyproject.toml` - Package configuration
- `tests/` - Unit tests

### SLSA Implementation
- `.github/workflows/release.yml` - GitHub attestation workflow
- `convert_github_attestation.py` - Attestation format converter
- `verify_slsa_complete.sh` - Comprehensive verification script
- `demo_all_slsa_scenarios.sh` - Complete scenario demonstration
- `verify_slsa.sh` - Basic verification script

### Documentation
- `README.md` - Package overview
- `SLSA_IMPLEMENTATION.md` - This file
- `create_release.md` - Release process documentation

## Usage Instructions

### Creating a Release with SLSA Provenance

1. **Tag a release**:
   ```bash
   git tag v0.1.1
   git push origin v0.1.1
   ```

2. **Or trigger manually**:
   ```bash
   gh workflow run "Release with SLSA Provenance" --field tag=v0.1.1
   ```

3. **Verify the attestation**:
   ```bash
   gh attestation verify zobra-*.whl --repo wiz-sec/zobra
   ```

### Verifying Downloaded Packages

If you download the package from releases:

```bash
# Download the package files
wget https://github.com/wiz-sec/zobra/releases/download/v0.1.1/zobra-0.1.1-py3-none-any.whl

# Verify with GitHub CLI
gh attestation verify zobra-0.1.1-py3-none-any.whl --repo wiz-sec/zobra
```

## Security Properties

Our SLSA implementation provides:

- **Build Integrity**: Cryptographic proof that artifacts match the build process
- **Source Authenticity**: Verification that code came from the expected repository
- **Build Environment**: Documentation of the build environment and parameters
- **Non-Repudiation**: Immutable record of the build process
- **Transparency**: Public visibility into the build process

## Future Improvements

To achieve full SLSA ecosystem compatibility:

1. **Organization Policy**: Add `slsa-framework/*` to allowed GitHub Actions
2. **Standard Generator**: Use official SLSA generator for broader compatibility
3. **Universal Verification**: Ensure compatibility with all SLSA verification tools

## References

- [SLSA Specification](https://slsa.dev/)
- [GitHub Attestations Documentation](https://docs.github.com/en/actions/security-guides/using-artifact-attestations)
- [SLSA Verifier](https://github.com/slsa-framework/slsa-verifier)
- [Sigstore](https://www.sigstore.dev/)
