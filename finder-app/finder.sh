#!/bin/sh 

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Error: Missing arguments."
    echo "Usage: $0 <filesdir> <searchstr>"
    exit 1
fi

# Assign input arguments to variables
filesdir=$1
searchstr=$2

# Check if filesdir is a directory
if [ ! -d "$filesdir" ]; then
    echo "Error: $filesdir invalid directory"
    exit 1
fi

# Find files then count matches
file_count=$(find "$filesdir" -type f | wc -l)
matching_line_count=$(grep -r "$searchstr" "$filesdir" 2>/dev/null | wc -l)

echo "The number of files are $file_count and the number of matching lines are $matching_line_count"