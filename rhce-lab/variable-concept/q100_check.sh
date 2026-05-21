#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/motd.yml"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_all"]="The playbook does not target 'all'. Set hosts: all to run on every managed host."
  ["no_copy"]="The playbook does not use the copy module. Use copy: content: dest: /etc/motd"
  ["no_motd_dest"]="The copy task does not target /etc/motd. Set dest: /etc/motd"
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check $pb_path"
  ["no_motd_file"]="/etc/motd does not exist on web1. Run the playbook: ansible-playbook $pb_path"
  ["wrong_content"]="/etc/motd on web1 does not contain 'Managed by Ansible'. Check the content: value in your copy task."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_all"]="Le playbook ne cible pas 'all'. Définissez hosts: all pour s'exécuter sur chaque hôte géré."
  ["no_copy"]="Le playbook n'utilise pas le module copy. Utilisez copy: content: dest: /etc/motd"
  ["no_motd_dest"]="La tâche copy ne cible pas /etc/motd. Définissez dest: /etc/motd"
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check $pb_path"
  ["no_motd_file"]="/etc/motd n'existe pas sur web1. Exécutez le playbook : ansible-playbook $pb_path"
  ["wrong_content"]="/etc/motd sur web1 ne contient pas 'Managed by Ansible'. Vérifiez la valeur content: dans votre tâche copy."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "hosts: all" "$pb_path"; then
  echo "$(get_message no_all)"; exit 0
fi

if ! grep -q "copy:" "$pb_path"; then
  echo "$(get_message no_copy)"; exit 0
fi

if ! grep -q "/etc/motd" "$pb_path"; then
  echo "$(get_message no_motd_dest)"; exit 0
fi

if ! ansible-playbook --syntax-check "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

motd_result=$(ansible web1 -m command -a "cat /etc/motd" 2>/dev/null)
if ! echo "$motd_result" | grep -q "SUCCESS"; then
  echo "$(get_message no_motd_file)"; exit 0
fi

if ! echo "$motd_result" | grep -q "Managed by Ansible"; then
  echo "$(get_message wrong_content)"; exit 0
fi

echo '{"result": "0"}'
