#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

declare -A messages_en=(
  ["no_playbook"]="Playbook ~/playbooks/magic_vars.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/magic_vars.yml"
  ["no_inventory_hostname"]="Playbook does not use 'inventory_hostname'. Use {{ inventory_hostname }} for the INVENTORY_NAME= line."
  ["no_group_names"]="Playbook does not use 'group_names'. Use {{ group_names | join(',') }} for the GROUPS= line."
  ["no_file"]="File /root/inventory_info.txt not found on all hosts. Run: ansible-playbook playbooks/magic_vars.yml"
  ["inventory_name_wrong"]="INVENTORY_NAME= line does not match the inventory hostname on one or more hosts."
  ["groups_missing"]="GROUPS= line is missing or empty in /root/inventory_info.txt on one or more hosts."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/magic_vars.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/magic_vars.yml"
  ["no_inventory_hostname"]="Le playbook n'utilise pas 'inventory_hostname'. Utilisez {{ inventory_hostname }} pour la ligne INVENTORY_NAME=."
  ["no_group_names"]="Le playbook n'utilise pas 'group_names'. Utilisez {{ group_names | join(',') }} pour la ligne GROUPS=."
  ["no_file"]="Le fichier /root/inventory_info.txt est introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/magic_vars.yml"
  ["inventory_name_wrong"]="La ligne INVENTORY_NAME= ne correspond pas au nom d'inventaire sur un ou plusieurs hôtes."
  ["groups_missing"]="La ligne GROUPS= est absente ou vide dans /root/inventory_info.txt sur un ou plusieurs hôtes."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/magic_vars.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/magic_vars.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must use inventory_hostname
grep -q "inventory_hostname" playbooks/magic_vars.yml || { echo "$(get_message no_inventory_hostname)"; exit 0; }

# CHECK 4 — playbook must use group_names
grep -q "group_names" playbooks/magic_vars.yml || { echo "$(get_message no_group_names)"; exit 0; }

# CHECK 5 — /root/inventory_info.txt must exist on all hosts
ansible all -m command -a "test -f /root/inventory_info.txt" &>/dev/null 2>&1 || { echo "$(get_message no_file)"; exit 0; }

# CHECK 6 — INVENTORY_NAME= must match the inventory hostname
# inventory_hostname equals hostname -s in our lab containers (web1 / web2)
ansible all -m shell -a \
  "h=\$(hostname -s); grep -q \"^INVENTORY_NAME=\${h}\$\" /root/inventory_info.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message inventory_name_wrong)"; exit 0; }

# CHECK 7 — GROUPS= line must be present and non-empty
ansible all -m shell -a \
  "grep -q '^GROUPS=.\+' /root/inventory_info.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message groups_missing)"; exit 0; }

echo '{"result": "0"}'
