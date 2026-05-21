#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/packages.yml\` that: installs \`php\` and \`mariadb-client\` on hosts in dev, test, and prod groups; installs \`build-essential\` only on dev group; performs an apt upgrade (state: latest, name: '*') on dev group only."
    hint="Use \`when: inventory_hostname in groups['dev'] or inventory_hostname in groups['test'] or inventory_hostname in groups['prod']\` for the first task. Use \`when: inventory_hostname in groups['dev']\` for the last two tasks."
    inst1="Create the playbook /home/ansible_user/workspace/packages.yml:"
    inst2="Check syntax and run the playbook:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/packages.yml\` qui : installe \`php\` et \`mariadb-client\` sur les hôtes des groupes dev, test et prod ; installe \`build-essential\` uniquement sur le groupe dev ; effectue un apt upgrade (state: latest, name: '*') uniquement sur le groupe dev."
    hint="Utilisez \`when: inventory_hostname in groups['dev'] or inventory_hostname in groups['test'] or inventory_hostname in groups['prod']\` pour la première tâche. Utilisez \`when: inventory_hostname in groups['dev']\` pour les deux dernières tâches."
    inst1="Créez le playbook /home/ansible_user/workspace/packages.yml :"
    inst2="Vérifiez la syntaxe et exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Install packages on managed hosts
  hosts: all
  become: true
  tasks:
    - name: Install php and mariadb-client on dev, test, prod
      ansible.builtin.apt:
        name:
          - php
          - mariadb-client
        state: present
        update_cache: true
      when: >
        inventory_hostname in groups["dev"] or
        inventory_hostname in groups["test"] or
        inventory_hostname in groups["prod"]

    - name: Install build-essential on dev only
      ansible.builtin.apt:
        name: build-essential
        state: present
      when: inventory_hostname in groups["dev"]

    - name: Upgrade all packages on dev
      ansible.builtin.apt:
        name: "*"
        state: latest
        update_cache: true
      when: inventory_hostname in groups["dev"]
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/packages.yml
ansible-playbook playbooks/packages.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,apt,packages,when"}'
