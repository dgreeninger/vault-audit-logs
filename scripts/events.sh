#!/bin/bash

set -e

cd "$(dirname "$0")"

echo "generating audit events..."

export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=$(jq -r .root_token init.json)

vault auth enable userpass > /dev/null || true
vault auth enable approle > /dev/null || true
vault secrets enable -version=2 kv > /dev/null || true
vault secrets enable database > /dev/null || true

for i in {1..20}; do
  vault write auth/userpass/users/$i password=$i > /dev/null
  vault write -f auth/approle/role/$i > /dev/null
done

for i in {1..20}; do
  unset VAULT_TOKEN
  vault login -method=userpass username=$i password=$i > /dev/null 2>&1

  r=$(vault read -field=role_id auth/approle/role/$i/role-id)
  s=$(vault write -f -field=secret_id auth/approle/role/$i/secret-id)
  vault write auth/approle/login role_id=$r secret_id=$s > /dev/null

  vault kv put kv/$i/db db_user=$RANDOM db_password=$RANDOM > /dev/null
  vault kv list kv/$i > /dev/null
  vault kv get kv/$i/db > /dev/null
  vault kv metadata delete kv/$i/db > /dev/null
done
