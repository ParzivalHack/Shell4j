#!/bin/bash

# Prompt user for a URL
read -p "Enter the URL: " url

# Use curl to retrieve the server type from the HTTP response headers
server_type_header=$(curl -sI "$url" | grep -i "Server:" | awk '{print $2}')

# Use curl to retrieve the HTML content and check for common server identifiers
server_type_html=$(curl -sL "$url" | grep -iE "<meta[^>]*server[^>]*>" | sed -n 's/.*content="\([^"]*\)".*/\1/p')

# Display the results
if [ -n "$server_type_header" ]; then
    echo "Server Type (from header): $server_type_header"
elif [ -n "$server_type_html" ]; then
    echo "Server Type (from HTML): $server_type_html"
else
    echo "Server type not detected."
fi
