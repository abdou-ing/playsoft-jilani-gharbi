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
  ["no_template"]="Template /home/ansible_user/workspace/hosts.j2 not found. Create it with the for loop using hostvars."
  ["no_playbook"]="Playbook /home/ansible_user/workspace/gen_hosts.yml not found. Create it with two plays."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/gen_hosts.yml"
  ["no_for_loop"]="Template hosts.j2 does not contain a Jinja2 for loop over groups['all']. Add: {% for x in groups['all'] %}"
  ["no_hostvars"]="Template hosts.j2 does not use hostvars. Use: hostvars[x]['ansible_facts']['default_ipv4']['address']"
  ["no_myhosts"]="/etc/myhosts not found on web1 (dev group). Run: ansible-playbook playbooks/gen_hosts.yml"
  ["no_localhost"]="/etc/myhosts does not contain the '127.0.0.1 localhost' line on web1."
  ["no_web1_ip"]="/etc/myhosts does not contain an entry for web1's IP address."
  ["no_web2_ip"]="/etc/myhosts does not contain an entry for web2's IP address."
  ["two_plays"]="gen_hosts.yml must have two plays: one for all hosts (gather facts) and one for dev group."
)
declare -A messages_fr=(
  ["no_template"]="Template /home/ansible_user/workspace/hosts.j2 introuvable. Créez-le avec la boucle for utilisant hostvars."
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/gen_hosts.yml est introuvable. Créez-le avec deux plays."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/gen_hosts.yml"
  ["no_for_loop"]="Le template hosts.j2 ne contient pas de boucle for Jinja2 sur groups['all']. Ajoutez : {% for x in groups['all'] %}"
  ["no_hostvars"]="Le template hosts.j2 n'utilise pas hostvars. Utilisez : hostvars[x]['ansible_facts']['default_ipv4']['address']"
  ["no_myhosts"]="/etc/myhosts introuvable sur web1 (groupe dev). Exécutez : ansible-playbook playbooks/gen_hosts.yml"
  ["no_localhost"]="/etc/myhosts ne contient pas la ligne '127.0.0.1 localhost' sur web1."
  ["no_web1_ip"]="/etc/myhosts ne contient pas d'entrée pour l'adresse IP de web1."
  ["no_web2_ip"]="/etc/myhosts ne contient pas d'entrée pour l'adresse IP de web2."
  ["two_plays"]="gen_hosts.yml doit avoir deux plays : un pour tous les hôtes (collecte de faits) et un pour le groupe dev."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — template must exist
[ -f "playbooks/hosts.j2" ] || { echo "$(get_message no_template)"; exit 0; }

# CHECK 2 — playbook must exist
[ -f "playbooks/gen_hosts.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 3 — no syntax errors
ansible-playbook --syntax-check playbooks/gen_hosts.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 4 — template must have for loop over groups
grep -q "for x in groups" playbooks/hosts.j2 || grep -q "for .* in groups\['all'\]" playbooks/hosts.j2 || \
  { echo "$(get_message no_for_loop)"; exit 0; }

# CHECK 5 — template must use hostvars
grep -q "hostvars" playbooks/hosts.j2 || { echo "$(get_message no_hostvars)"; exit 0; }

# CHECK 6 — playbook must have two plays
play_count=$(grep -c "^- name:" playbooks/gen_hosts.yml 2>/dev/null || echo 0)
[ "$play_count" -ge 2 ] || { echo "$(get_message two_plays)"; exit 0; }

# CHECK 7 — /etc/myhosts exists on dev group
ansible dev -m command -a "test -f /etc/myhosts" &>/dev/null 2>&1 || { echo "$(get_message no_myhosts)"; exit 0; }

# CHECK 8 — /etc/myhosts contains localhost entry
ansible dev -m shell -a "grep -q '127.0.0.1.*localhost' /etc/myhosts" &>/dev/null 2>&1 || \
  { echo "$(get_message no_localhost)"; exit 0; }

# CHECK 9 — /etc/myhosts contains web1's IP
web1_ip=$(ansible dev -m setup -a "filter=ansible_default_ipv4" 2>/dev/null | grep '"address"' | head -1 | awk -F'"' '{print $4}')
if [ -n "$web1_ip" ]; then
  ansible dev -m shell -a "grep -q '$web1_ip' /etc/myhosts" &>/dev/null 2>&1 || \
    { echo "$(get_message no_web1_ip)"; exit 0; }
fi

# CHECK 10 — /etc/myhosts has multiple host entries (more than just localhost)
ansible dev -m shell -a "grep -c '^[0-9]' /etc/myhosts | grep -q '[2-9]'" &>/dev/null 2>&1 || \
  ansible dev -m shell -a "wc -l < /etc/myhosts | awk '{exit (\$1 < 4)}'" &>/dev/null 2>&1 || \
  { echo "$(get_message no_web2_ip)"; exit 0; }

echo '{"result": "0"}'
