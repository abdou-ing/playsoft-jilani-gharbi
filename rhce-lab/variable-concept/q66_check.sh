#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/copy_demo.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_copy"]="The playbook does not use the copy module. Add a task with: copy: src: ... dest: ..."
  ["no_src"]="The copy task is missing src:. Set the source file path on the control node: src: files/hello.txt"
  ["no_dest"]="The copy task is missing dest:. Set the destination path on the managed host: dest: /tmp/hello.txt"
  ["no_webservers"]="The playbook does not target 'webservers'. Set: hosts: webservers"
  ["syntax_error"]="The playbook has a syntax error. Run: ansible-playbook --syntax-check -i $inventory $pb_path"
  ["not_copied_web1"]="The file was not found at /home/ansible_user/workspace/hello.txt on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["not_copied_web2"]="The file was not found at /home/ansible_user/workspace/hello.txt on web2. Run the playbook: ansible-playbook -i $inventory $pb_path"
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_copy"]="Le playbook n'utilise pas le module copy. Ajoutez une tâche avec : copy: src: ... dest: ..."
  ["no_src"]="La tâche copy n'a pas de src:. Définissez le chemin du fichier source sur le nœud de contrôle : src: files/hello.txt"
  ["no_dest"]="La tâche copy n'a pas de dest:. Définissez le chemin de destination sur l'hôte géré : dest: /tmp/hello.txt"
  ["no_webservers"]="Le playbook ne cible pas 'webservers'. Définissez : hosts: webservers"
  ["syntax_error"]="Le playbook contient une erreur de syntaxe. Exécutez : ansible-playbook --syntax-check -i $inventory $pb_path"
  ["not_copied_web1"]="Le fichier n'a pas été trouvé dans /home/ansible_user/workspace/hello.txt sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["not_copied_web2"]="Le fichier n'a pas été trouvé dans /home/ansible_user/workspace/hello.txt sur web2. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "copy:" "$pb_path"; then
  echo "$(get_message no_copy)"; exit 0
fi

if ! grep -q "src:" "$pb_path"; then
  echo "$(get_message no_src)"; exit 0
fi

if ! grep -q "dest:" "$pb_path"; then
  echo "$(get_message no_dest)"; exit 0
fi

if ! grep -q "webservers" "$pb_path"; then
  echo "$(get_message no_webservers)"; exit 0
fi

if ! ansible-playbook --syntax-check -i "$inventory" "$pb_path" &>/dev/null; then
  echo "$(get_message syntax_error)"; exit 0
fi

dest=$(grep "dest:" "$pb_path" | awk '{print $2}' | tr -d '"'"'" | head -1)

if ! ansible web1 -i "$inventory" -m stat -a "path=$dest" 2>/dev/null | grep -q '"exists": true'; then
  echo "$(get_message not_copied_web1)"; exit 0
fi

if ! ansible web2 -i "$inventory" -m stat -a "path=$dest" 2>/dev/null | grep -q '"exists": true'; then
  echo "$(get_message not_copied_web2)"; exit 0
fi

echo '{"result": "0"}'
