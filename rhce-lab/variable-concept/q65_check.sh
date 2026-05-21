#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_inventory"]="Inventory file not found at $inventory. Create it first with webservers and dbservers groups."
  ["no_children_section"]="The [all_servers:children] section is missing from the inventory. Append it below your existing groups."
  ["no_webservers_child"]="webservers is not listed under [all_servers:children]. Add it so all_servers inherits the webservers hosts."
  ["no_dbservers_child"]="dbservers is not listed under [all_servers:children]. Add it so all_servers inherits the dbservers hosts."
  ["missing_web1"]="web1 is not returned by 'ansible all_servers --list-hosts'. Make sure web1 is in the webservers group."
  ["missing_web2"]="web2 is not returned by 'ansible all_servers --list-hosts'. Make sure web2 is in the webservers group."
  ["missing_bd1"]="bd1 is not returned by 'ansible all_servers --list-hosts'. Make sure bd1 is in the dbservers group."
)
declare -A messages_fr=(
  ["no_inventory"]="Fichier d'inventaire introuvable à $inventory. Créez-le d'abord avec les groupes webservers et dbservers."
  ["no_children_section"]="La section [all_servers:children] est absente de l'inventaire. Ajoutez-la sous vos groupes existants."
  ["no_webservers_child"]="webservers n'est pas listé sous [all_servers:children]. Ajoutez-le pour que all_servers hérite des hôtes webservers."
  ["no_dbservers_child"]="dbservers n'est pas listé sous [all_servers:children]. Ajoutez-le pour que all_servers hérite des hôtes dbservers."
  ["missing_web1"]="web1 n'est pas retourné par 'ansible all_servers --list-hosts'. Assurez-vous que web1 est dans le groupe webservers."
  ["missing_web2"]="web2 n'est pas retourné par 'ansible all_servers --list-hosts'. Assurez-vous que web2 est dans le groupe webservers."
  ["missing_bd1"]="bd1 n'est pas retourné par 'ansible all_servers --list-hosts'. Assurez-vous que bd1 est dans le groupe dbservers."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$inventory" ]; then
  echo "$(get_message no_inventory)"; exit 0
fi

if ! grep -q "^\[all_servers:children\]" "$inventory"; then
  echo "$(get_message no_children_section)"; exit 0
fi

# Check that webservers and dbservers appear in the children block
in_children_block=0
has_webservers=0
has_dbservers=0
while IFS= read -r line; do
  if [[ "$line" =~ ^\[all_servers:children\] ]]; then
    in_children_block=1; continue
  fi
  if [[ "$line" =~ ^\[ ]]; then
    in_children_block=0
  fi
  if [[ $in_children_block -eq 1 ]]; then
    [[ "$line" =~ ^webservers ]] && has_webservers=1
    [[ "$line" =~ ^dbservers  ]] && has_dbservers=1
  fi
done < "$inventory"

[ $has_webservers -eq 0 ] && { echo "$(get_message no_webservers_child)"; exit 0; }
[ $has_dbservers  -eq 0 ] && { echo "$(get_message no_dbservers_child)";  exit 0; }

# Verify all 3 hosts appear in all_servers
list_output=$(ansible all_servers --list-hosts -i "$inventory" 2>&1)
echo "$list_output" | grep -q "web1" || { echo "$(get_message missing_web1)"; exit 0; }
echo "$list_output" | grep -q "web2" || { echo "$(get_message missing_web2)"; exit 0; }
echo "$list_output" | grep -q "bd1"  || { echo "$(get_message missing_bd1)";  exit 0; }

echo '{"result": "0"}'
