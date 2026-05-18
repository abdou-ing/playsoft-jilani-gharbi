#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a playbook at \`~/playbooks/dict_vars.yml\` that defines a dictionary variable \`app_config\` in the \`vars:\` section with the following keys:\n\nname: myapp\nport: \"8080\"\nenv: production\n\nThen write \`/root/app_config.txt\` on all managed hosts containing:\n\nAPP=\`app_config.name\`\nPORT=\`app_config.port\`\nENV=\`app_config.env\`\n\nUse the \`lineinfile\` module for each line and dot notation to access dictionary keys."
    hint="A dictionary (map) variable is defined with nested keys under the variable name. Access its keys with dot notation: \`{{ app_config.name }}\` or bracket notation: \`{{ app_config['name'] }}\`."
    inst1="Create the playbook at ~/playbooks/dict_vars.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Créez un playbook dans \`~/playbooks/dict_vars.yml\` qui définit une variable dictionnaire \`app_config\` dans la section \`vars:\` avec les clés suivantes :\n\nname: myapp\nport: \"8080\"\nenv: production\n\nEnsuite, écrivez \`/root/app_config.txt\` sur tous les hôtes gérés contenant :\n\nAPP=\`app_config.name\`\nPORT=\`app_config.port\`\nENV=\`app_config.env\`\n\nUtilisez le module \`lineinfile\` pour chaque ligne et la notation pointée pour accéder aux clés du dictionnaire."
    hint="Une variable dictionnaire (map) est définie avec des clés imbriquées sous le nom de la variable. Accédez à ses clés avec la notation pointée : \`{{ app_config.name }}\` ou la notation entre crochets : \`{{ app_config['name'] }}\`."
    inst1="Créez le playbook dans ~/playbooks/dict_vars.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Use a dictionary variable
  hosts: all
  become: true
  vars:
    app_config:
      name: myapp
      port: "8080"
      env: production
  tasks:
    - name: Set APP line
      lineinfile:
        path: /root/app_config.txt
        regexp: "^APP="
        line: "APP={{ app_config.name }}"
        create: yes

    - name: Set PORT line
      lineinfile:
        path: /root/app_config.txt
        regexp: "^PORT="
        line: "PORT={{ app_config.port }}"
        create: yes

    - name: Set ENV line
      lineinfile:
        path: /root/app_config.txt
        regexp: "^ENV="
        line: "ENV={{ app_config.env }}"
        create: yes
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/dict_vars.yml
ansible-playbook playbooks/dict_vars.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,dictionary,variables,vars,lineinfile"}'
