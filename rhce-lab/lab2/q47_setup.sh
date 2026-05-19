#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

rm -f $HOME/.ssh/id_ed25519*

case "$lang" in
  en)
    question="Generate an Ed25519 SSH key pair for \`ansible_user\` on the control node with no passphrase, saving it to \`~/.ssh/id_ed25519\`."
    hint="Use the \`-N\` flag to set an empty passphrase and \`-f\` to specify the output file."
    inst1="Generate the Ed25519 key pair with no passphrase:"
    ;;
  fr)
    question="Générez une paire de clés SSH Ed25519 pour \`ansible_user\` sur le nœud de contrôle sans phrase secrète, en l'enregistrant dans \`~/.ssh/id_ed25519\`."
    hint="Utilisez le flag \`-N\` pour définir une phrase secrète vide et \`-f\` pour spécifier le fichier de sortie."
    inst1="Générez la paire de clés Ed25519 sans phrase secrète :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2
    exit 1
    ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" \
  '[{"instruction": $inst1, "command": "ssh-keygen -t ed25519 -N \"\" -f ~/.ssh/id_ed25519"}]')

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
    "tags": "ansible,rhce,ssh"
  }'
