# Manual Release Creation for SLSA Demo

Since the GitHub Actions workflow didn't trigger automatically, let's create the release manually to proceed with the SLSA demonstration.

## Steps to Create Release Manually

### 1. Go to GitHub Releases Page
Visit: https://github.com/wiz-sec/zobra/releases

### 2. Click "Create a new release"

### 3. Fill in Release Details
- **Tag version**: `v0.1.0` (should be pre-filled since we pushed the tag)
- **Release title**: `Release v0.1.0 - Initial zobra package for SLSA demonstration`
- **Description**:
```markdown
# Zobra v0.1.0 - SLSA Demonstration Package

This is the initial release of the zobra Python package, created for SLSA (Supply-chain Levels for Software Artifacts) provenance demonstration.

## Features
- ✅ `zobra.dump_file('foo.txt')` - Create files with default content
- ✅ `zobra.dump_file('file.txt', 'custom content')` - Create files with custom content  
- ✅ `zobra.read_file('file.txt')` - Read file content
- ✅ `zobra.get_version()` - Get package version

## Usage
```python
import zobra

# Create a file with default content (as specified in POC)
zobra.dump_file('foo.txt')

# Create a file with custom content
zobra.dump_file('custom.txt', 'Hello, SLSA!')

# Read a file
content = zobra.read_file('foo.txt')
print(content)
```

## SLSA Demonstration
This package is part of a SLSA provenance demonstration:
- **Scenario 1**: ✅ Create package + verify
- **Package**: zobra Python package
- **Functionality**: File creation and reading operations
- **Purpose**: Demonstrate SLSA provenance generation and verification

## Installation
```bash
pip install zobra-0.1.0-py3-none-any.whl
```

## Files Included
- `zobra-0.1.0-py3-none-any.whl` - Python wheel distribution
- `zobra-0.1.0.tar.gz` - Source distribution

## Next Steps
1. Generate SLSA provenance (manual or via GitHub Actions)
2. Verify provenance using slsa-verifier
3. Demonstrate supply chain security validation
```

### 4. Upload Artifacts
Upload these files from the `dist/` directory:
- `zobra-0.1.0-py3-none-any.whl`
- `zobra-0.1.0.tar.gz`

### 5. Publish Release
Click "Publish release"

## Alternative: Trigger GitHub Actions Manually

If you prefer to use the automated SLSA workflow:

1. Go to: https://github.com/wiz-sec/zobra/actions
2. Click on "Release with SLSA Provenance" workflow
3. Click "Run workflow" button
4. Select branch: `main`
5. Click "Run workflow"

This will trigger the automated build and SLSA provenance generation.

## Next Steps After Release

Once the release is created (manually or automatically), you can proceed with:

1. **Download artifacts** for verification
2. **Generate SLSA provenance** (if not done automatically)
3. **Verify provenance** using slsa-verifier
4. **Demonstrate Scenario 1 completion**

The package is ready and functional - we've successfully completed the "Create package" part of Scenario 1!
