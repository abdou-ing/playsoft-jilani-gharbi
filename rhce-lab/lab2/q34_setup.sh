#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  # Enable debugging: -e (exit on error), -o xtrace (show commands), -u (undefined vars are errors), -x (trace commands)
  set -eoux
  # Shift arguments to ignore "debug" and pass the rest to the script
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

s3_path="s3://cloudlab-docker-bucket/ansible/playbooks/playbook_error_indent.yml"
playbook_dir="/home/ansible_user/playbooks"
playbook_name="$playbook_dir/playbook_errors.yml"

# Create the playbooks directory if it doesn't exist
mkdir -p "$playbook_dir"

# Copy an invalid playbook file
aws s3 cp "$s3_path" "$playbook_name"

# Define the question, hint, and instructions based on the language
case "$lang" in
  "en")
    question="Fix the invalid Ansible playbook located at '$playbook_name'."
    hint="The playbook contains syntax errors and logical issues. Use 'ansible-lint' or 'ansible-playbook --syntax-check' to identify and fix the errors."
    instructions='[
  {
    "instruction": "Navigate to the playbooks directory.",
    "command": "cd '"$playbook_dir"'"
  },
  {
    "instruction": "Check the playbook for syntax errors using 'ansible-playbook --syntax-check'.",
    "command": "ansible-playbook --syntax-check '"$playbook_name"'"
  },
  {
    "instruction": "Use 'ansible-lint' to identify potential issues in the playbook.",
    "command": "ansible-lint '"$playbook_name"'"
  },
  {
    "instruction": "Fix the errors in the playbook and save the file.",
    "command": "nano '"$playbook_name"'"
  },
  {
    "instruction": "Run the playbook to verify it works correctly.",
    "command": "ansible-playbook '"$playbook_name"'"
  }
]'
    ;;
  "fr")
    question="Corrigez le playbook Ansible invalide situé à '$playbook_name'."
    hint="Le playbook contient des erreurs de syntaxe et des problèmes logiques. Utilisez 'ansible-lint' ou 'ansible-playbook --syntax-check' pour identifier et corriger les erreurs."
    instructions='[
  {
    "instruction": "Accédez au répertoire des playbooks.",
    "command": "cd '"$playbook_dir"'"
  },
  {
    "instruction": "Vérifiez le playbook pour les erreurs de syntaxe en utilisant 'ansible-playbook --syntax-check'.",
    "command": "ansible-playbook --syntax-check '"$playbook_name"'"
  },
  {
    "instruction": "Utilisez 'ansible-lint' pour identifier les problèmes potentiels dans le playbook.",
    "command": "ansible-lint '"$playbook_name"'"
  },
  {
    "instruction": "Corrigez les erreurs dans le playbook et enregistrez le fichier.",
    "command": "nano '"$playbook_name"'"
  },
  {
    "instruction": "Exécutez le playbook pour vérifier le bon fonctionnement.",
    "command": "ansible-playbook '"$playbook_name"'"
  }
]'
    ;;
  "de")
    question="Korrigieren Sie das ungültige Ansible-Playbook unter '$playbook_name'."
    hint="Das Playbook enthält Syntaxfehler und logische Probleme. Verwenden Sie 'ansible-lint' oder 'ansible-playbook --syntax-check', um die Fehler zu identifizieren und zu beheben."
    instructions='[
  {
    "instruction": "Wechseln Sie in das Playbook-Verzeichnis.",
    "command": "cd '"$playbook_dir"'"
  },
  {
    "instruction": "Überprüfen Sie das Playbook auf Syntaxfehler mit 'ansible-playbook --syntax-check'.",
    "command": "ansible-playbook --syntax-check '"$playbook_name"'"
  },
  {
    "instruction": "Verwenden Sie 'ansible-lint', um potenzielle Probleme im Playbook zu identifizieren.",
    "command": "ansible-lint '"$playbook_name"'"
  },
  {
    "instruction": "Beheben Sie die Fehler im Playbook und speichern Sie die Datei.",
    "command": "nano '"$playbook_name"'"
  },
  {
    "instruction": "Führen Sie das Playbook aus, um zu überprüfen, ob es korrekt funktioniert.",
    "command": "ansible-playbook '"$playbook_name"'"
  }
]'
    ;;
  "es")
    question="Corrija el playbook de Ansible no válido ubicado en '$playbook_name'."
    hint="El playbook contiene errores de sintaxis y problemas lógicos. Use 'ansible-lint' o 'ansible-playbook --syntax-check' para identificar y corregir los errores."
    instructions='[
  {
    "instruction": "Navegue al directorio de playbooks.",
    "command": "cd '"$playbook_dir"'"
  },
  {
    "instruction": "Verifique el playbook en busca de errores de sintaxis usando 'ansible-playbook --syntax-check'.",
    "command": "ansible-playbook --syntax-check '"$playbook_name"'"
  },
  {
    "instruction": "Use 'ansible-lint' para identificar problemas potenciales en el playbook.",
    "command": "ansible-lint '"$playbook_name"'"
  },
  {
    "instruction": "Corrija los errores en el playbook y guarde el archivo.",
    "command": "nano '"$playbook_name"'"
  },
  {
    "instruction": "Ejecute el playbook para verificar que funciona correctamente.",
    "command": "ansible-playbook '"$playbook_name"'"
  }
]'
    ;;
  "it")
    question="Correggi il playbook Ansible non valido situato in '$playbook_name'."
    hint="Il playbook contiene errori di sintassi e problemi logici. Usa 'ansible-lint' o 'ansible-playbook --syntax-check' per identificare e correggere gli errori."
    instructions='[
  {
    "instruction": "Vai alla directory dei playbook.",
    "command": "cd '"$playbook_dir"'"
  },
  {
    "instruction": "Controlla il playbook per errori di sintassi usando 'ansible-playbook --syntax-check'.",
    "command": "ansible-playbook --syntax-check '"$playbook_name"'"
  },
  {
    "instruction": "Usa 'ansible-lint' per identificare potenziali problemi nel playbook.",
    "command": "ansible-lint '"$playbook_name"'"
  },
  {
    "instruction": "Correggi gli errori nel playbook e salva il file.",
    "command": "nano '"$playbook_name"'"
  },
  {
    "instruction": "Esegui il playbook per verificare che funzioni correttamente.",
    "command": "ansible-playbook '"$playbook_name"'"
  }
]'
    ;;
  *)
    # Default to English if the language is not supported
    question="Fix the invalid Ansible playbook located at '$playbook_name'."
    hint="The playbook contains syntax errors and logical issues. Use 'ansible-lint' or 'ansible-playbook --syntax-check' to identify and fix the errors."
    instructions='[
  {
    "instruction": "Navigate to the playbooks directory.",
    "command": "cd '"$playbook_dir"'"
  },
  {
    "instruction": "Check the playbook for syntax errors using 'ansible-playbook --syntax-check'.",
    "command": "ansible-playbook --syntax-check '"$playbook_name"'"
  },
  {
    "instruction": "Use 'ansible-lint' to identify potential issues in the playbook.",
    "command": "ansible-lint '"$playbook_name"'"
  },
  {
    "instruction": "Fix the errors in the playbook and save the file.",
    "command": "nano '"$playbook_name"'"
  },
  {
    "instruction": "Run the playbook to verify it works correctly.",
    "command": "ansible-playbook '"$playbook_name"'"
  }
]'
    ;;
esac

# JSON output
display='{
  "question": "'"$question"'",
  "type": "button",
  "hint": "'"$hint"'",
  "instructions": '"$instructions"',
  "text": "Check",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .