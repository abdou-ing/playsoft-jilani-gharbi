#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/account_expiry.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_chage"]="The playbook does not call chage. Use the command module: cmd: chage -E 2026-12-31 john"
  ["wrong_expiry"]="John's account expiry is not set to 2026-12-31 on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_chage"]="Le playbook n'appelle pas chage. Utilisez le module command : cmd: chage -E 2026-12-31 john"
  ["wrong_expiry"]="La date d'expiration du compte de john n'est pas définie au 2026-12-31 sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "chage" "$pb_path"; then
  echo "$(get_message no_chage)"; exit 0
fi

chage_output=$(ansible web1 -i "$inventory" -m command -a "chage -l john" --become 2>/dev/null)

if ! echo "$chage_output" | grep -i "Account expires" | grep -q "2026"; then
  echo "$(get_message wrong_expiry)"; exit 0
fi

echo '{"result": "0"}'
