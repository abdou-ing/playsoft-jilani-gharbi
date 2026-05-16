#!/bin/bash

PROJECT_ROOT="/home/jilani/playsoft-jilani-gharbi/playsoft-infra"
TF_OUTPUT="${PROJECT_ROOT}/terraform-k8s/tf_output.json"
ANSIBLE_VARS="${PROJECT_ROOT}/ansible/group_vars/all.yml"

# Helper: read a top-level scalar from all.yml
get_ansible_var() {
  grep "^${1}:" "${ANSIBLE_VARS}" | awk '{print $2}' | tr -d '"' | tr -d "'"
}

# ── Load config ───────────────────────────────────────────────────────────────
BASTION_IP=$(jq -r '.bastion_public_ip.value' "${TF_OUTPUT}")
GUAC_ROUTE=$(get_ansible_var "guac_route")
[ -z "${GUAC_ROUTE}" ] && GUAC_ROUTE="guacamole"

GUAC_URL="http://${BASTION_IP}/${GUAC_ROUTE}"

ADMIN_USER=$(get_ansible_var "auth_username")
ADMIN_PASS=$(get_ansible_var "auth_password")

USER_PREFIX=$(get_ansible_var "user_prefix")
USER_PASS_PREFIX=$(get_ansible_var "user_password_prefix")
CONN_PREFIX=$(get_ansible_var "connection_prefix")
NODE_PREFIX=$(get_ansible_var "exam_node_prefix")

# ── Connection types ──────────────────────────────────────────────────────────
CONN_TYPES=$(grep -A 10 "^connection_type:" "${ANSIBLE_VARS}" \
  | grep -v "^\s*#" \
  | grep -E "^\s*-\s*\"?(vnc|ssh|win)\"?" \
  | sed 's/.*-\s*//' | tr -d '"' | tr -d "'")

IS_VNC=$(echo "${CONN_TYPES}" | grep -q "vnc" && echo "true" || echo "false")
IS_SSH=$(echo "${CONN_TYPES}" | grep -q "ssh" && echo "true" || echo "false")
IS_WIN=$(echo "${CONN_TYPES}" | grep -q "win" && echo "true" || echo "false")

# ── VM counts from Terraform ──────────────────────────────────────────────────
VNC_VM_COUNT=$(jq -r '.vnc_vm_ids.value | length' "${TF_OUTPUT}")
SSH_VM_COUNT=$(jq -r '.ssh_vm_ids.value | length' "${TF_OUTPUT}")
WIN_VM_COUNT=$(jq -r '.windows_vm_ids.value | length' "${TF_OUTPUT}")

# ── Admin token ───────────────────────────────────────────────────────────────
ADMIN_TOKEN=$(curl -s -X POST "${GUAC_URL}/api/tokens" \
  -d "username=${ADMIN_USER}&password=${ADMIN_PASS}" \
  -H "Content-Type: application/x-www-form-urlencoded" | jq -r '.authToken')

if [ "${ADMIN_TOKEN}" = "null" ] || [ -z "${ADMIN_TOKEN}" ]; then
  echo "Error: Failed to obtain admin token"
  exit 1
fi

# ── Fetch all connections once ────────────────────────────────────────────────
CONN_DATA=$(curl -s "${GUAC_URL}/api/session/data/postgresql/connections?token=${ADMIN_TOKEN}")

# Helper: look up connection ID by exact name
get_conn_id() {
  echo "${CONN_DATA}" | jq -r --arg n "$1" \
    'to_entries[] | select(.value.name == $n) | .key'
}

# Helper: build Guacamole client ID (Base64 encoded)
generate_client_id() {
  printf "${1}\0c\0postgresql" | base64 | tr -d '='
}

# ── Single user: candidat1 ────────────────────────────────────────────────────
USERNAME="${USER_PREFIX}1"
PASSWORD="${USER_PASS_PREFIX}1"

TOKEN=$(curl -s -X POST "${GUAC_URL}/api/tokens" \
  -d "username=${USERNAME}&password=${PASSWORD}" \
  -H "Content-Type: application/x-www-form-urlencoded" | jq -r '.authToken')

echo "Obtained token for ${USERNAME}: ${TOKEN}"

# ── Count total connections for this user ─────────────────────────────────────
TOTAL_SESSIONS=0
[ "${IS_VNC}" = "true" ] && TOTAL_SESSIONS=$((TOTAL_SESSIONS + VNC_VM_COUNT))
[ "${IS_SSH}" = "true" ] && TOTAL_SESSIONS=$((TOTAL_SESSIONS + SSH_VM_COUNT))
[ "${IS_WIN}" = "true" ] && TOTAL_SESSIONS=$((TOTAL_SESSIONS + WIN_VM_COUNT))

# ── Print access summary ──────────────────────────────────────────────────────
echo ""
echo "------------------------------------------------"
echo "Access Summary for ${USERNAME}:"
echo "------------------------------------------------"
echo "Homepage:               ${GUAC_URL}/?token=${TOKEN}#/"
echo "------------------------------------------------"

if [ "${TOTAL_SESSIONS}" -gt 2 ]; then
  echo "Sessions:"
fi

if [ "${IS_VNC}" = "true" ]; then
  for i in $(seq 1 "${VNC_VM_COUNT}"); do
    NODE_NAME="${NODE_PREFIX}${i}"
    CONN_NAME="${CONN_PREFIX}-${i}-vnc"
    CID=$(get_conn_id "${CONN_NAME}")
    if [ -n "${CID}" ] && [ "${CID}" != "null" ]; then
      CLIENT_ID=$(generate_client_id "${CID}")
      echo "  VNC (${NODE_NAME}):   ${GUAC_URL}/#/client/${CLIENT_ID}?token=${TOKEN}"
    else
      echo "  VNC (${NODE_NAME}):   [connection '${CONN_NAME}' not found]"
    fi
  done
fi

if [ "${IS_SSH}" = "true" ]; then
  for i in $(seq 1 "${SSH_VM_COUNT}"); do
    NODE_NAME="${NODE_PREFIX}${i}"
    CONN_NAME="${CONN_PREFIX}-${i}-ssh"
    CID=$(get_conn_id "${CONN_NAME}")
    if [ -n "${CID}" ] && [ "${CID}" != "null" ]; then
      CLIENT_ID=$(generate_client_id "${CID}")
      echo "  SSH (${NODE_NAME}):   ${GUAC_URL}/#/client/${CLIENT_ID}?token=${TOKEN}"
    else
      echo "  SSH (${NODE_NAME}):   [connection '${CONN_NAME}' not found]"
    fi
  done
fi

if [ "${IS_WIN}" = "true" ]; then
  for i in $(seq 1 "${WIN_VM_COUNT}"); do
    NODE_NAME="${NODE_PREFIX}${i}"
    CONN_NAME="${CONN_PREFIX}-${i}-win"
    CID=$(get_conn_id "${CONN_NAME}")
    if [ -n "${CID}" ] && [ "${CID}" != "null" ]; then
      CLIENT_ID=$(generate_client_id "${CID}")
      echo "  RDP (${NODE_NAME}):   ${GUAC_URL}/#/client/${CLIENT_ID}?token=${TOKEN}"
    else
      echo "  RDP (${NODE_NAME}):   [connection '${CONN_NAME}' not found]"
    fi
  done
fi

echo "------------------------------------------------"
