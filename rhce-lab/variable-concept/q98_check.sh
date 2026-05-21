#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/check_disk.yml"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["no_register"]="The playbook is missing 'register: disk_info'. Add it to the command task."
  ["wrong_var"]="The register variable must be named 'disk_info'. Found a different name."
  ["no_debug"]="The playbook does not use the debug module. Add a debug task to print disk_info."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check $pb_path"
  ["run_failed"]="The playbook failed to run. Check: ansible-playbook $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["no_register"]="Le playbook manque 'register: disk_info'. Ajoutez-le à la tâche command."
  ["wrong_var"]="La variable register doit s'appeler 'disk_info'. Un nom différent a été trouvé."
  ["no_debug"]="Le playbook n'utilise pas le module debug. Ajoutez une tâche debug pour afficher disk_info."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check $pb_path"
  ["run_failed"]="Le playbook a échoué à l'exécution. Vérifiez : ansible-playbook $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! grep -q "register:" "$pb_path"; then
  echo "$(get_message no_register)"; exit 0
fi

if ! grep -q "disk_info" "$pb_path"; then
  echo "$(get_message wrong_var)"; exit 0
fi

if ! grep -q "debug:" "$pb_path"; then
  echo "$(get_message no_debug)"; exit 0
fi

if ! ansible-playbook --syntax-check "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible-playbook "$pb_path" -q >/dev/null 2>&1; then
  echo "$(get_message run_failed)"; exit 0
fi

echo '{"result": "0"}'
