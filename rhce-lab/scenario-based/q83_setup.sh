#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

# Ensure developers group exists
if ! getent group developers &>/dev/null; then
  sudo groupadd developers 2>/dev/null || true
fi

# Clean state: remove /srv/devproject so the task starts fresh each run
sudo rm -rf /srv/devproject 2>/dev/null || true

cmd1="sudo mkdir -p /srv/devproject
sudo chown :developers /srv/devproject
sudo chmod g+s /srv/devproject"
cmd2="ls -ld /srv/devproject
stat -c '%G %a' /srv/devproject"

case "$lang" in
  en)
    question="The team is launching a shared project. Create the directory \`/srv/devproject\` owned by the \`developers\` group, and set the setgid bit so that every file created inside it automatically belongs to the \`developers\` group — letting John and his teammates collaborate without permission conflicts."
    hint="Three steps: sudo mkdir -p /srv/devproject → sudo chown :developers /srv/devproject → sudo chmod g+s /srv/devproject. The setgid bit appears as 's' in the group execute position in ls -ld output."
    inst1="Create the directory, assign group ownership to <span class=\"bold-green-text\">developers</span>, and set the <span class=\"bold-green-text\">setgid</span> bit in one sequence:"
    inst2="Verify the directory has the correct group owner and the <span class=\"bold-green-text\">setgid</span> bit set (look for <span class=\"bold-green-text\">'s'</span> in the group execute position and a <span class=\"bold-green-text\">'2'</span> prefix in the octal mode):"
    ;;
  fr)
    question="L'équipe lance un projet partagé. Créez le répertoire \`/srv/devproject\` appartenant au groupe \`developers\`, et appliquez le bit setgid afin que chaque fichier créé à l'intérieur appartienne automatiquement au groupe \`developers\` — permettant à John et ses coéquipiers de collaborer sans conflits de permissions."
    hint="Trois étapes : sudo mkdir -p /srv/devproject → sudo chown :developers /srv/devproject → sudo chmod g+s /srv/devproject. Le bit setgid apparaît comme 's' à la position d'exécution du groupe dans la sortie de ls -ld."
    inst1="Créez le répertoire, assignez la propriété de groupe à <span class=\"bold-green-text\">developers</span>, et définissez le bit <span class=\"bold-green-text\">setgid</span> en une séquence :"
    inst2="Vérifiez que le répertoire a le bon propriétaire de groupe et que le bit <span class=\"bold-green-text\">setgid</span> est défini (cherchez <span class=\"bold-green-text\">'s'</span> à la position d'exécution du groupe et un préfixe <span class=\"bold-green-text\">'2'</span> dans le mode octal) :"
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
    "tags": "linux,chmod,setgid,mkdir,permissions,onboarding"
  }'
