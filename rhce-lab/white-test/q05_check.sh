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
  ["no_role_dir"]="Role directory /home/ansible_user/workspace/roles/apache/ not found. Create it with: mkdir -p /home/ansible_user/workspace/roles/apache/{tasks,templates,vars,handlers}"
  ["no_tasks"]="File /home/ansible_user/workspace/roles/apache/tasks/main.yml not found. Create it with the required tasks."
  ["no_template"]="Template /home/ansible_user/workspace/roles/apache/templates/index.html.j2 not found. Create the Jinja2 template."
  ["no_vars"]="File /home/ansible_user/workspace/roles/apache/vars/main.yml not found. Create it with pkgs and rule variables."
  ["no_playbook"]="Playbook /home/ansible_user/workspace/newrole.yml not found. Create it using the apache role on webservers group."
  ["syntax_error"]="Playbook /home/ansible_user/workspace/newrole.yml has syntax errors. Run: ansible-playbook --syntax-check playbooks/newrole.yml"
  ["no_apache_role_ref"]="newrole.yml does not reference the apache role. Add 'roles: [apache]' to the playbook."
  ["apache_not_running"]="apache2 is not running on web1 or web2. Run: ansible-playbook playbooks/newrole.yml"
  ["no_index_html"]="/var/www/html/index.html not found on web1 or web2. The template task must deploy it."
  ["no_welcome_content"]="/var/www/html/index.html does not contain 'Welcome to' on web1 or web2."
  ["no_fqdn_fact"]="Template does not use ansible_facts['fqdn']. Add the FQDN fact to index.html.j2."
  ["no_ip_fact"]="Template does not use ansible_facts['default_ipv4']. Add the IP fact to index.html.j2."
)
declare -A messages_fr=(
  ["no_role_dir"]="Répertoire du rôle /home/ansible_user/workspace/roles/apache/ introuvable. Créez-le avec : mkdir -p /home/ansible_user/workspace/roles/apache/{tasks,templates,vars,handlers}"
  ["no_tasks"]="Fichier /home/ansible_user/workspace/roles/apache/tasks/main.yml introuvable. Créez-le avec les tâches requises."
  ["no_template"]="Template /home/ansible_user/workspace/roles/apache/templates/index.html.j2 introuvable. Créez le template Jinja2."
  ["no_vars"]="Fichier /home/ansible_user/workspace/roles/apache/vars/main.yml introuvable. Créez-le avec les variables pkgs et rule."
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/newrole.yml est introuvable. Créez-le en utilisant le rôle apache sur le groupe webservers."
  ["syntax_error"]="Le playbook /home/ansible_user/workspace/newrole.yml contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/newrole.yml"
  ["no_apache_role_ref"]="newrole.yml ne référence pas le rôle apache. Ajoutez 'roles: [apache]' au playbook."
  ["apache_not_running"]="apache2 n'est pas en cours d'exécution sur web1 ou web2. Exécutez : ansible-playbook playbooks/newrole.yml"
  ["no_index_html"]="/var/www/html/index.html introuvable sur web1 ou web2. La tâche template doit le déployer."
  ["no_welcome_content"]="/var/www/html/index.html ne contient pas 'Welcome to' sur web1 ou web2."
  ["no_fqdn_fact"]="Le template n'utilise pas ansible_facts['fqdn']. Ajoutez le fact FQDN dans index.html.j2."
  ["no_ip_fact"]="Le template n'utilise pas ansible_facts['default_ipv4']. Ajoutez le fact IP dans index.html.j2."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — role directory must exist
[ -d "playbooks/roles/apache" ] || { echo "$(get_message no_role_dir)"; exit 0; }

# CHECK 2 — tasks/main.yml must exist
[ -f "playbooks/roles/apache/tasks/main.yml" ] || { echo "$(get_message no_tasks)"; exit 0; }

# CHECK 3 — template must exist
[ -f "playbooks/roles/apache/templates/index.html.j2" ] || { echo "$(get_message no_template)"; exit 0; }

# CHECK 4 — vars/main.yml must exist
[ -f "playbooks/roles/apache/vars/main.yml" ] || { echo "$(get_message no_vars)"; exit 0; }

# CHECK 5 — template uses the required facts
grep -q "fqdn" playbooks/roles/apache/templates/index.html.j2 || { echo "$(get_message no_fqdn_fact)"; exit 0; }
grep -q "default_ipv4" playbooks/roles/apache/templates/index.html.j2 || { echo "$(get_message no_ip_fact)"; exit 0; }

# CHECK 6 — newrole.yml must exist
[ -f "playbooks/newrole.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 7 — no syntax errors
ansible-playbook --syntax-check playbooks/newrole.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 8 — playbook references apache role
grep -q "apache" playbooks/newrole.yml || { echo "$(get_message no_apache_role_ref)"; exit 0; }

# CHECK 9 — apache2 running on webservers
ansible webservers -m shell -a "systemctl is-active apache2" &>/dev/null 2>&1 || \
  { echo "$(get_message apache_not_running)"; exit 0; }

# CHECK 10 — index.html exists and contains "Welcome to"
ansible webservers -m command -a "test -f /var/www/html/index.html" &>/dev/null 2>&1 || \
  { echo "$(get_message no_index_html)"; exit 0; }

ansible webservers -m shell -a "grep -q 'Welcome to' /var/www/html/index.html" &>/dev/null 2>&1 || \
  { echo "$(get_message no_welcome_content)"; exit 0; }

echo '{"result": "0"}'
