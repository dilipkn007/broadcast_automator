#!/bin/bash
# Helper script to generate release signing keystore and configure key.properties.
set -e

echo "=========================================================="
echo "  Makhanchor Broadcast Automator Keystore Generator  "
echo "=========================================================="
echo

# Prompt for passwords securely
read -s -p "Enter a secure password for your Keystore (min 6 chars): " PASSWORD
echo
if [ ${#PASSWORD} -lt 6 ]; then
  echo "Error: Password must be at least 6 characters."
  exit 1
fi

read -s -p "Confirm Keystore Password: " PASSWORD_CONFIRM
echo
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
  echo "Error: Passwords do not match."
  exit 1
fi

# Get the script directory to run keytool in the android/app/ folder properly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYSTORE_PATH="$SCRIPT_DIR/app/upload-keystore.jks"
PROPERTIES_PATH="$SCRIPT_DIR/key.properties"

# Generate keystore
echo
echo "Generating upload-keystore.jks..."
keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storepass "$PASSWORD" \
  -keypass "$PASSWORD" \
  -dname "CN=Makhanchor Dev, OU=Development, O=Makhanchor, L=Bangalore, S=Karnataka, C=IN"

# Configure key.properties
echo "Updating key.properties..."
cat << EOF > "$PROPERTIES_PATH"
storePassword=$PASSWORD
keyPassword=$PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
EOF

echo
echo "=========================================================="
echo " SUCCESS: Keystore generated and key.properties updated!"
echo " You are now ready to compile your release package."
echo " Run the following command next:"
echo "   flutter build appbundle --release"
echo "=========================================================="
