#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

# Delegate into the control-node container if running on the host
_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

cfg_path="/home/ansible_user/ansible.cfg"
inventory_path="/home/ansible_user/inventory"

declare -A messages_en=(
  # Prerequisites: previous questions must be done before this one can pass
  ["no_cfg"]="ansible.cfg not found at $cfg_path. Complete question 50 first."
  ["no_inventory"]="Inventory file not found at $inventory_path. Complete question 49 first."
  # Ping failure: host-specific messages so the candidate knows exactly which host is down
  ["web1_failed"]="web1 did not respond to ping. Check: SSH key copied to web1 (q48), web1 in inventory (q49), ansible.cfg correct (q50)."
  ["web2_failed"]="web2 did not respond to ping. Check: SSH key copied to web2 (q48), web2 in inventory (q49), ansible.cfg correct (q50)."
  # ansible.cfg read from wrong directory: Ansible picks up ansible.cfg from CWD or ~/.ansible.cfg
  # If the candidate runs ansible from a different directory, Ansible may not find the cfg
  ["cfg_not_loaded"]="ansible.cfg was not loaded. Make sure it is at $cfg_path and run ansible from your home directory."
  # Host unreachable: SSH is not set up or the container is stopped
  ["web1_unreachable"]="web1 is unreachable. Check that the container is running and SSH key was copied: ssh-copy-id ansible_user@web1"
  ["web2_unreachable"]="web2 is unreachable. Check that the container is running and SSH key was copied: ssh-copy-id ansible_user@web2"
  # Auth failure: SSH key not in authorized_keys or wrong remote_user
  ["web1_auth"]="Authentication failed on web1. Check remote_user=ansible_user in ansible.cfg and that the SSH key was copied."
  ["web2_auth"]="Authentication failed on web2. Check remote_user=ansible_user in ansible.cfg and that the SSH key was copied."
)
declare -A messages_fr=(
  ["no_cfg"]="ansible.cfg introuvable dans $cfg_path. Complétez d'abord la question 50."
  ["no_inventory"]="Fichier d'inventaire introuvable dans $inventory_path. Complétez d'abord la question 49."
  ["web1_failed"]="web1 n'a pas répondu au ping. Vérifiez : clé SSH copiée vers web1 (q48), web1 dans l'inventaire (q49), ansible.cfg correct (q50)."
  ["web2_failed"]="web2 n'a pas répondu au ping. Vérifiez : clé SSH copiée vers web2 (q48), web2 dans l'inventaire (q49), ansible.cfg correct (q50)."
  ["cfg_not_loaded"]="ansible.cfg n'a pas été chargé. Assurez-vous qu'il se trouve dans $cfg_path et lancez ansible depuis votre répertoire home."
  ["web1_unreachable"]="web1 est injoignable. Vérifiez que le conteneur tourne et que la clé SSH a été copiée : ssh-copy-id ansible_user@web1"
  ["web2_unreachable"]="web2 est injoignable. Vérifiez que le conteneur tourne et que la clé SSH a été copiée : ssh-copy-id ansible_user@web2"
  ["web1_auth"]="Échec d'authentification sur web1. Vérifiez remote_user=ansible_user dans ansible.cfg et que la clé SSH a bien été copiée."
  ["web2_auth"]="Échec d'authentification sur web2. Vérifiez remote_user=ansible_user dans ansible.cfg et que la clé SSH a bien été copiée."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

# CHECK 1 — ansible.cfg must exist (prerequisite: q50)
# Catches: candidate skipped q50 or created the file in the wrong location
if [ ! -f "$cfg_path" ]; then
  echo "$(get_message no_cfg)"; exit 0
fi

# CHECK 2 — inventory file must exist (prerequisite: q49)
# Catches: candidate skipped q49 or named the inventory file incorrectly
if [ ! -f "$inventory_path" ]; then
  echo "$(get_message no_inventory)"; exit 0
fi

# Run ansible ping from the ansible_user home directory so ansible.cfg is picked up correctly
# Captures both stdout and stderr to parse the full output
result=$(cd /home/ansible_user && ansible all -m ping 2>&1)

# CHECK 3 — ansible.cfg must have been loaded
# Catches: candidate ran ansible from a different CWD, or ansible.cfg is malformed
if echo "$result" | grep -q "No config file found"; then
  echo "$(get_message cfg_not_loaded)"; exit 0
fi

# CHECK 4 — web1 must not be unreachable
# Catches: SSH not set up, container stopped, wrong hostname in inventory
if echo "$result" | grep -q "web1 | UNREACHABLE"; then
  echo "$(get_message web1_unreachable)"; exit 0
fi

# CHECK 5 — web2 must not be unreachable
if echo "$result" | grep -q "web2 | UNREACHABLE"; then
  echo "$(get_message web2_unreachable)"; exit 0
fi

# CHECK 6 — web1 must not have an authentication failure
# Catches: SSH key not in authorized_keys, wrong remote_user in ansible.cfg
if echo "$result" | grep -q "web1 | FAILED" && echo "$result" | grep -q "Authentication failed\|Permission denied"; then
  echo "$(get_message web1_auth)"; exit 0
fi

# CHECK 7 — web2 must not have an authentication failure
if echo "$result" | grep -q "web2 | FAILED" && echo "$result" | grep -q "Authentication failed\|Permission denied"; then
  echo "$(get_message web2_auth)"; exit 0
fi

# CHECK 8 — web1 must respond with SUCCESS
# Final confirmation that ping completed successfully for web1
if ! echo "$result" | grep -q "web1 | SUCCESS"; then
  echo "$(get_message web1_failed)"; exit 0
fi

# CHECK 9 — web2 must respond with SUCCESS
# Final confirmation that ping completed successfully for web2
if ! echo "$result" | grep -q "web2 | SUCCESS"; then
  echo "$(get_message web2_failed)"; exit 0
fi

echo '{"result": "0"}'
