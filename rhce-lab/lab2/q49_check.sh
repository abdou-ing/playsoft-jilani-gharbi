#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

# If the control-node container is running, pipe this script into it and run there
_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

inventory_path="/home/ansible_user/inventory"

# Error messages shown to the candidate on failure
declare -A messages_en=(
  ["wrong_name"]="Inventory file has the wrong name. Expected: ~/inventory (got: FOUND_FILE). Rename it: mv FOUND_FILE $inventory_path"
  ["no_file"]="Inventory file $inventory_path does not exist. Create it with [webservers] containing web1 and web2."
  ["no_web1"]="web1 is not listed under [webservers] in $inventory_path."
  ["no_web2"]="web2 is not listed under [webservers] in $inventory_path."
  ["wrong_group_web1"]="web1 must be under [webservers], not another group."
  ["wrong_group_web2"]="web2 must be under [webservers], not another group."
)
declare -A messages_fr=(
  ["wrong_name"]="Le fichier d'inventaire a un mauvais nom. Attendu : ~/inventory (trouvé : FOUND_FILE). Renommez-le : mv FOUND_FILE $inventory_path"
  ["no_file"]="Le fichier d'inventaire $inventory_path n'existe pas. Créez-le avec [webservers] contenant web1 et web2."
  ["no_web1"]="web1 n'est pas listé sous [webservers] dans $inventory_path."
  ["no_web2"]="web2 n'est pas listé sous [webservers] dans $inventory_path."
  ["wrong_group_web1"]="web1 doit être sous [webservers], pas dans un autre groupe."
  ["wrong_group_web2"]="web2 doit être sous [webservers], pas dans un autre groupe."
)



# Helper: reads the inventory file line by line and returns the group name
# that contains the given host (by tracking the last [section] header seen)
get_host_group() {
  local host="$1" current_group=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
      current_group="${BASH_REMATCH[1]}"          # entered a new group section
    elif [[ "$line" =~ ^$host([[:space:]]|$) ]]; then
      echo "$current_group"; return               # host found — return its group
    fi
  done < "$inventory_path"
}

# CHECK 1 — inventory file must be named exactly "inventory"
# Looks for common wrong names in the expected directory and tells the candidate to rename
if [ ! -f "$inventory_path" ]; then
  inventory_dir="$(dirname "$inventory_path")"
  found_file=""
  for wrong_name in hosts inventory.ini inventory.yml inventory.yaml ansible_hosts; do
    [ -f "$inventory_dir/$wrong_name" ] && found_file="$inventory_dir/$wrong_name" && break
  done
  if [ -n "$found_file" ]; then
    msg=$(get_message wrong_name)
    echo "${msg//FOUND_FILE/$found_file}"; exit 0
  fi
  echo "$(get_message no_file)"; exit 0
fi

# CHECK 2 — web1 must appear somewhere in the file
if ! grep -q "^web1" "$inventory_path"; then
  echo "$(get_message no_web1)"; exit 0
fi

# CHECK 3 — web2 must appear somewhere in the file
if ! grep -q "^web2" "$inventory_path"; then
  echo "$(get_message no_web2)"; exit 0
fi

# CHECK 4 — web1 must be in the [webservers] group specifically
web1_group=$(get_host_group web1)
if [[ "$web1_group" != "webservers" ]]; then
  echo "$(get_message wrong_group_web1)"; exit 0
fi

# CHECK 5 — web2 must be in the [webservers] group specifically
web2_group=$(get_host_group web2)
if [[ "$web2_group" != "webservers" ]]; then
  echo "$(get_message wrong_group_web2)"; exit 0
fi

echo '{"result": "0"}'
