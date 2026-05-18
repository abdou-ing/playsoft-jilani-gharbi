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
  ["no_playbook"]="Playbook ~/playbooks/dict_vars.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/dict_vars.yml"
  ["no_vars_section"]="Playbook does not have a 'vars:' section. Define the app_config dictionary under vars:."
  ["no_app_config"]="Dictionary variable 'app_config' not found in the playbook vars: section."
  ["no_dot_notation"]="Playbook does not use dot or bracket notation to access app_config keys (e.g. app_config.name)."
  ["no_file"]="File /root/app_config.txt not found on all hosts. Run: ansible-playbook playbooks/dict_vars.yml"
  ["app_wrong"]="APP= line in /root/app_config.txt is not 'myapp' on one or more hosts. Set app_config.name: myapp in vars:."
  ["port_wrong"]="PORT= line in /root/app_config.txt is not '8080' on one or more hosts. Set app_config.port: \"8080\" in vars:."
  ["env_wrong"]="ENV= line in /root/app_config.txt is not 'production' on one or more hosts. Set app_config.env: production in vars:."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/dict_vars.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/dict_vars.yml"
  ["no_vars_section"]="Le playbook n'a pas de section 'vars:'. Définissez le dictionnaire app_config sous vars:."
  ["no_app_config"]="La variable dictionnaire 'app_config' est introuvable dans la section vars: du playbook."
  ["no_dot_notation"]="Le playbook n'utilise pas la notation pointée ou entre crochets pour accéder aux clés d'app_config (ex. app_config.name)."
  ["no_file"]="Le fichier /root/app_config.txt est introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/dict_vars.yml"
  ["app_wrong"]="La ligne APP= dans /root/app_config.txt n'est pas 'myapp' sur un ou plusieurs hôtes. Définissez app_config.name: myapp dans vars:."
  ["port_wrong"]="La ligne PORT= dans /root/app_config.txt n'est pas '8080' sur un ou plusieurs hôtes. Définissez app_config.port: \"8080\" dans vars:."
  ["env_wrong"]="La ligne ENV= dans /root/app_config.txt n'est pas 'production' sur un ou plusieurs hôtes. Définissez app_config.env: production dans vars:."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/dict_vars.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/dict_vars.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must have a vars: section
grep -q "^  vars:" playbooks/dict_vars.yml || grep -q "^vars:" playbooks/dict_vars.yml || { echo "$(get_message no_vars_section)"; exit 0; }

# CHECK 4 — app_config dictionary must be defined
grep -q "app_config" playbooks/dict_vars.yml || { echo "$(get_message no_app_config)"; exit 0; }

# CHECK 5 — must use dot or bracket notation to access dictionary keys
# (catches: candidate flattened into simple vars instead of a dict)
grep -qE "app_config\.(name|port|env)|app_config\['(name|port|env)'\]" playbooks/dict_vars.yml || { echo "$(get_message no_dot_notation)"; exit 0; }

# CHECK 6 — /root/app_config.txt must exist on all hosts
ansible all -m command -a "test -f /root/app_config.txt" &>/dev/null 2>&1 || { echo "$(get_message no_file)"; exit 0; }

# CHECK 7 — APP= must be 'myapp'
ansible all -m command -a "grep -q '^APP=myapp$' /root/app_config.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message app_wrong)"; exit 0; }

# CHECK 8 — PORT= must be '8080'
ansible all -m command -a "grep -q '^PORT=8080$' /root/app_config.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message port_wrong)"; exit 0; }

# CHECK 9 — ENV= must be 'production'
ansible all -m command -a "grep -q '^ENV=production$' /root/app_config.txt" \
  &>/dev/null 2>&1 || { echo "$(get_message env_wrong)"; exit 0; }

echo '{"result": "0"}'
