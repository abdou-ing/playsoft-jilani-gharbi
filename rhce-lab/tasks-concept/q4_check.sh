#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/register_when.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_register"]="The playbook does not use 'register:'. Capture the command output with register: result."
  ["no_ignore_errors"]="The playbook does not have 'ignore_errors: yes'. Add it to the command task so the play continues if ssh is not active."
  ["no_when"]="The playbook does not use a 'when:' condition. Add when: result.rc == 0 to the debug task."
  ["no_rc"]="The when condition does not check 'result.rc'. Use: when: result.rc == 0"
  ["no_debug"]="The playbook does not have a 'debug:' task to print the status message."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="The playbook failed to run. Check your syntax and make sure ignore_errors: yes is set on the command task."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_register"]="Le playbook n'utilise pas 'register:'. Capturez la sortie avec register: result."
  ["no_ignore_errors"]="Le playbook n'a pas 'ignore_errors: yes'. Ajoutez-le à la tâche command pour que le play continue si ssh n'est pas actif."
  ["no_when"]="Le playbook n'utilise pas de condition 'when:'. Ajoutez when: result.rc == 0 à la tâche debug."
  ["no_rc"]="La condition when ne vérifie pas 'result.rc'. Utilisez : when: result.rc == 0"
  ["no_debug"]="Le playbook n'a pas de tâche 'debug:' pour afficher le message de statut."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="Le playbook a échoué à s'exécuter. Vérifiez la syntaxe et assurez-vous que ignore_errors: yes est défini."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "register:" "$pb_path"; then
  echo "$(get_message no_register)"; exit 0
fi

if ! grep -q "ignore_errors:" "$pb_path"; then
  echo "$(get_message no_ignore_errors)"; exit 0
fi

if ! grep -q "when:" "$pb_path"; then
  echo "$(get_message no_when)"; exit 0
fi

if ! grep -q "result\.rc" "$pb_path"; then
  echo "$(get_message no_rc)"; exit 0
fi

if ! grep -q "debug:" "$pb_path"; then
  echo "$(get_message no_debug)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible-playbook -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message run_failed)"; exit 0
fi

echo '{"result": "0"}'
