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
  ["no_playbook"]="Playbook ~/playbooks/webserver.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/webserver.yml"
  # apache2 installation
  ["apache_missing"]="apache2 is not installed on webservers1 (web1). Run: ansible-playbook playbooks/webserver.yml"
  # service state
  ["apache_inactive"]="apache2 service is not running on webservers1. Check 'state: started' in your service task."
  # service not enabled at boot (enabled: yes missing)
  ["apache_not_enabled"]="apache2 service is not enabled on boot on webservers1. Add 'enabled: true' to your service task."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/webserver.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/webserver.yml"
  ["apache_missing"]="apache2 n'est pas installé sur webservers1 (web1). Exécutez : ansible-playbook playbooks/webserver.yml"
  ["apache_inactive"]="Le service apache2 ne tourne pas sur webservers1. Vérifiez 'state: started' dans votre tâche service."
  ["apache_not_enabled"]="Le service apache2 n'est pas activé au démarrage sur webservers1. Ajoutez 'enabled: true' à votre tâche service."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/webserver.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/webserver.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — apache2 must be installed on webservers1 (web1)
# (catches: wrong hosts target, apt module missing, package name wrong)
ansible webservers1 -m command -a "dpkg -l apache2" &>/dev/null 2>&1 || { echo "$(get_message apache_missing)"; exit 0; }

# CHECK 4 — apache2 service must be running
# (catches: service task missing, state: stopped used instead)
ansible webservers1 -m command -a "systemctl is-active apache2" 2>/dev/null | grep -q "^active$" || { echo "$(get_message apache_inactive)"; exit 0; }

# CHECK 5 — apache2 service must be enabled at boot
# (catches: enabled: true omitted from service task)
ansible webservers1 -m command -a "systemctl is-enabled apache2" 2>/dev/null | grep -q "^enabled$" || { echo "$(get_message apache_not_enabled)"; exit 0; }

echo '{"result": "0"}'
