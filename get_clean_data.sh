#!/bin/bash

# Data retrieved from: https://www.eia.gov/electricity/gridmonitor/sixMonthFiles/EIA930_INTERCHANGE_2023_Jan_Jun.csv
filename="EIA930_INTERCHANGE_2023_Jan_Jun.csv"

#TODO POSIX compliance

# Download the file and make backup if we don't already have it
interchange_data_url="https://www.eia.gov/electricity/gridmonitor/sixMonthFiles/$filename"
if [ ! -e "$filename" ]; then
    wget "$interchange_data_url"
fi

if [ ! -e "$filename.bak" ]; then
    cp "$filename" "$filename.bak"
fi

# Remove double quotes from first line
sed -i '1s/["]//g' "$filename"
# Replace spaces in first line with underscores
sed -i '1s/[ ]/_/g' "$filename"
# Delete parenthesis
sed -i -E '1s/(\(|\))//g' "$filename"

# Remove quotes and commas from interchange MW amounts over one thousand
sed -i -E 's/"(-?[0-9]+),([0-9]+)"/\1\2/g' "$filename"
# Change empty data (,,) from interchange MW amounts to 0
sed -i -E 's/,,/,0,/g' "$filename"
