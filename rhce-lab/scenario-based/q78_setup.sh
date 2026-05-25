#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

# Clean state: remove john so the student starts fresh each run
sudo userdel -r john 2>/dev/null || true
sudo rm -rf /home/john 2>/dev/null || true

cmd1="sudo useradd -m -s /bin/bash john"
cmd2="id john
grep john /etc/passwd"

case "$lang" in
  en)
    question="A new junior developer, John, is starting today. Create a local user account named \`john\` with a home directory at \`/home/john\` and \`/bin/bash\` as his login shell."
    hint="Use useradd with -m (create home directory) and -s /bin/bash (set login shell). Verify with: id john — you should see the uid, gid, and groups."
    inst1="Create the user account for <span class=\"bold-green-text\">john</span> with a home directory and the bash shell:"
    inst2="Verify the account was created correctly — check the uid, home directory, and shell:"
    ;;
  fr)
    question="Un nouveau développeur junior, John, commence aujourd'hui. Créez un compte utilisateur local nommé \`john\` avec un répertoire home à \`/home/john\` et \`/bin/bash\` comme shell de connexion."
    hint="Utilisez useradd avec -m (créer le répertoire home) et -s /bin/bash (définir le shell de connexion). Vérifiez avec : id john — vous devez voir l'uid, le gid et les groupes."
    inst1="Créez le compte utilisateur pour <span class=\"bold-green-text\">john</span> avec un répertoire home et le shell bash :"
    inst2="Vérifiez que le compte a été créé correctement — contrôlez l'uid, le répertoire home et le shell :"
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
    "tags": "linux,useradd,user-management,onboarding"
  }'
