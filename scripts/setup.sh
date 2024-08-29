#!/bin/bash

set -e 

cd "$(dirname "$0")"

echo "initializing vault..."
export VAULT_ADDR=http://localhost:8200
vault operator init -key-shares=1 -key-threshold=1 -format=json > init.json

sleep 0.5

echo "unsealing vault..."
export VAULT_UNSEAL=$(jq -r .unseal_keys_b64[0] init.json)
export VAULT_TOKEN=$(jq -r .root_token init.json)
vault operator unseal $VAULT_UNSEAL > /dev/null

sleep 0.5

echo "enabling audit logs..."
vault audit enable socket address=filebeat:9090 socket_type=tcp > /dev/null

sleep 0.5

echo "creating secrets engines..."
vault auth enable userpass > /dev/null
vault auth enable approle > /dev/null
vault secrets enable -version=2 kv > /dev/null
vault secrets enable database > /dev/null

sleep 0.5

echo "creating sample userpass/approle ..."
names=(
    "alice" "bob" "charlie" "david" "emma" "frank" "grace" "hannah" "ivy" "jack"
    "katie" "liam" "mia" "nathan" "olivia" "paul" "quinn" "rachel" "sam" "tina"
    "ursula" "victor" "wendy" "xander" "yara" "zach"
)

vault policy write example - > /dev/null <<EOF
path "*" {
  capabilities = ["create","read","update","list","delete"]
}
EOF

for name in "${names[@]}"; do
  vault write auth/userpass/users/$name password=$name token_policies=example > /dev/null
  vault write -f auth/approle/role/svc-${name:0:1} token_policies=example > /dev/null
done
