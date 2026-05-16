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
  ["no_playbook"]="Playbook ~/playbooks/add_hosts.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/add_hosts.yml"
  # entry completely missing
  ["entry_missing"]="Entry '10.0.0.1 myserver' not found in /etc/hosts on all hosts. Run: ansible-playbook playbooks/add_hosts.yml"
  # wrong IP used (e.g. 127.0.0.1 myserver)
  ["wrong_ip"]="'myserver' entry found in /etc/hosts but with wrong IP. Expected: 10.0.0.1 myserver"
  # entry duplicated (lineinfile without line param makes it non-idempotent)
  ["entry_duplicate"]="Entry '10.0.0.1 myserver' appears more than once in /etc/hosts. Use the lineinfile module with the 'line' parameter to ensure idempotency."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/add_hosts.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/add_hosts.yml"
  ["entry_missing"]="L'entrée '10.0.0.1 myserver' est absente de /etc/hosts sur tous les hôtes. Exécutez : ansible-playbook playbooks/add_hosts.yml"
  ["wrong_ip"]="L'entrée 'myserver' existe dans /etc/hosts mais avec une mauvaise IP. Attendu : 10.0.0.1 myserver"
  ["entry_duplicate"]="L'entrée '10.0.0.1 myserver' apparaît plus d'une fois dans /etc/hosts. Utilisez le module lineinfile avec le paramètre 'line' pour garantir l'idempotence."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/add_hosts.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/add_hosts.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — exact entry must exist in /etc/hosts on all hosts
ansible all -m command -a "grep '10.0.0.1 myserver' /etc/hosts" &>/dev/null 2>&1 || {
  # CHECK 3b — check if myserver exists but with wrong IP
  if ansible all -m command -a "grep 'myserver' /etc/hosts" &>/dev/null 2>&1; then
    echo "$(get_message wrong_ip)"; exit 0
  fi
  echo "$(get_message entry_missing)"; exit 0
}

# CHECK 4 — entry must appear exactly once (idempotency check)
# (catches: candidate used lineinfile without 'line' param or ran playbook multiple times with append)
count=$(ansible all -m command -a "grep -c '10.0.0.1 myserver' /etc/hosts" 2>/dev/null | grep -E '^[0-9]+$' | sort -rn | head -1)
if [[ -n "$count" && "$count" -gt 1 ]]; then
  echo "$(get_message entry_duplicate)"; exit 0
fi

echo '{"result": "0"}'
