#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

output_file="/home/ansible_user/workspace/uptime.txt"

cmd1="ansible webservers -m command -a 'uptime' > /home/ansible_user/workspace/uptime.txt"
cmd2="cat /home/ansible_user/workspace/uptime.txt"
cmd3="grep -c 'CHANGED' /home/ansible_user/workspace/uptime.txt"

case "$lang" in
  en)
    question="Run an Ansible ad-hoc command to display the uptime of ALL \`webservers\` hosts and save the output to \`$output_file\`."
    hint="Use the command module with the uptime command and redirect the full ansible output to the file using shell redirection."
    inst1="Run the <span class=\"bold-green-text\">ansible</span> ad-hoc command with the <span class=\"bold-green-text\">command</span> module and redirect the full output to the file:"
    inst2="Check the file was created and contains <span class=\"bold-green-text\">uptime</span> data from all <span class=\"bold-green-text\">webservers</span> hosts:"
    inst3="Confirm every host responded — count <span class=\"bold-green-text\">CHANGED</span> lines, must match the number of hosts in the group:"
    ;;
  fr)
    question="Exécutez une commande Ansible ad-hoc pour afficher l'uptime de TOUS les hôtes \`webservers\` et enregistrez la sortie dans \`$output_file\`."
    hint="Utilisez le module command avec la commande uptime et redirigez la sortie complète d'ansible vers le fichier en utilisant la redirection shell."
    inst1="Exécutez la commande <span class=\"bold-green-text\">ansible</span> ad-hoc avec le module <span class=\"bold-green-text\">command</span> et redirigez la sortie complète vers le fichier :"
    inst2="Vérifiez que le fichier a été créé et contient les données d'<span class=\"bold-green-text\">uptime</span> de tous les hôtes <span class=\"bold-green-text\">webservers</span> :"
    inst3="Confirmez que chaque hôte a répondu — comptez les lignes <span class=\"bold-green-text\">CHANGED</span>, le nombre doit correspondre aux hôtes du groupe :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd1" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd3" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

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
    "tags": "ansible,adhoc,command"
  }'
