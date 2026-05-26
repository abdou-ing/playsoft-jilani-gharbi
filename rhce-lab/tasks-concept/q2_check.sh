#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/loop_vars.yml"
vars_path="/home/ansible_user/workspace/vars/pkglist.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_vars_file"]="Variables file not found at $vars_path. Create it with a 'packages:' list containing name and state entries."
  ["no_packages_key"]="The vars file does not define a 'packages:' list. Use packages: as the top-level key."
  ["no_name_field"]="The vars file entries are missing the 'name:' field. Each package must have name: and state:."
  ["no_state_field"]="The vars file entries are missing the 'state:' field. Each package must have name: and state:."
  ["no_pb_file"]="Playbook not found at $pb_path. Create it using vars_files and loop."
  ["no_vars_files"]="The playbook does not use 'vars_files:'. Load the variables file with vars_files: vars/pkglist.yml"
  ["no_loop"]="The playbook does not use 'loop:'. Add loop: \"{{ packages }}\" to iterate over the variable."
  ["no_item_name"]="The playbook does not reference 'item.name'. Use name: \"{{ item.name }}\" in the package task."
  ["no_item_state"]="The playbook does not reference 'item.state'. Use state: \"{{ item.state }}\" in the package task."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="The playbook failed to run successfully. Check the vars file and playbook content."
)
declare -A messages_fr=(
  ["no_vars_file"]="Fichier de variables introuvable à $vars_path. Créez-le avec une liste 'packages:' contenant des entrées name et state."
  ["no_packages_key"]="Le fichier vars ne définit pas une liste 'packages:'. Utilisez packages: comme clé de niveau supérieur."
  ["no_name_field"]="Les entrées du fichier vars manquent du champ 'name:'. Chaque paquet doit avoir name: et state:."
  ["no_state_field"]="Les entrées du fichier vars manquent du champ 'state:'. Chaque paquet doit avoir name: et state:."
  ["no_pb_file"]="Playbook introuvable à $pb_path. Créez-le avec vars_files et loop."
  ["no_vars_files"]="Le playbook n'utilise pas 'vars_files:'. Chargez le fichier avec vars_files: vars/pkglist.yml"
  ["no_loop"]="Le playbook n'utilise pas 'loop:'. Ajoutez loop: \"{{ packages }}\" pour itérer sur la variable."
  ["no_item_name"]="Le playbook ne référence pas 'item.name'. Utilisez name: \"{{ item.name }}\" dans la tâche package."
  ["no_item_state"]="Le playbook ne référence pas 'item.state'. Utilisez state: \"{{ item.state }}\" dans la tâche package."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="Le playbook a échoué à s'exécuter. Vérifiez le fichier vars et le contenu du playbook."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$vars_path" ]; then
  echo "$(get_message no_vars_file)"; exit 0
fi

if ! grep -q "^packages:" "$vars_path"; then
  echo "$(get_message no_packages_key)"; exit 0
fi

if ! grep -q "name:" "$vars_path"; then
  echo "$(get_message no_name_field)"; exit 0
fi

if ! grep -q "state:" "$vars_path"; then
  echo "$(get_message no_state_field)"; exit 0
fi

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_pb_file)"; exit 0
fi

if ! grep -q "vars_files" "$pb_path"; then
  echo "$(get_message no_vars_files)"; exit 0
fi

if ! grep -q "loop:" "$pb_path"; then
  echo "$(get_message no_loop)"; exit 0
fi

if ! grep -q "item\.name" "$pb_path"; then
  echo "$(get_message no_item_name)"; exit 0
fi

if ! grep -q "item\.state" "$pb_path"; then
  echo "$(get_message no_item_state)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible-playbook -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message run_failed)"; exit 0
fi

echo '{"result": "0"}'
