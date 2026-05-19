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
  ["no_playbook"]="Playbook /home/ansible_user/playbooks/users.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/users.yml"
  # alice checks
  ["alice_missing"]="User alice does not exist on all hosts. Run: ansible-playbook playbooks/users.yml"
  ["alice_shell"]="User alice does not have shell /bin/bash on all hosts. Check the 'shell' parameter in your playbook."
  ["alice_home"]="User alice does not have home /home/alice on all hosts. Check the 'home' parameter in your playbook."
  # bob checks
  ["bob_missing"]="User bob does not exist on all hosts. Run: ansible-playbook playbooks/users.yml"
  ["bob_uid"]="User bob does not have uid 2006 on all hosts. Check the 'uid' parameter in your playbook."
  ["bob_shell"]="User bob does not have shell /bin/sh on all hosts. Check the 'shell' parameter in your playbook."
  ["bob_home"]="User bob does not have home /home/bob on all hosts. Check the 'home' parameter in your playbook."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/playbooks/users.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/users.yml"
  ["alice_missing"]="L'utilisateur alice n'existe pas sur tous les hôtes. Exécutez : ansible-playbook playbooks/users.yml"
  ["alice_shell"]="L'utilisateur alice n'a pas le shell /bin/bash sur tous les hôtes. Vérifiez le paramètre 'shell' dans votre playbook."
  ["alice_home"]="L'utilisateur alice n'a pas le home /home/alice sur tous les hôtes. Vérifiez le paramètre 'home' dans votre playbook."
  ["bob_missing"]="L'utilisateur bob n'existe pas sur tous les hôtes. Exécutez : ansible-playbook playbooks/users.yml"
  ["bob_uid"]="L'utilisateur bob n'a pas l'uid 2006 sur tous les hôtes. Vérifiez le paramètre 'uid' dans votre playbook."
  ["bob_shell"]="L'utilisateur bob n'a pas le shell /bin/sh sur tous les hôtes. Vérifiez le paramètre 'shell' dans votre playbook."
  ["bob_home"]="L'utilisateur bob n'a pas le home /home/bob sur tous les hôtes. Vérifiez le paramètre 'home' dans votre playbook."
)



cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/users.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/users.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — alice must exist on all hosts
ansible all -m command -a "id alice" &>/dev/null 2>&1 || { echo "$(get_message alice_missing)"; exit 0; }

# CHECK 4 — alice must have shell /bin/bash (catches: shell omitted or set to /bin/sh)
ansible all -m command -a "getent passwd alice" 2>/dev/null | grep -q ":/bin/bash$" || { echo "$(get_message alice_shell)"; exit 0; }

# CHECK 5 — alice must have home /home/alice (catches: home omitted, defaults to /home/alice but verify)
ansible all -m command -a "getent passwd alice" 2>/dev/null | grep -q ":/home/alice:" || { echo "$(get_message alice_home)"; exit 0; }

# CHECK 6 — bob must exist on all hosts
ansible all -m command -a "id bob" &>/dev/null 2>&1 || { echo "$(get_message bob_missing)"; exit 0; }

# CHECK 7 — bob must have uid 2006 (catches: uid omitted or set to wrong value)
ansible all -m command -a "id -u bob" 2>/dev/null | grep -q "^2006$" || { echo "$(get_message bob_uid)"; exit 0; }

# CHECK 8 — bob must have shell /bin/sh (catches: shell set to /bin/bash instead)
ansible all -m command -a "getent passwd bob" 2>/dev/null | grep -q ":/bin/sh$" || { echo "$(get_message bob_shell)"; exit 0; }

# CHECK 9 — bob must have home /home/bob (catches: home omitted or wrong path)
ansible all -m command -a "getent passwd bob" 2>/dev/null | grep -q ":/home/bob:" || { echo "$(get_message bob_home)"; exit 0; }

echo '{"result": "0"}'
