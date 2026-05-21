#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/create_file.yml"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["no_copy"]="The playbook does not use the copy module. Use copy: content: dest: /tmp/hello.txt"
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check $pb_path"
  ["no_remote_file"]="/tmp/hello.txt does not exist on web1. Run the playbook: ansible-playbook $pb_path"
  ["wrong_content"]="/tmp/hello.txt exists on web1 but does not contain 'Hello from Ansible'."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["no_copy"]="Le playbook n'utilise pas le module copy. Utilisez copy: content: dest: /tmp/hello.txt"
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check $pb_path"
  ["no_remote_file"]="/tmp/hello.txt n'existe pas sur web1. Exécutez le playbook : ansible-playbook $pb_path"
  ["wrong_content"]="/tmp/hello.txt existe sur web1 mais ne contient pas 'Hello from Ansible'."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! grep -q "copy:" "$pb_path"; then
  echo "$(get_message no_copy)"; exit 0
fi

if ! ansible-playbook --syntax-check "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

file_content=$(ansible web1 -m command -a "cat /tmp/hello.txt" 2>/dev/null)
if ! echo "$file_content" | grep -q "SUCCESS"; then
  echo "$(get_message no_remote_file)"; exit 0
fi

if ! echo "$file_content" | grep -q "Hello from Ansible"; then
  echo "$(get_message wrong_content)"; exit 0
fi

echo '{"result": "0"}'
