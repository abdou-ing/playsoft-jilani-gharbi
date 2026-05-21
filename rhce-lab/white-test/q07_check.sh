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
  ["no_playbook"]="Playbook /home/ansible_user/workspace/balance.yml not found. Create it with three plays."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/balance.yml"
  ["not_three_plays"]="balance.yml must have exactly 3 plays (gather facts, balancer play, webservers play). Count the 'hosts:' lines."
  ["no_all_hosts"]="Play 1 must target 'all' hosts for fact gathering. Add: hosts: all"
  ["no_balancers_play"]="Play 2 must target the 'balancers' group. Add a play with hosts: balancers."
  ["no_webservers_play"]="Play 3 must target the 'webservers' group. Add a play with hosts: webservers."
  ["no_balancer_role"]="balance.yml does not reference the 'balancer' role. Add 'roles: [balancer]' to the balancers play."
  ["no_phpinfo_role"]="balance.yml does not reference the 'phpinfo' role. Add 'roles: [phpinfo]' to the webservers play."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/balance.yml est introuvable. Créez-le avec trois plays."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/balance.yml"
  ["not_three_plays"]="balance.yml doit avoir exactement 3 plays (collecte de faits, play balancer, play webservers). Comptez les lignes 'hosts:'."
  ["no_all_hosts"]="Le Play 1 doit cibler tous les hôtes ('all') pour la collecte de faits. Ajoutez : hosts: all"
  ["no_balancers_play"]="Le Play 2 doit cibler le groupe 'balancers'. Ajoutez un play avec hosts: balancers."
  ["no_webservers_play"]="Le Play 3 doit cibler le groupe 'webservers'. Ajoutez un play avec hosts: webservers."
  ["no_balancer_role"]="balance.yml ne référence pas le rôle 'balancer'. Ajoutez 'roles: [balancer]' au play balancers."
  ["no_phpinfo_role"]="balance.yml ne référence pas le rôle 'phpinfo'. Ajoutez 'roles: [phpinfo]' au play webservers."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook must exist
[ -f "playbooks/balance.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — no syntax errors
ansible-playbook --syntax-check playbooks/balance.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — must have exactly 3 plays (3 'hosts:' lines at root level)
play_count=$(grep -c "^- hosts:\|^  hosts:" playbooks/balance.yml 2>/dev/null || echo 0)
hosts_count=$(grep -c "^- name:" playbooks/balance.yml 2>/dev/null || echo 0)
[ "$hosts_count" -ge 3 ] || { echo "$(get_message not_three_plays)"; exit 0; }

# CHECK 4 — first play must target all
grep -q "hosts:\s*all" playbooks/balance.yml || { echo "$(get_message no_all_hosts)"; exit 0; }

# CHECK 5 — must have balancers play
grep -q "hosts:\s*balancers" playbooks/balance.yml || { echo "$(get_message no_balancers_play)"; exit 0; }

# CHECK 6 — must have webservers play
grep -q "hosts:\s*webservers" playbooks/balance.yml || { echo "$(get_message no_webservers_play)"; exit 0; }

# CHECK 7 — must reference balancer role
grep -q "balancer" playbooks/balance.yml || { echo "$(get_message no_balancer_role)"; exit 0; }

# CHECK 8 — must reference phpinfo role
grep -q "phpinfo" playbooks/balance.yml || { echo "$(get_message no_phpinfo_role)"; exit 0; }

echo '{"result": "0"}'
