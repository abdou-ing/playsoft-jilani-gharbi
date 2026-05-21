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
  ["no_playbook"]="Playbook /home/ansible_user/workspace/hwreport.yml not found. Create it first."
  ["no_template"]="Template /home/ansible_user/workspace/hwreport.j2 not found. Create it with the required fields."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/hwreport.yml"
  ["no_block"]="Playbook must use block/rescue structure. Add 'block:' and 'rescue:' sections."
  ["no_report"]="/root/hwreport.txt not found on all hosts. Run: ansible-playbook playbooks/hwreport.yml"
  ["no_hostname"]="/root/hwreport.txt does not contain the inventory hostname line on one or more hosts."
  ["no_memory"]="/root/hwreport.txt does not contain the memory line on one or more hosts."
  ["no_bios"]="/root/hwreport.txt does not contain the BIOS version line on one or more hosts."
  ["no_sda"]="/root/hwreport.txt does not contain the sda disk size line on one or more hosts."
  ["no_sdb"]="/root/hwreport.txt does not contain the sdb disk line (even as NULL) on one or more hosts."
  ["no_hostname_fact"]="Template hwreport.j2 does not use ansible_facts['hostname']. Add the hostname fact."
  ["no_memory_fact"]="Template hwreport.j2 does not use ansible_facts['memtotal_mb']. Add the memory fact."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/hwreport.yml est introuvable. Créez-le d'abord."
  ["no_template"]="Le template /home/ansible_user/workspace/hwreport.j2 est introuvable. Créez-le avec les champs requis."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/hwreport.yml"
  ["no_block"]="Le playbook doit utiliser la structure block/rescue. Ajoutez les sections 'block:' et 'rescue:'."
  ["no_report"]="/root/hwreport.txt introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/hwreport.yml"
  ["no_hostname"]="/root/hwreport.txt ne contient pas la ligne du nom d'hôte d'inventaire sur un ou plusieurs hôtes."
  ["no_memory"]="/root/hwreport.txt ne contient pas la ligne de mémoire sur un ou plusieurs hôtes."
  ["no_bios"]="/root/hwreport.txt ne contient pas la ligne de version BIOS sur un ou plusieurs hôtes."
  ["no_sda"]="/root/hwreport.txt ne contient pas la ligne de taille du disque sda sur un ou plusieurs hôtes."
  ["no_sdb"]="/root/hwreport.txt ne contient pas la ligne du disque sdb (même comme NULL) sur un ou plusieurs hôtes."
  ["no_hostname_fact"]="Le template hwreport.j2 n'utilise pas ansible_facts['hostname']. Ajoutez le fact hostname."
  ["no_memory_fact"]="Le template hwreport.j2 n'utilise pas ansible_facts['memtotal_mb']. Ajoutez le fact mémoire."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook must exist
[ -f "playbooks/hwreport.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — template must exist
[ -f "playbooks/hwreport.j2" ] || { echo "$(get_message no_template)"; exit 0; }

# CHECK 3 — no syntax errors
ansible-playbook --syntax-check playbooks/hwreport.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 4 — playbook must have block/rescue
grep -q "block:" playbooks/hwreport.yml || { echo "$(get_message no_block)"; exit 0; }
grep -q "rescue:" playbooks/hwreport.yml || { echo "$(get_message no_block)"; exit 0; }

# CHECK 5 — template uses hostname fact
grep -q "hostname" playbooks/hwreport.j2 || { echo "$(get_message no_hostname_fact)"; exit 0; }

# CHECK 6 — template uses memory fact
grep -q "memtotal_mb" playbooks/hwreport.j2 || { echo "$(get_message no_memory_fact)"; exit 0; }

# CHECK 7 — /root/hwreport.txt must exist on all hosts
ansible all -m command -a "test -f /root/hwreport.txt" &>/dev/null 2>&1 || \
  { echo "$(get_message no_report)"; exit 0; }

# CHECK 8 — must contain hostname line
ansible all -m shell -a \
  "h=\$(hostname -s); grep -q \"Inventory host name.*\${h}\" /root/hwreport.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message no_hostname)"; exit 0; }

# CHECK 9 — must contain memory line
ansible all -m shell -a "grep -q 'Total memory in MB' /root/hwreport.txt" &>/dev/null 2>&1 || \
  { echo "$(get_message no_memory)"; exit 0; }

# CHECK 10 — must contain BIOS line
ansible all -m shell -a "grep -q 'BIOS version' /root/hwreport.txt" &>/dev/null 2>&1 || \
  { echo "$(get_message no_bios)"; exit 0; }

# CHECK 11 — must contain sda line
ansible all -m shell -a "grep -q 'disk device sda' /root/hwreport.txt" &>/dev/null 2>&1 || \
  { echo "$(get_message no_sda)"; exit 0; }

# CHECK 12 — must contain sdb line (with value or NULL)
ansible all -m shell -a "grep -q 'disk device sdb' /root/hwreport.txt" &>/dev/null 2>&1 || \
  { echo "$(get_message no_sdb)"; exit 0; }

echo '{"result": "0"}'
