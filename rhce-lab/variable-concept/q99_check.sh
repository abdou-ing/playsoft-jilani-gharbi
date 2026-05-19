#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/full_setup.yml"

# SKIP: auto-create and run full_setup.yml silently
if [[ "$1" == "skip" ]]; then
  cat > "$pb_path" <<'EOF'
---
- name: full service setup
  hosts: webservers
  become: yes
  tasks:
    - name: install package
      package:
        name: "{{ pkg_name }}"
        state: present
    - name: start and enable service at boot
      service:
        name: "{{ pkg_name }}"
        state: started
        enabled: yes
EOF
  ansible-playbook "$pb_path" -q >/dev/null 2>&1
  echo '{"result": "0"}'; exit 0
fi

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_webservers"]="The playbook does not target 'webservers'. Set hosts: webservers."
  ["no_become"]="The playbook is missing 'become: yes'. Add it at the play level."
  ["no_enabled"]="The playbook does not set 'enabled: yes' on the service task. The service must be enabled at boot."
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check $pb_path"
  ["not_active"]="nginx is not running on web1. Run the playbook: ansible-playbook $pb_path"
  ["not_enabled"]="nginx is not enabled at boot on web1. Make sure the service task has enabled: yes"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez hosts: webservers."
  ["no_become"]="Le playbook manque 'become: yes'. Ajoutez-le au niveau du play."
  ["no_enabled"]="Le playbook ne définit pas 'enabled: yes' sur la tâche service. Le service doit être activé au démarrage."
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check $pb_path"
  ["not_active"]="nginx ne fonctionne pas sur web1. Exécutez le playbook : ansible-playbook $pb_path"
  ["not_enabled"]="nginx n'est pas activé au démarrage sur web1. Assurez-vous que la tâche service a enabled: yes"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! grep -q "become:" "$pb_path"; then
  echo "$(get_message no_become)"; exit 0
fi

if ! grep -q "enabled:" "$pb_path"; then
  echo "$(get_message no_enabled)"; exit 0
fi

if ! ansible-playbook --syntax-check "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible web1 -m command -a "systemctl is-active nginx" 2>/dev/null | grep -q "active"; then
  echo "$(get_message not_active)"; exit 0
fi

if ! ansible web1 -m command -a "systemctl is-enabled nginx" 2>/dev/null | grep -q "enabled"; then
  echo "$(get_message not_enabled)"; exit 0
fi

echo '{"result": "0"}'
