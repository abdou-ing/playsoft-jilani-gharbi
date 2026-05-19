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
mkdir -p $code_path
playbook_name="$code_path/create_config_playbook.yml"

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="Create an Ansible playbook under $code_path to create an empty config file (/etc/my_config)"
    hint="You could use the module file"
    instructions='[
  {
    "instruction": "Navigate to '$code_path'",
    "command": "cd '$code_path'"
  },
  {
    "instruction": "Create a new playbook file named '$playbook_name' with the following structure",
    "command": "echo -e \"---\\n- hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Create an empty config file\\n      ansible.builtin.file:\\n        path: /etc/my_config\\n        state: touch\" > '$playbook_name'"
  },
  {
    "instruction": "Run the playbook to create the empty config file",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Verify that the config file was created",
    "command": "ls -l /etc/my_config"
  }
]'
    ;;
  "fr")
    question="Créez un playbook Ansible sous $code_path pour créer un fichier de configuration vide (/etc/my_config)"
    hint="Vous pouvez utiliser le module file"
    instructions='[
  {
    "instruction": "Accédez à '$code_path'",
    "command": "cd '$code_path'"
  },
  {
    "instruction": "Créez un nouveau fichier de playbook nommé '$playbook_name' avec la structure suivante",
    "command": "echo -e \"---\\n- hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Créer un fichier de configuration vide\\n      ansible.builtin.file:\\n        path: /etc/my_config\\n        state: touch\" > '$playbook_name'"
  },
  {
    "instruction": "Exécutez le playbook pour créer le fichier de configuration vide",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Vérifiez que le fichier de configuration a été créé",
    "command": "ls -l /etc/my_config"
  }
]'
    ;;
  "de")
    question="Erstellen Sie ein Ansible-Playbook unter $code_path, um eine leere Konfigurationsdatei (/etc/my_config) zu erstellen"
    hint="Sie können das Modul file verwenden"
    instructions='[
  {
    "instruction": "Wechseln Sie nach '$code_path'",
    "command": "cd '$code_path'"
  },
  {
    "instruction": "Erstellen Sie eine neue Playbook-Datei namens '$playbook_name' mit der folgenden Struktur",
    "command": "echo -e \"---\\n- hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Erstellen Sie eine leere Konfigurationsdatei\\n      ansible.builtin.file:\\n        path: /etc/my_config\\n        state: touch\" > '$playbook_name'"
  },
  {
    "instruction": "Führen Sie das Playbook aus, um die leere Konfigurationsdatei zu erstellen",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Überprüfen Sie, ob die Konfigurationsdatei erstellt wurde",
    "command": "ls -l /etc/my_config"
  }
]'
    ;;
  "es")
    question="Cree un playbook de Ansible en $code_path para crear un archivo de configuración vacío (/etc/my_config)"
    hint="Puede usar el módulo file"
    instructions='[
  {
    "instruction": "Navegue a '$code_path'",
    "command": "cd '$code_path'"
  },
  {
    "instruction": "Cree un nuevo archivo de playbook llamado '$playbook_name' con la siguiente estructura",
    "command": "echo -e \"---\\n- hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Crear un archivo de configuración vacío\\n      ansible.builtin.file:\\n        path: /etc/my_config\\n        state: touch\" > '$playbook_name'"
  },
  {
    "instruction": "Ejecute el playbook para crear el archivo de configuración vacío",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Verifique que el archivo de configuración fue creado",
    "command": "ls -l /etc/my_config"
  }
]'
    ;;
  "it")
    question="Crea un playbook Ansible in $code_path per creare un file di configurazione vuoto (/etc/my_config)"
    hint="Puoi usare il modulo file"
    instructions='[
  {
    "instruction": "Vai a '$code_path'",
    "command": "cd '$code_path'"
  },
  {
    "instruction": "Crea un nuovo file di playbook chiamato '$playbook_name' con la seguente struttura",
    "command": "echo -e \"---\\n- hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Crea un file di configurazione vuoto\\n      ansible.builtin.file:\\n        path: /etc/my_config\\n        state: touch\" > '$playbook_name'"
  },
  {
    "instruction": "Esegui il playbook per creare il file di configurazione vuoto",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Verifica che il file di configurazione sia stato creato",
    "command": "ls -l /etc/my_config"
  }
]'
    ;;
  *)
    # Default to English if the language is not supported
    question="Create an Ansible playbook under $code_path to create an empty config file (/etc/my_config)"
    hint="You could use the module file"
    instructions='[
  {
    "instruction": "Navigate to '$code_path'",
    "command": "cd '$code_path'"
  },
  {
    "instruction": "Create a new playbook file named '$playbook_name' with the following structure",
    "command": "echo -e \"---\\n- hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Create an empty config file\\n      ansible.builtin.file:\\n        path: /etc/my_config\\n        state: touch\" > '$playbook_name'"
  },
  {
    "instruction": "Run the playbook to create the empty config file",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Verify that the config file was created",
    "command": "ls -l /etc/my_config"
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