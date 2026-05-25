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
  ["wrong_max"]="John's maximum password age is not set to 90 days. Run: sudo chage -M 90 john — then verify with: chage -l john"
  ["wrong_warn"]="John's password warning period is not set to 7 days. Run: sudo chage -W 7 john — then verify with: chage -l john"
)
declare -A messages_fr=(
  ["no_user"]="L'utilisateur 'john' n'existe pas. Créez-le d'abord : sudo useradd -m -s /bin/bash john"
  ["wrong_max"]="L'âge maximum du mot de passe de john n'est pas défini à 90 jours. Exécutez : sudo chage -M 90 john — puis vérifiez avec : chage -l john"
  ["wrong_warn"]="La période d'avertissement du mot de passe de john n'est pas définie à 7 jours. Exécutez : sudo chage -W 7 john — puis vérifiez avec : chage -l john"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if ! id john &>/dev/null; then
  echo "$(get_message no_user)"; exit 0
fi

chage_output=$(sudo chage -l john 2>/dev/null)

max_days=$(echo "$chage_output" | grep -i "Maximum number" | grep -oE '[0-9]+$')
warn_days=$(echo "$chage_output" | grep -i "warning" | grep -oE '[0-9]+$')

if [ "$max_days" != "90" ]; then
  echo "$(get_message wrong_max)"; exit 0
fi

if [ "$warn_days" != "7" ]; then
  echo "$(get_message wrong_warn)"; exit 0
fi

echo '{"result": "0"}'
