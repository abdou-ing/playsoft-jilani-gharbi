#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/failed_when.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_register"]="The playbook does not use 'register:'. Capture the command output with register: command_result."
  ["no_failed_when"]="The playbook does not use 'failed_when:'. Add: failed_when: \"'failed' in command_result.stdout\""
  ["no_ignore_errors"]="The playbook does not have 'ignore_errors: yes'. Add it so the playbook continues after the failed_when triggers."
  ["no_debug"]="The playbook does not have a 'debug:' task after the command. Add a debug task to show the playbook continued."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="The playbook failed unexpectedly. Check that ignore_errors: yes is set on the command task."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_register"]="Le playbook n'utilise pas 'register:'. Capturez la sortie avec register: command_result."
  ["no_failed_when"]="Le playbook n'utilise pas 'failed_when:'. Ajoutez : failed_when: \"'failed' in command_result.stdout\""
  ["no_ignore_errors"]="Le playbook n'a pas 'ignore_errors: yes'. Ajoutez-le pour que le playbook continue après le déclenchement de failed_when."
  ["no_debug"]="Le playbook n'a pas de tâche 'debug:' après la commande. Ajoutez une tâche debug pour montrer que le playbook a continué."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="Le playbook a échoué de manière inattendue. Vérifiez que ignore_errors: yes est défini sur la tâche command."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "register:" "$pb_path"; then
  echo "$(get_message no_register)"; exit 0
fi

if ! grep -q "failed_when:" "$pb_path"; then
  echo "$(get_message no_failed_when)"; exit 0
fi

if ! grep -q "ignore_errors:" "$pb_path"; then
  echo "$(get_message no_ignore_errors)"; exit 0
fi

if ! grep -q "debug:" "$pb_path"; then
  echo "$(get_message no_debug)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

# With ignore_errors: yes the playbook should exit 0 even with failed_when triggering
if ! ansible-playbook -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message run_failed)"; exit 0
fi

echo '{"result": "0"}'
