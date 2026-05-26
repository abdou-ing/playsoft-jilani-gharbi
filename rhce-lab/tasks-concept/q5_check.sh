#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/loop_when.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_loop"]="The playbook does not use 'loop:'. Add a loop: block listing the packages to install."
  ["no_when"]="The playbook does not use a 'when:' condition. Add: when: ansible_facts['distribution'] in ['Ubuntu', 'Debian']"
  ["no_distribution"]="The when condition does not reference 'distribution'. Use ansible_facts['distribution']."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["vim_missing"]="vim is not installed on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["wget_missing"]="wget is not installed on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["git_missing"]="git is not installed on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_loop"]="Le playbook n'utilise pas 'loop:'. Ajoutez un bloc loop: listant les paquets à installer."
  ["no_when"]="Le playbook n'utilise pas de condition 'when:'. Ajoutez : when: ansible_facts['distribution'] in ['Ubuntu', 'Debian']"
  ["no_distribution"]="La condition when ne référence pas 'distribution'. Utilisez ansible_facts['distribution']."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["vim_missing"]="vim n'est pas installé sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["wget_missing"]="wget n'est pas installé sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["git_missing"]="git n'est pas installé sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "loop:" "$pb_path"; then
  echo "$(get_message no_loop)"; exit 0
fi

if ! grep -q "when:" "$pb_path"; then
  echo "$(get_message no_when)"; exit 0
fi

if ! grep -q "distribution" "$pb_path"; then
  echo "$(get_message no_distribution)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible web1 -i "$inventory" -m command -a "dpkg -l vim" 2>/dev/null | grep -q "^ii"; then
  echo "$(get_message vim_missing)"; exit 0
fi

if ! ansible web1 -i "$inventory" -m command -a "dpkg -l wget" 2>/dev/null | grep -q "^ii"; then
  echo "$(get_message wget_missing)"; exit 0
fi

if ! ansible web1 -i "$inventory" -m command -a "dpkg -l git" 2>/dev/null | grep -q "^ii"; then
  echo "$(get_message git_missing)"; exit 0
fi

echo '{"result": "0"}'
