#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

declare -A messages_en=(
  ["no_key"]="No SSH key found at ~/.ssh/id_ed25519. Run: ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["empty_key"]="SSH key file exists but is empty. Run: ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["invalid_key"]="SSH key file does not contain a valid Ed25519 private key. Run: ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["bad_perms"]="SSH private key has wrong permissions. Fix with: chmod 600 ~/.ssh/id_ed25519"
  ["no_pub"]="Public key file not found. Regenerate both files: ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["pub_mismatch"]="Public key does not match the private key. Regenerate: ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["passphrase_key"]="SSH key is protected by a passphrase. Generate a key with no passphrase: ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
)
declare -A messages_fr=(
  ["no_key"]="Aucune clé SSH trouvée dans ~/.ssh/id_ed25519. Exécutez : ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["empty_key"]="Le fichier de clé SSH existe mais est vide. Exécutez : ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["invalid_key"]="Le fichier de clé SSH ne contient pas une clé privée Ed25519 valide. Exécutez : ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["bad_perms"]="Les permissions de la clé privée SSH sont incorrectes. Corrigez avec : chmod 600 ~/.ssh/id_ed25519"
  ["no_pub"]="Le fichier de clé publique est introuvable. Régénérez les deux fichiers : ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["pub_mismatch"]="La clé publique ne correspond pas à la clé privée. Régénérez : ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
  ["passphrase_key"]="La clé SSH est protégée par une phrase secrète. Générez une clé sans phrase secrète : ssh-keygen -t ed25519 -N \\\"\\\" -f ~/.ssh/id_ed25519"
)


key_file="/home/ansible_user/.ssh/id_ed25519"

# No key file at all
if [ ! -f "$key_file" ]; then
  echo "$(get_message no_key)"; exit 0
fi

# File exists but is empty
if [ ! -s "$key_file" ]; then
  echo "$(get_message empty_key)"; exit 0
fi

# File must start with a valid OpenSSH private key header
first_line=$(head -1 "$key_file")
if [[ "$first_line" != "-----BEGIN OPENSSH PRIVATE KEY-----" ]]; then
  echo "$(get_message invalid_key)"; exit 0
fi

# Private key permissions must be 600 or 400
perms=$(stat -c "%a" "$key_file" 2>/dev/null)
if [[ "$perms" != "600" && "$perms" != "400" ]]; then
  echo "$(get_message bad_perms)"; exit 0
fi

# Key must have no passphrase
if ! ssh-keygen -y -P "" -f "$key_file" &>/dev/null; then
  echo "$(get_message passphrase_key)"; exit 0
fi

# Public key file must exist alongside the private key
pub_file="${key_file}.pub"
if [ ! -f "$pub_file" ]; then
  echo "$(get_message no_pub)"; exit 0
fi

# Public key must match the private key
generated_pub=$(ssh-keygen -y -P "" -f "$key_file" 2>/dev/null | awk '{print $1, $2}')
stored_pub=$(awk '{print $1, $2}' "$pub_file" 2>/dev/null)
if [[ "$generated_pub" != "$stored_pub" ]]; then
  echo "$(get_message pub_mismatch)"; exit 0
fi

# Verify the key type is actually Ed25519
key_type=$(ssh-keygen -l -f "$key_file" 2>/dev/null | awk '{print $NF}' | tr -d '()')
if [[ "$key_type" != "ED25519" ]]; then
  echo "$(get_message invalid_key)"; exit 0
fi

echo '{"result": "0"}'
