#!/bin/bash
# One-liner installation script for chezmoi-sqlrsync

set -euo pipefail

REPO_URL="https://github.com/pnwmatt/chezmoi-sqlrsyncn"
BRANCH="main"

# Check if chezmoi is installed
if ! command -v chezmoi &> /dev/null; then
    echo "Error: chezmoi is not installed. Please install chezmoi first."
    echo "Visit: https://chezmoi.io/install/"
    exit 1
fi

# Get chezmoi source directory
CHEZMOI_SOURCE_DIR=$(chezmoi source-path)
if [[ ! -d "$CHEZMOI_SOURCE_DIR" ]]; then
    echo "Error: Chezmoi source directory not found: $CHEZMOI_SOURCE_DIR"
    echo "Run 'chezmoi init' first."
    exit 1
fi

echo "Installing SQLRsync integration to: $CHEZMOI_SOURCE_DIR"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Download and extract
echo "Downloading from $REPO_URL..."
curl -sSL "${REPO_URL}/archive/${BRANCH}.tar.gz" | tar -xz -C "$TEMP_DIR"

EXTRACTED_DIR="$TEMP_DIR/chezmoi-sqlrsync-${BRANCH}"

# Copy files
echo "Installing scripts..."
mkdir -p "$CHEZMOI_SOURCE_DIR/scripts/lib"
cp -r "$EXTRACTED_DIR/scripts/"* "$CHEZMOI_SOURCE_DIR/scripts/"

echo "Installing templates..."
mkdir -p "$CHEZMOI_SOURCE_DIR/templates"
cp -r "$EXTRACTED_DIR/templates/"* "$CHEZMOI_SOURCE_DIR/templates/" 2>/dev/null || true

echo "Installing documentation..."
mkdir -p "$CHEZMOI_SOURCE_DIR/docs"
cp -r "$EXTRACTED_DIR/docs/"* "$CHEZMOI_SOURCE_DIR/docs/" 2>/dev/null || true

echo ""
echo "✅ SQLRsync integration installed successfully!"
echo ""
echo "Next steps:"
echo "1. Add SQLRsync configuration to your .chezmoi.toml.tmpl"
echo "2. See examples in: $CHEZMOI_SOURCE_DIR/templates/chezmoi.toml.example"
echo "3. Run: chezmoi apply"
echo ""
echo "Documentation available in: $CHEZMOI_SOURCE_DIR/docs/"