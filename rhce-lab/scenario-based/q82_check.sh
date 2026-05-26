#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/password_policy.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_chage"]="The playbook does not call chage. Use the command module: cmd: chage -M 90 -W 7 john"
  ["wrong_max"]="John's maximum password age is not 90 days on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["wrong_warn"]="John's password warning period is not 7 days on web1. Ensure your chage command includes -W 7."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_chage"]="Le playbook n'appelle pas chage. Utilisez le module command : cmd: chage -M 90 -W 7 john"
  ["wrong_max"]="L'âge maximum du mot de passe de john n'est pas 90 jours sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["wrong_warn"]="La période d'avertissement du mot de passe de john n'est pas 7 jours sur web1. Assurez-vous que votre commande chage inclut -W 7."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "chage" "$pb_path"; then
  echo "$(get_message no_chage)"; exit 0
fi

chage_output=$(ansible web1 -i "$inventory" -m command -a "chage -l john" --become 2>/dev/null)

max_days=$(echo "$chage_output" | grep -i "Maximum number" | grep -oE '[0-9]+$')
warn_days=$(echo "$chage_output" | grep -i "warning" | grep -oE '[0-9]+$')

if [ "$max_days" != "90" ]; then
  echo "$(get_message wrong_max)"; exit 0
fi

if [ "$warn_days" != "7" ]; then
  echo "$(get_message wrong_warn)"; exit 0
fi

echo '{"result": "0"}'
