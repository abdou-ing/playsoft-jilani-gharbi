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
playbook_name="apache_playbook.yml"

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="Create an Ansible playbook ($code_path/$playbook_name) to install and start the 'apache2' package on the remote host 'web1'."
    hint="Use the 'ansible.builtin.apt' module to install the package and the 'ansible.builtin.service' module to ensure it is running."
    instructions='[
  {
    "instruction": "Navigate to the Ansible code directory.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Create a playbook file named '"$playbook_name"' with the following content.",
    "command": "echo -e \"---\\n- hosts: web1\\n  tasks:\\n    - name: Install apache2\\n      ansible.builtin.apt:\\n        name: apache2\\n        state: present\\n\\n    - name: Ensure apache2 is running\\n      ansible.builtin.service:\\n        name: apache2\\n        state: started\" > '$playbook_name'"
  },
  {
    "instruction": "Run the playbook to install and start apache2 on the remote host.",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Verify that the apache2 service is running on the host 'web1'.",
    "command": "curl http://web1"
  }
]'
    ;;
  "fr")
    question="Create an Ansible playbook ($code_path/$playbook_name) to install and start the 'apache2' package on the remote host 'web1'."    hint="Utilisez le module 'ansible.builtin.apt' pour installer le package et le module 'ansible.builtin.service' pour vous assurer qu'il est en cours d'exécution."
    instructions='[
  {
    "instruction": "Accédez au répertoire de code Ansible.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Créez un fichier de playbook nommé '"$playbook_name"' avec le contenu suivant.",
    "command": "echo -e \"---\\n- hosts: web1\\n  tasks:\\n    - name: Install apache2\\n      ansible.builtin.apt:\\n        name: apache2\\n        state: present\\n\\n    - name: Ensure apache2 is running\\n      ansible.builtin.service:\\n        name: apache2\\n        state: started\" > '$playbook_name'"
  },
  {
    "instruction": "Exécutez le playbook pour installer et démarrer apache2 sur le serveur distant.",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Vérifiez que le service apache2 est en cours fonctionnel sur le serveur 'web1'.",
    "command": "curl http://web1"
  }
]'
    ;;
  "de")
    question="Erstellen Sie ein Ansible-Playbook ($code_path/$playbook_name), um das Paket 'apache2' auf dem Remote-Host 'web1' zu installieren und zu starten."    hint="Verwenden Sie das Modul 'ansible.builtin.apt', um das Paket zu installieren, und das Modul 'ansible.builtin.service', um sicherzustellen, dass es ausgeführt wird."
    instructions='[
  {
    "instruction": "Wechseln Sie in das Ansible-Code-Verzeichnis.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Erstellen Sie eine Playbook-Datei namens '"$playbook_name"' mit dem folgenden Inhalt.",
    "command": "echo -e \"---\\n- hosts: web1\\n  tasks:\\n    - name: Install apache2\\n      ansible.builtin.apt:\\n        name: apache2\\n        state: present\\n\\n    - name: Ensure apache2 is running\\n      ansible.builtin.service:\\n        name: apache2\\n        state: started\" > '$playbook_name'"
  },
  {
    "instruction": "Führen Sie das Playbook aus, um apache2 auf dem Remote-Host zu installieren und zu starten.",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Überprüfen Sie, ob der apache2-Dienst auf dem Host 'web1' ausgeführt wird.",
    "command": "curl http://web1"
  }
]'
    ;;
  "es")
    question="Cree un playbook de Ansible ($code_path/$playbook_name) para instalar e iniciar el paquete 'apache2' en el host remoto 'web1'."
    hint="Use el módulo 'ansible.builtin.apt' para instalar el paquete y el módulo 'ansible.builtin.service' para asegurarse de que esté en ejecución."
    instructions='[
  {
    "instruction": "Navegue al directorio de código de Ansible.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Cree un archivo de playbook llamado '"$playbook_name"' con el siguiente contenido.",
    "command": "echo -e \"---\\n- hosts: web1\\n  tasks:\\n    - name: Install apache2\\n      ansible.builtin.apt:\\n        name: apache2\\n        state: present\\n\\n    - name: Ensure apache2 is running\\n      ansible.builtin.service:\\n        name: apache2\\n        state: started\" > '$playbook_name'"
  },
  {
    "instruction": "Ejecute el playbook para instalar e iniciar apache2 en el host remoto.",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Verifique que el servicio apache2 esté en ejecución en el host 'web1'.",
    "command": "curl http://web1"
  }
]'
    ;;
  "it")
    question="Crea un playbook Ansible ($code_path/$playbook_name) per installare e avviare il pacchetto 'apache2' sull'host remoto 'web1'."
    hint="Usa il modulo 'ansible.builtin.apt' per installare il pacchetto e il modulo 'ansible.builtin.service' per assicurarti che sia in esecuzione."
    instructions='[
  {
    "instruction": "Vai alla directory del codice Ansible.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Crea un file di playbook chiamato '"$playbook_name"' con il seguente contenuto.",
    "command": "echo -e \"---\\n- hosts: web1\\n  tasks:\\n    - name: Install apache2\\n      ansible.builtin.apt:\\n        name: apache2\\n        state: present\\n\\n    - name: Ensure apache2 is running\\n      ansible.builtin.service:\\n        name: apache2\\n        state: started\" > '$playbook_name'"
  },
  {
    "instruction": "Esegui il playbook per installare e avviare apache2 sullhost remoto.",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Verifica che il servizio apache2 sia in esecuzione sullhost 'web1'.",
    "command": "curl http://web1"
  }
]'
    ;;
  *)
    # Default to English if the language is not supported
    question="Create an Ansible playbook ($code_path/$playbook_name) to install and start the 'apache2' package on the remote host 'web1'."
    hint="Use the 'ansible.builtin.apt' module to install the package and the 'ansible.builtin.service' module to ensure it is running."
    instructions='[
  {
    "instruction": "Navigate to the Ansible code directory.",
    "command": "cd '"$code_path"'"
  },
  {
    "instruction": "Create a playbook file named '"$playbook_name"' with the following content.",
    "command": "echo -e \"---\\n- hosts: web1\\n  tasks:\\n    - name: Install apache2\\n      ansible.builtin.apt:\\n        name: apache2\\n        state: present\\n\\n    - name: Ensure apache2 is running\\n      ansible.builtin.service:\\n        name: apache2\\n        state: started\" > '$playbook_name'"
  },
  {
    "instruction": "Run the playbook to install and start apache2 on the remote host.",
    "command": "ansible-playbook '$playbook_name'"
  },
  {
    "instruction": "Verify that the apache2 service is running on the host 'web1'.",
    "command": "curl http://web1"
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