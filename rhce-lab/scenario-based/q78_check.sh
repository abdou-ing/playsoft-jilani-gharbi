#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/onboard_john.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_user_module"]="The playbook does not use the 'user' module. Use ansible.builtin.user with name: john."
  ["no_become"]="The playbook is missing 'become: yes'. Managing users requires privilege escalation."
  ["no_john"]="User 'john' does not exist on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["wrong_shell"]="john exists on web1 but his shell is not /bin/bash. Add shell: /bin/bash to your user task."
  ["no_home"]="john exists on web1 but has no home directory. Add create_home: yes to your user task."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_user_module"]="Le playbook n'utilise pas le module 'user'. Utilisez ansible.builtin.user avec name: john."
  ["no_become"]="Le playbook n'a pas 'become: yes'. La gestion des utilisateurs nécessite une élévation de privilèges."
  ["no_john"]="L'utilisateur 'john' n'existe pas sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["wrong_shell"]="john existe sur web1 mais son shell n'est pas /bin/bash. Ajoutez shell: /bin/bash à votre tâche user."
  ["no_home"]="john existe sur web1 mais n'a pas de répertoire home. Ajoutez create_home: yes à votre tâche user."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "user:" "$pb_path" && ! grep -q "ansible.builtin.user" "$pb_path"; then
  echo "$(get_message no_user_module)"; exit 0
fi

if ! grep -q "become" "$pb_path"; then
  echo "$(get_message no_become)"; exit 0
fi

result=$(ansible web1 -i "$inventory" -m command -a "getent passwd john" --become 2>/dev/null)
if ! echo "$result" | grep -q "rc=0"; then
  echo "$(get_message no_john)"; exit 0
fi

if ! echo "$result" | grep -q "/bin/bash"; then
  echo "$(get_message wrong_shell)"; exit 0
fi

if ! echo "$result" | grep -q "/home/john"; then
  echo "$(get_message no_home)"; exit 0
fi

echo '{"result": "0"}'
