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
  ["no_playbook"]="Playbook /home/ansible_user/workspace/packages.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/packages.yml"
  ["no_php"]="php is not installed on all managed hosts. Run: ansible-playbook playbooks/packages.yml"
  ["no_mariadb"]="mariadb-client is not installed on all managed hosts. Run: ansible-playbook playbooks/packages.yml"
  ["no_build_essential"]="build-essential is not installed on web1 (dev group). Run: ansible-playbook playbooks/packages.yml"
  ["no_when_dev"]="Playbook is missing a 'when' condition for the dev group. Use: when: inventory_hostname in groups['dev']"
  ["no_when_multi"]="Playbook is missing 'when' conditions for dev, test, and prod groups."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/packages.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/packages.yml"
  ["no_php"]="php n'est pas installé sur tous les hôtes gérés. Exécutez : ansible-playbook playbooks/packages.yml"
  ["no_mariadb"]="mariadb-client n'est pas installé sur tous les hôtes gérés. Exécutez : ansible-playbook playbooks/packages.yml"
  ["no_build_essential"]="build-essential n'est pas installé sur web1 (groupe dev). Exécutez : ansible-playbook playbooks/packages.yml"
  ["no_when_dev"]="Le playbook n'a pas de condition 'when' pour le groupe dev. Utilisez : when: inventory_hostname in groups['dev']"
  ["no_when_multi"]="Le playbook n'a pas de conditions 'when' pour les groupes dev, test et prod."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook must exist
[ -f "playbooks/packages.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — no syntax errors
ansible-playbook --syntax-check playbooks/packages.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook uses when conditions
grep -q "groups\[.dev.\]" playbooks/packages.yml || grep -q "groups\['dev'\]" playbooks/packages.yml || \
  { echo "$(get_message no_when_dev)"; exit 0; }
grep -q "groups\[.test.\]" playbooks/packages.yml || grep -q "groups\['test'\]" playbooks/packages.yml || \
  { echo "$(get_message no_when_multi)"; exit 0; }

# CHECK 4 — php installed on web1 and web2
ansible all -m command -a "dpkg -l php 2>/dev/null | grep -q '^ii'" &>/dev/null 2>&1 || \
  { echo "$(get_message no_php)"; exit 0; }

# CHECK 5 — mariadb-client installed on web1 and web2
ansible all -m command -a "dpkg -l mariadb-client 2>/dev/null | grep -q '^ii'" &>/dev/null 2>&1 || \
  { echo "$(get_message no_mariadb)"; exit 0; }

# CHECK 6 — build-essential installed on web1 (dev group)
ansible dev -m command -a "dpkg -l build-essential 2>/dev/null | grep -q '^ii'" &>/dev/null 2>&1 || \
  { echo "$(get_message no_build_essential)"; exit 0; }

echo '{"result": "0"}'
