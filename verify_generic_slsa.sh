#!/bin/bash

# Generic SLSA Verification Script
# This script can verify SLSA provenance for any artifact type using slsa-verifier
# Supports Go binaries, Python packages, Node.js packages, and generic artifacts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
REPO=""
TAG=""
ARTIFACT_TYPE="auto"
ARTIFACT_PATH=""
PROVENANCE_PATH=""
SOURCE_BRANCH="main"
DOWNLOAD_ARTIFACTS=true
VERIFY_ONLY=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_header() {
    echo -e "${PURPLE}🔐 $1${NC}"
    echo "=================================================="
}

# Function to show usage
show_usage() {
    cat << EOF
Generic SLSA Verification Script

Usage: $0 [OPTIONS]

OPTIONS:
    -r, --repo REPO              Repository in format owner/repo (required)
    -t, --tag TAG               Tag to verify (required)
    -a, --artifact-type TYPE    Artifact type: auto, go, python, nodejs, generic (default: auto)
    -p, --artifact-path PATH    Path to artifact file (for verify-only mode)
    -s, --provenance-path PATH  Path to provenance file (for verify-only mode)
    -b, --source-branch BRANCH  Source branch name (default: main)
    -n, --no-download          Skip downloading artifacts (verify existing files)
    -v, --verify-only          Only verify, don't download (requires -p and -s)
    -h, --help                 Show this help message

EXAMPLES:
    # Auto-detect and verify Go project
    $0 -r owner/repo -t go-v1.0.0

    # Verify Python package
    $0 -r owner/repo -t py-v0.1.0 -a python

    # Verify existing artifacts without downloading
    $0 -r owner/repo -t v1.0.0 -v -p ./artifact.bin -s ./provenance.intoto.jsonl

    # Verify with custom branch
    $0 -r owner/repo -t v1.0.0 -b develop

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -a|--artifact-type)
            ARTIFACT_TYPE="$2"
            shift 2
            ;;
        -p|--artifact-path)
            ARTIFACT_PATH="$2"
            shift 2
            ;;
        -s|--provenance-path)
            PROVENANCE_PATH="$2"
            shift 2
            ;;
        -b|--source-branch)
            SOURCE_BRANCH="$2"
            shift 2
            ;;
        -n|--no-download)
            DOWNLOAD_ARTIFACTS=false
            shift
            ;;
        -v|--verify-only)
            VERIFY_ONLY=true
            DOWNLOAD_ARTIFACTS=false
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$REPO" ] || [ -z "$TAG" ]; then
    print_error "Repository and tag are required"
    show_usage
    exit 1
fi

if [ "$VERIFY_ONLY" = true ] && ([ -z "$ARTIFACT_PATH" ] || [ -z "$PROVENANCE_PATH" ]); then
    print_error "Verify-only mode requires both --artifact-path and --provenance-path"
    show_usage
    exit 1
fi

print_header "Generic SLSA Provenance Verification"
print_status "Repository: $REPO"
print_status "Tag: $TAG"
print_status "Artifact Type: $ARTIFACT_TYPE"
print_status "Source Branch: $SOURCE_BRANCH"
echo

# Check prerequisites
print_status "Checking prerequisites..."

# Check if slsa-verifier is installed
if ! command -v slsa-verifier &> /dev/null; then
    print_error "slsa-verifier is not installed"
    echo "Please install it with:"
    echo "  go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest"
    echo "Or download from: https://github.com/slsa-framework/slsa-verifier/releases"
    exit 1
fi

SLSA_VERIFIER_VERSION=$(slsa-verifier version 2>/dev/null | head -n1 || echo "unknown")
print_success "slsa-verifier found: $SLSA_VERIFIER_VERSION"

# Check if GitHub CLI is available (only if downloading)
if [ "$DOWNLOAD_ARTIFACTS" = true ]; then
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is required for downloading artifacts"
        echo "Please install it from: https://cli.github.com/"
        exit 1
    fi
    
    GH_VERSION=$(gh version | head -n1 || echo "unknown")
    print_success "GitHub CLI found: $GH_VERSION"
fi

echo

# Function to detect artifact type from repository
detect_artifact_type() {
    if [ "$ARTIFACT_TYPE" != "auto" ]; then
        echo "$ARTIFACT_TYPE"
        return
    fi
    
    print_status "Auto-detecting artifact type from repository..."
    
    # Create temporary directory for detection
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone just the files we need for detection
    if git clone --depth 1 --branch "$TAG" "https://github.com/$REPO.git" . 2>/dev/null; then
        if [ -f "go.mod" ]; then
            echo "go"
        elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ]; then
            echo "python"
        elif [ -f "package.json" ]; then
            echo "nodejs"
        else
            echo "generic"
        fi
    else
        print_warning "Could not clone repository for detection, using generic"
        echo "generic"
    fi
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
}

# Function to download artifacts from GitHub Actions
download_artifacts() {
    local artifact_type="$1"
    
    print_status "Downloading artifacts from GitHub Actions..."
    
    # Find the latest successful workflow run for the tag
    print_status "Finding workflow run for tag $TAG..."
    
    # Try different workflow names based on artifact type
    local workflow_names=()
    case "$artifact_type" in
        "go")
            workflow_names=("generic-slsa.yml" "go-slsa-generic.yml" "go-slsa-build.yml")
            ;;
        "python")
            workflow_names=("generic-slsa.yml" "python-slsa-trusted.yml" "release.yml")
            ;;
        "nodejs")
            workflow_names=("generic-slsa.yml" "nodejs-slsa.yml" "release.yml")
            ;;
        *)
            workflow_names=("generic-slsa.yml" "release.yml")
            ;;
    esac
    
    local run_id=""
    local workflow_used=""
    
    for workflow in "${workflow_names[@]}"; do
        print_status "Checking workflow: $workflow"
        run_id=$(gh run list --repo "$REPO" --workflow="$workflow" --status="success" --limit=10 --json databaseId,headBranch,headSha --jq ".[] | select(.headBranch == \"$TAG\" or .headSha != null) | .databaseId" | head -n1)
        
        if [ -n "$run_id" ] && [ "$run_id" != "null" ]; then
            workflow_used="$workflow"
            break
        fi
    done
    
    if [ -z "$run_id" ] || [ "$run_id" = "null" ]; then
        print_error "No successful workflow runs found for tag $TAG"
        print_status "Available workflows:"
        gh run list --repo "$REPO" --limit=5 --json workflowName,status,conclusion,headBranch --jq '.[] | "\(.workflowName): \(.status)/\(.conclusion) (branch: \(.headBranch))"'
        exit 1
    fi
    
    print_success "Found workflow run ID: $run_id (workflow: $workflow_used)"
    
    # Download artifacts
    print_status "Downloading artifacts..."
    
    # List available artifacts
    print_status "Available artifacts:"
    gh run view "$run_id" --repo "$REPO" --json artifacts --jq '.artifacts[] | "\(.name) (\(.sizeInBytes) bytes)"'
    
    # Download all artifacts from the run
    gh run download "$run_id" --repo "$REPO" || {
        print_error "Failed to download artifacts"
        exit 1
    }
    
    print_success "Artifacts downloaded successfully"
    
    # List downloaded files
    print_status "Downloaded files:"
    find . -name "*.intoto.jsonl" -o -name "*.whl" -o -name "*.tar.gz" -o -name "*.tgz" -o -name "zobra-go-*" -o -name "*.exe" | head -20
}

# Function to find artifacts and provenance files
find_files() {
    local artifact_type="$1"
    
    print_status "Finding artifact and provenance files..."
    
    # Find provenance file
    local provenance_files=($(find . -name "*.intoto.jsonl" 2>/dev/null))
    
    if [ ${#provenance_files[@]} -eq 0 ]; then
        print_error "No provenance files (*.intoto.jsonl) found"
        return 1
    elif [ ${#provenance_files[@]} -gt 1 ]; then
        print_warning "Multiple provenance files found:"
        printf '%s\n' "${provenance_files[@]}"
        print_status "Using the first one: ${provenance_files[0]}"
    fi
    
    PROVENANCE_PATH="${provenance_files[0]}"
    print_success "Provenance file: $PROVENANCE_PATH"
    
    # Find artifact files based on type
    local artifact_files=()
    case "$artifact_type" in
        "go")
            artifact_files=($(find . -name "zobra-go-*" -type f 2>/dev/null))
            ;;
        "python")
            artifact_files=($(find . -name "*.whl" -o -name "*.tar.gz" 2>/dev/null | grep -v "\.intoto\."))
            ;;
        "nodejs")
            artifact_files=($(find . -name "*.tgz" 2>/dev/null))
            ;;
        *)
            # For generic, try to find any non-provenance files
            artifact_files=($(find . -type f ! -name "*.intoto.jsonl" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -10))
            ;;
    esac
    
    if [ ${#artifact_files[@]} -eq 0 ]; then
        print_error "No artifact files found for type: $artifact_type"
        print_status "Available files:"
        find . -type f | head -20
        return 1
    fi
    
    print_success "Found ${#artifact_files[@]} artifact file(s):"
    printf '%s\n' "${artifact_files[@]}"
    
    # Store all artifact files for verification
    ARTIFACT_FILES=("${artifact_files[@]}")
}

# Function to verify a single artifact
verify_artifact() {
    local artifact_file="$1"
    local provenance_file="$2"
    
    print_status "Verifying artifact: $(basename "$artifact_file")"
    
    # Construct slsa-verifier command
    local cmd="slsa-verifier verify-artifact"
    cmd="$cmd \"$artifact_file\""
    cmd="$cmd --provenance-path \"$provenance_file\""
    cmd="$cmd --source-uri github.com/$REPO"
    
    # Use source-tag if tag looks like a version, otherwise use source-branch
    if [[ "$TAG" =~ ^v[0-9] ]] || [[ "$TAG" =~ ^[0-9] ]]; then
        cmd="$cmd --source-tag \"$TAG\""
    else
        cmd="$cmd --source-branch \"$SOURCE_BRANCH\""
    fi
    
    print_status "Running: $cmd"
    echo
    
    # Execute verification
    if eval "$cmd"; then
        print_success "✅ VERIFICATION PASSED for $(basename "$artifact_file")"
        return 0
    else
        print_error "❌ VERIFICATION FAILED for $(basename "$artifact_file")"
        return 1
    fi
}

# Main execution
main() {
    # Detect artifact type if needed
    if [ "$VERIFY_ONLY" = false ]; then
        DETECTED_TYPE=$(detect_artifact_type)
        if [ "$ARTIFACT_TYPE" = "auto" ]; then
            ARTIFACT_TYPE="$DETECTED_TYPE"
        fi
        print_success "Using artifact type: $ARTIFACT_TYPE"
        echo
    fi
    
    # Download artifacts if needed
    if [ "$DOWNLOAD_ARTIFACTS" = true ]; then
        download_artifacts "$ARTIFACT_TYPE"
        echo
        
        # Find artifact and provenance files
        find_files "$ARTIFACT_TYPE"
        echo
    else
        # Use provided paths for verify-only mode
        if [ "$VERIFY_ONLY" = true ]; then
            ARTIFACT_FILES=("$ARTIFACT_PATH")
            print_success "Using provided artifact: $ARTIFACT_PATH"
            print_success "Using provided provenance: $PROVENANCE_PATH"
        else
            find_files "$ARTIFACT_TYPE"
        fi
        echo
    fi
    
    # Verify all artifacts
    print_header "SLSA Verification Results"
    
    local success_count=0
    local total_count=${#ARTIFACT_FILES[@]}
    
    for artifact_file in "${ARTIFACT_FILES[@]}"; do
        if verify_artifact "$artifact_file" "$PROVENANCE_PATH"; then
            ((success_count++))
        fi
        echo
    done
    
    # Summary
    print_header "Verification Summary"
    print_status "Repository: github.com/$REPO"
    print_status "Tag: $TAG"
    print_status "Artifact Type: $ARTIFACT_TYPE"
    print_status "Total Artifacts: $total_count"
    print_status "Successful Verifications: $success_count"
    
    if [ "$success_count" -eq "$total_count" ]; then
        print_success "🎉 ALL VERIFICATIONS PASSED!"
        print_success "Supply chain integrity verified for all artifacts"
        exit 0
    else
        print_error "Some verifications failed ($((total_count - success_count))/$total_count)"
        exit 1
    fi
}

# Run main function
main "$@"
