#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create Jinja2 template \`/home/ansible_user/workspace/hosts.j2\` and playbook \`/home/ansible_user/workspace/gen_hosts.yml\`. The template generates \`/etc/myhosts\` with localhost entries and dynamic lines for each host using \`hostvars\` facts (IP, FQDN, hostname). The playbook has two plays: Play 1 gathers facts from all hosts; Play 2 deploys the template to \`/etc/myhosts\` on the \`dev\` group."
    hint="Use a Jinja2 for loop: \`{% for x in groups['all'] %}\` with \`hostvars[x]['ansible_facts']['default_ipv4']['address']\`. Play 1 must run on all hosts to populate hostvars."
    inst1="Create the Jinja2 template /home/ansible_user/workspace/hosts.j2:"
    inst2="Create the playbook /home/ansible_user/workspace/gen_hosts.yml:"
    inst3="Run the playbook:"
    ;;
  fr)
    question="Créez le template Jinja2 \`/home/ansible_user/workspace/hosts.j2\` et le playbook \`/home/ansible_user/workspace/gen_hosts.yml\`. Le template génère \`/etc/myhosts\` avec des entrées localhost et des lignes dynamiques pour chaque hôte utilisant les faits \`hostvars\` (IP, FQDN, hostname). Le playbook a deux plays : le Play 1 collecte les faits de tous les hôtes ; le Play 2 déploie le template dans \`/etc/myhosts\` sur le groupe \`dev\`."
    hint="Utilisez une boucle for Jinja2 : \`{% for x in groups['all'] %}\` avec \`hostvars[x]['ansible_facts']['default_ipv4']['address']\`. Le Play 1 doit s'exécuter sur tous les hôtes pour peupler hostvars."
    inst1="Créez le template Jinja2 /home/ansible_user/workspace/hosts.j2 :"
    inst2="Créez le playbook /home/ansible_user/workspace/gen_hosts.yml :"
    inst3="Exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_template='```jinja2
127.0.0.1   localhost localhost.localdomain
::1         localhost

{% for x in groups["all"] %}
{{ hostvars[x]["ansible_facts"]["default_ipv4"]["address"] }} {{ hostvars[x]["ansible_facts"]["fqdn"] }} {{ hostvars[x]["ansible_facts"]["hostname"] }}
{% endfor %}
```'

cmd_playbook='```yaml
- name: Gather facts from all hosts
  hosts: all
  gather_facts: true
  tasks: []

- name: Deploy /etc/myhosts on dev group
  hosts: dev
  become: true
  tasks:
    - name: Deploy myhosts from template
      ansible.builtin.template:
        src: hosts.j2
        dest: /etc/myhosts
        owner: root
        group: root
        mode: "0644"
```'

cmd_run='```bash
ansible-playbook playbooks/gen_hosts.yml
ansible dev -m command -a "cat /etc/myhosts"
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_template" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_playbook" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,template,jinja2,hostvars,facts"}'
