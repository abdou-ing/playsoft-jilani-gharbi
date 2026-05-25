#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

# Skip-q78 guard: create john if he was not created yet
if ! id john &>/dev/null; then
  sudo useradd -m -s /bin/bash john 2>/dev/null || true
fi

# Clean state: reset any existing account expiry so the task is fresh each run
sudo chage -E -1 john 2>/dev/null || true

cmd1="sudo chage -E 2026-12-31 john"
cmd2="chage -l john"

case "$lang" in
  en)
    question="John's three-month contract has a fixed end date. To stay compliant, configure his account to automatically expire (be disabled) on \`2026-12-31\`, so no manual cleanup is needed when the contract ends."
    hint="Use chage -E with the date in YYYY-MM-DD format. Run: sudo chage -E 2026-12-31 john. Verify with: chage -l john — look for the 'Account expires' line showing Dec 31, 2026."
    inst1="Set John's account expiry date to <span class=\"bold-green-text\">2026-12-31</span> so it is automatically disabled when his contract ends:"
    inst2="Verify the account expiry is correctly configured — look for the <span class=\"bold-green-text\">Account expires</span> line:"
    ;;
  fr)
    question="Le contrat de trois mois de John a une date de fin fixe. Pour rester conforme, configurez son compte pour qu'il expire (soit désactivé) automatiquement le \`2026-12-31\`, afin qu'aucun nettoyage manuel ne soit nécessaire à la fin du contrat."
    hint="Utilisez chage -E avec la date au format YYYY-MM-DD. Exécutez : sudo chage -E 2026-12-31 john. Vérifiez avec : chage -l john — cherchez la ligne 'Account expires' indiquant Dec 31, 2026."
    inst1="Définissez la date d'expiration du compte de John au <span class=\"bold-green-text\">2026-12-31</span> pour qu'il soit automatiquement désactivé à la fin de son contrat :"
    inst2="Vérifiez que l'expiration du compte est correctement configurée — cherchez la ligne <span class=\"bold-green-text\">Account expires</span> :"
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
    "tags": "linux,chage,account-expiry,user-management,onboarding"
  }'
