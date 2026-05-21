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
  ["no_vault"]="File /home/ansible_user/workspace/vault.yml not found. Create it with ansible-vault."
  ["not_encrypted"]="vault.yml is not encrypted. It must start with \$ANSIBLE_VAULT. Run: ansible-vault encrypt vault.yml --vault-password-file=password.txt"
  ["no_password_file"]="File /home/ansible_user/workspace/password.txt not found. Create it with: echo 'atenorth' > /home/ansible_user/workspace/password.txt"
  ["wrong_password_perms"]="password.txt does not have permissions 0600. Run: chmod 0600 /home/ansible_user/workspace/password.txt"
  ["wrong_vault_password"]="Cannot decrypt vault.yml with password 'atenorth'. Ensure password.txt contains exactly 'atenorth'."
  ["missing_dev_pass"]="vault.yml does not contain 'dev_pass' key after decryption. Add: dev_pass: wakennym"
  ["missing_mgr_pass"]="vault.yml does not contain 'mgr_pass' key after decryption. Add: mgr_pass: rocky"
)
declare -A messages_fr=(
  ["no_vault"]="Fichier /home/ansible_user/workspace/vault.yml introuvable. Créez-le avec ansible-vault."
  ["not_encrypted"]="vault.yml n'est pas chiffré. Il doit commencer par \$ANSIBLE_VAULT. Exécutez : ansible-vault encrypt vault.yml --vault-password-file=password.txt"
  ["no_password_file"]="Fichier /home/ansible_user/workspace/password.txt introuvable. Créez-le avec : echo 'atenorth' > /home/ansible_user/workspace/password.txt"
  ["wrong_password_perms"]="password.txt n'a pas les permissions 0600. Exécutez : chmod 0600 /home/ansible_user/workspace/password.txt"
  ["wrong_vault_password"]="Impossible de déchiffrer vault.yml avec le mot de passe 'atenorth'. Assurez-vous que password.txt contient exactement 'atenorth'."
  ["missing_dev_pass"]="vault.yml ne contient pas la clé 'dev_pass' après déchiffrement. Ajoutez : dev_pass: wakennym"
  ["missing_mgr_pass"]="vault.yml ne contient pas la clé 'mgr_pass' après déchiffrement. Ajoutez : mgr_pass: rocky"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — vault.yml must exist
[ -f "playbooks/vault.yml" ] || { echo "$(get_message no_vault)"; exit 0; }

# CHECK 2 — must be encrypted
head -1 playbooks/vault.yml | grep -q '^\$ANSIBLE_VAULT' || { echo "$(get_message not_encrypted)"; exit 0; }

# CHECK 3 — password.txt must exist
[ -f "playbooks/password.txt" ] || { echo "$(get_message no_password_file)"; exit 0; }

# CHECK 4 — password.txt must have mode 0600
perms=$(stat -c "%a" playbooks/password.txt 2>/dev/null)
[ "$perms" = "600" ] || { echo "$(get_message wrong_password_perms)"; exit 0; }

# CHECK 5 — must be decryptable with "atenorth"
decrypted=$(ansible-vault decrypt --output=- playbooks/vault.yml --vault-password-file=playbooks/password.txt 2>/dev/null)
[ $? -eq 0 ] || { echo "$(get_message wrong_vault_password)"; exit 0; }

# CHECK 6 — must contain dev_pass key
echo "$decrypted" | grep -q "dev_pass" || { echo "$(get_message missing_dev_pass)"; exit 0; }

# CHECK 7 — must contain mgr_pass key
echo "$decrypted" | grep -q "mgr_pass" || { echo "$(get_message missing_mgr_pass)"; exit 0; }

echo '{"result": "0"}'
