#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/handler_demo.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_notify"]="The playbook does not use 'notify:'. Add notify: write_log to the copy task."
  ["no_handlers"]="The playbook does not have a 'handlers:' section. Define the handler at the end of the play."
  ["no_copy"]="The playbook does not use the 'copy:' module. Use copy: with src: and dest: to transfer the file."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["no_dest_file"]="/tmp/handler_dest.txt does not exist on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["no_log_file"]="/tmp/handler.log does not exist on web1. The handler may not have been triggered — make sure the copy task produces a 'changed' status (delete /tmp/handler_dest.txt on web1 and re-run)."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_notify"]="Le playbook n'utilise pas 'notify:'. Ajoutez notify: write_log à la tâche copy."
  ["no_handlers"]="Le playbook n'a pas de section 'handlers:'. Définissez le handler à la fin du play."
  ["no_copy"]="Le playbook n'utilise pas le module 'copy:'. Utilisez copy: avec src: et dest: pour transférer le fichier."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["no_dest_file"]="/tmp/handler_dest.txt n'existe pas sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["no_log_file"]="/tmp/handler.log n'existe pas sur web1. Le handler n'a peut-être pas été déclenché — assurez-vous que la tâche copy produit le statut 'changed' (supprimez /tmp/handler_dest.txt sur web1 et relancez)."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "notify:" "$pb_path"; then
  echo "$(get_message no_notify)"; exit 0
fi

if ! grep -q "handlers:" "$pb_path"; then
  echo "$(get_message no_handlers)"; exit 0
fi

if ! grep -q "copy:" "$pb_path"; then
  echo "$(get_message no_copy)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

# Remove dest file on web1 to guarantee changed status and handler triggers
ansible web1 -i "$inventory" -m file -a "path=/tmp/handler_dest.txt state=absent" &>/dev/null || true
ansible web1 -i "$inventory" -m file -a "path=/tmp/handler.log state=absent" &>/dev/null || true

ansible-playbook -i "$inventory" "$pb_path" &>/dev/null || true

if ! ansible web1 -i "$inventory" -m stat -a "path=/tmp/handler_dest.txt" 2>/dev/null | grep -q '"exists": true'; then
  echo "$(get_message no_dest_file)"; exit 0
fi

if ! ansible web1 -i "$inventory" -m stat -a "path=/tmp/handler.log" 2>/dev/null | grep -q '"exists": true'; then
  echo "$(get_message no_log_file)"; exit 0
fi

echo '{"result": "0"}'
