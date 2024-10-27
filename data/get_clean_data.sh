#!/bin/bash
# Usage: ./get_clean_data YEAR

# Check if curl is available; exit if not found
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed. Please install curl and try again."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Error: No year provided."
    echo "Defaulting to 2023"
    year="2023"
else
    year="$1"
fi

# work in data dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR

set_filenames() {
    interchange_filename_1="EIA930_INTERCHANGE_${year}_Jan_Jun.csv"
    interchange_filename_2="EIA930_INTERCHANGE_${year}_Jul_Dec.csv"
    balance_filename_1="EIA930_BALANCE_${year}_Jan_Jun.csv"
    balance_filename_2="EIA930_BALANCE_${year}_Jul_Dec.csv"
    filenames=("${interchange_filename_1}" "${interchange_filename_2}" "${balance_filename_1}" "${balance_filename_2}")
}

set_data_urls() {
    url_prefix="https://www.eia.gov/electricity/gridmonitor/sixMonthFiles/"
    interchange_url_1="${url_prefix}${interchange_filename_1}"
    interchange_url_2="${url_prefix}${interchange_filename_2}"
    balance_url_1="${url_prefix}${balance_filename_1}"
    balance_url_2="${url_prefix}${balance_filename_2}"
    urls=("${interchange_url_1}" "${interchange_url_2}" "${balance_url_1}" "${balance_url_2}")
}

download_data() {
    for i in "${!urls[@]}"; do
        if [ ! -e "${filenames[$i]}" ]; then
            if ! curl -O "${urls[$i]}"; then
                echo "Error: Failed to download file ${filenames[$i]}"
                exit 1
            fi
        fi
    done
}

create_copies() {
    for filename in "${filenames[@]}"; do
        if [ ! -e "$filename.clean" ]; then
            echo "Creating file $filename.clean"
            cp "$filename" "$filename.clean"
        fi
    done
}

set_filenames
set_data_urls
download_data
create_copies

clean_headers() {
    for filename in "${filenames[@]}"; do
        echo "Cleaning header of $filename.clean"
        sed '1s/["]//g' "$filename.clean" > temp && mv temp "$filename.clean"
        sed '1s/[ ]/_/g' "$filename.clean" > temp && mv temp "$filename.clean"
        sed -E '1s/(\(|\))//g' "$filename.clean" > temp && mv temp "$filename.clean" # Extended RegEx removes parens
    done
}

clean_data() {
    for filename in "${filenames[@]}"; do
        echo "Cleaning data of $filename.clean"
        # "1,234","1,234,567" -> 1234,1234567
        sed -E 's/"(-?[0-9]+),?([0-9]*),?([0-9]*)"/\1\2\3/g' "$filename.clean" > temp && mv temp "$filename.clean"
    done
}

# Execute the cleaning functions
clean_headers
clean_data

# Clean up the temporary file if it exists
[ -e temp ] && rm temp
