#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create an Ansible Vault file \`/home/ansible_user/workspace/vault.yml\` containing \`dev_pass: wakennym\` and \`mgr_pass: rocky\`. The vault password must be \`atenorth\`, stored in \`/home/ansible_user/workspace/password.txt\` with permissions 0600."
    hint="Use \`ansible-vault create vault.yml\` and enter 'atenorth' as the vault password. Store the password in password.txt and protect it with chmod 0600."
    inst1="Create the vault password file and set permissions:"
    inst2="Create the encrypted vault file (enter 'atenorth' as password):"
    inst3="Verify the vault file is encrypted:"
    ;;
  fr)
    question="Créez un fichier Ansible Vault \`/home/ansible_user/workspace/vault.yml\` contenant \`dev_pass: wakennym\` et \`mgr_pass: rocky\`. Le mot de passe du vault doit être \`atenorth\`, stocké dans \`/home/ansible_user/workspace/password.txt\` avec les permissions 0600."
    hint="Utilisez \`ansible-vault create vault.yml\` et entrez 'atenorth' comme mot de passe du vault. Stockez le mot de passe dans password.txt et protégez-le avec chmod 0600."
    inst1="Créez le fichier de mot de passe du vault et définissez les permissions :"
    inst2="Créez le fichier vault chiffré (entrez 'atenorth' comme mot de passe) :"
    inst3="Vérifiez que le fichier vault est chiffré :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_password='```bash
echo "atenorth" > /home/ansible_user/workspace/password.txt
chmod 0600 /home/ansible_user/workspace/password.txt
```'

cmd_vault='```bash
cd ~/playbooks
ansible-vault create vault.yml --vault-password-file=password.txt
# In the editor, type:
# dev_pass: wakennym
# mgr_pass: rocky
# Then save and exit (:wq in vim)

# OR use a single command:
ansible-vault encrypt_string --vault-password-file=password.txt --name dev_pass wakennym
```'

cmd_verify='```bash
ansible-vault view vault.yml --vault-password-file=/home/ansible_user/workspace/password.txt
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_password" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_vault" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_verify" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,vault,encryption,security"}'
