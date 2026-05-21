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
  ["no_inventory"]="Inventory file /home/ansible_user/workspace/inventory not found. Create it with the required groups."
  ["no_cfg"]="ansible.cfg not found at /home/ansible_user/workspace/ansible.cfg. Create it with required settings."
  ["no_dev_group"]="[dev] group not found in inventory. Add web1 under [dev]."
  ["no_test_group"]="[test] group not found in inventory. Add web2 under [test]."
  ["no_prod_group"]="[prod] group not found in inventory. Add web1 and web2 under [prod]."
  ["no_balancers_group"]="[balancers] group not found in inventory. Add web1 under [balancers]."
  ["no_webservers_children"]="[webservers:children] not found in inventory. Add it with dev, test, prod as children."
  ["web1_not_in_dev"]="web1 is not listed under the [dev] group in the inventory."
  ["web2_not_in_test"]="web2 is not listed under the [test] group in the inventory."
  ["web1_not_in_prod"]="web1 is not listed under the [prod] group in the inventory."
  ["web2_not_in_prod"]="web2 is not listed under the [prod] group in the inventory."
  ["no_remote_user"]="ansible.cfg is missing 'remote_user = ansible_user' in [defaults] section."
  ["no_inventory_cfg"]="ansible.cfg is missing 'inventory = inventory' in [defaults] section."
  ["no_roles_path"]="ansible.cfg is missing 'roles_path' setting in [defaults] section."
  ["no_become"]="ansible.cfg is missing 'become = true' in [privilege_escalation] section."
  ["ping_fail"]="ansible all -m ping failed. Check your inventory, ansible.cfg, and SSH connectivity."
)
declare -A messages_fr=(
  ["no_inventory"]="Fichier d'inventaire /home/ansible_user/workspace/inventory introuvable. Créez-le avec les groupes requis."
  ["no_cfg"]="ansible.cfg introuvable dans /home/ansible_user/workspace/ansible.cfg. Créez-le avec les paramètres requis."
  ["no_dev_group"]="Le groupe [dev] est absent de l'inventaire. Ajoutez web1 sous [dev]."
  ["no_test_group"]="Le groupe [test] est absent de l'inventaire. Ajoutez web2 sous [test]."
  ["no_prod_group"]="Le groupe [prod] est absent de l'inventaire. Ajoutez web1 et web2 sous [prod]."
  ["no_balancers_group"]="Le groupe [balancers] est absent de l'inventaire. Ajoutez web1 sous [balancers]."
  ["no_webservers_children"]="[webservers:children] est absent de l'inventaire. Ajoutez-le avec dev, test, prod comme enfants."
  ["web1_not_in_dev"]="web1 n'est pas listé sous le groupe [dev] dans l'inventaire."
  ["web2_not_in_test"]="web2 n'est pas listé sous le groupe [test] dans l'inventaire."
  ["web1_not_in_prod"]="web1 n'est pas listé sous le groupe [prod] dans l'inventaire."
  ["web2_not_in_prod"]="web2 n'est pas listé sous le groupe [prod] dans l'inventaire."
  ["no_remote_user"]="ansible.cfg manque 'remote_user = ansible_user' dans la section [defaults]."
  ["no_inventory_cfg"]="ansible.cfg manque 'inventory = inventory' dans la section [defaults]."
  ["no_roles_path"]="ansible.cfg manque le paramètre 'roles_path' dans la section [defaults]."
  ["no_become"]="ansible.cfg manque 'become = true' dans la section [privilege_escalation]."
  ["ping_fail"]="ansible all -m ping a échoué. Vérifiez votre inventaire, ansible.cfg et la connectivité SSH."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — inventory file must exist
[ -f "playbooks/inventory" ] || { echo "$(get_message no_inventory)"; exit 0; }

# CHECK 2 — ansible.cfg must exist
[ -f "playbooks/ansible.cfg" ] || { echo "$(get_message no_cfg)"; exit 0; }

inv="playbooks/inventory"

# CHECK 3 — required groups must exist
grep -q "^\[dev\]" "$inv" || { echo "$(get_message no_dev_group)"; exit 0; }
grep -q "^\[test\]" "$inv" || { echo "$(get_message no_test_group)"; exit 0; }
grep -q "^\[prod\]" "$inv" || { echo "$(get_message no_prod_group)"; exit 0; }
grep -q "^\[balancers\]" "$inv" || { echo "$(get_message no_balancers_group)"; exit 0; }
grep -q "^\[webservers:children\]" "$inv" || { echo "$(get_message no_webservers_children)"; exit 0; }

# CHECK 4 — hosts in correct groups (parse INI sections)
get_host_group_all() {
  local host="$1"
  local current_group=""
  local found_groups=()
  while IFS= read -r line; do
    if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
      current_group="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^${host}([[:space:]]|$) ]]; then
      found_groups+=("$current_group")
    fi
  done < "$inv"
  echo "${found_groups[*]}"
}

web1_groups=$(get_host_group_all web1)
web2_groups=$(get_host_group_all web2)

echo "$web1_groups" | grep -q "dev" || { echo "$(get_message web1_not_in_dev)"; exit 0; }
echo "$web2_groups" | grep -q "test" || { echo "$(get_message web2_not_in_test)"; exit 0; }
echo "$web1_groups" | grep -q "prod" || { echo "$(get_message web1_not_in_prod)"; exit 0; }
echo "$web2_groups" | grep -q "prod" || { echo "$(get_message web2_not_in_prod)"; exit 0; }

cfg="playbooks/ansible.cfg"

# CHECK 5 — ansible.cfg required settings
grep -q "remote_user\s*=\s*ansible_user" "$cfg" || { echo "$(get_message no_remote_user)"; exit 0; }
grep -q "inventory\s*=" "$cfg" || { echo "$(get_message no_inventory_cfg)"; exit 0; }
grep -q "roles_path\s*=" "$cfg" || { echo "$(get_message no_roles_path)"; exit 0; }
grep -q "become\s*=\s*true" "$cfg" || { echo "$(get_message no_become)"; exit 0; }

# CHECK 6 — ansible all -m ping must succeed
cd playbooks
ansible all -m ping &>/dev/null 2>&1 || { echo "$(get_message ping_fail)"; exit 0; }

echo '{"result": "0"}'
