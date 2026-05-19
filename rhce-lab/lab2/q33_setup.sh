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

code_path="/home/ansible_user/ansible"

# Define the question, hint, and instructions based on the language
case "$lang" in
  "en")
    question="Configure Ansible to manage a remote host 'web1' (use default inventory '/etc/ansible/hosts')."
    hint="Update the Ansible inventory to include the host 'web1' and ensure passwordless SSH access is set up."
    instructions='[
  {
    "instruction": "Navigate to the Ansible code directory.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Add '\''web1'\'' to the Ansible inventory file '/etc/ansible/hosts'.",
    "command": "echo '\''web1'\'' | sudo tee -a /etc/ansible/hosts"
  },
  {
    "instruction": "Ensure passwordless SSH access is configured for the '\''web1'\'' host.",
    "command": "ssh-copy-id <web1-user>@web1"
  },
  {
    "instruction": "Verify the connection by running a ping test.",
    "command": "ansible web1 -i /etc/ansible/hosts -m ping"
  }
]'
    ;;
  "fr")
    question="Configurez Ansible pour gérer un hôte distant 'web1' (utilisez l'inventaire par défaut '/etc/ansible/hosts')."
    hint="Mettez à jour l'inventaire Ansible pour inclure l'hôte 'web1' et assurez-vous que l'accès SSH sans mot de passe est configuré."
    instructions='[
  {
    "instruction": "Accédez au répertoire de code Ansible.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Ajoutez '\''web1'\'' au fichier d'\''inventaire Ansible '/etc/ansible/hosts'.",
    "command": "echo '\''web1'\'' | sudo tee -a /etc/ansible/hosts"
  },
  {
    "instruction": "Assurez-vous que l'\''accès SSH sans mot de passe est configuré pour l'\''hôte '\''web1'\''.",
    "command": "ssh-copy-id <web1-user>@web1"
  },
  {
    "instruction": "Vérifiez la connexion en exécutant un test ping.",
    "command": "ansible web1 -i /etc/ansible/hosts -m ping"
  }
]'
    ;;
  "de")
    question="Konfigurieren Sie Ansible, um einen Remote-Host 'web1' zu verwalten (verwenden Sie das Standard-Inventar '/etc/ansible/hosts')."
    hint="Aktualisieren Sie das Ansible-Inventar, um den Host 'web1' einzubeziehen, und stellen Sie sicher, dass der passwortlose SSH-Zugriff eingerichtet ist."
    instructions='[
  {
    "instruction": "Wechseln Sie in das Ansible-Code-Verzeichnis.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Fügen Sie '\''web1'\'' zur Ansible-Inventardatei '/etc/ansible/hosts' hinzu.",
    "command": "echo '\''web1'\'' | sudo tee -a /etc/ansible/hosts"
  },
  {
    "instruction": "Stellen Sie sicher, dass der passwortlose SSH-Zugriff für den Host '\''web1'\'' konfiguriert ist.",
    "command": "ssh-copy-id <web1-user>@web1"
  },
  {
    "instruction": "Überprüfen Sie die Verbindung, indem Sie einen Ping-Test ausführen.",
    "command": "ansible web1 -i /etc/ansible/hosts -m ping"
  }
]'
    ;;
  "es")
    question="Configure Ansible para gestionar un host remoto 'web1' (use el inventario predeterminado '/etc/ansible/hosts')."
    hint="Actualice el inventario de Ansible para incluir el host 'web1' y asegúrese de que el acceso SSH sin contraseña esté configurado."
    instructions='[
  {
    "instruction": "Navegue al directorio de código de Ansible.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Agregue '\''web1'\'' al archivo de inventario de Ansible '/etc/ansible/hosts'.",
    "command": "echo '\''web1'\'' | sudo tee -a /etc/ansible/hosts"
  },
  {
    "instruction": "Asegúrese de que el acceso SSH sin contraseña esté configurado para el host '\''web1'\''.",
    "command": "ssh-copy-id <web1-user>@web1"
  },
  {
    "instruction": "Verifique la conexión ejecutando una prueba de ping.",
    "command": "ansible web1 -i /etc/ansible/hosts -m ping"
  }
]'
    ;;
  "it")
    question="Configura Ansible per gestire un host remoto 'web1' (usa l'inventario predefinito '/etc/ansible/hosts')."
    hint="Aggiorna l'inventario di Ansible per includere l'host 'web1' e assicurati che l'accesso SSH senza password sia configurato."
    instructions='[
  {
    "instruction": "Vai alla directory del codice Ansible.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Aggiungi '\''web1'\'' al file di inventario di Ansible '/etc/ansible/hosts'.",
    "command": "echo '\''web1'\'' | sudo tee -a /etc/ansible/hosts"
  },
  {
    "instruction": "Assicurati che l'accesso SSH senza password sia configurato per l'host '\''web1'\''.",
    "command": "ssh-copy-id <web1-user>@web1"
  },
  {
    "instruction": "Verifica la connessione eseguendo un test ping.",
    "command": "ansible web1 -i /etc/ansible/hosts -m ping"
  }
]'
    ;;
  *)
    # Default to English if the language is not supported
    question="Configure Ansible to manage a remote host 'web1' (use default inventory '/etc/ansible/hosts')."
    hint="Update the Ansible inventory to include the host 'web1' and ensure passwordless SSH access is set up."
    instructions='[
  {
    "instruction": "Navigate to the Ansible code directory.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Add '\''web1'\'' to the Ansible inventory file '/etc/ansible/hosts'.",
    "command": "echo '\''web1'\'' | sudo tee -a /etc/ansible/hosts"
  },
  {
    "instruction": "Ensure passwordless SSH access is configured for the '\''web1'\'' host.",
    "command": "ssh-copy-id <web1-user>@web1"
  },
  {
    "instruction": "Verify the connection by running a ping test.",
    "command": "ansible web1 -i /etc/ansible/hosts -m ping"
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