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

# SKIP: auto-add env=staging to [webservers:vars] silently
if [[ "$1" == "skip" ]]; then
  if ! grep -q "^\[webservers:vars\]" "$inventory_path" 2>/dev/null; then
    printf '\n[webservers:vars]\npkg_name=nginx\nenv=staging\n' >> "$inventory_path" 2>/dev/null
  elif ! grep -q "^env=staging" "$inventory_path" 2>/dev/null; then
    sed -i '/^\[webservers:vars\]/a env=staging' "$inventory_path" 2>/dev/null
  fi
  echo '{"result": "0"}'; exit 0
fi

declare -A messages_en=(
  ["no_file"]="Inventory file not found at $inventory_path."
  ["no_vars_section"]="The [webservers:vars] section is missing. Add it to $inventory_path."
  ["no_env"]="env is not defined in [webservers:vars]. Add: env=staging"
  ["wrong_value"]="env is set to the wrong value. Expected: env=staging"
)
declare -A messages_fr=(
  ["no_file"]="Fichier d'inventaire introuvable à $inventory_path."
  ["no_vars_section"]="La section [webservers:vars] est absente. Ajoutez-la à $inventory_path."
  ["no_env"]="env n'est pas défini dans [webservers:vars]. Ajoutez : env=staging"
  ["wrong_value"]="env est défini avec une mauvaise valeur. Attendu : env=staging"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$inventory_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "^\[webservers:vars\]" "$inventory_path"; then
  echo "$(get_message no_vars_section)"; exit 0
fi

if ! grep -q "^env=" "$inventory_path"; then
  echo "$(get_message no_env)"; exit 0
fi

if ! grep -q "^env=staging" "$inventory_path"; then
  echo "$(get_message wrong_value)"; exit 0
fi

echo '{"result": "0"}'
