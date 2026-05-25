#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

# Skip-q78 guard: create john if he was not created yet
if ! id john &>/dev/null; then
  sudo useradd -m -s /bin/bash john 2>/dev/null || true
fi

# Clean state: remove john from sudo group so the task is fresh each run
sudo gpasswd -d john sudo 2>/dev/null || true

cmd1="sudo usermod -aG sudo john"
cmd2="groups john
sudo -l -U john"

case "$lang" in
  en)
    question="John complains he cannot install packages or run administrative tasks. The team policy is that developers manage software through sudo. Grant \`john\` sudo privileges by adding him to the appropriate administrative group for this Ubuntu system."
    hint="On Ubuntu/Debian, the 'sudo' group grants sudo access. Use: sudo usermod -aG sudo john. Verify with: groups john (should list 'sudo')."
    inst1="Add <span class=\"bold-green-text\">john</span> to the <span class=\"bold-green-text\">sudo</span> group to grant him administrative privileges:"
    inst2="Verify that <span class=\"bold-green-text\">john</span> now belongs to the <span class=\"bold-green-text\">sudo</span> group and has sudo permissions:"
    ;;
  fr)
    question="John se plaint de ne pas pouvoir installer des paquets ou exécuter des tâches administratives. La politique de l'équipe est que les développeurs gèrent les logiciels via sudo. Accordez à \`john\` les privilèges sudo en l'ajoutant au groupe administratif approprié pour ce système Ubuntu."
    hint="Sur Ubuntu/Debian, le groupe 'sudo' accorde l'accès sudo. Utilisez : sudo usermod -aG sudo john. Vérifiez avec : groups john (doit lister 'sudo')."
    inst1="Ajoutez <span class=\"bold-green-text\">john</span> au groupe <span class=\"bold-green-text\">sudo</span> pour lui accorder les privilèges administratifs :"
    inst2="Vérifiez que <span class=\"bold-green-text\">john</span> appartient maintenant au groupe <span class=\"bold-green-text\">sudo</span> et dispose des permissions sudo :"
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
    "tags": "linux,sudo,privileges,usermod,onboarding"
  }'
