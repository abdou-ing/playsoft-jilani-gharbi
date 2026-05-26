#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/force_handler.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_force_handlers"]="The playbook does not set 'force_handlers: yes'. Add it to the play header to ensure handlers run even when a task fails."
  ["no_notify"]="The playbook does not use 'notify:'. The first task must notify the handler."
  ["no_handlers"]="The playbook does not have a 'handlers:' section. Define the mark_done handler at the end of the play."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["no_log_file"]="/tmp/handler_forced.log does not exist on web1. Run the playbook — the handler should write this file even though the second task fails: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_force_handlers"]="Le playbook ne définit pas 'force_handlers: yes'. Ajoutez-le dans l'en-tête du play pour que les handlers s'exécutent même en cas d'échec d'une tâche."
  ["no_notify"]="Le playbook n'utilise pas 'notify:'. La première tâche doit notifier le handler."
  ["no_handlers"]="Le playbook n'a pas de section 'handlers:'. Définissez le handler mark_done à la fin du play."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["no_log_file"]="/tmp/handler_forced.log n'existe pas sur web1. Exécutez le playbook — le handler doit écrire ce fichier même si la deuxième tâche échoue : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -qE "force_handlers:\s*(yes|true)" "$pb_path"; then
  echo "$(get_message no_force_handlers)"; exit 0
fi

if ! grep -q "notify:" "$pb_path"; then
  echo "$(get_message no_notify)"; exit 0
fi

if ! grep -q "handlers:" "$pb_path"; then
  echo "$(get_message no_handlers)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

# Remove existing artifacts so the copy task triggers a changed status
ansible web1 -i "$inventory" -m file -a "path=/tmp/force_copy.txt state=absent" &>/dev/null || true
ansible web1 -i "$inventory" -m file -a "path=/tmp/handler_forced.log state=absent" &>/dev/null || true

# Run the playbook — expected to fail on the second task but handler should still run
ansible-playbook -i "$inventory" "$pb_path" &>/dev/null || true

if ! ansible web1 -i "$inventory" -m stat -a "path=/tmp/handler_forced.log" 2>/dev/null | grep -q '"exists": true'; then
  echo "$(get_message no_log_file)"; exit 0
fi

echo '{"result": "0"}'
