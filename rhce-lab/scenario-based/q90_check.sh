#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/firewall_rules.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_iptables"]="The playbook does not use ansible.builtin.iptables. Use this module to define each firewall rule."
  ["no_established_rule"]="No ACCEPT rule for ESTABLISHED/RELATED connections found in INPUT chain on web1. Add an iptables task with ctstate: [ESTABLISHED, RELATED] and jump: ACCEPT as the first rule."
  ["no_ssh_rule"]="No ACCEPT rule for TCP port 22 (SSH) found in INPUT chain on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["no_http_rule"]="No ACCEPT rule for TCP port 80 (HTTP) found in INPUT chain on web1. Ensure you have an iptables task for port 80."
  ["no_reject_rule"]="No REJECT rule found in INPUT chain on web1. Add an iptables task with jump: REJECT as the last rule."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_iptables"]="Le playbook n'utilise pas ansible.builtin.iptables. Utilisez ce module pour définir chaque règle de pare-feu."
  ["no_established_rule"]="Aucune règle ACCEPT pour les connexions ESTABLISHED/RELATED trouvée dans la chaîne INPUT sur web1. Ajoutez une tâche iptables avec ctstate: [ESTABLISHED, RELATED] et jump: ACCEPT comme première règle."
  ["no_ssh_rule"]="Aucune règle ACCEPT pour le port TCP 22 (SSH) trouvée dans la chaîne INPUT sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["no_http_rule"]="Aucune règle ACCEPT pour le port TCP 80 (HTTP) trouvée dans la chaîne INPUT sur web1. Assurez-vous d'avoir une tâche iptables pour le port 80."
  ["no_reject_rule"]="Aucune règle REJECT trouvée dans la chaîne INPUT sur web1. Ajoutez une tâche iptables avec jump: REJECT comme dernière règle."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "iptables" "$pb_path"; then
  echo "$(get_message no_iptables)"; exit 0
fi

iptables_output=$(ansible web1 -i "$inventory" -m command \
  -a "iptables -L INPUT -n" --become 2>/dev/null)

if ! echo "$iptables_output" | grep -qE "ACCEPT.*(state|ctstate).*(ESTABLISHED|RELATED)"; then
  echo "$(get_message no_established_rule)"; exit 0
fi

if ! echo "$iptables_output" | grep -qE "ACCEPT.*tcp.*dpt:22"; then
  echo "$(get_message no_ssh_rule)"; exit 0
fi

if ! echo "$iptables_output" | grep -qE "ACCEPT.*tcp.*dpt:80"; then
  echo "$(get_message no_http_rule)"; exit 0
fi

if ! echo "$iptables_output" | grep -q "REJECT"; then
  echo "$(get_message no_reject_rule)"; exit 0
fi

echo '{"result": "0"}'
