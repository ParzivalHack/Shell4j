#!/bin/bash

# Prompt user for a URL
read -p "Enter the URL: " url

# Extract the domain from the URL
domain=$(echo "$url" | awk -F[/:] '{print $4}')

webserverdomain=$(dig +short "$domain" | awk '!/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/')
# Use dig to retrieve the IP address of the web server
ip_address=$(dig +short "$domain" | tail -n1)

# Use curl to retrieve the web server's port
port=$(curl -sI "$url" | grep -i "location: http" | awk -F: '{print $3}' | tr -d '\r')

# Display the results in a more organized way
echo "Website Information for $url:"
echo "-------------------------------------"
echo "Web Server Domain: $webserverdomain"
echo "Web Server IP Address: $ip_address"
echo "Web Server Port: $port"
echo "-------------------------------------"
