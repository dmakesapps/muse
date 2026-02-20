#!/bin/bash

# Define the target directory
TARGET_DIR="."

echo "Starting permission fix with cat..."

# Find all files in the current directory and subdirectories
find "$TARGET_DIR" -type f | while read -r file; do
    # check if file has extended attributes
    if xattr -l "$file" | grep -q "com.apple.macl"; then
        echo "Fixing $file..."
        
        # Use cat to strip attributes
        cat "$file" > "$file.tmp"
        
        # Check if copy was successful
        if [ $? -eq 0 ]; then
            # Delete original file
            rm "$file"
            
            # Move temporary file to original name
            mv "$file.tmp" "$file"
            
            echo "Fixed $file"
        else
            echo "Failed to copy $file"
            rm "$file.tmp" 2>/dev/null
        fi
    fi
done

echo "Permission fix complete."
