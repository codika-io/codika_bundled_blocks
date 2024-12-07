#!/bin/bash

# Define base paths
BASE_DIR="../"  # Relative to script location
ARCHIVES_DIR="$BASE_DIR/archives"
LATEST_DIR="$BASE_DIR/latest"
SOURCE_DIR="$HOME/.codika/codika_blocks/blocks"  # Keep this absolute as it's the source

# Create necessary directories
mkdir -p "$ARCHIVES_DIR"
mkdir -p "$LATEST_DIR"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory $SOURCE_DIR does not exist"
    exit 1
fi

# Generate version timestamp (format: YYYY-MM-DD_HH-MM-SS)
VERSION_TIMESTAMP=$(date -u +"%Y-%m-%d_%H-%M-%S")

# If there's an existing latest version, archive it and remove latest directory
if [ -f "$LATEST_DIR/manifest.json" ]; then
    OLD_VERSION=$(jq -r '.version' "$LATEST_DIR/manifest.json")
    if [ ! -z "$OLD_VERSION" ]; then
        mv "$LATEST_DIR" "$ARCHIVES_DIR/$OLD_VERSION"
    fi
fi

# Remove latest directory if it exists and create a fresh one
rm -rf "$LATEST_DIR"
mkdir -p "$LATEST_DIR"

# Create a fresh manifest file with current timestamp
cat > "$LATEST_DIR/manifest.json" << EOF
{
    "version": "$VERSION_TIMESTAMP",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%S") UTC",
    "blocks": []
}
EOF

# Loop through all directories in the source directory
for brick_dir in "$SOURCE_DIR"/*/ ; do
    if [ -d "$brick_dir" ]; then
        brick_name=$(basename "$brick_dir")
        echo "Bundling brick: $brick_name"
        
        # Bundle the brick
        mason bundle "$brick_dir" -o "$LATEST_DIR"
        
        if [ $? -eq 0 ]; then
            echo "Successfully bundled $brick_name"
            # Add block to manifest
            tmp=$(mktemp)
            jq ".blocks += [\"$brick_name\"]" "$LATEST_DIR/manifest.json" > "$tmp" && mv "$tmp" "$LATEST_DIR/manifest.json"
        else
            echo "Error bundling $brick_name"
        fi
    fi
done

# Keep only the last 5 archives (adjust number as needed)
cd "$ARCHIVES_DIR"
ls -t | tail -n +6 | xargs -r rm -rf

echo "Bundling complete!"
echo "New version created: $VERSION_TIMESTAMP"
echo "Bundles available in: $LATEST_DIR"
