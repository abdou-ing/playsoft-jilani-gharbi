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
  ["no_playbook"]="Playbook /home/ansible_user/workspace/timesync.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/timesync.yml"
  ["no_chrony_pkg"]="chrony package is not installed on all managed hosts. Run: ansible-playbook playbooks/timesync.yml"
  ["no_chrony_conf"]="/etc/chrony.conf not found on all hosts. The playbook must deploy this file."
  ["no_ntp_server"]="/etc/chrony.conf does not contain 'server pool.ntp.org iburst' on all hosts."
  ["chrony_not_running"]="chrony service is not running on all hosts. Check: systemctl status chrony"
  ["chrony_not_enabled"]="chrony service is not enabled on all hosts. Use enabled: true in the service task."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/timesync.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/timesync.yml"
  ["no_chrony_pkg"]="Le paquet chrony n'est pas installé sur tous les hôtes gérés. Exécutez : ansible-playbook playbooks/timesync.yml"
  ["no_chrony_conf"]="/etc/chrony.conf est introuvable sur tous les hôtes. Le playbook doit déployer ce fichier."
  ["no_ntp_server"]="/etc/chrony.conf ne contient pas 'server pool.ntp.org iburst' sur tous les hôtes."
  ["chrony_not_running"]="Le service chrony n'est pas en cours d'exécution sur tous les hôtes. Vérifiez : systemctl status chrony"
  ["chrony_not_enabled"]="Le service chrony n'est pas activé sur tous les hôtes. Utilisez enabled: true dans la tâche service."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook must exist
[ -f "playbooks/timesync.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — no syntax errors
ansible-playbook --syntax-check playbooks/timesync.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — chrony package installed on all hosts
ansible all -m command -a "dpkg -l chrony | grep -q '^ii'" &>/dev/null 2>&1 || \
  { echo "$(get_message no_chrony_pkg)"; exit 0; }

# CHECK 4 — /etc/chrony.conf exists on all hosts
ansible all -m command -a "test -f /etc/chrony.conf" &>/dev/null 2>&1 || \
  { echo "$(get_message no_chrony_conf)"; exit 0; }

# CHECK 5 — chrony.conf contains the NTP server line
ansible all -m shell -a "grep -q 'pool.ntp.org iburst' /etc/chrony.conf" &>/dev/null 2>&1 || \
  { echo "$(get_message no_ntp_server)"; exit 0; }

# CHECK 6 — chrony service is running
ansible all -m shell -a "systemctl is-active chrony" &>/dev/null 2>&1 || \
  { echo "$(get_message chrony_not_running)"; exit 0; }

# CHECK 7 — chrony service is enabled
ansible all -m shell -a "systemctl is-enabled chrony" &>/dev/null 2>&1 || \
  { echo "$(get_message chrony_not_enabled)"; exit 0; }

echo '{"result": "0"}'
