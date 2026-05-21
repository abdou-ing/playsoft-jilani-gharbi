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
  ["no_requirements"]="File /home/ansible_user/workspace/roles/requirements.yml not found. Create it with the two role entries."
  ["no_balancer_entry"]="requirements.yml does not contain an entry named 'balancer'. Add the balancer role with its src URL."
  ["no_phpinfo_entry"]="requirements.yml does not contain an entry named 'phpinfo'. Add the phpinfo role with its src URL."
  ["no_balancer_dir"]="Role 'balancer' directory not found in /home/ansible_user/workspace/roles/. Run: ansible-galaxy install -r roles/requirements.yml -p roles/"
  ["no_phpinfo_dir"]="Role 'phpinfo' directory not found in /home/ansible_user/workspace/roles/. Run: ansible-galaxy install -r roles/requirements.yml -p roles/"
  ["no_geerlingguy_apache"]="requirements.yml must reference the geerlingguy ansible-role-apache archive for the balancer role."
  ["no_geerlingguy_php"]="requirements.yml must reference the geerlingguy ansible-role-php archive for the phpinfo role."
)
declare -A messages_fr=(
  ["no_requirements"]="Fichier /home/ansible_user/workspace/roles/requirements.yml introuvable. Créez-le avec les deux entrées de rôles."
  ["no_balancer_entry"]="requirements.yml ne contient pas d'entrée nommée 'balancer'. Ajoutez le rôle balancer avec son URL src."
  ["no_phpinfo_entry"]="requirements.yml ne contient pas d'entrée nommée 'phpinfo'. Ajoutez le rôle phpinfo avec son URL src."
  ["no_balancer_dir"]="Le répertoire du rôle 'balancer' est introuvable dans /home/ansible_user/workspace/roles/. Exécutez : ansible-galaxy install -r roles/requirements.yml -p roles/"
  ["no_phpinfo_dir"]="Le répertoire du rôle 'phpinfo' est introuvable dans /home/ansible_user/workspace/roles/. Exécutez : ansible-galaxy install -r roles/requirements.yml -p roles/"
  ["no_geerlingguy_apache"]="requirements.yml doit référencer l'archive geerlingguy ansible-role-apache pour le rôle balancer."
  ["no_geerlingguy_php"]="requirements.yml doit référencer l'archive geerlingguy ansible-role-php pour le rôle phpinfo."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — requirements.yml must exist
[ -f "playbooks/roles/requirements.yml" ] || { echo "$(get_message no_requirements)"; exit 0; }

# CHECK 2 — must contain balancer entry
grep -q "balancer" playbooks/roles/requirements.yml || { echo "$(get_message no_balancer_entry)"; exit 0; }

# CHECK 3 — must contain phpinfo entry
grep -q "phpinfo" playbooks/roles/requirements.yml || { echo "$(get_message no_phpinfo_entry)"; exit 0; }

# CHECK 4 — must reference geerlingguy apache archive
grep -q "geerlingguy.*apache\|ansible-role-apache" playbooks/roles/requirements.yml || \
  { echo "$(get_message no_geerlingguy_apache)"; exit 0; }

# CHECK 5 — must reference geerlingguy php archive
grep -q "geerlingguy.*php\|ansible-role-php" playbooks/roles/requirements.yml || \
  { echo "$(get_message no_geerlingguy_php)"; exit 0; }

# CHECK 6 — balancer role directory must exist
[ -d "playbooks/roles/balancer" ] || { echo "$(get_message no_balancer_dir)"; exit 0; }

# CHECK 7 — phpinfo role directory must exist
[ -d "playbooks/roles/phpinfo" ] || { echo "$(get_message no_phpinfo_dir)"; exit 0; }

echo '{"result": "0"}'
