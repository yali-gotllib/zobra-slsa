#!/bin/bash

# Complete SLSA Provenance Generation and Verification Demo
# This script demonstrates the entire end-to-end process

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}🔐 $1${NC}"
    echo "=================================================="
}

print_step() {
    echo -e "${BLUE}📋 Step $1: $2${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header "Complete SLSA Provenance Generation and Verification Demo"
echo "This demo shows the entire process from build to verification"
echo

# Step 1: Show the current project structure
print_step "1" "Project Structure Analysis"
echo "Current project structure:"
echo "📁 Repository: zobra-slsa"
echo "📄 Go project: main.go + go.mod"
echo "📄 Python project: pyproject.toml + zobra/"
echo "📄 Generic workflow: .github/workflows/generic-slsa.yml"
echo

# Show key files
print_info "Key project files:"
echo "  - go.mod (triggers Go detection)"
echo "  - pyproject.toml (triggers Python detection)"
echo "  - main.go (Go source)"
echo "  - zobra/ (Python package)"
echo

# Step 2: Simulate the workflow detection logic
print_step "2" "Artifact Type Detection (Simulated)"
echo "The workflow would detect project type as follows:"
echo

if [ -f "go.mod" ]; then
    echo "🔍 Found go.mod → Detected: Go project"
    DETECTED_TYPE="go"
elif [ -f "pyproject.toml" ]; then
    echo "🔍 Found pyproject.toml → Detected: Python project"  
    DETECTED_TYPE="python"
elif [ -f "package.json" ]; then
    echo "🔍 Found package.json → Detected: Node.js project"
    DETECTED_TYPE="nodejs"
else
    echo "🔍 No specific files found → Detected: Generic project"
    DETECTED_TYPE="generic"
fi

print_success "Detected project type: $DETECTED_TYPE"
echo

# Step 3: Show what the build process would do
print_step "3" "Build Process Simulation"
echo "In GitHub Actions, the workflow would:"
echo

case "$DETECTED_TYPE" in
    "go")
        echo "🔧 Setup: Install Go 1.21"
        echo "🏗️  Build commands:"
        echo "   GOOS=linux GOARCH=amd64 go build -o zobra-go-linux-amd64 main.go"
        echo "   GOOS=darwin GOARCH=amd64 go build -o zobra-go-darwin-amd64 main.go"
        echo "   GOOS=windows GOARCH=amd64 go build -o zobra-go-windows-amd64.exe main.go"
        echo "📦 Artifacts: zobra-go-* (cross-platform binaries)"
        ;;
    "python")
        echo "🔧 Setup: Install Python 3.9 + build tools"
        echo "🏗️  Build commands:"
        echo "   python -m pip install --upgrade pip"
        echo "   pip install build"
        echo "   python -m build"
        echo "📦 Artifacts: dist/*.whl, dist/*.tar.gz"
        ;;
esac
echo

# Step 4: Demonstrate local build (to show what artifacts look like)
print_step "4" "Local Build Demonstration"
echo "Let's build the artifacts locally to show what gets generated:"
echo

# Clean up previous builds
rm -f zobra-go-* 2>/dev/null || true
rm -rf dist/ 2>/dev/null || true

if [ "$DETECTED_TYPE" = "go" ]; then
    print_info "Building Go binaries..."
    
    # Build Go binaries
    echo "Building Linux AMD64..."
    GOOS=linux GOARCH=amd64 go build -o zobra-go-linux-amd64 main.go
    
    echo "Building Darwin AMD64..."
    GOOS=darwin GOARCH=amd64 go build -o zobra-go-darwin-amd64 main.go
    
    echo "Building Windows AMD64..."
    GOOS=windows GOARCH=amd64 go build -o zobra-go-windows-amd64.exe main.go
    
    print_success "Go build complete!"
    echo "Generated artifacts:"
    ls -la zobra-go-* | while read line; do echo "  $line"; done
    echo
fi

# Also build Python to show both types
if command -v python3 &> /dev/null; then
    print_info "Building Python package..."
    
    # Install build if not present
    python3 -m pip install build --user --quiet 2>/dev/null || true
    
    # Build Python package
    python3 -m build --quiet 2>/dev/null || {
        print_warning "Python build failed (this is OK for demo)"
    }
    
    if [ -d "dist" ]; then
        print_success "Python build complete!"
        echo "Generated artifacts:"
        ls -la dist/ | while read line; do echo "  $line"; done
        echo
    fi
fi

# Step 5: Show hash generation (critical for SLSA)
print_step "5" "Hash Generation for SLSA Provenance"
echo "SLSA requires SHA256 hashes of all artifacts:"
echo

if [ "$DETECTED_TYPE" = "go" ] && ls zobra-go-* >/dev/null 2>&1; then
    print_info "Generating hashes for Go artifacts:"
    
    # Use shasum on macOS, sha256sum on Linux
    if command -v shasum >/dev/null 2>&1; then
        HASH_CMD="shasum -a 256"
    else
        HASH_CMD="sha256sum"
    fi
    
    $HASH_CMD zobra-go-* | while read hash file; do
        echo "  $file: $hash"
    done
    echo
    
    print_info "Base64-encoded hashes (as required by SLSA generator):"
    if command -v shasum >/dev/null 2>&1; then
        # macOS
        ENCODED_HASHES=$(shasum -a 256 zobra-go-* | base64)
    else
        # Linux
        ENCODED_HASHES=$(sha256sum zobra-go-* | base64 -w0)
    fi
    echo "  $ENCODED_HASHES"
    echo
fi

# Step 6: Show what the SLSA generator would do
print_step "6" "SLSA Provenance Generation (GitHub Actions)"
echo "In GitHub Actions, the workflow calls the official SLSA generator:"
echo

cat << 'EOF'
🔧 SLSA Generator Configuration:
   uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
   with:
     base64-subjects: "${{ needs.build.outputs.hashes }}"
     upload-assets: true
     upload-tag-name: "${{ github.ref_name }}"
     provenance-name: "generic-slsa-provenance-go.intoto.jsonl"

🔐 What the SLSA generator does:
   1. Creates ephemeral signing keys using Sigstore
   2. Generates provenance with build metadata
   3. Signs the provenance cryptographically
   4. Records signature in transparency log
   5. Uploads provenance file to GitHub release
EOF
echo

# Step 7: Show example provenance structure
print_step "7" "SLSA Provenance Structure"
echo "The generated provenance file contains:"
echo

cat << 'EOF'
📄 Example provenance structure (generic-slsa-provenance-go.intoto.jsonl):
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "subject": [
    {
      "name": "zobra-go-linux-amd64",
      "digest": {
        "sha256": "7133cefc1352219ebc7e49b63c5c6d0bfa1d40bf6f1ed54ee1cbc2b30216ec45"
      }
    }
  ],
  "predicate": {
    "builder": {
      "id": "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0"
    },
    "buildType": "https://github.com/slsa-framework/slsa-github-generator/generic@v1",
    "invocation": {
      "configSource": {
        "uri": "git+https://github.com/owner/repo@refs/tags/v1.0.0",
        "digest": {
          "sha1": "abc123..."
        }
      }
    },
    "metadata": {
      "buildInvocationId": "12345-67890",
      "buildStartedOn": "2024-08-14T17:00:00Z",
      "buildFinishedOn": "2024-08-14T17:05:00Z",
      "completeness": {
        "parameters": true,
        "environment": false,
        "materials": false
      },
      "reproducible": false
    }
  }
}
EOF
echo

# Step 8: Show verification process
print_step "8" "SLSA Provenance Verification Process"
echo "To verify the provenance, we use the official slsa-verifier:"
echo

# Check if slsa-verifier is available
if command -v slsa-verifier >/dev/null 2>&1; then
    print_success "slsa-verifier is installed!"
    VERIFIER_VERSION=$(slsa-verifier version 2>/dev/null | head -n1 || echo "unknown")
    echo "Version: $VERIFIER_VERSION"
    echo
    
    print_info "Verification command structure:"
    echo "slsa-verifier verify-artifact [ARTIFACT] \\"
    echo "  --provenance-path [PROVENANCE.intoto.jsonl] \\"
    echo "  --source-uri github.com/owner/repo \\"
    echo "  --source-tag v1.0.0"
    echo
    
    print_info "What slsa-verifier checks:"
    echo "✓ Provenance signature is valid (using Sigstore)"
    echo "✓ Provenance was generated by trusted SLSA builder"
    echo "✓ Artifact hash matches provenance subject"
    echo "✓ Source repository matches expected repository"
    echo "✓ Source tag/branch matches build source"
    echo "✓ Builder identity is correct SLSA generator"
    echo
    
    if [ -f "zobra-python-trusted-provenance.intoto.jsonl" ] && [ -f "zobra-0.1.4-py3-none-any.whl" ]; then
        print_info "Demo: Verifying existing Python artifact..."
        echo "Command: slsa-verifier verify-artifact zobra-0.1.4-py3-none-any.whl \\"
        echo "  --provenance-path zobra-python-trusted-provenance.intoto.jsonl \\"
        echo "  --source-uri github.com/yali-gotllib/zobra-slsa \\"
        echo "  --source-tag py-v0.1.4"
        echo
        
        # Try to verify (might fail due to repository mismatch, but shows the process)
        if slsa-verifier verify-artifact zobra-0.1.4-py3-none-any.whl \
            --provenance-path zobra-python-trusted-provenance.intoto.jsonl \
            --source-uri github.com/yali-gotllib/zobra-slsa \
            --source-tag py-v0.1.4 2>/dev/null; then
            print_success "Verification PASSED! ✅"
        else
            print_warning "Verification failed (expected - demo repository mismatch)"
            echo "In a real scenario with matching repository, this would pass"
        fi
        echo
    fi
    
else
    print_warning "slsa-verifier not installed"
    echo "To install: go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest"
    echo
    
    print_info "When installed, verification would show:"
    cat << 'EOF'
✅ Example successful verification output:
Verified build using builder "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0"
Verifying artifact zobra-go-linux-amd64: PASSED
PASSED: SLSA verification passed
EOF
    echo
fi

# Step 9: Show the complete workflow
print_step "9" "Complete Workflow Summary"
echo "Here's the complete end-to-end process:"
echo

cat << 'EOF'
🔄 Complete SLSA Workflow:

1. 📝 Developer pushes tag (e.g., git tag v1.0.0)
2. 🤖 GitHub Actions triggers generic-slsa.yml workflow
3. 🔍 Workflow detects project type (Go/Python/Node.js/Generic)
4. 🔧 Workflow sets up appropriate build environment
5. 🏗️  Workflow builds artifacts using detected/configured commands
6. 🔐 Workflow generates SHA256 hashes of all artifacts
7. 📋 Workflow calls official SLSA generator with hashes
8. 🔑 SLSA generator creates signed provenance using Sigstore
9. 📤 Workflow uploads artifacts + provenance to GitHub release
10. ✅ User downloads and verifies using slsa-verifier

🛡️  Security Guarantees:
   ✓ Non-forgeable: Provenance signed by trusted SLSA generator
   ✓ Ephemeral: Build runs in fresh, isolated environment  
   ✓ Auditable: All build steps recorded in provenance
   ✓ Verifiable: Anyone can verify using slsa-verifier
   ✓ Transparent: Signatures recorded in public transparency log
EOF
echo

# Step 10: Show verification script usage
print_step "10" "Using the Verification Script"
echo "The verify_generic_slsa.sh script automates the entire verification process:"
echo

print_info "Basic usage:"
echo "./verify_generic_slsa.sh -r owner/repo -t v1.0.0"
echo

print_info "What the script does:"
echo "1. 📥 Downloads artifacts from GitHub Actions"
echo "2. 🔍 Finds provenance files (*.intoto.jsonl)"
echo "3. 🔍 Finds artifact files based on project type"
echo "4. ✅ Verifies each artifact using slsa-verifier"
echo "5. 📊 Reports verification results"
echo

print_info "Example verification output:"
cat << 'EOF'
🔐 Generic SLSA Provenance Verification
==================================================
ℹ️  Repository: owner/repo
ℹ️  Tag: v1.0.0
ℹ️  Artifact Type: go

✅ slsa-verifier found: slsa-verifier version v2.7.1
✅ GitHub CLI found: gh version 2.32.1

📦 Detected Go project (go.mod found)
✅ Using artifact type: go

📥 Downloading artifacts from GitHub Actions...
✅ Found workflow run ID: 12345 (workflow: generic-slsa.yml)
✅ Artifacts downloaded successfully

✅ Found 3 artifact file(s):
./zobra-go-linux-amd64
./zobra-go-darwin-amd64
./zobra-go-windows-amd64.exe

🔐 SLSA Verification Results
==================================================

ℹ️  Verifying artifact: zobra-go-linux-amd64
Verified build using builder "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0"
Verifying artifact zobra-go-linux-amd64: PASSED
PASSED: SLSA verification passed
✅ ✅ VERIFICATION PASSED for zobra-go-linux-amd64

🔐 Verification Summary
==================================================
ℹ️  Total Artifacts: 3
ℹ️  Successful Verifications: 3
✅ 🎉 ALL VERIFICATIONS PASSED!
✅ Supply chain integrity verified for all artifacts
EOF
echo

print_header "Demo Complete!"
print_success "You now understand the complete SLSA provenance generation and verification process!"
echo
print_info "Next steps:"
echo "1. 📤 Push a tag to trigger the workflow: git tag v1.0.0 && git push origin v1.0.0"
echo "2. ⏳ Wait for GitHub Actions to complete the build"
echo "3. ✅ Verify the artifacts: ./verify_generic_slsa.sh -r owner/repo -t v1.0.0"
echo
print_info "The workflow provides SLSA Level 3 security guarantees for any artifact type!"

# Cleanup demo artifacts
print_info "Cleaning up demo artifacts..."
rm -f zobra-go-* 2>/dev/null || true
print_success "Demo cleanup complete!"
