#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/install_pkg.yml"

# SKIP: auto-create and run install_pkg.yml silently (nginx needed by q96/q99)
if [[ "$1" == "skip" ]]; then
  cat > "$pb_path" <<'EOF'
---
- name: install package from variable
  hosts: webservers
  become: yes
  tasks:
    - name: install pkg_name
      package:
        name: "{{ pkg_name }}"
        state: present
EOF
  ansible-playbook "$pb_path" -q >/dev/null 2>&1
  echo '{"result": "0"}'; exit 0
fi

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["no_pkg_name"]="The playbook does not use the pkg_name variable. Use: name: \"{{ pkg_name }}\""
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check $pb_path"
  ["not_installed"]="nginx is not installed on web1. Run the playbook: ansible-playbook $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["no_pkg_name"]="Le playbook n'utilise pas la variable pkg_name. Utilisez : name: \"{{ pkg_name }}\""
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check $pb_path"
  ["not_installed"]="nginx n'est pas installé sur web1. Exécutez le playbook : ansible-playbook $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! grep -q "pkg_name" "$pb_path"; then
  echo "$(get_message no_pkg_name)"; exit 0
fi

if ! ansible-playbook --syntax-check "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible web1 -m command -a "dpkg -l nginx" 2>/dev/null | grep -q "^ii"; then
  echo "$(get_message not_installed)"; exit 0
fi

echo '{"result": "0"}'
