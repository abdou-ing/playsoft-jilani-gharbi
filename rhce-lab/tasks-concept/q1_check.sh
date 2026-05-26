#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/loop_install.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_loop"]="The playbook does not use 'loop:'. Add a loop: block listing the packages to install."
  ["no_item"]="The playbook does not reference '{{ item }}'. Use name: \"{{ item }}\" in the package task."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["curl_missing"]="curl is not installed on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["tree_missing"]="tree is not installed on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_loop"]="Le playbook n'utilise pas 'loop:'. Ajoutez un bloc loop: listant les paquets à installer."
  ["no_item"]="Le playbook ne référence pas '{{ item }}'. Utilisez name: \"{{ item }}\" dans la tâche package."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["curl_missing"]="curl n'est pas installé sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["tree_missing"]="tree n'est pas installé sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "loop:" "$pb_path"; then
  echo "$(get_message no_loop)"; exit 0
fi

if ! grep -q "item" "$pb_path"; then
  echo "$(get_message no_item)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible web1 -i "$inventory" -m command -a "dpkg -l curl" 2>/dev/null | grep -q "^ii"; then
  echo "$(get_message curl_missing)"; exit 0
fi

if ! ansible web1 -i "$inventory" -m command -a "dpkg -l tree" 2>/dev/null | grep -q "^ii"; then
  echo "$(get_message tree_missing)"; exit 0
fi

echo '{"result": "0"}'
