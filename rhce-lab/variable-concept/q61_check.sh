#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/install_pkg.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Write the fixed version there."
  ["no_pkg_name"]="The playbook does not reference pkg_name. Use: name: \"{{ pkg_name }}\""
  ["unquoted"]="The variable reference is still unquoted. Fix: name: \"{{ pkg_name }}\" (double quotes required around {{ }})."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["not_installed"]="curl is not installed on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Écrivez-y la version corrigée."
  ["no_pkg_name"]="Le playbook ne référence pas pkg_name. Utilisez : name: \"{{ pkg_name }}\""
  ["unquoted"]="La référence de variable n'est pas citée. Corrigez : name: \"{{ pkg_name }}\" (guillemets doubles requis autour des {{ }})."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["not_installed"]="curl n'est pas installé sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "pkg_name" "$pb_path"; then
  echo "$(get_message no_pkg_name)"; exit 0
fi

# Detect unquoted {{ pkg_name }} — value that starts with {{ without a leading quote
if grep -qE "name:[[:space:]]+\{\{" "$pb_path"; then
  echo "$(get_message unquoted)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible web1 -i "$inventory" -m command -a "dpkg -l curl" 2>/dev/null | grep -q "^ii"; then
  echo "$(get_message not_installed)"; exit 0
fi

echo '{"result": "0"}'
