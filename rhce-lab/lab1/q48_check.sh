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
  ["no_key"]="No SSH key found. Complete question 2 first: ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["ssh_fail_web1"]="Passwordless SSH to web1 failed. Run: ssh-copy-id ansible_user@web1 (password: Labby123)"
  ["ssh_fail_web2"]="Passwordless SSH to web2 failed. Run: ssh-copy-id ansible_user@web2 (password: Labby123)"
  ["wrong_user_web1"]="SSH works on web1 but not as ansible_user. Make sure you ran: ssh-copy-id ansible_user@web1"
  ["wrong_user_web2"]="SSH works on web2 but not as ansible_user. Make sure you ran: ssh-copy-id ansible_user@web2"
  ["authkeys_perms_web1"]="~/.ssh/authorized_keys on web1 has wrong permissions. SSH will refuse it. Fix on web1: chmod 600 ~/.ssh/authorized_keys"
  ["authkeys_perms_web2"]="~/.ssh/authorized_keys on web2 has wrong permissions. SSH will refuse it. Fix on web2: chmod 600 ~/.ssh/authorized_keys"
  ["key_mismatch_web1"]="The current public key is not in authorized_keys on web1. Re-run: ssh-copy-id ansible_user@web1"
  ["key_mismatch_web2"]="The current public key is not in authorized_keys on web2. Re-run: ssh-copy-id ansible_user@web2"
)
declare -A messages_fr=(
  ["no_key"]="Aucune clé SSH trouvée. Complétez d'abord la question 2 : ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["ssh_fail_web1"]="La connexion SSH sans mot de passe vers web1 a échoué. Exécutez : ssh-copy-id ansible_user@web1 (mot de passe : Labby123)"
  ["ssh_fail_web2"]="La connexion SSH sans mot de passe vers web2 a échoué. Exécutez : ssh-copy-id ansible_user@web2 (mot de passe : Labby123)"
  ["wrong_user_web1"]="SSH fonctionne sur web1 mais pas en tant qu'ansible_user. Assurez-vous d'avoir exécuté : ssh-copy-id ansible_user@web1"
  ["wrong_user_web2"]="SSH fonctionne sur web2 mais pas en tant qu'ansible_user. Assurez-vous d'avoir exécuté : ssh-copy-id ansible_user@web2"
  ["authkeys_perms_web1"]="~/.ssh/authorized_keys sur web1 a des permissions incorrectes. SSH le refusera. Corrigez sur web1 : chmod 600 ~/.ssh/authorized_keys"
  ["authkeys_perms_web2"]="~/.ssh/authorized_keys sur web2 a des permissions incorrectes. SSH le refusera. Corrigez sur web2 : chmod 600 ~/.ssh/authorized_keys"
  ["key_mismatch_web1"]="La clé publique actuelle n'est pas dans authorized_keys sur web1. Ré-exécutez : ssh-copy-id ansible_user@web1"
  ["key_mismatch_web2"]="La clé publique actuelle n'est pas dans authorized_keys sur web2. Ré-exécutez : ssh-copy-id ansible_user@web2"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

SSH="ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5"

# Determine active key file
key_file=""
[ -f "$HOME/.ssh/id_rsa" ]     && key_file="$HOME/.ssh/id_rsa"
[ -f "$HOME/.ssh/id_ed25519" ] && key_file="$HOME/.ssh/id_ed25519"

[ -z "$key_file" ] && { echo "$(get_message no_key)"; exit 0; }

for host in web1 web2; do
  # Basic passwordless SSH test
  if ! $SSH ansible_user@$host true </dev/null 2>/dev/null; then
    echo "$(get_message ssh_fail_$host)"; exit 0
  fi

  # Verify we connected as ansible_user (not another user via default key)
  logged_user=$($SSH ansible_user@$host id -un </dev/null 2>/dev/null)
  if [[ "$logged_user" != "ansible_user" ]]; then
    echo "$(get_message wrong_user_$host)"; exit 0
  fi

  # Check authorized_keys permissions on the remote host (must be 600 or 640)
  authkeys_perms=$($SSH ansible_user@$host "stat -c '%a' ~/.ssh/authorized_keys" </dev/null 2>/dev/null)
  if [[ "$authkeys_perms" != "600" && "$authkeys_perms" != "640" && "$authkeys_perms" != "644" ]]; then
    echo "$(get_message authkeys_perms_$host)"; exit 0
  fi

  # Verify the current public key is actually present in authorized_keys
  current_pubkey=$(ssh-keygen -y -P "" -f "$key_file" 2>/dev/null | awk '{print $1, $2}')
  key_in_authkeys=$($SSH ansible_user@$host "grep -c '$(echo $current_pubkey | awk '{print $2}')' ~/.ssh/authorized_keys" </dev/null 2>/dev/null || echo 0)
  if [[ "$key_in_authkeys" -lt 1 ]]; then
    echo "$(get_message key_mismatch_$host)"; exit 0
  fi
done

echo '{"result": "0"}'
