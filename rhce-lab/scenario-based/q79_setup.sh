#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

# Ensure developers group exists
if ! getent group developers &>/dev/null; then
  sudo groupadd developers 2>/dev/null || true
fi

# Skip-q78 guard: create john if he was not created yet
if ! id john &>/dev/null; then
  sudo useradd -m -s /bin/bash john 2>/dev/null || true
fi

# Clean state: remove john from developers so the task is fresh each run
sudo gpasswd -d john developers 2>/dev/null || true

cmd1="sudo usermod -aG developers john"
cmd2="groups john
id john"

case "$lang" in
  en)
    question="You forgot to give John access to the team's shared resources. The development team uses a group called \`developers\`. Add \`john\` as a secondary member of the \`developers\` group."
    hint="Use usermod -aG to append a group without removing existing memberships. The -a flag is critical — omitting it would replace all supplementary groups. Verify with: groups john"
    inst1="Add <span class=\"bold-green-text\">john</span> to the <span class=\"bold-green-text\">developers</span> group as a secondary member:"
    inst2="Verify that <span class=\"bold-green-text\">john</span> is now listed in the <span class=\"bold-green-text\">developers</span> group:"
    ;;
  fr)
    question="Vous avez oublié de donner à John l'accès aux ressources partagées de l'équipe. L'équipe de développement utilise un groupe appelé \`developers\`. Ajoutez \`john\` comme membre secondaire du groupe \`developers\`."
    hint="Utilisez usermod -aG pour ajouter un groupe sans supprimer les appartenances existantes. Le flag -a est essentiel — l'omettre remplacerait tous les groupes supplémentaires. Vérifiez avec : groups john"
    inst1="Ajoutez <span class=\"bold-green-text\">john</span> au groupe <span class=\"bold-green-text\">developers</span> comme membre secondaire :"
    inst2="Vérifiez que <span class=\"bold-green-text\">john</span> est maintenant listé dans le groupe <span class=\"bold-green-text\">developers</span> :"
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
    "tags": "linux,groups,usermod,onboarding"
  }'
