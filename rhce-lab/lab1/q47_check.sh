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
  ["no_key"]="No SSH key found at ~/.ssh/id_rsa or ~/.ssh/id_ed25519. Run: ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["empty_key"]="SSH key file exists but is empty. Run: ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["invalid_key"]="SSH key file does not contain a valid RSA or ED25519 private key. Run: ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["bad_perms"]="SSH private key has wrong permissions. Fix with: chmod 600 ~/.ssh/id_rsa"
  ["no_pub"]="Public key file not found. Regenerate both files: ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["pub_mismatch"]="Public key does not match the private key. Regenerate: ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["passphrase_key"]="SSH key is protected by a passphrase. Generate a key with no passphrase: ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["key_too_short"]="RSA key is too short (minimum 2048 bits). Regenerate: ssh-keygen -t rsa -b 2048 -N \"\" -f ~/.ssh/id_rsa"
)
declare -A messages_fr=(
  ["no_key"]="Aucune clé SSH trouvée dans ~/.ssh/id_rsa ou ~/.ssh/id_ed25519. Exécutez : ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["empty_key"]="Le fichier de clé SSH existe mais est vide. Exécutez : ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["invalid_key"]="Le fichier de clé SSH ne contient pas une clé privée RSA ou ED25519 valide. Exécutez : ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["bad_perms"]="Les permissions de la clé privée SSH sont incorrectes. Corrigez avec : chmod 600 ~/.ssh/id_rsa"
  ["no_pub"]="Le fichier de clé publique est introuvable. Régénérez les deux fichiers : ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["pub_mismatch"]="La clé publique ne correspond pas à la clé privée. Régénérez : ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["passphrase_key"]="La clé SSH est protégée par une phrase secrète. Générez une clé sans phrase secrète : ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
  ["key_too_short"]="La clé RSA est trop courte (minimum 2048 bits). Régénérez : ssh-keygen -t rsa -b 2048 -N \"\" -f ~/.ssh/id_rsa"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

# Determine which key file exists
key_file=""
[ -f "$HOME/.ssh/id_rsa" ]     && key_file="$HOME/.ssh/id_rsa"
[ -f "$HOME/.ssh/id_ed25519" ] && key_file="$HOME/.ssh/id_ed25519"

# No key file at all
if [ -z "$key_file" ]; then
  echo "$(get_message no_key)"; exit 0
fi

# File exists but is empty
if [ ! -s "$key_file" ]; then
  echo "$(get_message empty_key)"; exit 0
fi

# File must start with a valid PEM private key header
first_line=$(head -1 "$key_file")
if [[ "$first_line" != "-----BEGIN OPENSSH PRIVATE KEY-----" && \
      "$first_line" != "-----BEGIN RSA PRIVATE KEY-----" ]]; then
  echo "$(get_message invalid_key)"; exit 0
fi

# Private key permissions must be 600 or 400 (SSH refuses to use world-readable keys)
perms=$(stat -c "%a" "$key_file" 2>/dev/null)
if [[ "$perms" != "600" && "$perms" != "400" ]]; then
  echo "$(get_message bad_perms)"; exit 0
fi

# Key must have no passphrase (ssh-keygen -y should succeed without a prompt)
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

# RSA keys must be at least 2048 bits (ED25519 is always 256 bits, always acceptable)
key_bits=$(ssh-keygen -l -f "$key_file" 2>/dev/null | awk '{print $1}')
key_type=$(ssh-keygen -l -f "$key_file" 2>/dev/null | awk '{print $NF}' | tr -d '()')
if [[ "$key_type" == "RSA" && -n "$key_bits" && "$key_bits" -lt 2048 ]]; then
  echo "$(get_message key_too_short)"; exit 0
fi

echo '{"result": "0"}'
