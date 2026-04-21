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
CONN_TYPES=$(grep -A 5 "^connection_type:" "${ANSIBLE_VARS}" | grep -E "^\s*-\s*\"?(vnc|ssh)\"?" | sed 's/.*-\s*//' | tr -d '"' | tr -d "'")
IS_VNC=$(echo "${CONN_TYPES}" | grep -q "vnc" && echo "true" || echo "false")
IS_SSH=$(echo "${CONN_TYPES}" | grep -q "ssh" && echo "true" || echo "false")

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

CONN_ID_1=$(echo "${CONN_DATA}" | jq -r --arg name "${CONN_PREFIX}-1-vnc" 'to_entries[] | select(.value.name == $name) | .key')
CONN_ID_2=$(echo "${CONN_DATA}" | jq -r --arg name "${CONN_PREFIX}-1-ssh" 'to_entries[] | select(.value.name == $name) | .key')

echo "Detected Connection IDs: VNC=${CONN_ID_1}, SSH=${CONN_ID_2}"

# Validation: Only fail if an ENABLED connection is missing its ID
if [ "${IS_VNC}" = "true" ]; then
    if [ -z "${CONN_ID_1}" ] || [ "${CONN_ID_1}" = "null" ]; then
        echo "Error: Could not find connection ID for ${CONN_PREFIX}-1-vnc (VNC is enabled)"
        exit 1
    fi
fi

if [ "${IS_SSH}" = "true" ]; then
    if [ -z "${CONN_ID_2}" ] || [ "${CONN_ID_2}" = "null" ]; then
        echo "Error: Could not find connection ID for ${CONN_PREFIX}-1-ssh (SSH is enabled)"
        exit 1
    fi
fi

# Step 3 — Get candidate token
TOKEN=$(curl -s -X POST "${GUAC_URL}/api/tokens" \
  -d "username=${USERNAME}&password=${PASSWORD}" \
  -H "Content-Type: application/x-www-form-urlencoded" | jq -r '.authToken')
 echo "Obtained token for ${USERNAME}: ${TOKEN}"
# Step 4 — Optional: Initialize tunnels
for CID in "${CONN_ID_1}" "${CONN_ID_2}"; do
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

if [ "${IS_VNC}" = "true" ] && [ "${IS_SSH}" = "true" ]; then
  echo "Home page (Global): ${GUAC_URL}/?token=${TOKEN}#/"
  echo "VNC Session:        ${GUAC_URL}/#/client/$(generate_client_id "${CONN_ID_1}")?token=${TOKEN}"
  echo "SSH Session:        ${GUAC_URL}/#/client/$(generate_client_id "${CONN_ID_2}")?token=${TOKEN}"
elif [ "${IS_VNC}" = "true" ]; then
  echo "Direct VNC URL:     ${GUAC_URL}/#/client/$(generate_client_id "${CONN_ID_1}")?token=${TOKEN}"
elif [ "${IS_SSH}" = "true" ]; then
  echo "Direct SSH URL:     ${GUAC_URL}/#/client/$(generate_client_id "${CONN_ID_2}")?token=${TOKEN}"
fi
echo "------------------------------------------------"