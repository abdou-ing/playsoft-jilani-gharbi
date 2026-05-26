#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/fail_demo.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_fail_module"]="The playbook does not use the 'fail:' module. Add a task using fail: with msg: and a when: condition."
  ["no_fail_msg"]="The fail task does not have a 'msg:' field. Add a descriptive message: msg: \"Host does not meet requirements.\""
  ["no_when"]="The fail task does not have a 'when:' condition. Add when: to make the fail conditional — otherwise it always fails."
  ["no_distribution"]="The when condition does not reference 'distribution'. Use ansible_facts['distribution'] to check the OS."
  ["no_debug"]="The playbook does not have a 'debug:' task to confirm success. Add a debug task after the fail task."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="The playbook failed to run. If the fail module triggered, check your when: condition — on Ubuntu hosts the fail task should be skipped."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_fail_module"]="Le playbook n'utilise pas le module 'fail:'. Ajoutez une tâche avec fail: ayant msg: et une condition when:."
  ["no_fail_msg"]="La tâche fail n'a pas de champ 'msg:'. Ajoutez un message descriptif : msg: \"L'hôte ne répond pas aux exigences.\""
  ["no_when"]="La tâche fail n'a pas de condition 'when:'. Ajoutez when: pour rendre le fail conditionnel — sinon il échoue toujours."
  ["no_distribution"]="La condition when ne référence pas 'distribution'. Utilisez ansible_facts['distribution'] pour vérifier l'OS."
  ["no_debug"]="Le playbook n'a pas de tâche 'debug:' pour confirmer le succès. Ajoutez une tâche debug après la tâche fail."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["run_failed"]="Le playbook a échoué à s'exécuter. Si le module fail s'est déclenché, vérifiez votre condition when: — sur les hôtes Ubuntu la tâche fail doit être passée."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "^[[:space:]]*fail:" "$pb_path"; then
  echo "$(get_message no_fail_module)"; exit 0
fi

if ! grep -q "msg:" "$pb_path"; then
  echo "$(get_message no_fail_msg)"; exit 0
fi

if ! grep -q "when:" "$pb_path"; then
  echo "$(get_message no_when)"; exit 0
fi

if ! grep -q "distribution" "$pb_path"; then
  echo "$(get_message no_distribution)"; exit 0
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
