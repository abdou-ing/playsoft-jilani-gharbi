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
  ["no_user_list"]="File /home/ansible_user/workspace/user_list.yml not found. Create it with the users list."
  ["no_playbook"]="Playbook /home/ansible_user/workspace/create_user.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/create_user.yml"
  ["no_vars_files"]="Playbook does not use vars_files. Add: vars_files: [user_list.yml, vault.yml]"
  ["no_vault_ref"]="Playbook vars_files does not reference vault.yml. Add vault.yml to vars_files."
  ["no_dev_pass"]="Playbook does not use dev_pass variable for developer users."
  ["no_mgr_pass"]="Playbook does not use mgr_pass variable for manager users."
  ["no_password_hash"]="Playbook does not use password_hash('sha512') filter. Passwords must be hashed."
  ["adam_missing"]="User 'adam' not found on web1 (dev group). Run: ansible-playbook playbooks/create_user.yml --vault-password-file=playbooks/password.txt"
  ["lucifer_missing"]="User 'lucifer' not found on web1 (dev group). Run: ansible-playbook playbooks/create_user.yml --vault-password-file=playbooks/password.txt"
  ["gabriel_missing"]="User 'gabriel' not found on web1 (prod group). Run: ansible-playbook playbooks/create_user.yml --vault-password-file=playbooks/password.txt"
  ["no_job_condition"]="Playbook does not check job field. Use: when: item.job == 'developer'"
)
declare -A messages_fr=(
  ["no_user_list"]="Fichier /home/ansible_user/workspace/user_list.yml introuvable. Créez-le avec la liste des utilisateurs."
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/create_user.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/create_user.yml"
  ["no_vars_files"]="Le playbook n'utilise pas vars_files. Ajoutez : vars_files: [user_list.yml, vault.yml]"
  ["no_vault_ref"]="Les vars_files du playbook ne référencent pas vault.yml. Ajoutez vault.yml aux vars_files."
  ["no_dev_pass"]="Le playbook n'utilise pas la variable dev_pass pour les utilisateurs developers."
  ["no_mgr_pass"]="Le playbook n'utilise pas la variable mgr_pass pour les utilisateurs managers."
  ["no_password_hash"]="Le playbook n'utilise pas le filtre password_hash('sha512'). Les mots de passe doivent être hachés."
  ["adam_missing"]="L'utilisateur 'adam' est introuvable sur web1 (groupe dev). Exécutez : ansible-playbook playbooks/create_user.yml --vault-password-file=playbooks/password.txt"
  ["lucifer_missing"]="L'utilisateur 'lucifer' est introuvable sur web1 (groupe dev). Exécutez : ansible-playbook playbooks/create_user.yml --vault-password-file=playbooks/password.txt"
  ["gabriel_missing"]="L'utilisateur 'gabriel' est introuvable sur web1 (groupe prod). Exécutez : ansible-playbook playbooks/create_user.yml --vault-password-file=playbooks/password.txt"
  ["no_job_condition"]="Le playbook ne vérifie pas le champ job. Utilisez : when: item.job == 'developer'"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — user_list.yml must exist
[ -f "playbooks/user_list.yml" ] || { echo "$(get_message no_user_list)"; exit 0; }

# CHECK 2 — playbook must exist
[ -f "playbooks/create_user.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 3 — no syntax errors
ansible-playbook --syntax-check playbooks/create_user.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 4 — playbook uses vars_files
grep -q "vars_files" playbooks/create_user.yml || { echo "$(get_message no_vars_files)"; exit 0; }

# CHECK 5 — vars_files includes vault.yml
grep -q "vault.yml" playbooks/create_user.yml || { echo "$(get_message no_vault_ref)"; exit 0; }

# CHECK 6 — uses dev_pass and mgr_pass
grep -q "dev_pass" playbooks/create_user.yml || { echo "$(get_message no_dev_pass)"; exit 0; }
grep -q "mgr_pass" playbooks/create_user.yml || { echo "$(get_message no_mgr_pass)"; exit 0; }

# CHECK 7 — uses password_hash
grep -q "password_hash" playbooks/create_user.yml || { echo "$(get_message no_password_hash)"; exit 0; }

# CHECK 8 — uses job condition
grep -q "item.job\|\.job ==" playbooks/create_user.yml || { echo "$(get_message no_job_condition)"; exit 0; }

# CHECK 9 — adam exists on dev group (web1)
ansible dev -m command -a "id adam" &>/dev/null 2>&1 || { echo "$(get_message adam_missing)"; exit 0; }

# CHECK 10 — lucifer exists on dev group (web1)
ansible dev -m command -a "id lucifer" &>/dev/null 2>&1 || { echo "$(get_message lucifer_missing)"; exit 0; }

# CHECK 11 — gabriel exists on prod group (web1 is in prod)
ansible prod -m command -a "id gabriel" &>/dev/null 2>&1 | grep -q "gabriel" || \
  { echo "$(get_message gabriel_missing)"; exit 0; }

echo '{"result": "0"}'
