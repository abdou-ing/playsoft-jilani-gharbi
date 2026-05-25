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
  ["no_user"]="User 'john' does not exist. Create it first: sudo useradd -m -s /bin/bash john"
  ["no_expiry"]="John's account expiry is not set (shows 'never'). Set it with: sudo chage -E 2026-12-31 john"
  ["wrong_expiry"]="John's account expiry is not set to 2026-12-31. Run: sudo chage -E 2026-12-31 john — then verify with: chage -l john"
)
declare -A messages_fr=(
  ["no_user"]="L'utilisateur 'john' n'existe pas. Créez-le d'abord : sudo useradd -m -s /bin/bash john"
  ["no_expiry"]="L'expiration du compte de john n'est pas définie (affiche 'never'). Définissez-la avec : sudo chage -E 2026-12-31 john"
  ["wrong_expiry"]="L'expiration du compte de john n'est pas définie au 2026-12-31. Exécutez : sudo chage -E 2026-12-31 john — puis vérifiez avec : chage -l john"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if ! id john &>/dev/null; then
  echo "$(get_message no_user)"; exit 0
fi

chage_output=$(sudo chage -l john 2>/dev/null)
expiry_line=$(echo "$chage_output" | grep -i "Account expires")

if echo "$expiry_line" | grep -qi "never"; then
  echo "$(get_message no_expiry)"; exit 0
fi

if ! echo "$expiry_line" | grep -q "2026"; then
  echo "$(get_message wrong_expiry)"; exit 0
fi

if ! echo "$expiry_line" | grep -qi "dec" || ! echo "$expiry_line" | grep -q "31"; then
  echo "$(get_message wrong_expiry)"; exit 0
fi

echo '{"result": "0"}'
