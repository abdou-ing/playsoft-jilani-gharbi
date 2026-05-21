#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/multi_task.yml"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check $pb_path"
  ["no_service"]="nginx is not running on web1. Make sure the service task uses state: started."
  ["no_index"]="/var/www/html/index.html does not exist on web1. Check the copy task destination."
  ["wrong_content"]="/var/www/html/index.html does not contain 'Welcome'. Check the copy task content."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check $pb_path"
  ["no_service"]="nginx ne fonctionne pas sur web1. Assurez-vous que la tâche service utilise state: started."
  ["no_index"]="/var/www/html/index.html n'existe pas sur web1. Vérifiez la destination de la tâche copy."
  ["wrong_content"]="/var/www/html/index.html ne contient pas 'Welcome'. Vérifiez le contenu de la tâche copy."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! ansible-playbook --syntax-check "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible web1 -m command -a "systemctl is-active nginx" 2>/dev/null | grep -q "active"; then
  echo "$(get_message no_service)"; exit 0
fi

index_result=$(ansible web1 -m command -a "cat /var/www/html/index.html" 2>/dev/null)
if ! echo "$index_result" | grep -q "SUCCESS"; then
  echo "$(get_message no_index)"; exit 0
fi

if ! echo "$index_result" | grep -q "Welcome"; then
  echo "$(get_message wrong_content)"; exit 0
fi

echo '{"result": "0"}'
