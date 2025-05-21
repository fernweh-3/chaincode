#!/bin/bash

# ===================== Check if sourced =====================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "⚠️  This script must be sourced, not executed directly."
  echo "   Use: source $0 [1|2|0]"
  return 1 2>/dev/null || exit 1
fi

# ===================== Input Validation =====================
if [ $# -ne 1 ]; then
  echo ""
  echo "Usage: source $0 [org_number]"
  echo "  1 - Set peer environment for Org1"
  echo "  2 - Set peer environment for Org2"
  echo "  0 - Show current CORE_PEER_LOCALMSPID"
  echo ""
  return 1
fi

# ===================== Org Configs =====================
if [ "$1" -eq 1 ]; then
  echo "🔁 Switching to Org1..."
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
  export CORE_PEER_ADDRESS="localhost:7051"
  return
fi

if [ "$1" -eq 2 ]; then
  echo "🔁 Switching to Org2..."
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
  export CORE_PEER_ADDRESS="localhost:9051"
  return
fi

if [ "$1" -eq 0 ]; then
  echo "👤 Current organization: $CORE_PEER_LOCALMSPID"
  return
fi

# ===================== Invalid Input =====================
echo "❌ Invalid organization number: $1"
echo "Valid options: 1 (Org1), 2 (Org2), 0 (Show current)"
return 1