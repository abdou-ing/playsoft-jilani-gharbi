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
sudo chown ansible_user:ansible_user $code_path
playbook_name="user_playbook.yml"

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="You need to create an Ansible playbook '$playbook_name' (under $code_path) to add a user named 'john' with sudo privileges and a '123456' password."
    hint="Define a task to add a user and configure sudo privileges. Use the 'ansible.builtin.user' and 'ansible.builtin.copy' modules."
    instructions=$(cat <<EOF
[
  {
    "instruction": "Navigate to $code_path",
    "command": "cd $code_path"
  },
  {
    "instruction": "Copy the following playbook content into the file '$playbook_name'",
    "command": "---\n- hosts: localhost\n  become: true\n  tasks:\n    - name: Create user john\n      ansible.builtin.user:\n        name: john\n        password: \"{{ '123456' | password_hash('sha512') }}\"\n        state: present\n\n    - name: Grant sudo privileges\n      ansible.builtin.copy:\n        dest: /etc/sudoers.d/john\n        content: \"john ALL=(ALL) NOPASSWD:ALL\"\n        owner: root\n        group: root\n        mode: \"0440\""
  },
  {
    "instruction": "Run the playbook to create the user and configure sudo privileges",
    "command": "ansible-playbook $playbook_name"
  },
  {
    "instruction": "Verify the user is created and has sudo privileges",
    "command": "su - john -c 'sudo whoami'"
  }
]
EOF
)
    ;;
  "fr")
    question="Vous devez créer un playbook Ansible '$playbook_name' (dans $code_path) pour ajouter un utilisateur nommé 'john' avec des privilèges sudo et un mot de passe '123456'."
    hint="Définissez une tâche pour ajouter un utilisateur et configurer les privilèges sudo. Utilisez les modules 'ansible.builtin.user' et 'ansible.builtin.copy'."
    instructions=$(cat <<EOF
[
  {
    "instruction": "Accédez à $code_path",
    "command": "cd $code_path"
  },
  {
    "instruction": "Copiez le contenu suivant du playbook dans le fichier '$playbook_name'",
    "command": "---\n- hosts: localhost\n  become: true\n  tasks:\n    - name: Créer l'utilisateur john\n      ansible.builtin.user:\n        name: john\n        password: \"{{ '123456' | password_hash('sha512') }}\"\n        state: present\n\n    - name: Accorder les privilèges sudo\n      ansible.builtin.copy:\n        dest: /etc/sudoers.d/john\n        content: \"john ALL=(ALL) NOPASSWD:ALL\"\n        owner: root\n        group: root\n        mode: \"0440\""
  },
  {
    "instruction": "Exécutez le playbook pour créer l'utilisateur et configurer les privilèges sudo",
    "command": "ansible-playbook $playbook_name"
  },
  {
    "instruction": "Vérifiez que l'utilisateur est créé et a les privilèges sudo",
    "command": "su - john -c 'sudo whoami'"
  }
]
EOF
)
    ;;
  "de")
    question="Sie müssen ein Ansible-Playbook '$playbook_name' (in $code_path) erstellen, um einen Benutzer namens 'john' mit sudo-Berechtigungen und einem Passwort '123456' hinzuzufügen."
    hint="Definieren Sie eine Aufgabe, um einen Benutzer hinzuzufügen und sudo-Berechtigungen zu konfigurieren. Verwenden Sie die Module 'ansible.builtin.user' und 'ansible.builtin.copy'."
    instructions=$(cat <<EOF
[
  {
    "instruction": "Wechseln Sie nach $code_path",
    "command": "cd $code_path"
  },
  {
    "instruction": "Kopieren Sie den folgenden Playbook-Inhalt in die Datei '$playbook_name'",
    "command": "---\n- hosts: localhost\n  become: true\n  tasks:\n    - name: Benutzer john erstellen\n      ansible.builtin.user:\n        name: john\n        password: \"{{ '123456' | password_hash('sha512') }}\"\n        state: present\n\n    - name: Sudo-Berechtigungen gewähren\n      ansible.builtin.copy:\n        dest: /etc/sudoers.d/john\n        content: \"john ALL=(ALL) NOPASSWD:ALL\"\n        owner: root\n        group: root\n        mode: \"0440\""
  },
  {
    "instruction": "Führen Sie das Playbook aus, um den Benutzer zu erstellen und sudo-Berechtigungen zu konfigurieren",
    "command": "ansible-playbook $playbook_name"
  },
  {
    "instruction": "Überprüfen Sie, ob der Benutzer erstellt wurde und sudo-Berechtigungen hat",
    "command": "su - john -c 'sudo whoami'"
  }
]
EOF
)
    ;;
  "es")
    question="Necesitas crear un playbook de Ansible '$playbook_name' (en $code_path) para agregar un usuario llamado 'john' con privilegios sudo y una contraseña '123456'."
    hint="Define una tarea para agregar un usuario y configurar privilegios sudo. Usa los módulos 'ansible.builtin.user' y 'ansible.builtin.copy'."
    instructions=$(cat <<EOF
[
  {
    "instruction": "Navega a $code_path",
    "command": "cd $code_path"
  },
  {
    "instruction": "Copia el siguiente contenido del playbook en el archivo '$playbook_name'",
    "command": "---\n- hosts: localhost\n  become: true\n  tasks:\n    - name: Crear usuario john\n      ansible.builtin.user:\n        name: john\n        password: \"{{ '123456' | password_hash('sha512') }}\"\n        state: present\n\n    - name: Otorgar privilegios sudo\n      ansible.builtin.copy:\n        dest: /etc/sudoers.d/john\n        content: \"john ALL=(ALL) NOPASSWD:ALL\"\n        owner: root\n        group: root\n        mode: \"0440\""
  },
  {
    "instruction": "Ejecuta el playbook para crear el usuario y configurar los privilegios sudo",
    "command": "ansible-playbook $playbook_name"
  },
  {
    "instruction": "Verifica que el usuario esté creado y tenga privilegios sudo",
    "command": "su - john -c 'sudo whoami'"
  }
]
EOF
)
    ;;
  "it")
    question="Devi creare un playbook Ansible '$playbook_name' (in $code_path) per aggiungere un utente chiamato 'john' con privilegi sudo e una password '123456'."
    hint="Definisci un'attività per aggiungere un utente e configurare i privilegi sudo. Usa i moduli 'ansible.builtin.user' e 'ansible.builtin.copy'."
    instructions=$(cat <<EOF
[
  {
    "instruction": "Vai a $code_path",
    "command": "cd $code_path"
  },
  {
    "instruction": "Copia il seguente contenuto del playbook nel file '$playbook_name'",
    "command": "---\n- hosts: localhost\n  become: true\n  tasks:\n    - name: Crea l'utente john\n      ansible.builtin.user:\n        name: john\n        password: \"{{ '123456' | password_hash('sha512') }}\"\n        state: present\n\n    - name: Concedi i privilegi sudo\n      ansible.builtin.copy:\n        dest: /etc/sudoers.d/john\n        content: \"john ALL=(ALL) NOPASSWD:ALL\"\n        owner: root\n        group: root\n        mode: \"0440\""
  },
  {
    "instruction": "Esegui il playbook per creare l'utente e configurare i privilegi sudo",
    "command": "ansible-playbook $playbook_name"
  },
  {
    "instruction": "Verifica che l'utente sia stato creato e abbia i privilegi sudo",
    "command": "su - john -c 'sudo whoami'"
  }
]
EOF
)
    ;;
  *)
    # Default to English if the language is not supported
    question="You need to create an Ansible playbook '$playbook_name' (under $code_path) to add a user named 'john' with sudo privileges and a '123456' password."
    hint="Define a task to add a user and configure sudo privileges. Use the 'ansible.builtin.user' and 'ansible.builtin.copy' modules."
    instructions=$(cat <<EOF
[
  {
    "instruction": "Navigate to $code_path",
    "command": "cd $code_path"
  },
  {
    "instruction": "Copy the following playbook content into the file '$playbook_name'",
    "command": "---\n- hosts: localhost\n  become: true\n  tasks:\n    - name: Create user john\n      ansible.builtin.user:\n        name: john\n        password: \"{{ '123456' | password_hash('sha512') }}\"\n        state: present\n\n    - name: Grant sudo privileges\n      ansible.builtin.copy:\n        dest: /etc/sudoers.d/john\n        content: \"john ALL=(ALL) NOPASSWD:ALL\"\n        owner: root\n        group: root\n        mode: \"0440\""
  },
  {
    "instruction": "Run the playbook to create the user and configure sudo privileges",
    "command": "ansible-playbook $playbook_name"
  },
  {
    "instruction": "Verify the user is created and has sudo privileges",
    "command": "su - john -c 'sudo whoami'"
  }
]
EOF
)
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