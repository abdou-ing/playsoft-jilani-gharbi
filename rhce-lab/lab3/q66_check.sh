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
  ["no_playbook"]="Playbook ~/playbooks/set_fact_vars.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/set_fact_vars.yml"
  ["no_set_fact"]="Playbook does not use 'set_fact:'. Use the set_fact module to define env_label."
  ["no_env_label"]="Variable 'env_label' not found in the playbook. Define it with set_fact: env_label: \"{{ ansible_hostname }}-prod\"."
  ["no_file"]="File /root/env_label.txt not found on all hosts. Run: ansible-playbook playbooks/set_fact_vars.yml"
  ["content_wrong"]="Content of /root/env_label.txt does not match '<hostname>-prod' on one or more hosts. Ensure env_label is built from ansible_hostname."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/set_fact_vars.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/set_fact_vars.yml"
  ["no_set_fact"]="Le playbook n'utilise pas 'set_fact:'. Utilisez le module set_fact pour définir env_label."
  ["no_env_label"]="La variable 'env_label' est introuvable dans le playbook. Définissez-la avec set_fact: env_label: \"{{ ansible_hostname }}-prod\"."
  ["no_file"]="Le fichier /root/env_label.txt est introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/set_fact_vars.yml"
  ["content_wrong"]="Le contenu de /root/env_label.txt ne correspond pas à '<hostname>-prod' sur un ou plusieurs hôtes. Assurez-vous que env_label est construit à partir de ansible_hostname."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/set_fact_vars.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/set_fact_vars.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must use set_fact:
grep -q "set_fact:" playbooks/set_fact_vars.yml || { echo "$(get_message no_set_fact)"; exit 0; }

# CHECK 4 — env_label variable must be defined
grep -q "env_label" playbooks/set_fact_vars.yml || { echo "$(get_message no_env_label)"; exit 0; }

# CHECK 5 — /root/env_label.txt must exist on all hosts
ansible all -m command -a "test -f /root/env_label.txt" &>/dev/null 2>&1 || { echo "$(get_message no_file)"; exit 0; }

# CHECK 6 — file content must be '<hostname>-prod' on each host
ansible all -m shell -a \
  "h=\$(hostname -s); grep -q \"^\${h}-prod\$\" /root/env_label.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message content_wrong)"; exit 0; }

echo '{"result": "0"}'
