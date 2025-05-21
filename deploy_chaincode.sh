#!/bin/bash

set -e

echo "📦 Hyperledger Fabric Chaincode Deployment"

# Prompt with defaults
read -p "Chaincode name (e.g. global_variables): " CC_NAME
read -p "Chaincode version (e.g. 1.0): " CC_VERSION
read -p "Chaincode folder name (inside current directory): " FOLDER_NAME

# Derived values
CHANNEL_NAME="mychannel"
LABEL="${CC_NAME}_${CC_VERSION}"
PACKAGE_FILE="${CC_NAME}.tar.gz"
CC_SRC_PATH="./${FOLDER_NAME}"

echo "📁 Using chaincode path: $CC_SRC_PATH"
echo "📡 Channel: $CHANNEL_NAME"

# Step 1: Vendor and Package
echo "📚 Vendoring Go dependencies..."
pushd "$CC_SRC_PATH" > /dev/null
GO111MODULE=on go mod vendor
if [ ! -d "vendor" ]; then
  echo "❌ Vendor directory not found in $CC_SRC_PATH. Please run 'go mod vendor' first."
  exit 1
fi
popd > /dev/null

# Ensure peer binary and config are available
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../config

cd ../test-network/
# package the chaincode
echo "⏳ Packaging chaincode..."
peer lifecycle chaincode package "$PACKAGE_FILE" \
  --path "$CC_SRC_PATH" \
  --lang golang \
  --label "$LABEL"

# Set environment for Org1 as admin
echo "🔧 Operating as Org1..."
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_ADDRESS=localhost:7051

# Step 2: Install on Org1
peer lifecycle chaincode install "$PACKAGE_FILE"

# Step 3: Query package ID (on Org1)
echo "🔍 Getting package ID..."
INSTALLED_INFO=$(peer lifecycle chaincode queryinstalled)
PACKAGE_ID=$(echo "$INSTALLED_INFO" | grep "$LABEL" | awk -F 'Package ID: |, Label:' '{print $2}')
echo "📦 Package ID: $PACKAGE_ID"

# Step 4: Approve chaincode definition for Org1
peer lifecycle chaincode approveformyorg \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --channelID "$CHANNEL_NAME" \
  --name "$CC_NAME" \
  --version "$CC_VERSION" \
  --package-id "$PACKAGE_ID" \
  --sequence 1 \
  --tls \
  --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

# Set environment for Org2
echo "🔧 Operating as Org2..."
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
export CORE_PEER_ADDRESS=localhost:9051
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

# Step 5: Install on Org2
peer lifecycle chaincode install "$PACKAGE_FILE"

# Step 6: Approve a chaincode definition for Org2
peer lifecycle chaincode approveformyorg \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --channelID "$CHANNEL_NAME" \
  --name "$CC_NAME" \
  --version "$CC_VERSION" \
  --package-id "$PACKAGE_ID" \
  --sequence 1 \
  --tls \
  --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"


# Step 7: Check readiness
echo "🔍 Checking commit readiness..."
peer lifecycle chaincode checkcommitreadiness \
  --channelID "$CHANNEL_NAME" \
  --name "$CC_NAME" \
  --version "$CC_VERSION" \
  --sequence 1 \
  --tls \
  --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
  --output json

# Step 8: Commit
echo "🚀 Committing chaincode..."
peer lifecycle chaincode commit \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --channelID "$CHANNEL_NAME" \
  --name "$CC_NAME" \
  --version "$CC_VERSION" \
  --sequence 1 \
  --tls \
  --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
  --peerAddresses localhost:9051 \
  --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

# Step 9: Query committed
echo "📘 Querying committed chaincode..."
peer lifecycle chaincode querycommitted \
  --channelID "$CHANNEL_NAME" \
  --name "$CC_NAME"

echo "✅ Chaincode '$CC_NAME' version '$CC_VERSION' successfully deployed on '$CHANNEL_NAME'."