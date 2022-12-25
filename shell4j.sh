#!/bin/bash

# Prompt the user for a URL
read -p "Enter a URL: " URL

# Use cURL to fetch the contents of the URL
CONTENTS=$(curl -s "$URL")

# Check if the log4j configuration is exposed in the contents
if grep -q "log4j\.configuration" <<< "$CONTENTS"; then
  echo "Vulnerability detected: log4j configuration is exposed"
  echo "Exploitation: An attacker may be able to modify the log4j configuration to gain access to sensitive information or execute arbitrary code."
else
  echo "No log4j vulnerabilities detected"
fi

# Check if log4j is vulnerable to log injection
if grep -q "log4j\.appender\.FILE\.Threshold" <<< "$CONTENTS"; then
  echo "Vulnerability detected: log4j is vulnerable to log injection"
  echo "Exploitation: An attacker may be able to inject malicious log entries that can execute arbitrary code or compromise sensitive information."
fi

# Check if log4j is vulnerable to log forging
if grep -q "log4j\.appender\.FILE\.layout\.ConversionPattern" <<< "$CONTENTS"; then
  echo "Vulnerability detected: log4j is vulnerable to log forging"
  echo "Exploitation: An attacker may be able to forge log entries to hide their activity or manipulate log data."
fi
