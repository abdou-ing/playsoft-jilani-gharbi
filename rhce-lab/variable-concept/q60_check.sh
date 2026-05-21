#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

inventory_path="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_inventory"]="Inventory file not found at $inventory_path. Create it with web1, web2, and bd1."
  ["no_web1"]="web1 is missing from the inventory. Add it under [webservers]."
  ["no_web2"]="web2 is missing from the inventory. Add it under [webservers]."
  ["no_bd1"]="bd1 is missing from the inventory. Add it under [dbservers]."
  ["no_hosts_web1"]="web1 is not in /etc/hosts. Add the line: 10.30.0.11 web1"
  ["no_hosts_web2"]="web2 is not in /etc/hosts. Add the line: 10.30.0.12 web2"
  ["no_hosts_bd1"]="bd1 is not in /etc/hosts. Add the line: 10.30.0.13 bd1"
  ["wrong_ip_web1"]="web1 resolves to the wrong IP. Expected 10.30.0.11 — check your /etc/hosts entry."
  ["wrong_ip_web2"]="web2 resolves to the wrong IP. Expected 10.30.0.12 — check your /etc/hosts entry."
  ["wrong_ip_bd1"]="bd1 resolves to the wrong IP. Expected 10.30.0.13 — check your /etc/hosts entry."
  ["no_ssh_key"]="No SSH key found at ~/.ssh/id_rsa. Generate one first: ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ''"
  ["ping_web1"]="Ansible cannot reach web1. Distribute your SSH key: ssh-copy-id ansible_user@web1 (password: Labby123)"
  ["ping_web2"]="Ansible cannot reach web2. Distribute your SSH key: ssh-copy-id ansible_user@web2 (password: Labby123)"
  ["ping_bd1"]="Ansible cannot reach bd1. Distribute your SSH key: ssh-copy-id ansible_user@bd1 (password: Labby123)"
)
declare -A messages_fr=(
  ["no_inventory"]="Fichier d'inventaire introuvable à $inventory_path. Créez-le avec web1, web2 et bd1."
  ["no_web1"]="web1 est absent de l'inventaire. Ajoutez-le sous [webservers]."
  ["no_web2"]="web2 est absent de l'inventaire. Ajoutez-le sous [webservers]."
  ["no_bd1"]="bd1 est absent de l'inventaire. Ajoutez-le sous [dbservers]."
  ["no_hosts_web1"]="web1 est absent de /etc/hosts. Ajoutez la ligne : 10.30.0.11 web1"
  ["no_hosts_web2"]="web2 est absent de /etc/hosts. Ajoutez la ligne : 10.30.0.12 web2"
  ["no_hosts_bd1"]="bd1 est absent de /etc/hosts. Ajoutez la ligne : 10.30.0.13 bd1"
  ["wrong_ip_web1"]="web1 est résolu avec la mauvaise IP. Attendu : 10.30.0.11 — vérifiez votre entrée /etc/hosts."
  ["wrong_ip_web2"]="web2 est résolu avec la mauvaise IP. Attendu : 10.30.0.12 — vérifiez votre entrée /etc/hosts."
  ["wrong_ip_bd1"]="bd1 est résolu avec la mauvaise IP. Attendu : 10.30.0.13 — vérifiez votre entrée /etc/hosts."
  ["no_ssh_key"]="Aucune clé SSH trouvée dans ~/.ssh/id_rsa. Générez-en une : ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ''"
  ["ping_web1"]="Ansible ne peut pas joindre web1. Distribuez votre clé SSH : ssh-copy-id ansible_user@web1 (mot de passe : Labby123)"
  ["ping_web2"]="Ansible ne peut pas joindre web2. Distribuez votre clé SSH : ssh-copy-id ansible_user@web2 (mot de passe : Labby123)"
  ["ping_bd1"]="Ansible ne peut pas joindre bd1. Distribuez votre clé SSH : ssh-copy-id ansible_user@bd1 (mot de passe : Labby123)"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

# 1. Inventory exists
if [ ! -f "$inventory_path" ]; then
  echo "$(get_message no_inventory)"; exit 0
fi

# 2. All three hosts present in inventory
if ! grep -qE "^web1" "$inventory_path"; then
  echo "$(get_message no_web1)"; exit 0
fi
if ! grep -qE "^web2" "$inventory_path"; then
  echo "$(get_message no_web2)"; exit 0
fi
if ! grep -qE "^bd1" "$inventory_path"; then
  echo "$(get_message no_bd1)"; exit 0
fi

# 3. /etc/hosts: each hostname resolves and resolves to the CORRECT IP
check_host_ip() {
  local host="$1" expected_ip="$2" missing_key="$3" wrong_key="$4"
  local resolved_ip
  resolved_ip=$(getent hosts "$host" 2>/dev/null | awk '{print $1}')
  if [ -z "$resolved_ip" ]; then
    echo "$(get_message "$missing_key")"; exit 0
  fi
  if [ "$resolved_ip" != "$expected_ip" ]; then
    echo "$(get_message "$wrong_key")"; exit 0
  fi
}

check_host_ip web1 10.30.0.11 no_hosts_web1 wrong_ip_web1
check_host_ip web2 10.30.0.12 no_hosts_web2 wrong_ip_web2
check_host_ip bd1  10.30.0.13 no_hosts_bd1  wrong_ip_bd1

# 4. SSH key was generated
if [ ! -f "/home/ansible_user/.ssh/id_rsa" ]; then
  echo "$(get_message no_ssh_key)"; exit 0
fi

# 5. Ansible ping succeeds on EACH host individually
check_ping() {
  local host="$1" fail_key="$2"
  if ! ansible -i "$inventory_path" "$host" -m ping 2>&1 | grep -q "SUCCESS"; then
    echo "$(get_message "$fail_key")"; exit 0
  fi
}

check_ping web1 ping_web1
check_ping web2 ping_web2
check_ping bd1  ping_bd1

echo '{"result": "0"}'
