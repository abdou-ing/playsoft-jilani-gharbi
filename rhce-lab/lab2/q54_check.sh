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
  ["no_playbook"]="Playbook /home/ansible_user/playbooks/remove_user.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/remove_user.yml"
  # charlie still exists (account not removed)
  ["charlie_exists"]="User charlie still exists on all hosts. Run: ansible-playbook playbooks/remove_user.yml"
  # home directory still present even though account was removed (remove_home: true missing)
  ["charlie_home_exists"]="User charlie was removed but home directory /home/charlie still exists. Add 'remove_home: true' to the user module."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/playbooks/remove_user.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/remove_user.yml"
  ["charlie_exists"]="L'utilisateur charlie existe encore sur tous les hôtes. Exécutez : ansible-playbook playbooks/remove_user.yml"
  ["charlie_home_exists"]="L'utilisateur charlie a été supprimé mais le répertoire /home/charlie existe encore. Ajoutez 'remove_home: true' au module user."
)



cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/remove_user.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/remove_user.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — charlie account must not exist on any host
# (catches: state: absent missing, wrong username, playbook not run)
if ansible all -m command -a "id charlie" &>/dev/null 2>&1; then
  echo "$(get_message charlie_exists)"; exit 0
fi

# CHECK 4 — charlie home directory must also be removed
# (catches: remove_home: true omitted — account gone but /home/charlie still on disk)
if ansible all -m command -a "test -d /home/charlie" &>/dev/null 2>&1; then
  echo "$(get_message charlie_home_exists)"; exit 0
fi

echo '{"result": "0"}'
