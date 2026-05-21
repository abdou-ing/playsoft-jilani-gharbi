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
  ["no_playbook"]="Playbook /home/ansible_user/workspace/web.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/web.yml"
  ["no_webdev_dir"]="/webdev directory not found on web1. Run: ansible-playbook playbooks/web.yml"
  ["wrong_perms"]="/webdev does not have mode 2775 on web1. Set mode: '02775' in the file task."
  ["wrong_group"]="/webdev group is not 'webdev' on web1. Set group: webdev in the file task."
  ["no_symlink"]="Symlink /var/www/html/mywebdev not found on web1. Use file module with state: link."
  ["no_index"]="/webdev/index.html not found on web1. Create it with the copy module."
  ["wrong_content"]="/webdev/index.html does not contain 'Development' on web1."
  ["wrong_index_perms"]="/webdev/index.html does not have mode 0640 on web1."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/web.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/web.yml"
  ["no_webdev_dir"]="Le répertoire /webdev est introuvable sur web1. Exécutez : ansible-playbook playbooks/web.yml"
  ["wrong_perms"]="/webdev n'a pas le mode 2775 sur web1. Définissez mode: '02775' dans la tâche file."
  ["wrong_group"]="Le groupe de /webdev n'est pas 'webdev' sur web1. Définissez group: webdev dans la tâche file."
  ["no_symlink"]="Le lien symbolique /var/www/html/mywebdev est introuvable sur web1. Utilisez le module file avec state: link."
  ["no_index"]="/webdev/index.html est introuvable sur web1. Créez-le avec le module copy."
  ["wrong_content"]="/webdev/index.html ne contient pas 'Development' sur web1."
  ["wrong_index_perms"]="/webdev/index.html n'a pas le mode 0640 sur web1."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook must exist
[ -f "playbooks/web.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — no syntax errors
ansible-playbook --syntax-check playbooks/web.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — /webdev must exist on web1 (dev group)
ansible dev -m command -a "test -d /webdev" &>/dev/null 2>&1 || { echo "$(get_message no_webdev_dir)"; exit 0; }

# CHECK 4 — /webdev permissions must include setgid (2775)
ansible dev -m shell -a "stat -c '%a' /webdev | grep -q '2775'" &>/dev/null 2>&1 || \
  { echo "$(get_message wrong_perms)"; exit 0; }

# CHECK 5 — /webdev group must be webdev
ansible dev -m shell -a "stat -c '%G' /webdev | grep -q '^webdev$'" &>/dev/null 2>&1 || \
  { echo "$(get_message wrong_group)"; exit 0; }

# CHECK 6 — symlink must exist
ansible dev -m shell -a "test -L /var/www/html/mywebdev" &>/dev/null 2>&1 || \
  { echo "$(get_message no_symlink)"; exit 0; }

# CHECK 7 — /webdev/index.html must exist
ansible dev -m command -a "test -f /webdev/index.html" &>/dev/null 2>&1 || \
  { echo "$(get_message no_index)"; exit 0; }

# CHECK 8 — index.html must contain "Development"
ansible dev -m shell -a "grep -q 'Development' /webdev/index.html" &>/dev/null 2>&1 || \
  { echo "$(get_message wrong_content)"; exit 0; }

# CHECK 9 — index.html permissions must be 0640
ansible dev -m shell -a "stat -c '%a' /webdev/index.html | grep -q '640'" &>/dev/null 2>&1 || \
  { echo "$(get_message wrong_index_perms)"; exit 0; }

echo '{"result": "0"}'
