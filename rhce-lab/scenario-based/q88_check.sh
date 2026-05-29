#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/ntp_config.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_lineinfile"]="The playbook does not use lineinfile. Use ansible.builtin.lineinfile to set NTP= in /etc/systemd/timesyncd.conf."
  ["no_service"]="The playbook does not manage the timesyncd service. Add a service task: name: systemd-timesyncd, state: restarted."
  ["wrong_ntp"]="NTP=pool.ntp.org is not set in /etc/systemd/timesyncd.conf on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_lineinfile"]="Le playbook n'utilise pas lineinfile. Utilisez ansible.builtin.lineinfile pour définir NTP= dans /etc/systemd/timesyncd.conf."
  ["no_service"]="Le playbook ne gère pas le service timesyncd. Ajoutez une tâche service : name: systemd-timesyncd, state: restarted."
  ["wrong_ntp"]="NTP=pool.ntp.org n'est pas défini dans /etc/systemd/timesyncd.conf sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "lineinfile" "$pb_path"; then
  echo "$(get_message no_lineinfile)"; exit 0
fi

if ! grep -q "timesyncd" "$pb_path"; then
  echo "$(get_message no_service)"; exit 0
fi

ntp_result=$(ansible web1 -i "$inventory" -m command \
  -a "grep '^NTP=' /etc/systemd/timesyncd.conf" --become 2>/dev/null)

if ! echo "$ntp_result" | grep -q "pool.ntp.org"; then
  echo "$(get_message wrong_ntp)"; exit 0
fi

echo '{"result": "0"}'
