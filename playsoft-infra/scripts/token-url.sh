#!/bin/bash
# Paths
PROJECT_ROOT="/home/jilani/playsoft-jilani-gharbi/playsoft-infra"
TF_OUTPUT="${PROJECT_ROOT}/terraform-k8s/tf_output.json"
ANSIBLE_VARS="${PROJECT_ROOT}/ansible/group_vars/all.yml"

# Helper to get Ansible variables
get_ansible_var() {
  grep "^${1}:" "${ANSIBLE_VARS}" | awk '{print $2}' | tr -d '"' | tr -d "'"
}

# Retrieve variables dynamically
BASTION_IP=$(jq -r '.bastion_public_ip.value' "${TF_OUTPUT}")
GUAC_ROUTE=$(get_ansible_var "guac_route")
[ -z "${GUAC_ROUTE}" ] && GUAC_ROUTE="guacamole"

GUAC_URL="http://${BASTION_IP}/${GUAC_ROUTE}/"

# Admin credentials for fetching connection IDs
ADMIN_USER=$(get_ansible_var "auth_username")
ADMIN_PASS=$(get_ansible_var "auth_password")

# Candidate credentials (assuming first user)
USER_PREFIX=$(get_ansible_var "user_prefix")
USER_PASS_PREFIX=$(get_ansible_var "user_password_prefix")
CONN_PREFIX=$(get_ansible_var "connection_prefix")

USERNAME="${USER_PREFIX}1"
PASSWORD="${USER_PASS_PREFIX}1"

# Determine connection types from all.yml to avoid strict errors on disabled types
CONN_TYPES=$(grep -A 10 "^connection_type:" "${ANSIBLE_VARS}" | grep -v "^\s*#" | grep -E "^\s*-\s*\"?(vnc|ssh|win)\"?" | sed 's/.*-\s*//' | tr -d '"' | tr -d "'")
IS_VNC=$(echo "${CONN_TYPES}" | grep -q "vnc" && echo "true" || echo "false")
IS_SSH=$(echo "${CONN_TYPES}" | grep -q "ssh" && echo "true" || echo "false")
IS_WIN=$(echo "${CONN_TYPES}" | grep -q "win" && echo "true" || echo "false")

# Determine which VM families actually exist in Terraform output.
VNC_VM_COUNT=$(jq -r '.vnc_vm_ids.value | length' "${TF_OUTPUT}")
WIN_VM_COUNT=$(jq -r '.windows_vm_ids.value | length' "${TF_OUTPUT}")

HAS_VNC=$( [ "${IS_VNC}" = "true" ] && [ "${VNC_VM_COUNT}" -gt 0 ] && echo "true" || echo "false" )
HAS_SSH=$( [ "${IS_SSH}" = "true" ] && [ "${VNC_VM_COUNT}" -gt 0 ] && echo "true" || echo "false" )
HAS_WIN=$( [ "${IS_WIN}" = "true" ] && [ "${WIN_VM_COUNT}" -gt 0 ] && echo "true" || echo "false" )

# Step 1 — Get admin token to fetch connection IDs
ADMIN_TOKEN=$(curl -s -X POST "${GUAC_URL}/api/tokens" \
  -d "username=${ADMIN_USER}&password=${ADMIN_PASS}" \
  -H "Content-Type: application/x-www-form-urlencoded" | jq -r '.authToken')

if [ "${ADMIN_TOKEN}" = "null" ] || [ -z "${ADMIN_TOKEN}" ]; then
  echo "Error: Failed to obtain admin token"
  exit 1
fi

# Step 2 — Dynamically find Connection IDs
CONN_DATA=$(curl -s "${GUAC_URL}/api/session/data/postgresql/connections?token=${ADMIN_TOKEN}")

declare -A CONN_IDS
for TYPE in vnc ssh win; do
  HAS_TYPE_VAR="HAS_$(echo "${TYPE}" | tr '[:lower:]' '[:upper:]')"
  if [ "${!HAS_TYPE_VAR}" = "true" ]; then
    CONN_IDS["${TYPE}"]=$(echo "${CONN_DATA}" | jq -r --arg name "${CONN_PREFIX}-1-${TYPE}" 'to_entries[] | select(.value.name == $name) | .key')
  fi
done

echo "Detected Connection IDs: VNC=${CONN_IDS[vnc]:-}, SSH=${CONN_IDS[ssh]:-}, WIN=${CONN_IDS[win]:-}"

# Validation: Only fail if an enabled connection type has real backing VMs and still
# does not have a Guacamole connection.
for TYPE in vnc ssh win; do
  HAS_TYPE_VAR="HAS_$(echo "${TYPE}" | tr '[:lower:]' '[:upper:]')"
  if [ "${!HAS_TYPE_VAR}" = "true" ]; then
    if [ -z "${CONN_IDS[${TYPE}]}" ] || [ "${CONN_IDS[${TYPE}]}" = "null" ]; then
      echo "Error: Could not find connection ID for ${CONN_PREFIX}-1-${TYPE} (${TYPE} is enabled)"
      exit 1
    fi
  fi
done

# Step 3 — Get candidate token
TOKEN=$(curl -s -X POST "${GUAC_URL}/api/tokens" \
  -d "username=${USERNAME}&password=${PASSWORD}" \
  -H "Content-Type: application/x-www-form-urlencoded" | jq -r '.authToken')
echo "Obtained token for ${USERNAME}: ${TOKEN}"
# Step 4 — Optional: Initialize tunnels
for TYPE in vnc ssh win; do
  CID="${CONN_IDS[${TYPE}]}"
  if [ ! -z "${CID}" ] && [ "${CID}" != "null" ]; then
    curl -s "${GUAC_URL}/api/tunnel?connect" \
      --data-urlencode "token=${TOKEN}" \
      --data-urlencode "GUAC_DATA_SOURCE=postgresql" \
      --data-urlencode "GUAC_ID=${CID}" \
      --data-urlencode "GUAC_TYPE=c" \
      --data-urlencode "GUAC_WIDTH=1024" \
      --data-urlencode "GUAC_HEIGHT=768" \
      --data-urlencode "GUAC_DPI=96" > /dev/null
  fi
done

# Step 5 — Helper to generate Guacamole Client ID (Base64)
generate_client_id() {
  local id="$1"
  local type="c"
  local source="postgresql"
  printf "${id}\0${type}\0${source}" | base64 | tr -d '='
}

# Step 6 — Generate and print URLs
echo -e "\n------------------------------------------------"
echo "Access Summary for ${USERNAME}:"
echo "------------------------------------------------"

ENABLED_COUNT=0
[ "${HAS_VNC}" = "true" ] && ENABLED_COUNT=$((ENABLED_COUNT + 1))
[ "${HAS_SSH}" = "true" ] && ENABLED_COUNT=$((ENABLED_COUNT + 1))
[ "${HAS_WIN}" = "true" ] && ENABLED_COUNT=$((ENABLED_COUNT + 1))

if [ "${ENABLED_COUNT}" -eq 0 ]; then
  echo "No Guacamole connections are available for the current Terraform output."
  echo "Configured types: ${CONN_TYPES}"
  echo "Terraform counts: vnc_vm_ids=${VNC_VM_COUNT}, windows_vm_ids=${WIN_VM_COUNT}"
  echo "------------------------------------------------"
  exit 0
fi

if [ "${ENABLED_COUNT}" -gt 1 ]; then
  echo "Home page (Global): ${GUAC_URL}/?token=${TOKEN}#/"
fi

[ "${HAS_VNC}" = "true" ] && echo "VNC Session:        ${GUAC_URL}/#/client/$(generate_client_id "${CONN_IDS[vnc]}")?token=${TOKEN}"
[ "${HAS_SSH}" = "true" ] && echo "SSH Session:        ${GUAC_URL}/#/client/$(generate_client_id "${CONN_IDS[ssh]}")?token=${TOKEN}"
[ "${HAS_WIN}" = "true" ] && echo "RDP Session:        ${GUAC_URL}/#/client/$(generate_client_id "${CONN_IDS[win]}")?token=${TOKEN}"
echo "------------------------------------------------"
