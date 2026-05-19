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
  ["no_playbook"]="Playbook /home/ansible_user/playbooks/copy_file.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/copy_file.yml"
  ["no_source"]="Source file /home/ansible_user/playbooks/config.json not found on control-node. It should have been pre-created — check with: ls /home/ansible_user/playbooks/config.json"
  # /etc/myapp directory not created
  ["dir_missing"]="/etc/myapp directory does not exist on all hosts. Add a 'file' task with state: directory before copying."
  # file copied to wrong path
  ["wrong_dest"]="config.json was not found at /etc/myapp/config.json on all hosts. Check the 'dest' parameter in your copy task."
  # /etc/myapp exists as a file instead of a directory
  ["not_a_dir"]="/etc/myapp exists but is a file, not a directory. Remove it and recreate with state: directory."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/playbooks/copy_file.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/copy_file.yml"
  ["no_source"]="Le fichier source /home/ansible_user/playbooks/config.json est introuvable sur le control-node. Il aurait dû être pré-créé — vérifiez avec : ls /home/ansible_user/playbooks/config.json"
  ["dir_missing"]="Le répertoire /etc/myapp n'existe pas sur tous les hôtes. Ajoutez une tâche 'file' avec state: directory avant la copie."
  ["wrong_dest"]="config.json n'a pas été trouvé dans /etc/myapp/config.json sur tous les hôtes. Vérifiez le paramètre 'dest' dans votre tâche copy."
  ["not_a_dir"]="/etc/myapp existe mais est un fichier, pas un répertoire. Supprimez-le et recréez-le avec state: directory."
)



cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/copy_file.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/copy_file.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — source config.json must exist on control-node
[ -f "playbooks/config.json" ] || { echo "$(get_message no_source)"; exit 0; }

# CHECK 4 — /etc/myapp must be a directory, not a file
# (catches: candidate created /etc/myapp as a file)
if ansible all -m command -a "test -e /etc/myapp" &>/dev/null 2>&1; then
  ansible all -m command -a "test -d /etc/myapp" &>/dev/null 2>&1 || { echo "$(get_message not_a_dir)"; exit 0; }
else
  echo "$(get_message dir_missing)"; exit 0
fi

# CHECK 5 — config.json must exist at /etc/myapp/config.json on all hosts
# (catches: file copied to /etc/config.json or /etc/myapp/ without filename)
ansible all -m command -a "test -f /etc/myapp/config.json" &>/dev/null 2>&1 || { echo "$(get_message wrong_dest)"; exit 0; }

echo '{"result": "0"}'
