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
  ["no_playbook"]="Playbook ~/playbooks/report.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/report.yml"
  ["no_report"]="File /root/report.txt not found on all hosts. Run: ansible-playbook playbooks/report.yml"
  ["host_wrong"]="HOST= line in /root/report.txt does not match the actual hostname on one or more hosts. Use {{ ansible_hostname }} in your lineinfile task."
  ["memory_wrong"]="MEMORY= line in /root/report.txt does not match ansible_memtotal_mb on one or more hosts. Use {{ ansible_memtotal_mb }} in your lineinfile task."
  ["bios_missing"]="BIOS= line is missing or empty in /root/report.txt on one or more hosts. Use {{ ansible_bios_version }} in your lineinfile task."
  ["sda_missing"]="SDA_DISK_SIZE= line is missing or empty in /root/report.txt on one or more hosts. Use {{ ansible_devices.sda.size }} in your lineinfile task."
  ["sdb_missing"]="SDB_DISK_SIZE= line is missing or empty in /root/report.txt on one or more hosts. Use {{ ansible_devices.sdb.size }} in your lineinfile task."
  ["no_hostname_var"]="Playbook does not use ansible_hostname. Replace the HOST value with {{ ansible_hostname }}."
  ["no_memory_var"]="Playbook does not use ansible_memtotal_mb. Replace the MEMORY value with {{ ansible_memtotal_mb }}."
  ["no_bios_var"]="Playbook does not use ansible_bios_version. Replace the BIOS value with {{ ansible_bios_version }}."
  ["no_sda_var"]="Playbook does not use ansible_devices.sda.size. Replace SDA_DISK_SIZE value with {{ ansible_devices.sda.size }}."
  ["no_sdb_var"]="Playbook does not use ansible_devices.sdb.size. Replace SDB_DISK_SIZE value with {{ ansible_devices.sdb.size }}."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/report.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/report.yml"
  ["no_report"]="Le fichier /root/report.txt est introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/report.yml"
  ["host_wrong"]="La ligne HOST= dans /root/report.txt ne correspond pas au nom d'hôte réel sur un ou plusieurs hôtes. Utilisez {{ ansible_hostname }} dans votre tâche lineinfile."
  ["memory_wrong"]="La ligne MEMORY= dans /root/report.txt ne correspond pas à ansible_memtotal_mb sur un ou plusieurs hôtes. Utilisez {{ ansible_memtotal_mb }} dans votre tâche lineinfile."
  ["bios_missing"]="La ligne BIOS= est absente ou vide dans /root/report.txt sur un ou plusieurs hôtes. Utilisez {{ ansible_bios_version }} dans votre tâche lineinfile."
  ["sda_missing"]="La ligne SDA_DISK_SIZE= est absente ou vide dans /root/report.txt sur un ou plusieurs hôtes. Utilisez {{ ansible_devices.sda.size }} dans votre tâche lineinfile."
  ["sdb_missing"]="La ligne SDB_DISK_SIZE= est absente ou vide dans /root/report.txt sur un ou plusieurs hôtes. Utilisez {{ ansible_devices.sdb.size }} dans votre tâche lineinfile."
  ["no_hostname_var"]="Le playbook n'utilise pas ansible_hostname. Remplacez la valeur HOST par {{ ansible_hostname }}."
  ["no_memory_var"]="Le playbook n'utilise pas ansible_memtotal_mb. Remplacez la valeur MEMORY par {{ ansible_memtotal_mb }}."
  ["no_bios_var"]="Le playbook n'utilise pas ansible_bios_version. Remplacez la valeur BIOS par {{ ansible_bios_version }}."
  ["no_sda_var"]="Le playbook n'utilise pas ansible_devices.sda.size. Remplacez la valeur SDA_DISK_SIZE par {{ ansible_devices.sda.size }}."
  ["no_sdb_var"]="Le playbook n'utilise pas ansible_devices.sdb.size. Remplacez la valeur SDB_DISK_SIZE par {{ ansible_devices.sdb.size }}."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/report.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/report.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must reference the correct Ansible fact variables
# (catches: candidate hardcoded static values instead of using facts)
grep -q "ansible_hostname" playbooks/report.yml || { echo "$(get_message no_hostname_var)"; exit 0; }
grep -q "ansible_memtotal_mb" playbooks/report.yml || { echo "$(get_message no_memory_var)"; exit 0; }
grep -q "ansible_bios_version" playbooks/report.yml || { echo "$(get_message no_bios_var)"; exit 0; }
grep -q "ansible_devices.sda.size\|ansible_devices\['sda'\]\['size'\]" playbooks/report.yml || { echo "$(get_message no_sda_var)"; exit 0; }
grep -q "ansible_devices.sdb.size\|ansible_devices\['sdb'\]\['size'\]" playbooks/report.yml || { echo "$(get_message no_sdb_var)"; exit 0; }

# CHECK 4 — /root/report.txt must exist on all hosts
ansible all -m command -a "test -f /root/report.txt" &>/dev/null 2>&1 || { echo "$(get_message no_report)"; exit 0; }

# CHECK 5 — HOST= must match the actual hostname on each host
# ansible_hostname equals the output of `hostname -s` on each node
ansible all -m shell -a \
  "h=\$(hostname -s); grep -q \"^HOST=\${h}\$\" /root/report.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message host_wrong)"; exit 0; }

# CHECK 6 — MEMORY= must match ansible_memtotal_mb on each host
# Ansible computes ansible_memtotal_mb as integer(MemTotal_kB / 1024)
ansible all -m shell -a \
  "m=\$(awk '/MemTotal/{print int(\$2/1024)}' /proc/meminfo); grep -q \"^MEMORY=\${m}\$\" /root/report.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message memory_wrong)"; exit 0; }

# CHECK 7 — BIOS= line must be present and non-empty
# (value may vary per environment; we verify the key exists with content)
ansible all -m shell -a \
  "grep -q '^BIOS=.\+' /root/report.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message bios_missing)"; exit 0; }

# CHECK 8 — SDA_DISK_SIZE= line must be present and non-empty
ansible all -m shell -a \
  "grep -q '^SDA_DISK_SIZE=.\+' /root/report.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message sda_missing)"; exit 0; }

# CHECK 9 — SDB_DISK_SIZE= line must be present and non-empty
ansible all -m shell -a \
  "grep -q '^SDB_DISK_SIZE=.\+' /root/report.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message sdb_missing)"; exit 0; }

echo '{"result": "0"}'
