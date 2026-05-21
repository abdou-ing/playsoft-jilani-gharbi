#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

inventory_path="/home/ansible_user/inventory"

declare -A messages_en=(
  ["no_file"]="Inventory file not found at $inventory_path. Create it first."
  ["no_vars_section"]="The [webservers:vars] section is missing from $inventory_path. Add it below [webservers]."
  ["no_pkg_name"]="pkg_name is not defined in [webservers:vars]. Add: pkg_name=nginx"
  ["wrong_value"]="pkg_name is set to the wrong value. Expected: pkg_name=nginx"
)
declare -A messages_fr=(
  ["no_file"]="Fichier d'inventaire introuvable à $inventory_path. Créez-le d'abord."
  ["no_vars_section"]="La section [webservers:vars] est absente de $inventory_path. Ajoutez-la sous [webservers]."
  ["no_pkg_name"]="pkg_name n'est pas défini dans [webservers:vars]. Ajoutez : pkg_name=nginx"
  ["wrong_value"]="pkg_name est défini avec une mauvaise valeur. Attendu : pkg_name=nginx"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$inventory_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "^\[webservers:vars\]" "$inventory_path"; then
  echo "$(get_message no_vars_section)"; exit 0
fi

if ! grep -q "^pkg_name=" "$inventory_path"; then
  echo "$(get_message no_pkg_name)"; exit 0
fi

if ! grep -q "^pkg_name=nginx" "$inventory_path"; then
  echo "$(get_message wrong_value)"; exit 0
fi

echo '{"result": "0"}'
