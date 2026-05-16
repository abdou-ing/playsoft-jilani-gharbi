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
  ["no_playbook"]="Playbook ~/playbooks/create_backup.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/create_backup.yml"
  # /backup does not exist at all
  ["dir_missing"]="Directory /backup does not exist on all managed hosts. Run: ansible-playbook playbooks/create_backup.yml"
  # /backup is a file, not a directory
  ["not_a_dir"]="/backup exists but is a file, not a directory. Use the file module with state: directory."
  # wrong permissions
  ["wrong_perms"]="Directory /backup does not have permissions 755 on all hosts. Set mode: '0755' in your file task."
  # wrong owner
  ["wrong_owner"]="Directory /backup is not owned by root on all hosts. Set owner: root in your file task."
  # wrong group
  ["wrong_group"]="Directory /backup does not have group root on all hosts. Set group: root in your file task."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/create_backup.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/create_backup.yml"
  ["dir_missing"]="Le répertoire /backup n'existe pas sur tous les hôtes gérés. Exécutez : ansible-playbook playbooks/create_backup.yml"
  ["not_a_dir"]="/backup existe mais est un fichier, pas un répertoire. Utilisez le module file avec state: directory."
  ["wrong_perms"]="Le répertoire /backup n'a pas les permissions 755 sur tous les hôtes. Définissez mode: '0755' dans votre tâche file."
  ["wrong_owner"]="Le répertoire /backup n'appartient pas à root sur tous les hôtes. Définissez owner: root dans votre tâche file."
  ["wrong_group"]="Le répertoire /backup n'a pas le groupe root sur tous les hôtes. Définissez group: root dans votre tâche file."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/create_backup.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/create_backup.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — /backup must exist on all hosts
ansible all -m command -a "test -e /backup" &>/dev/null 2>&1 || { echo "$(get_message dir_missing)"; exit 0; }

# CHECK 4 — /backup must be a directory, not a file
# (catches: candidate used state: touch instead of state: directory)
ansible all -m command -a "test -d /backup" &>/dev/null 2>&1 || { echo "$(get_message not_a_dir)"; exit 0; }

# CHECK 5 — permissions must be exactly 755
# (catches: mode omitted, mode: '0777', mode: '0644', etc.)
ansible all -m command -a "stat -c '%a' /backup" 2>/dev/null | grep -q "^755$" || { echo "$(get_message wrong_perms)"; exit 0; }

# CHECK 6 — owner must be root
# (catches: owner omitted — directory created as ansible_user)
ansible all -m command -a "stat -c '%U' /backup" 2>/dev/null | grep -q "^root$" || { echo "$(get_message wrong_owner)"; exit 0; }

# CHECK 7 — group must be root
# (catches: group omitted — inherits group from parent directory)
ansible all -m command -a "stat -c '%G' /backup" 2>/dev/null | grep -q "^root$" || { echo "$(get_message wrong_group)"; exit 0; }

echo '{"result": "0"}'
