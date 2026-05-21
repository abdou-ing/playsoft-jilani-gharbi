#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/when_demo.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_webservers"]="The playbook does not target 'webservers'. Set: hosts: webservers"
  ["no_when"]="The playbook has no when: directive. Add: when: ansible_os_family == \"Debian\" to the install task."
  ["no_os_family"]="The when: condition does not check ansible_os_family. Use: when: ansible_os_family == \"Debian\""
  ["no_tree"]="The playbook does not install the 'tree' package. Set: name: tree in the package task."
  ["no_become"]="The playbook is missing become: yes. Package installation requires root privileges."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["not_installed"]="tree is not installed on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez : hosts: webservers"
  ["no_when"]="Le playbook n'a pas de directive when:. Ajoutez : when: ansible_os_family == \"Debian\" à la tâche d'installation."
  ["no_os_family"]="La condition when: ne vérifie pas ansible_os_family. Utilisez : when: ansible_os_family == \"Debian\""
  ["no_tree"]="Le playbook n'installe pas le paquet 'tree'. Définissez : name: tree dans la tâche package."
  ["no_become"]="Le playbook n'a pas become: yes. L'installation de paquets nécessite les droits root."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["not_installed"]="tree n'est pas installé sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! grep -q "when:" "$pb_path"; then
  echo "$(get_message no_when)"; exit 0
fi

if ! grep -q "ansible_os_family" "$pb_path"; then
  echo "$(get_message no_os_family)"; exit 0
fi

if ! grep -q "tree" "$pb_path"; then
  echo "$(get_message no_tree)"; exit 0
fi

if ! grep -q "become:" "$pb_path"; then
  echo "$(get_message no_become)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible web1 -i "$inventory" -m command -a "dpkg -l tree" 2>/dev/null | grep -q "^ii"; then
  echo "$(get_message not_installed)"; exit 0
fi

echo '{"result": "0"}'
