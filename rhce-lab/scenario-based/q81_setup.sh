#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

# Skip-q78 guard: create john if he was not created yet
if ! id john &>/dev/null; then
  sudo useradd -m -s /bin/bash john 2>/dev/null || true
fi

# Reset password aging to Ubuntu defaults so the question reflects the fresh state
# (in case q83 was done first and already set max to 90)
sudo chage -M 99999 -W 7 john 2>/dev/null || true

cmd1="chage -l john"

answer_a="99999"
answer_b="90"
answer_c="60"
answer_d="365"
solution="$answer_a"

case "$lang" in
  en)
    question="Before John sets a long-term password, security asks you to verify the current password aging policy on his account — specifically, has a maximum password age been set yet? What value does Ubuntu report for the \`Maximum number of days between password change\` for John's account right now?"
    hint="Run 'chage -l john' to list password aging information. Look for the 'Maximum number of days between password change' line — Ubuntu's default before any policy is applied means no expiry is enforced."
    inst1="Run this command to display John's current password aging policy:"
    ;;
  fr)
    question="Avant que John ne définisse un mot de passe à long terme, la sécurité vous demande de vérifier la politique de vieillissement actuelle sur son compte — en particulier, un âge maximum de mot de passe a-t-il été défini ? Quelle valeur Ubuntu rapporte-t-il pour le \`Maximum number of days between password change\` du compte de John en ce moment ?"
    hint="Exécutez 'chage -l john' pour lister les informations de vieillissement du mot de passe. Regardez la ligne 'Maximum number of days between password change' — la valeur par défaut d'Ubuntu avant l'application d'une politique signifie qu'aucune expiration n'est appliquée."
    inst1="Exécutez cette commande pour afficher la politique de vieillissement actuelle du mot de passe de John :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")
shuffled=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

jq -n --indent 4 \
  --arg question "$question" \
  --arg hint "$hint" \
  --arg inst1 "$inst1" \
  --arg cmd1 "$cmd1" \
  --arg solution "$solution" \
  --argjson answers "{$shuffled}" \
  '{
    "question": $question,
    "type": "multi",
    "answers": $answers,
    "hint": $hint,
    "instructions": [{"instruction": $inst1, "command": $cmd1}],
    "solution": $solution,
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "tags": "linux,chage,password-aging,onboarding"
  }'
