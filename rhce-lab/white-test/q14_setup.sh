#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/user_list.yml\` with a list of users (adam/developer, gabriel/manager, lucifer/developer). Create \`/home/ansible_user/workspace/create_user.yml\` using \`vars_files: [user_list.yml, vault.yml]\` to create users: developers (adam, lucifer) on dev+test with group 'devops' and password from \`dev_pass\` (sha512); managers (gabriel) on prod with group 'opsmgr' and password from \`mgr_pass\` (sha512)."
    hint="Use \`password_hash('sha512')\` filter to hash the passwords. Use a loop over the users list with \`when\` conditions on the job field. Run with \`--vault-password-file=password.txt\`."
    inst1="Create /home/ansible_user/workspace/user_list.yml:"
    inst2="Create /home/ansible_user/workspace/create_user.yml:"
    inst3="Run the playbook with the vault password file:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/user_list.yml\` avec une liste d'utilisateurs (adam/developer, gabriel/manager, lucifer/developer). Créez \`/home/ansible_user/workspace/create_user.yml\` utilisant \`vars_files: [user_list.yml, vault.yml]\` pour créer les utilisateurs : les développeurs (adam, lucifer) sur dev+test avec le groupe 'devops' et le mot de passe de \`dev_pass\` (sha512) ; les managers (gabriel) sur prod avec le groupe 'opsmgr' et le mot de passe de \`mgr_pass\` (sha512)."
    hint="Utilisez le filtre \`password_hash('sha512')\` pour hacher les mots de passe. Utilisez une boucle sur la liste des utilisateurs avec des conditions \`when\` sur le champ job. Exécutez avec \`--vault-password-file=password.txt\`."
    inst1="Créez /home/ansible_user/workspace/user_list.yml :"
    inst2="Créez /home/ansible_user/workspace/create_user.yml :"
    inst3="Exécutez le playbook avec le fichier de mot de passe vault :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_userlist='```yaml
---
users:
  - name: adam
    job: developer
  - name: gabriel
    job: manager
  - name: lucifer
    job: developer
```'

cmd_playbook='```yaml
- name: Create users based on job role
  hosts: all
  become: true
  vars_files:
    - user_list.yml
    - vault.yml
  tasks:
    - name: Ensure devops group exists
      ansible.builtin.group:
        name: devops
        state: present
      when: >
        inventory_hostname in groups["dev"] or
        inventory_hostname in groups["test"]

    - name: Ensure opsmgr group exists
      ansible.builtin.group:
        name: opsmgr
        state: present
      when: inventory_hostname in groups["prod"]

    - name: Create developer users on dev and test
      ansible.builtin.user:
        name: "{{ item.name }}"
        groups: devops
        password: "{{ dev_pass | password_hash(\"sha512\") }}"
        state: present
      loop: "{{ users }}"
      when: >
        item.job == "developer" and
        (inventory_hostname in groups["dev"] or
         inventory_hostname in groups["test"])

    - name: Create manager users on prod
      ansible.builtin.user:
        name: "{{ item.name }}"
        groups: opsmgr
        password: "{{ mgr_pass | password_hash(\"sha512\") }}"
        state: present
      loop: "{{ users }}"
      when: >
        item.job == "manager" and
        inventory_hostname in groups["prod"]
```'

cmd_run='```bash
cd ~/playbooks
ansible-playbook create_user.yml --vault-password-file=password.txt
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_userlist" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_playbook" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,users,vault,vars_files,password_hash"}'
