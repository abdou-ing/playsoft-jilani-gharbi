#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/vars_demo.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_vars"]="The playbook does not have a vars: section. Add vars: at the play level and define greeting."
  ["no_greeting"]="The greeting variable is not defined in vars:. Add: greeting: 'Hello from Ansible'"
  ["no_debug"]="The playbook does not use the debug module. Add a task with: debug: msg: \"{{ greeting }}\""
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="The playbook ran but failed. Check the output: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_vars"]="Le playbook n'a pas de section vars:. Ajoutez vars: au niveau du jeu et définissez greeting."
  ["no_greeting"]="La variable greeting n'est pas définie dans vars:. Ajoutez : greeting: 'Hello from Ansible'"
  ["no_debug"]="Le playbook n'utilise pas le module debug. Ajoutez une tâche avec : debug: msg: \"{{ greeting }}\""
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="Le playbook s'est exécuté mais a échoué. Vérifiez la sortie : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -qE "^[[:space:]]*vars:" "$pb_path"; then
  echo "$(get_message no_vars)"; exit 0
fi

if ! grep -q "greeting" "$pb_path"; then
  echo "$(get_message no_greeting)"; exit 0
fi

if ! grep -q "debug:" "$pb_path"; then
  echo "$(get_message no_debug)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible-playbook -i "$inventory" "$pb_path" -q >/dev/null 2>&1; then
  echo "$(get_message run_failed)"; exit 0
fi

echo '{"result": "0"}'
