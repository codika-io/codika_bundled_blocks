#!/bin/bash

# Define source and destination directories with absolute paths from home directory
SOURCE_DIR="$HOME/.codika/codika_blocks/blocks"
BASE_BUNDLES_DIR="$HOME/.codika/codika_bundled_blocks"
VERSIONS_DIR="$BASE_BUNDLES_DIR/versions"
LATEST_LINK="$BASE_BUNDLES_DIR/latest"

# Generate version timestamp (format: YYYY-MM-DD_HH-MM-SS)
VERSION_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DEST_DIR="$VERSIONS_DIR/$VERSION_TIMESTAMP"

# Create necessary directories
mkdir -p "$VERSIONS_DIR"
mkdir -p "$DEST_DIR"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory $SOURCE_DIR does not exist"
    exit 1
fi

# Create a manifest file with timestamp and other metadata
cat > "$DEST_DIR/manifest.json" << EOF
{
    "version": "$VERSION_TIMESTAMP",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "blocks": []
}
EOF

# Loop through all directories in the source directory
for brick_dir in "$SOURCE_DIR"/*/ ; do
    if [ -d "$brick_dir" ]; then
        # Get the brick name (last part of the path)
        brick_name=$(basename "$brick_dir")
        echo "Bundling brick: $brick_name"
        
        # Bundle the brick
        mason bundle "$brick_dir" -o "$DEST_DIR"
        
        if [ $? -eq 0 ]; then
            echo "Successfully bundled $brick_name"
            # Add block to manifest
            tmp=$(mktemp)
            jq ".blocks += [\"$brick_name\"]" "$DEST_DIR/manifest.json" > "$tmp" && mv "$tmp" "$DEST_DIR/manifest.json"
        else
            echo "Error bundling $brick_name"
        fi
    fi
done

# Update the "latest" symlink
rm -f "$LATEST_LINK"
ln -s "$DEST_DIR" "$LATEST_LINK"

# Keep only the last 5 versions (adjust number as needed)
cd "$VERSIONS_DIR"
ls -t | tail -n +6 | xargs -r rm -rf

echo "Bundling complete!"
echo "New version created: $VERSION_TIMESTAMP"
echo "Access latest version at: $LATEST_LINK"
