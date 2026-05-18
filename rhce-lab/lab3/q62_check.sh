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
  ["no_vars_file"]="Variables file ~/playbooks/my_package.yml not found. Create it with: pkg_name: curl"
  ["no_pkg_name"]="Variable 'pkg_name' not found in my_package.yml. Add the line: pkg_name: curl"
  ["wrong_pkg_value"]="Variable 'pkg_name' must be set to 'curl' in my_package.yml."
  ["no_playbook"]="Playbook ~/playbooks/install_from_vars.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/install_from_vars.yml"
  ["no_vars_files"]="Playbook does not use 'vars_files:'. Load the variables file with: vars_files: [my_package.yml]"
  ["no_pkg_ref"]="Playbook does not reference '{{ pkg_name }}'. Use it as the package name in your apt task."
  ["pkg_missing"]="Package 'curl' is not installed on all managed hosts. Run: ansible-playbook playbooks/install_from_vars.yml"
)
declare -A messages_fr=(
  ["no_vars_file"]="Le fichier de variables ~/playbooks/my_package.yml est introuvable. Créez-le avec : pkg_name: curl"
  ["no_pkg_name"]="La variable 'pkg_name' est introuvable dans my_package.yml. Ajoutez la ligne : pkg_name: curl"
  ["wrong_pkg_value"]="La variable 'pkg_name' doit être définie à 'curl' dans my_package.yml."
  ["no_playbook"]="Le playbook ~/playbooks/install_from_vars.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/install_from_vars.yml"
  ["no_vars_files"]="Le playbook n'utilise pas 'vars_files:'. Chargez le fichier de variables avec : vars_files: [my_package.yml]"
  ["no_pkg_ref"]="Le playbook ne référence pas '{{ pkg_name }}'. Utilisez-le comme nom de paquet dans votre tâche apt."
  ["pkg_missing"]="Le paquet 'curl' n'est pas installé sur tous les hôtes gérés. Exécutez : ansible-playbook playbooks/install_from_vars.yml"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — variables file must exist
[ -f "playbooks/my_package.yml" ] || { echo "$(get_message no_vars_file)"; exit 0; }

# CHECK 2 — pkg_name must be defined in the vars file
grep -q "pkg_name" playbooks/my_package.yml || { echo "$(get_message no_pkg_name)"; exit 0; }

# CHECK 3 — pkg_name must be curl
grep -q "pkg_name:.*curl" playbooks/my_package.yml || { echo "$(get_message wrong_pkg_value)"; exit 0; }

# CHECK 4 — playbook file must exist
[ -f "playbooks/install_from_vars.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 5 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/install_from_vars.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 6 — playbook must use vars_files
grep -q "vars_files" playbooks/install_from_vars.yml || { echo "$(get_message no_vars_files)"; exit 0; }

# CHECK 7 — playbook must reference pkg_name variable
grep -q "pkg_name" playbooks/install_from_vars.yml || { echo "$(get_message no_pkg_ref)"; exit 0; }

# CHECK 8 — curl must be installed on all managed hosts
ansible all -m command -a "which curl" &>/dev/null 2>&1 || { echo "$(get_message pkg_missing)"; exit 0; }

echo '{"result": "0"}'
