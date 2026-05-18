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
  ["no_playbook"]="Playbook ~/playbooks/register_vars.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/register_vars.yml"
  ["no_register"]="Playbook does not use 'register:'. Capture the command output with: register: host_result"
  ["no_stdout"]="Playbook does not reference '.stdout' from the registered variable. Use {{ host_result.stdout }} in the copy task."
  ["no_file"]="File /root/registered_hostname.txt not found on all hosts. Run: ansible-playbook playbooks/register_vars.yml"
  ["content_wrong"]="Content of /root/registered_hostname.txt does not match the actual hostname on one or more hosts. Ensure you write {{ host_result.stdout }} to the file."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/register_vars.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/register_vars.yml"
  ["no_register"]="Le playbook n'utilise pas 'register:'. Capturez la sortie de la commande avec : register: host_result"
  ["no_stdout"]="Le playbook ne référence pas '.stdout' depuis la variable enregistrée. Utilisez {{ host_result.stdout }} dans la tâche copy."
  ["no_file"]="Le fichier /root/registered_hostname.txt est introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/register_vars.yml"
  ["content_wrong"]="Le contenu de /root/registered_hostname.txt ne correspond pas au nom d'hôte réel sur un ou plusieurs hôtes. Assurez-vous d'écrire {{ host_result.stdout }} dans le fichier."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/register_vars.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/register_vars.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must use register:
grep -q "register:" playbooks/register_vars.yml || { echo "$(get_message no_register)"; exit 0; }

# CHECK 4 — playbook must use .stdout from the registered variable
grep -q "\.stdout" playbooks/register_vars.yml || { echo "$(get_message no_stdout)"; exit 0; }

# CHECK 5 — /root/registered_hostname.txt must exist on all hosts
ansible all -m command -a "test -f /root/registered_hostname.txt" &>/dev/null 2>&1 || { echo "$(get_message no_file)"; exit 0; }

# CHECK 6 — file content must match the actual hostname on each host
ansible all -m shell -a \
  "h=\$(hostname -s); grep -q \"^\${h}\$\" /root/registered_hostname.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message content_wrong)"; exit 0; }

echo '{"result": "0"}'
