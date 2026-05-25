#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

# Skip-q78 guard: create john if he was not created yet
if ! id john &>/dev/null; then
  sudo useradd -m -s /bin/bash john 2>/dev/null || true
fi

# Clean state: reset password aging to defaults so the task is fresh each run
sudo chage -M 99999 -W 7 john 2>/dev/null || true

cmd1="sudo chage -M 90 -W 7 john"
cmd2="chage -l john"

case "$lang" in
  en)
    question="Security policy has now been finalized. Configure John's account so that his password expires every \`90\` days and he is warned \`7\` days before expiry."
    hint="Use chage with -M for maximum days and -W for warning days. Run: sudo chage -M 90 -W 7 john. Verify with: chage -l john — look for 'Maximum number of days between password change: 90' and 'Number of days of warning: 7'."
    inst1="Set the maximum password age to <span class=\"bold-green-text\">90 days</span> and the warning period to <span class=\"bold-green-text\">7 days</span> for john:"
    inst2="Verify the new password aging policy is correctly applied to <span class=\"bold-green-text\">john</span>:"
    ;;
  fr)
    question="La politique de sécurité a maintenant été finalisée. Configurez le compte de John afin que son mot de passe expire tous les \`90\` jours et qu'il soit averti \`7\` jours avant l'expiration."
    hint="Utilisez chage avec -M pour le nombre maximum de jours et -W pour les jours d'avertissement. Exécutez : sudo chage -M 90 -W 7 john. Vérifiez avec : chage -l john — cherchez 'Maximum number of days between password change: 90' et 'Number of days of warning: 7'."
    inst1="Définissez l'âge maximum du mot de passe à <span class=\"bold-green-text\">90 jours</span> et la période d'avertissement à <span class=\"bold-green-text\">7 jours</span> pour john :"
    inst2="Vérifiez que la nouvelle politique de vieillissement du mot de passe est correctement appliquée à <span class=\"bold-green-text\">john</span> :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n --arg inst1 "$inst1" --arg cmd1 "$cmd1" --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" \
  --arg hint "$hint" \
  --argjson instructions "$instructions" \
  '{
    "question": $question,
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "type": "button",
    "hint": $hint,
    "instructions": $instructions,
    "text": "Check",
    "tags": "linux,chage,password-policy,security,onboarding"
  }'
