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
  ["no_script"]="Script /home/ansible_user/workspace/apt-pack.sh not found. Create it with an ansible ad-hoc command using apt_repository."
  ["not_executable"]="Script /home/ansible_user/workspace/apt-pack.sh is not executable. Run: chmod +x /home/ansible_user/workspace/apt-pack.sh"
  ["no_ansible_cmd"]="Script does not contain an 'ansible' ad-hoc command. Use: ansible all -m ansible.builtin.apt_repository ..."
  ["no_apt_repo_module"]="Script must use the apt_repository or ansible.builtin.apt_repository module."
  ["repo_missing"]="Universe repository not found on all managed hosts. Run the script: /home/ansible_user/workspace/apt-pack.sh"
)
declare -A messages_fr=(
  ["no_script"]="Le script /home/ansible_user/workspace/apt-pack.sh est introuvable. Créez-le avec une commande ad-hoc ansible utilisant apt_repository."
  ["not_executable"]="Le script /home/ansible_user/workspace/apt-pack.sh n'est pas exécutable. Exécutez : chmod +x /home/ansible_user/workspace/apt-pack.sh"
  ["no_ansible_cmd"]="Le script ne contient pas de commande ad-hoc 'ansible'. Utilisez : ansible all -m ansible.builtin.apt_repository ..."
  ["no_apt_repo_module"]="Le script doit utiliser le module apt_repository ou ansible.builtin.apt_repository."
  ["repo_missing"]="Le dépôt Universe n'est pas trouvé sur tous les hôtes gérés. Exécutez le script : /home/ansible_user/workspace/apt-pack.sh"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — script must exist
[ -f "playbooks/apt-pack.sh" ] || { echo "$(get_message no_script)"; exit 0; }

# CHECK 2 — script must be executable
[ -x "playbooks/apt-pack.sh" ] || { echo "$(get_message not_executable)"; exit 0; }

# CHECK 3 — script must contain an ansible ad-hoc command
grep -q "^ansible " "playbooks/apt-pack.sh" || grep -q "[[:space:]]ansible " "playbooks/apt-pack.sh" || \
  { echo "$(get_message no_ansible_cmd)"; exit 0; }

# CHECK 4 — script must use apt_repository module
grep -q "apt_repository" "playbooks/apt-pack.sh" || { echo "$(get_message no_apt_repo_module)"; exit 0; }

# CHECK 5 — universe repo must be present on all hosts
ansible all -m command -a "grep -r 'focal universe' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null" \
  &>/dev/null 2>&1 || { echo "$(get_message repo_missing)"; exit 0; }

echo '{"result": "0"}'
