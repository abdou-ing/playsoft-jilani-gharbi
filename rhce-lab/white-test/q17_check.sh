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
  ["no_requirements"]="File /home/ansible_user/workspace/mycollections/requirements.yml not found. Create it with ansible.posix and community.general."
  ["no_ansible_posix"]="requirements.yml does not contain 'ansible.posix'. Add: - name: ansible.posix"
  ["no_community_general"]="requirements.yml does not contain 'community.general'. Add: - name: community.general"
  ["no_collections_key"]="requirements.yml must use a 'collections:' key. Add the 'collections:' list."
  ["posix_not_installed"]="ansible.posix collection not installed. Run: ansible-galaxy collection install -r mycollections/requirements.yml -p mycollections/"
  ["general_not_installed"]="community.general collection not installed. Run: ansible-galaxy collection install -r mycollections/requirements.yml -p mycollections/"
)
declare -A messages_fr=(
  ["no_requirements"]="Fichier /home/ansible_user/workspace/mycollections/requirements.yml introuvable. Créez-le avec ansible.posix et community.general."
  ["no_ansible_posix"]="requirements.yml ne contient pas 'ansible.posix'. Ajoutez : - name: ansible.posix"
  ["no_community_general"]="requirements.yml ne contient pas 'community.general'. Ajoutez : - name: community.general"
  ["no_collections_key"]="requirements.yml doit utiliser une clé 'collections:'. Ajoutez la liste 'collections:'."
  ["posix_not_installed"]="La collection ansible.posix n'est pas installée. Exécutez : ansible-galaxy collection install -r mycollections/requirements.yml -p mycollections/"
  ["general_not_installed"]="La collection community.general n'est pas installée. Exécutez : ansible-galaxy collection install -r mycollections/requirements.yml -p mycollections/"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — requirements.yml must exist
[ -f "playbooks/mycollections/requirements.yml" ] || { echo "$(get_message no_requirements)"; exit 0; }

# CHECK 2 — must have collections key
grep -q "collections:" playbooks/mycollections/requirements.yml || { echo "$(get_message no_collections_key)"; exit 0; }

# CHECK 3 — must contain ansible.posix
grep -q "ansible.posix" playbooks/mycollections/requirements.yml || { echo "$(get_message no_ansible_posix)"; exit 0; }

# CHECK 4 — must contain community.general
grep -q "community.general" playbooks/mycollections/requirements.yml || { echo "$(get_message no_community_general)"; exit 0; }

# CHECK 5 — ansible.posix must be installed
[ -d "playbooks/mycollections/ansible_collections/ansible/posix" ] || \
  ansible-galaxy collection list --collections-path playbooks/mycollections/ 2>/dev/null | grep -q "ansible.posix" || \
  { echo "$(get_message posix_not_installed)"; exit 0; }

# CHECK 6 — community.general must be installed
[ -d "playbooks/mycollections/ansible_collections/community/general" ] || \
  ansible-galaxy collection list --collections-path playbooks/mycollections/ 2>/dev/null | grep -q "community.general" || \
  { echo "$(get_message general_not_installed)"; exit 0; }

echo '{"result": "0"}'
