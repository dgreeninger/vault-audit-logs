#!/bin/bash

set -e

cd "$(dirname "$0")"

echo "generating audit events..."

export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=$(jq -r .root_token init.json)

vault auth enable userpass > /dev/null
vault auth enable approle > /dev/null

vault secrets enable -version=2 kv > /dev/null
vault secrets enable database > /dev/null

# kv secrets
vault kv put kv/app01/db db_user=example db_password=$RANDOM > /dev/null
vault kv put kv/app01/api api_key=$RANDOM > /dev/null
