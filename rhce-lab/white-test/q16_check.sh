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
  ["no_playbook"]="Playbook /home/ansible_user/workspace/cron.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/cron.yml"
  ["no_cron_module"]="Playbook does not use the 'cron' module. Use: ansible.builtin.cron"
  ["no_natasha_user"]="Playbook does not set user: natasha for the cron task."
  ["no_minute"]="Playbook does not set minute: '*/2' for the cron task."
  ["no_job_content"]="Playbook cron job does not contain 'EX294 in progress'. Set: job: logger \"EX294 in progress\""
  ["natasha_missing"]="User 'natasha' does not exist on all hosts. Add a user task or run the playbook."
  ["cron_missing"]="Cron job for natasha not found on all hosts. Run: ansible-playbook playbooks/cron.yml"
  ["wrong_minute"]="Cron job for natasha does not run at '*/2' minute interval on all hosts."
  ["missing_ex294"]="Cron job does not contain 'EX294 in progress' in the job command on all hosts."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/cron.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/cron.yml"
  ["no_cron_module"]="Le playbook n'utilise pas le module 'cron'. Utilisez : ansible.builtin.cron"
  ["no_natasha_user"]="Le playbook ne définit pas user: natasha pour la tâche cron."
  ["no_minute"]="Le playbook ne définit pas minute: '*/2' pour la tâche cron."
  ["no_job_content"]="La tâche cron du playbook ne contient pas 'EX294 in progress'. Définissez : job: logger \"EX294 in progress\""
  ["natasha_missing"]="L'utilisateur 'natasha' n'existe pas sur tous les hôtes. Ajoutez une tâche user ou exécutez le playbook."
  ["cron_missing"]="La tâche cron pour natasha est introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/cron.yml"
  ["wrong_minute"]="La tâche cron pour natasha ne s'exécute pas à l'intervalle de minute '*/2' sur tous les hôtes."
  ["missing_ex294"]="La tâche cron ne contient pas 'EX294 in progress' dans la commande job sur tous les hôtes."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook must exist
[ -f "playbooks/cron.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — no syntax errors
ansible-playbook --syntax-check playbooks/cron.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook uses cron module
grep -q "cron" playbooks/cron.yml || { echo "$(get_message no_cron_module)"; exit 0; }

# CHECK 4 — playbook targets natasha
grep -q "natasha" playbooks/cron.yml || { echo "$(get_message no_natasha_user)"; exit 0; }

# CHECK 5 — playbook sets minute */2
grep -q '\*/2' playbooks/cron.yml || { echo "$(get_message no_minute)"; exit 0; }

# CHECK 6 — playbook job contains EX294 in progress
grep -q "EX294 in progress" playbooks/cron.yml || { echo "$(get_message no_job_content)"; exit 0; }

# CHECK 7 — natasha user exists on all hosts
ansible all -m command -a "id natasha" &>/dev/null 2>&1 || { echo "$(get_message natasha_missing)"; exit 0; }

# CHECK 8 — cron job exists for natasha on all hosts
ansible all -m shell -a "crontab -l -u natasha 2>/dev/null | grep -q 'EX294'" &>/dev/null 2>&1 || \
  { echo "$(get_message cron_missing)"; exit 0; }

# CHECK 9 — cron job uses */2 minute interval
ansible all -m shell -a "crontab -l -u natasha 2>/dev/null | grep -q '\*/2'" &>/dev/null 2>&1 || \
  { echo "$(get_message wrong_minute)"; exit 0; }

echo '{"result": "0"}'
