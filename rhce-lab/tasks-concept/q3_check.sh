#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/when_os.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_when"]="The playbook does not use a 'when:' condition. Add: when: ansible_facts['os_family'] == \"Debian\""
  ["no_os_family"]="The when condition does not reference 'os_family'. Use ansible_facts['os_family'] or ansible_facts[\"os_family\"]."
  ["no_debian"]="The when condition does not check for 'Debian'. Use: when: ansible_facts[\"os_family\"] == \"Debian\""
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["nmap_missing"]="nmap is not installed on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_when"]="Le playbook n'utilise pas de condition 'when:'. Ajoutez : when: ansible_facts['os_family'] == \"Debian\""
  ["no_os_family"]="La condition when ne référence pas 'os_family'. Utilisez ansible_facts['os_family'] ou ansible_facts[\"os_family\"]."
  ["no_debian"]="La condition when ne vérifie pas 'Debian'. Utilisez : when: ansible_facts[\"os_family\"] == \"Debian\""
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["nmap_missing"]="nmap n'est pas installé sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "when:" "$pb_path"; then
  echo "$(get_message no_when)"; exit 0
fi

if ! grep -q "os_family" "$pb_path"; then
  echo "$(get_message no_os_family)"; exit 0
fi

if ! grep -q "Debian" "$pb_path"; then
  echo "$(get_message no_debian)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

if ! ansible web1 -i "$inventory" -m command -a "dpkg -l nmap" 2>/dev/null | grep -q "^ii"; then
  echo "$(get_message nmap_missing)"; exit 0
fi

echo '{"result": "0"}'
