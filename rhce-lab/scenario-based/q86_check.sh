#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/ssh_banner.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_copy"]="The playbook does not use the 'copy' module. Use ansible.builtin.copy to deploy the banner file to /etc/ssh/banner."
  ["no_lineinfile"]="The playbook does not use lineinfile. Use ansible.builtin.lineinfile to set 'Banner /etc/ssh/banner' in sshd_config."
  ["no_banner_file"]="/etc/ssh/banner does not exist on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["no_directive"]="The Banner directive is not set in /etc/ssh/sshd_config on web1. Ensure your lineinfile task sets 'Banner /etc/ssh/banner'."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_copy"]="Le playbook n'utilise pas le module 'copy'. Utilisez ansible.builtin.copy pour déployer le fichier de bannière vers /etc/ssh/banner."
  ["no_lineinfile"]="Le playbook n'utilise pas lineinfile. Utilisez ansible.builtin.lineinfile pour définir 'Banner /etc/ssh/banner' dans sshd_config."
  ["no_banner_file"]="/etc/ssh/banner n'existe pas sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["no_directive"]="La directive Banner n'est pas définie dans /etc/ssh/sshd_config sur web1. Assurez-vous que votre tâche lineinfile définit 'Banner /etc/ssh/banner'."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "copy:" "$pb_path" && ! grep -q "ansible.builtin.copy" "$pb_path"; then
  echo "$(get_message no_copy)"; exit 0
fi

if ! grep -q "lineinfile" "$pb_path"; then
  echo "$(get_message no_lineinfile)"; exit 0
fi

stat_result=$(ansible web1 -i "$inventory" -m stat -a "path=/etc/ssh/banner" --become 2>/dev/null)
if ! echo "$stat_result" | grep -q '"exists": true'; then
  echo "$(get_message no_banner_file)"; exit 0
fi

sshd_output=$(ansible web1 -i "$inventory" -m command -a "sshd -T" --become 2>/dev/null)
if ! echo "$sshd_output" | grep -qi "banner /etc/ssh/banner"; then
  echo "$(get_message no_directive)"; exit 0
fi

echo '{"result": "0"}'
