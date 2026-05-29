#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/firewall_rules.yml"

# Clean state: flush INPUT chain on webservers
ansible webservers -i "$inventory" -m command \
  -a "iptables -F INPUT" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: apply iptables firewall rules on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: allow established and related connections
      ansible.builtin.iptables:
        chain: INPUT
        ctstate:
          - ESTABLISHED
          - RELATED
        jump: ACCEPT

    - name: allow SSH on port 22
      ansible.builtin.iptables:
        chain: INPUT
        protocol: tcp
        destination_port: "22"
        jump: ACCEPT

    - name: allow HTTP on port 80
      ansible.builtin.iptables:
        chain: INPUT
        protocol: tcp
        destination_port: "80"
        jump: ACCEPT

    - name: reject all other INPUT traffic
      ansible.builtin.iptables:
        chain: INPUT
        jump: REJECT
```'
cmd2="\`\`\`shell
ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'iptables -L INPUT -n --line-numbers' --become
\`\`\`"

case "$lang" in
  en)
    question="**Harden** the \`webservers\` by applying iptables rules. Write a playbook at \`$pb_path\` that: accepts **established/related connections**, accepts TCP port \`22\` (SSH) and port \`80\` (HTTP) in the \`INPUT\` chain, and **rejects all other input traffic**. Use the \`ansible.builtin.iptables\` module."
    hint="Use ansible.builtin.iptables for each rule. Key parameters: chain, protocol, destination_port, jump (ACCEPT/REJECT), and ctstate for stateful matching. Order matters — place the REJECT rule last. Verify: ansible webservers -m command -a 'iptables -L INPUT -n --line-numbers' --become"
    inst1="Write the playbook at \`$pb_path\` — define all \`iptables\` rules, REJECT must be the last rule:"
    inst2="Run the playbook and verify the firewall rules on all webservers:"
    ;;
  fr)
    question="**Durcissez** les \`webservers\` en appliquant des règles iptables. Écrivez un playbook à \`$pb_path\` qui : accepte les **connexions établies/liées**, accepte le port TCP \`22\` (SSH) et le port \`80\` (HTTP) dans la chaîne \`INPUT\`, et **rejette tout autre trafic entrant**. Utilisez le module \`ansible.builtin.iptables\`."
    hint="Utilisez ansible.builtin.iptables pour chaque règle. Paramètres clés : chain, protocol, destination_port, jump (ACCEPT/REJECT), et ctstate pour le filtrage avec état. L'ordre est important — placez la règle REJECT en dernier. Vérifiez : ansible webservers -m command -a 'iptables -L INPUT -n --line-numbers' --become"
    inst1="Écrivez le playbook à \`$pb_path\` — définissez toutes les règles \`iptables\`, REJECT doit être la dernière règle :"
    inst2="Exécutez le playbook et vérifiez les règles de pare-feu sur tous les webservers :"
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
    "tags": "ansible,iptables,firewall,security,rhce"
  }'
