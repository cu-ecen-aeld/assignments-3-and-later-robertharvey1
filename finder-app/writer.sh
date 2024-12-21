#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Error Usage: $0 <filename> <filestr>"
    exit 1
fi

# Get the args
filename=$1
filestr=$2

# Create the directory path if it doesn't exist
mkdir -p "$(dirname "$filename")"

# Write the content to the file, overwriting if it exists
if ! echo "$filestr" > "$filename"; then
    echo "Error creating or updating $filename."
    exit 1
fi

echo "Success : File created"