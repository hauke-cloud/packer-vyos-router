#!/bin/bash
# Download and extract VyOS ISO from GitHub releases

set -e

REPO="hauke-cloud/packer-vyos-router"
DOWNLOAD_DIR="./downloads"

usage() {
    echo "Usage: $0 [version|latest]"
    echo ""
    echo "Download VyOS ISO from GitHub releases"
    echo ""
    echo "Examples:"
    echo "  $0               # Download latest release"
    echo "  $0 latest        # Download latest release"
    echo "  $0 v1.5-rolling-202601221200  # Download specific version"
    exit 1
}

get_latest_release() {
    curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

download_release() {
    local version="$1"
    
    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        echo "Fetching latest release..."
        version=$(get_latest_release)
        if [ -z "$version" ]; then
            echo "Error: Could not determine latest release"
            exit 1
        fi
    fi
    
    echo "Downloading release: $version"
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR"
    
    # Get release info
    echo "Fetching release information..."
    release_data=$(curl -s "https://api.github.com/repos/${REPO}/releases/tags/${version}")
    
    # Extract download URLs
    echo "$release_data" | grep -o 'https://github.com/[^"]*' | while read -r url; do
        filename=$(basename "$url")
        echo "Downloading: $filename"
        curl -L -o "$filename" "$url"
    done
    
    cd ..
    
    echo ""
    echo "✅ Download complete!"
    echo "Files saved to: $DOWNLOAD_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Verify checksums: cd $DOWNLOAD_DIR && sha256sum -c SHA256SUMS"
    echo "  2. Use ISO: Boot from the .iso file"
    echo ""
}

# Parse arguments
VERSION="${1:-latest}"

if [ "$VERSION" = "-h" ] || [ "$VERSION" = "--help" ]; then
    usage
fi

download_release "$VERSION"
