#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

output_file="/home/ansible_user/uptime.txt"

case "$lang" in
  en)
    question="Run an Ansible ad-hoc command to display the uptime of ALL \`webservers\` hosts and save the output to \`$output_file\`."
    hint="Use the command module with the uptime command and redirect the full ansible output to the file using shell redirection."
    inst1="Run the ad-hoc command and redirect the output to the file:"
    cmd1="ansible webservers -m command -a 'uptime' > ~/uptime.txt"
    inst2="Verify the file was created and contains content:"
    cmd2="cat ~/uptime.txt"
    ;;
  fr)
    question="Exécutez une commande Ansible ad-hoc pour afficher l'uptime de TOUS les hôtes \`webservers\` et enregistrez la sortie dans \`$output_file\`."
    hint="Utilisez le module command avec la commande uptime et redirigez la sortie complète d'ansible vers le fichier en utilisant la redirection shell."
    inst1="Exécutez la commande ad-hoc et redirigez la sortie vers le fichier :"
    cmd1="ansible webservers -m command -a 'uptime' > ~/uptime.txt"
    inst2="Vérifiez que le fichier a été créé et contient du contenu :"
    cmd2="cat ~/uptime.txt"
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
    "tags": "ansible,adhoc,command"
  }'
