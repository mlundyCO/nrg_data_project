#!/bin/sh

# Data retrieved from: https://www.eia.gov/electricity/gridmonitor/sixMonthFiles/EIA930_INTERCHANGE_2023_Jan_Jun.csv
if [ -z "$1" ]; then
    echo "Error: No filename provided."
    echo "Defaulting to EIA930_INTERCHANGE_2023_Jan_Jun.csv"
    filename="EIA930_INTERCHANGE_2023_Jan_Jun.csv"
else
    filename="$1"
fi

# Check if curl is available; exit if not found
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed. Please install curl and try again."
    exit 1
fi

# Download the file if it doesn't already exist
interchange_data_url="https://www.eia.gov/electricity/gridmonitor/sixMonthFiles/$filename"
if [ ! -e "$filename" ]; then
    if ! curl -O "$interchange_data_url"; then
        echo "Error: Failed to download file."
        exit 1
    fi
fi

# Create a backup if one doesn't already exist
if [ ! -e "$filename.bak" ]; then
    cp "$filename" "$filename.bak"
fi

clean_header() {
    sed '1s/["]//g' "$filename" > temp && mv temp "$filename"
    sed '1s/[ ]/_/g' "$filename" > temp && mv temp "$filename"
    sed -E '1s/(\(|\))//g' "$filename" > temp && mv temp "$filename" # Extended RegEx removes parens
}

clean_data() {
    sed -E 's/"(-?[0-9]+),([0-9]+)"/\1\2/g' "$filename" > temp && mv temp "$filename"
    sed -E 's/,,/,0,/g' "$filename" > temp && mv temp "$filename"
}

# Execute the cleaning functions
clean_header
clean_data

# Clean up the temporary file if it exists
[ -e temp ] && rm temp
