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
  ["no_playbook"]="Playbook /home/ansible_user/playbooks/deploy_webapp.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/deploy_webapp.yml"
  ["no_git_module"]="Playbook does not use the ansible.builtin.git module. Use it to clone the repository directly on webservers."
  ["repo_not_cloned"]="Repository not cloned at /var/www/html on webservers. Run: ansible-playbook playbooks/deploy_webapp.yml"
  ["wrong_repo"]="A git repository exists at /var/www/html on webservers but the remote URL does not match the expected repository."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/playbooks/deploy_webapp.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/deploy_webapp.yml"
  ["no_git_module"]="Le playbook n'utilise pas le module ansible.builtin.git. Utilisez-le pour cloner le dépôt directement sur les webservers."
  ["repo_not_cloned"]="Le dépôt n'est pas cloné dans /var/www/html sur les webservers. Exécutez : ansible-playbook playbooks/deploy_webapp.yml"
  ["wrong_repo"]="Un dépôt git existe dans /var/www/html sur les webservers mais l'URL distante ne correspond pas au dépôt attendu."
)



cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/deploy_webapp.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/deploy_webapp.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must use ansible.builtin.git (or short alias 'git') module
# (catches: candidate used copy/synchronize instead of git module)
grep -qE '^\s+(ansible\.builtin\.git|git):' playbooks/deploy_webapp.yml || { echo "$(get_message no_git_module)"; exit 0; }

# CHECK 4 — /var/www/html must be a git repo on webservers
# (catches: playbook not run yet, or dest path wrong)
ansible webservers -m command -a "test -d /var/www/html/.git" &>/dev/null 2>&1 || { echo "$(get_message repo_not_cloned)"; exit 0; }

# CHECK 5 — remote origin must point to the expected repo
# (catches: candidate cloned a different repo)
ansible webservers -m command -a "git -C /var/www/html remote get-url origin" 2>/dev/null \
  | grep -q "ansible-examples" || { echo "$(get_message wrong_repo)"; exit 0; }

echo '{"result": "0"}'
