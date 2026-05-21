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
  ["no_secret"]="File /home/ansible_user/workspace/secret.yml not found. This file should have been pre-created by the setup. Contact your instructor."
  ["not_encrypted"]="secret.yml is not encrypted. It must be an Ansible Vault file."
  ["old_password_works"]="secret.yml can still be decrypted with the OLD password 'curabete'. You must rekey it: ansible-vault rekey secret.yml"
  ["new_password_fails"]="secret.yml cannot be decrypted with the NEW password 'newvare'. Rekey it correctly: ansible-vault rekey secret.yml (old: curabete, new: newvare)"
)
declare -A messages_fr=(
  ["no_secret"]="Fichier /home/ansible_user/workspace/secret.yml introuvable. Ce fichier aurait dû être pré-créé par la configuration. Contactez votre formateur."
  ["not_encrypted"]="secret.yml n'est pas chiffré. Il doit s'agir d'un fichier Ansible Vault."
  ["old_password_works"]="secret.yml peut encore être déchiffré avec l'ANCIEN mot de passe 'curabete'. Vous devez le renchaîner : ansible-vault rekey secret.yml"
  ["new_password_fails"]="secret.yml ne peut pas être déchiffré avec le NOUVEAU mot de passe 'newvare'. Renchaînez-le correctement : ansible-vault rekey secret.yml (ancien : curabete, nouveau : newvare)"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# PREREQUISITE: Create secret.yml if it doesn't exist (encrypted with "curabete")
if [ ! -f "playbooks/secret.yml" ]; then
  mkdir -p playbooks
  echo "curabete" > /tmp/_vault_setup_pass.txt
  printf 'secret_key: mysecretvalue\nexam_token: rhce2024\n' | \
    ansible-vault encrypt --vault-password-file=/tmp/_vault_setup_pass.txt \
    --output=playbooks/secret.yml /dev/stdin 2>/dev/null
  rm -f /tmp/_vault_setup_pass.txt
  # If still not created, report error
  [ -f "playbooks/secret.yml" ] || { echo "$(get_message no_secret)"; exit 0; }
fi

# CHECK 1 — secret.yml must exist
[ -f "playbooks/secret.yml" ] || { echo "$(get_message no_secret)"; exit 0; }

# CHECK 2 — must be encrypted
head -1 playbooks/secret.yml | grep -q '^\$ANSIBLE_VAULT' || { echo "$(get_message not_encrypted)"; exit 0; }

# CHECK 3 — old password "curabete" must NOT work anymore
echo "curabete" > /tmp/_check_old_pass.txt
if ansible-vault decrypt --output=- playbooks/secret.yml \
    --vault-password-file=/tmp/_check_old_pass.txt &>/dev/null 2>&1; then
  rm -f /tmp/_check_old_pass.txt
  echo "$(get_message old_password_works)"; exit 0
fi
rm -f /tmp/_check_old_pass.txt

# CHECK 4 — new password "newvare" must work
echo "newvare" > /tmp/_check_new_pass.txt
if ! ansible-vault decrypt --output=- playbooks/secret.yml \
    --vault-password-file=/tmp/_check_new_pass.txt &>/dev/null 2>&1; then
  rm -f /tmp/_check_new_pass.txt
  echo "$(get_message new_password_fails)"; exit 0
fi
rm -f /tmp/_check_new_pass.txt

echo '{"result": "0"}'
