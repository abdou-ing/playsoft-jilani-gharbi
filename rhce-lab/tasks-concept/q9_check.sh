#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/block_rescue.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_block"]="The playbook does not have a 'block:' section. Group your tasks under a block: key."
  ["no_rescue"]="The playbook does not have a 'rescue:' section. Add a rescue: section to handle block failures."
  ["no_always"]="The playbook does not have an 'always:' section. Add an always: section for tasks that must always run."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["no_rescue_file"]="/tmp/rescue_output.txt does not exist on web1. Run the playbook: ansible-playbook -i $inventory $pb_path. The rescue section should create this file."
  ["wrong_rescue_content"]="/tmp/rescue_output.txt on web1 does not contain 'rescued'. Make sure the rescue shell task writes 'rescued' to the file."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_block"]="Le playbook n'a pas de section 'block:'. Regroupez vos tâches sous une clé block:."
  ["no_rescue"]="Le playbook n'a pas de section 'rescue:'. Ajoutez une section rescue: pour gérer les échecs du block."
  ["no_always"]="Le playbook n'a pas de section 'always:'. Ajoutez une section always: pour les tâches qui doivent toujours s'exécuter."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["no_rescue_file"]="/tmp/rescue_output.txt n'existe pas sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path. La section rescue doit créer ce fichier."
  ["wrong_rescue_content"]="/tmp/rescue_output.txt sur web1 ne contient pas 'rescued'. Assurez-vous que la tâche shell de rescue écrit 'rescued' dans le fichier."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "block:" "$pb_path"; then
  echo "$(get_message no_block)"; exit 0
fi

if ! grep -q "rescue:" "$pb_path"; then
  echo "$(get_message no_rescue)"; exit 0
fi

if ! grep -q "always:" "$pb_path"; then
  echo "$(get_message no_always)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

# Remove rescue file to ensure playbook runs fresh
ansible web1 -i "$inventory" -m file -a "path=/tmp/rescue_output.txt state=absent" &>/dev/null || true

# Run playbook — block will fail, rescue should create the file; playbook exits 0 (rescue handles the error)
ansible-playbook -i "$inventory" "$pb_path" &>/dev/null || true

rescue_result=$(ansible web1 -i "$inventory" -m command -a "cat /tmp/rescue_output.txt" 2>/dev/null)

if ! echo "$rescue_result" | grep -q "SUCCESS"; then
  echo "$(get_message no_rescue_file)"; exit 0
fi

if ! echo "$rescue_result" | grep -q "rescued"; then
  echo "$(get_message wrong_rescue_content)"; exit 0
fi

echo '{"result": "0"}'
