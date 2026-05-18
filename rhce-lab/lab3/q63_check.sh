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
  ["no_playbook"]="Playbook ~/playbooks/network_info.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/network_info.yml"
  ["no_ip_var"]="Playbook does not use ansible_default_ipv4. Use {{ ansible_default_ipv4.address }} for the IP= line."
  ["no_fqdn_var"]="Playbook does not use ansible_fqdn. Use {{ ansible_fqdn }} for the FQDN= line."
  ["no_file"]="File /root/network_info.txt not found on all hosts. Run: ansible-playbook playbooks/network_info.yml"
  ["ip_wrong"]="IP= line in /root/network_info.txt does not match the actual IP address on one or more hosts."
  ["fqdn_wrong"]="FQDN= line in /root/network_info.txt does not match the actual FQDN on one or more hosts."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/network_info.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/network_info.yml"
  ["no_ip_var"]="Le playbook n'utilise pas ansible_default_ipv4. Utilisez {{ ansible_default_ipv4.address }} pour la ligne IP=."
  ["no_fqdn_var"]="Le playbook n'utilise pas ansible_fqdn. Utilisez {{ ansible_fqdn }} pour la ligne FQDN=."
  ["no_file"]="Le fichier /root/network_info.txt est introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/network_info.yml"
  ["ip_wrong"]="La ligne IP= dans /root/network_info.txt ne correspond pas à l'adresse IP réelle sur un ou plusieurs hôtes."
  ["fqdn_wrong"]="La ligne FQDN= dans /root/network_info.txt ne correspond pas au FQDN réel sur un ou plusieurs hôtes."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/network_info.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/network_info.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must reference ansible_default_ipv4
grep -q "ansible_default_ipv4" playbooks/network_info.yml || { echo "$(get_message no_ip_var)"; exit 0; }

# CHECK 4 — playbook must reference ansible_fqdn
grep -q "ansible_fqdn" playbooks/network_info.yml || { echo "$(get_message no_fqdn_var)"; exit 0; }

# CHECK 5 — /root/network_info.txt must exist on all hosts
ansible all -m command -a "test -f /root/network_info.txt" &>/dev/null 2>&1 || { echo "$(get_message no_file)"; exit 0; }

# CHECK 6 — IP= must match the default IPv4 on each host
# Use the default-route interface IP, same logic as ansible_default_ipv4.address
ansible all -m shell -a "
  iface=\$(ip route show default 2>/dev/null | awk '/default/{print \$5; exit}')
  if [ -n \"\$iface\" ]; then
    actual_ip=\$(ip addr show \"\$iface\" 2>/dev/null | awk '/inet /{print \$2; exit}' | cut -d/ -f1)
  else
    actual_ip=\$(hostname -I 2>/dev/null | awk '{print \$1}')
  fi
  grep -q \"^IP=\${actual_ip}\$\" /root/network_info.txt
" &>/dev/null 2>&1 || { echo "$(get_message ip_wrong)"; exit 0; }

# CHECK 7 — FQDN= must match hostname -f on each host
ansible all -m shell -a \
  "fqdn=\$(hostname -f 2>/dev/null); grep -q \"^FQDN=\${fqdn}\$\" /root/network_info.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message fqdn_wrong)"; exit 0; }

echo '{"result": "0"}'
