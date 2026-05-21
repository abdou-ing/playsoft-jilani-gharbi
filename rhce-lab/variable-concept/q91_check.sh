#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/debug_vars.yml"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["no_debug"]="The playbook does not use the debug module. Add a task with debug: var: pkg_name"
  ["no_pkg_name"]="The playbook does not reference pkg_name. Make sure your debug task prints pkg_name."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check $pb_path"
  ["run_failed"]="The playbook ran but failed. Run it manually: ansible-playbook $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["no_debug"]="Le playbook n'utilise pas le module debug. Ajoutez une tâche avec debug: var: pkg_name"
  ["no_pkg_name"]="Le playbook ne référence pas pkg_name. Assurez-vous que votre tâche debug affiche pkg_name."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check $pb_path"
  ["run_failed"]="Le playbook s'est exécuté mais a échoué. Lancez-le manuellement : ansible-playbook $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! grep -q "debug:" "$pb_path"; then
  echo "$(get_message no_debug)"; exit 0
fi

if ! grep -q "pkg_name" "$pb_path"; then
  echo "$(get_message no_pkg_name)"; exit 0
fi

if ! ansible-playbook --syntax-check "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible-playbook "$pb_path" -q >/dev/null 2>&1; then
  echo "$(get_message run_failed)"; exit 0
fi

echo '{"result": "0"}'
