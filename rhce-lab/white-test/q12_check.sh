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
  ["no_playbook"]="Playbook /home/ansible_user/workspace/issue.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/issue.yml"
  ["no_dev_condition"]="Playbook is missing a when condition for the 'dev' group. Add: when: inventory_hostname in groups['dev']"
  ["no_test_condition"]="Playbook is missing a when condition for the 'test' group. Add: when: inventory_hostname in groups['test']"
  ["no_prod_condition"]="Playbook is missing a when condition for the 'prod' group. Add: when: inventory_hostname in groups['prod']"
  ["no_development_content"]="Playbook does not set 'Development' content for the dev group."
  ["no_test_content"]="Playbook does not set 'Test' content for the test group."
  ["no_production_content"]="Playbook does not set 'Production' content for the prod group."
  ["issue_empty"]="/etc/issue is empty or not set on all hosts. Run: ansible-playbook playbooks/issue.yml"
  ["issue_missing"]="/etc/issue not found on all hosts. Run: ansible-playbook playbooks/issue.yml"
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/issue.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/issue.yml"
  ["no_dev_condition"]="Le playbook n'a pas de condition when pour le groupe 'dev'. Ajoutez : when: inventory_hostname in groups['dev']"
  ["no_test_condition"]="Le playbook n'a pas de condition when pour le groupe 'test'. Ajoutez : when: inventory_hostname in groups['test']"
  ["no_prod_condition"]="Le playbook n'a pas de condition when pour le groupe 'prod'. Ajoutez : when: inventory_hostname in groups['prod']"
  ["no_development_content"]="Le playbook ne définit pas le contenu 'Development' pour le groupe dev."
  ["no_test_content"]="Le playbook ne définit pas le contenu 'Test' pour le groupe test."
  ["no_production_content"]="Le playbook ne définit pas le contenu 'Production' pour le groupe prod."
  ["issue_empty"]="/etc/issue est vide ou non défini sur tous les hôtes. Exécutez : ansible-playbook playbooks/issue.yml"
  ["issue_missing"]="/etc/issue introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/issue.yml"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook must exist
[ -f "playbooks/issue.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — no syntax errors
ansible-playbook --syntax-check playbooks/issue.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must have when conditions for each group
grep -q "groups\[.dev.\]\|groups\['dev'\]" playbooks/issue.yml || \
  { echo "$(get_message no_dev_condition)"; exit 0; }
grep -q "groups\[.test.\]\|groups\['test'\]" playbooks/issue.yml || \
  { echo "$(get_message no_test_condition)"; exit 0; }
grep -q "groups\[.prod.\]\|groups\['prod'\]" playbooks/issue.yml || \
  { echo "$(get_message no_prod_condition)"; exit 0; }

# CHECK 4 — playbook must set correct content for each group
grep -q "Development" playbooks/issue.yml || { echo "$(get_message no_development_content)"; exit 0; }
grep -q "Test" playbooks/issue.yml || { echo "$(get_message no_test_content)"; exit 0; }
grep -q "Production" playbooks/issue.yml || { echo "$(get_message no_production_content)"; exit 0; }

# CHECK 5 — /etc/issue must exist and be non-empty on all hosts
ansible all -m command -a "test -f /etc/issue" &>/dev/null 2>&1 || \
  { echo "$(get_message issue_missing)"; exit 0; }

ansible all -m shell -a "test -s /etc/issue" &>/dev/null 2>&1 || \
  { echo "$(get_message issue_empty)"; exit 0; }

echo '{"result": "0"}'
