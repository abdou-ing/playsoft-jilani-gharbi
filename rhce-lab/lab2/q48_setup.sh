#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Copy the SSH public key from the control node to both \`web1\` and \`web2\` to enable passwordless authentication as \`ansible_user\`. The password for \`ansible_user\` on both hosts is \`Labby123\`."
    hint="Use \`ssh-copy-id ansible_user@<host>\` for each host. Accept the host fingerprint when prompted. You must copy the key to both hosts."
    inst1="Copy the public key to web1 (enter password Labby123 when prompted):"
    inst2="Copy the public key to web2 (enter password Labby123 when prompted):"
    ;;
  fr)
    question="Copiez la clé publique SSH du nœud de contrôle vers \`web1\` et \`web2\` pour activer l'authentification sans mot de passe en tant qu'\`ansible_user\`. Le mot de passe d'\`ansible_user\` sur les deux hôtes est \`Labby123\`."
    hint="Utilisez \`ssh-copy-id ansible_user@<hôte>\` pour chaque hôte. Acceptez l'empreinte de l'hôte lorsqu'on vous le demande. Vous devez copier la clé sur les deux hôtes."
    inst1="Copiez la clé publique vers web1 (entrez le mot de passe Labby123 lorsque demandé) :"
    inst2="Copiez la clé publique vers web2 (entrez le mot de passe Labby123 lorsque demandé) :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2
    exit 1
    ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" \
  --arg inst2 "$inst2" \
  '[{"instruction": $inst1, "command": "ssh-copy-id ansible_user@web1"},
    {"instruction": $inst2, "command": "ssh-copy-id ansible_user@web2"}]')

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
