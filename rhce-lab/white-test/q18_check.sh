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
  ["no_playbook"]="Playbook /home/ansible_user/workspace/selinux.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/selinux.yml"
  ["no_selinux_ref"]="Playbook does not reference 'selinux' or 'apparmor'. Use ansible.posix.selinux module with state: permissive and policy: targeted."
  ["no_state"]="Playbook does not set 'state: permissive'. The selinux module requires state: permissive."
  ["no_policy"]="Playbook does not set 'policy: targeted'. The selinux module requires policy: targeted."
  ["no_hosts_all"]="Playbook does not target 'hosts: all'. It must run on all managed hosts."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/selinux.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/selinux.yml"
  ["no_selinux_ref"]="Le playbook ne fait pas référence à 'selinux' ou 'apparmor'. Utilisez le module ansible.posix.selinux avec state: permissive et policy: targeted."
  ["no_state"]="Le playbook ne définit pas 'state: permissive'. Le module selinux nécessite state: permissive."
  ["no_policy"]="Le playbook ne définit pas 'policy: targeted'. Le module selinux nécessite policy: targeted."
  ["no_hosts_all"]="Le playbook ne cible pas 'hosts: all'. Il doit s'exécuter sur tous les hôtes gérés."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook must exist
[ -f "playbooks/selinux.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — no syntax errors
ansible-playbook --syntax-check playbooks/selinux.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must reference selinux or apparmor module
grep -qi "selinux\|apparmor" playbooks/selinux.yml || { echo "$(get_message no_selinux_ref)"; exit 0; }

# CHECK 4 — playbook must set state: permissive
grep -q "state:.*permissive\|permissive" playbooks/selinux.yml || { echo "$(get_message no_state)"; exit 0; }

# CHECK 5 — playbook must set policy: targeted
grep -q "policy:.*targeted\|targeted" playbooks/selinux.yml || { echo "$(get_message no_policy)"; exit 0; }

# CHECK 6 — playbook must target all hosts
grep -q "hosts:\s*all" playbooks/selinux.yml || { echo "$(get_message no_hosts_all)"; exit 0; }

echo '{"result": "0"}'
