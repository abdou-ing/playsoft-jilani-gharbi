#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/create_user.yml"


declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["no_user_module"]="The playbook does not use the user module. Add a task with user: name: devops state: present"
  ["no_devops"]="The playbook does not reference the 'devops' user. Check the name: field in your user task."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check $pb_path"
  ["user_missing"]="User 'devops' does not exist on web1. Run the playbook: ansible-playbook $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["no_user_module"]="Le playbook n'utilise pas le module user. Ajoutez une tâche avec user: name: devops state: present"
  ["no_devops"]="Le playbook ne référence pas l'utilisateur 'devops'. Vérifiez le champ name: dans votre tâche user."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check $pb_path"
  ["user_missing"]="L'utilisateur 'devops' n'existe pas sur web1. Exécutez le playbook : ansible-playbook $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! grep -q "user:" "$pb_path"; then
  echo "$(get_message no_user_module)"; exit 0
fi

if ! grep -q "devops" "$pb_path"; then
  echo "$(get_message no_devops)"; exit 0
fi

if ! ansible-playbook --syntax-check "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible web1 -m command -a "id devops" 2>/dev/null | grep -q "uid="; then
  echo "$(get_message user_missing)"; exit 0
fi

echo '{"result": "0"}'
