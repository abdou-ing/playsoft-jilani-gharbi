#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/facts_demo.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_debug"]="The playbook does not use the debug module. Add a debug task that prints ansible_facts['distribution']."
  ["no_distribution"]="The playbook does not reference the distribution fact. Use: msg: \"OS is {{ ansible_facts['distribution'] }}\""
  ["gather_facts_disabled"]="gather_facts: no is set but no setup: task follows it — ansible_facts will be empty. Either remove gather_facts: no or add a setup: task before the debug task."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["undefined_var"]="The playbook ran but distribution is VARIABLE IS NOT DEFINED. Make sure gather_facts is enabled (remove gather_facts: no)."
  ["run_failed"]="The playbook ran but failed. Check the output: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_debug"]="Le playbook n'utilise pas le module debug. Ajoutez une tâche debug qui affiche ansible_facts['distribution']."
  ["no_distribution"]="Le playbook ne référence pas le fait distribution. Utilisez : msg: \"OS is {{ ansible_facts['distribution'] }}\""
  ["gather_facts_disabled"]="gather_facts: no est défini mais aucune tâche setup: ne suit — ansible_facts sera vide. Supprimez gather_facts: no ou ajoutez une tâche setup: avant la tâche debug."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["undefined_var"]="Le playbook s'est exécuté mais distribution est VARIABLE IS NOT DEFINED. Assurez-vous que gather_facts est activé (supprimez gather_facts: no)."
  ["run_failed"]="Le playbook s'est exécuté mais a échoué. Vérifiez la sortie : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "debug:" "$pb_path"; then
  echo "$(get_message no_debug)"; exit 0
fi

if ! grep -q "distribution" "$pb_path"; then
  echo "$(get_message no_distribution)"; exit 0
fi

# Catch gather_facts: no without a following setup: task
if grep -q "gather_facts:[[:space:]]*no" "$pb_path" && ! grep -q "setup:" "$pb_path"; then
  echo "$(get_message gather_facts_disabled)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

run_output=$(ansible-playbook -i "$inventory" "$pb_path" 2>&1)

if echo "$run_output" | grep -q "VARIABLE IS NOT DEFINED"; then
  echo "$(get_message undefined_var)"; exit 0
fi

if echo "$run_output" | grep -q "failed=\s*[^0]"; then
  echo "$(get_message run_failed)"; exit 0
fi

echo '{"result": "0"}'
