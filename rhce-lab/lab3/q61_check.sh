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
  ["no_playbook"]="Playbook ~/playbooks/vars_motd.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/vars_motd.yml"
  ["no_vars_section"]="Playbook does not have a 'vars:' section. Define 'company_name: PlaySoft' under vars:."
  ["no_company_var"]="Variable 'company_name' not found in the playbook. Add 'company_name: PlaySoft' to the vars: section."
  ["wrong_company_value"]="Variable 'company_name' must be set to 'PlaySoft'. Check your vars: section."
  ["no_hostname_fact"]="Playbook does not use ansible_hostname. Include {{ ansible_hostname }} in the /etc/motd content."
  ["no_motd"]="File /etc/motd not found on all hosts. Run: ansible-playbook playbooks/vars_motd.yml"
  ["hostname_missing"]="The actual hostname is not present in /etc/motd on one or more hosts. Use {{ ansible_hostname }} in the copy content."
  ["company_missing"]="'PlaySoft' is not present in /etc/motd on one or more hosts. Use {{ company_name }} in the copy content."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/vars_motd.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/vars_motd.yml"
  ["no_vars_section"]="Le playbook n'a pas de section 'vars:'. Définissez 'company_name: PlaySoft' sous vars:."
  ["no_company_var"]="La variable 'company_name' est introuvable dans le playbook. Ajoutez 'company_name: PlaySoft' à la section vars:."
  ["wrong_company_value"]="La variable 'company_name' doit être définie à 'PlaySoft'. Vérifiez votre section vars:."
  ["no_hostname_fact"]="Le playbook n'utilise pas ansible_hostname. Incluez {{ ansible_hostname }} dans le contenu de /etc/motd."
  ["no_motd"]="Le fichier /etc/motd est introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/vars_motd.yml"
  ["hostname_missing"]="Le nom d'hôte réel n'est pas présent dans /etc/motd sur un ou plusieurs hôtes. Utilisez {{ ansible_hostname }} dans le contenu du copy."
  ["company_missing"]="'PlaySoft' n'est pas présent dans /etc/motd sur un ou plusieurs hôtes. Utilisez {{ company_name }} dans le contenu du copy."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/vars_motd.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/vars_motd.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must have a vars: section
grep -q "^  vars:" playbooks/vars_motd.yml || grep -q "^vars:" playbooks/vars_motd.yml || { echo "$(get_message no_vars_section)"; exit 0; }

# CHECK 4 — company_name variable must be defined
grep -q "company_name" playbooks/vars_motd.yml || { echo "$(get_message no_company_var)"; exit 0; }

# CHECK 5 — company_name must be set to PlaySoft
grep -q "company_name:.*PlaySoft" playbooks/vars_motd.yml || { echo "$(get_message wrong_company_value)"; exit 0; }

# CHECK 6 — playbook must reference ansible_hostname
grep -q "ansible_hostname" playbooks/vars_motd.yml || { echo "$(get_message no_hostname_fact)"; exit 0; }

# CHECK 7 — /etc/motd must exist on all hosts
ansible all -m command -a "test -f /etc/motd" &>/dev/null 2>&1 || { echo "$(get_message no_motd)"; exit 0; }

# CHECK 8 — /etc/motd must contain the actual hostname on each host
ansible all -m shell -a \
  "h=\$(hostname -s); grep -q \"\$h\" /etc/motd" \
  &>/dev/null 2>&1 || { echo "$(get_message hostname_missing)"; exit 0; }

# CHECK 9 — /etc/motd must contain 'PlaySoft' on all hosts
ansible all -m command -a "grep -q PlaySoft /etc/motd" \
  &>/dev/null 2>&1 || { echo "$(get_message company_missing)"; exit 0; }

echo '{"result": "0"}'
