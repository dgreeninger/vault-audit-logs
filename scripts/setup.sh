#!/bin/bash

set -e 

cd "$(dirname "$0")"

echo "initializing vault..."
export VAULT_ADDR=http://localhost:8200
vault operator init -key-shares=1 -key-threshold=1 -format=json > init.json

sleep 1

echo "unsealing vault..."
export VAULT_UNSEAL=$(jq -r .unseal_keys_b64[0] init.json)
export VAULT_TOKEN=$(jq -r .root_token init.json)
vault operator unseal $VAULT_UNSEAL > /dev/null

sleep 1

echo "enabling audit logs..."
vault audit enable socket address=filebeat:9090 socket_type=tcp > /dev/null
