#!/bin/bash

set -e

cd "$(dirname "$0")"

echo "generating audit events..."

export VAULT_ADDR=http://localhost:8200

names=(
    "alice" "bob" "charlie" "david" "emma" "frank" "grace" "hannah" "ivy" "jack"
    "katie" "liam" "mia" "nathan" "olivia" "paul" "quinn" "rachel" "sam" "tina"
    "ursula" "victor" "wendy" "xander" "yara" "zach"
)

for name in "${names[@]}"; do
  export VAULT_TOKEN=$(vault login -token-only -method=userpass username=$name password=$name)
  
  vault kv put kv/users/$name/demo db_user=$RANDOM db_password=$(uuidgen) > /dev/null
  vault kv put kv/users/$name/example api_key=$(uuidgen) > /dev/null

  vault kv list kv/users/$name > /dev/null

  # Loop random number of times
  for ((i = 1; i <= $((RANDOM % 10 + 1)); i++)); do
    vault kv get kv/users/$name/demo > /dev/null
  done

done

for name in "${names[@]}"; do
  export VAULT_TOKEN=$(jq -r .root_token init.json)

  r=$(vault read -field=role_id auth/approle/role/svc-${name:0:1}/role-id)
  s=$(vault write -f -field=secret_id auth/approle/role/svc-${name:0:1}/secret-id)
  
  export VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id=$r secret_id=$s)

  vault kv put kv/svc/svc-${name:0:1}/db db_user=$RANDOM db_password=$RANDOM > /dev/null

  if [ $((RANDOM % 100 + 1)) -le 25 ]; then
    # 25% chance
    vault kv put kv/svc/svc-${name:0:1}/api api_key=$(uuidgen) > /dev/null

    for ((i = 1; i <= $((RANDOM % 10 + 1)); i++)); do
      vault kv get kv/svc/svc-${name:0:1}/api > /dev/null
    done
  fi

  # Loop random number of times
  for ((i = 1; i <= $((RANDOM % 10 + 1)); i++)); do
    vault kv get kv/svc/svc-${name:0:1}/db > /dev/null
  done
done
