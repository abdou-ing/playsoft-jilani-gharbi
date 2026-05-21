#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="A vault file \`/home/ansible_user/workspace/secret.yml\` has been pre-created on the control node, encrypted with password \`curabete\`. Rekey this vault file so that it uses the new password \`newvare\` instead."
    hint="Use \`ansible-vault rekey\` with \`--ask-vault-pass\` (enter 'curabete') and \`--new-vault-password-file\` or \`--ask-new-vault-pass\` (enter 'newvare')."
    inst1="Rekey the vault file to use the new password 'newvare':"
    inst2="Verify the rekey was successful:"
    ;;
  fr)
    question="Un fichier vault \`/home/ansible_user/workspace/secret.yml\` a été pré-créé sur le nœud de contrôle, chiffré avec le mot de passe \`curabete\`. Renchaînez ce fichier vault pour qu'il utilise le nouveau mot de passe \`newvare\`."
    hint="Utilisez \`ansible-vault rekey\` avec \`--ask-vault-pass\` (entrez 'curabete') et \`--new-vault-password-file\` ou \`--ask-new-vault-pass\` (entrez 'newvare')."
    inst1="Renchaînez le fichier vault pour utiliser le nouveau mot de passe 'newvare' :"
    inst2="Vérifiez que le renchaînement a réussi :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_rekey='```bash
cd ~/playbooks
# Method 1: interactive (enter old password then new password)
ansible-vault rekey secret.yml

# Method 2: using password files
echo "curabete" > /tmp/old_pass.txt
echo "newvare" > /tmp/new_pass.txt
ansible-vault rekey --vault-password-file=/tmp/old_pass.txt \
  --new-vault-password-file=/tmp/new_pass.txt secret.yml
rm -f /tmp/old_pass.txt /tmp/new_pass.txt
```'

cmd_verify='```bash
# Verify with new password (should show content)
echo "newvare" | ansible-vault view secret.yml --vault-password-file=/dev/stdin

# Verify old password no longer works (should fail)
echo "curabete" | ansible-vault view secret.yml --vault-password-file=/dev/stdin 2>&1 | grep -i "error\|incorrect"
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_rekey" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_verify" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,vault,rekey,encryption,security"}'
