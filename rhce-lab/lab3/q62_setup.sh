#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a variables file at \`~/playbooks/my_package.yml\` that defines a variable \`pkg_name\` with the value \`curl\`. Then create a playbook at \`~/playbooks/install_from_vars.yml\` that uses \`vars_files\` to load \`my_package.yml\` and installs the package defined by \`{{ pkg_name }}\` on all managed hosts."
    hint="Use \`vars_files:\` in your playbook header to load the external variables file. Use the \`apt\` module with \`name: \"{{ pkg_name }}\"\` and \`state: present\`."
    inst1="Create the variables file at ~/playbooks/my_package.yml:"
    inst2="Create the playbook at ~/playbooks/install_from_vars.yml:"
    inst3="Check syntax then run the playbook:"
    ;;
  fr)
    question="Créez un fichier de variables dans \`~/playbooks/my_package.yml\` qui définit une variable \`pkg_name\` avec la valeur \`curl\`. Ensuite, créez un playbook dans \`~/playbooks/install_from_vars.yml\` qui utilise \`vars_files\` pour charger \`my_package.yml\` et installe le paquet défini par \`{{ pkg_name }}\` sur tous les hôtes gérés."
    hint="Utilisez \`vars_files:\` dans l'en-tête de votre playbook pour charger le fichier de variables externe. Utilisez le module \`apt\` avec \`name: \"{{ pkg_name }}\"\` et \`state: present\`."
    inst1="Créez le fichier de variables dans ~/playbooks/my_package.yml :"
    inst2="Créez le playbook dans ~/playbooks/install_from_vars.yml :"
    inst3="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_vars='```yaml
pkg_name: curl
```'

cmd_playbook='```yaml
- name: Install package from vars_files
  hosts: all
  become: true
  vars_files:
    - my_package.yml
  tasks:
    - name: Install {{ pkg_name }}
      apt:
        name: "{{ pkg_name }}"
        state: present
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/install_from_vars.yml
ansible-playbook playbooks/install_from_vars.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_vars" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_playbook" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,vars_files,variables,apt"}'
