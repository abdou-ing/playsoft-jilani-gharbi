#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a shell script \`/home/ansible_user/workspace/apt-pack.sh\` that uses an Ansible ad-hoc command with the \`apt_repository\` module to add the Universe apt repository (\`deb http://archive.ubuntu.com/ubuntu focal universe\`) on all managed nodes. The script must be executable."
    hint="Use \`ansible all -m ansible.builtin.apt_repository\` with the \`repo\` argument. Run \`chmod +x\` on the script."
    inst1="Create the shell script /home/ansible_user/workspace/apt-pack.sh:"
    inst2="Make it executable and run it:"
    ;;
  fr)
    question="Créez un script shell \`/home/ansible_user/workspace/apt-pack.sh\` qui utilise une commande ad-hoc Ansible avec le module \`apt_repository\` pour ajouter le dépôt Universe apt (\`deb http://archive.ubuntu.com/ubuntu focal universe\`) sur tous les nœuds gérés. Le script doit être exécutable."
    hint="Utilisez \`ansible all -m ansible.builtin.apt_repository\` avec l'argument \`repo\`. Exécutez \`chmod +x\` sur le script."
    inst1="Créez le script shell /home/ansible_user/workspace/apt-pack.sh :"
    inst2="Rendez-le exécutable et exécutez-le :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_script='```bash
#!/bin/bash
cd ~/playbooks
ansible all -m ansible.builtin.apt_repository \
  -a "repo=\"deb http://archive.ubuntu.com/ubuntu focal universe\" state=present" \
  --become
```'

cmd_run='```bash
chmod +x /home/ansible_user/workspace/apt-pack.sh
/home/ansible_user/workspace/apt-pack.sh
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_script" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,ad-hoc,apt_repository,package"}'
