#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

project_dir="/home/ansible_user/ansible_user_project"

# Create the project directory
if [[ ! -d "$project_dir" ]]; then
  mkdir "$project_dir"
  #echo "Directory $project_dir created."
fi

cd "$project_dir"

# Create an empty playbook targeting localhost
cat <<EOF > playbook.yml
---
- name: Placeholder playbook
  hosts: localhost
  tasks:
    - name: Do nothing
      ansible.builtin.debug:
        msg: "This is a placeholder"
EOF

case "$lang" in
  "en")
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file targeting 'localhost'. Following Ansible best practices, update the playbook to add a user named 'Alice' with the password 'MyP@sswoRD' on 'localhost' using the 'ansible.builtin.user' module. Include the 'become' directive to ensure proper privileges, and verify that the user is created."
    hint="Modify 'playbook.yml' to target 'localhost', add the 'become: yes' directive at the play level, and include a task using the 'ansible.builtin.user' module to create 'Alice' with the specified password (hashed for security). Run the playbook to create the user."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to add user 'Alice' with password 'MyP@sswoRD' on localhost:\",
        \"command\": \"echo -e '---\\n- name: Configure localhost\\n  hosts: localhost\\n  become: yes\\n  tasks:\\n    - name: Add user Alice\\n      ansible.builtin.user:\\n        name: Alice\\n        password: \\\"{{ 'MyP@sswoRD' | password_hash('sha512') }}\\\"\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Run the playbook to create the user:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  "fr")
    question="Il existe un projet Ansible dans $project_dir avec un fichier 'playbook.yml' ciblant 'localhost'. En suivant les bonnes pratiques Ansible, mettez à jour le playbook pour ajouter un utilisateur nommé 'Alice' avec le mot de passe 'MyP@sswoRD' sur 'localhost' en utilisant le module 'ansible.builtin.user'. Incluez la directive 'become' pour garantir les privilèges nécessaires, et vérifiez que l'utilisateur est créé."
    hint="Modifiez 'playbook.yml' pour cibler 'localhost', ajoutez la directive 'become: yes' au niveau du jeu, et incluez une tâche utilisant le module 'ansible.builtin.user' pour créer 'Alice' avec le mot de passe spécifié (haché pour la sécurité). Exécutez le playbook pour créer l'utilisateur."
    instructions="[
      {
        \"instruction\": \"Naviguez vers le répertoire du projet:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Mettez à jour 'playbook.yml' pour ajouter l'utilisateur 'Alice' avec le mot de passe 'MyP@sswoRD' sur localhost:\",
        \"command\": \"echo -e '---\\n- name: Configurer localhost\\n  hosts: localhost\\n  become: yes\\n  tasks:\\n    - name: Ajouter l\\'utilisateur Alice\\n      ansible.builtin.user:\\n        name: Alice\\n        password: \\\"{{ 'MyP@sswoRD' | password_hash('sha512') }}\\\"\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Exécutez le playbook pour créer l'utilisateur:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  "de")
    question="Es gibt ein Ansible-Projekt in $project_dir mit einer Datei 'playbook.yml', die 'localhost' als Ziel hat. Aktualisieren Sie das Playbook gemäß Ansible-Best-Practices, um einen Benutzer namens 'Alice' mit dem Passwort 'MyP@sswoRD' auf 'localhost' mit dem Modul 'ansible.builtin.user' hinzuzufügen. Fügen Sie die Direktive 'become' hinzu, um die erforderlichen Berechtigungen sicherzustellen, und überprüfen Sie, ob der Benutzer erstellt wurde."
    hint="Ändern Sie 'playbook.yml', um 'localhost' anzuzielen, fügen Sie die Direktive 'become: yes' auf Spielebene hinzu, und schließen Sie eine Aufgabe ein, die das Modul 'ansible.builtin.user' verwendet, um 'Alice' mit dem angegebenen Passwort (gehasht für Sicherheit) zu erstellen. Führen Sie das Playbook aus, um den Benutzer zu erstellen."
    instructions="[
      {
        \"instruction\": \"Wechseln Sie zum Projektverzeichnis:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aktualisieren Sie 'playbook.yml', um den Benutzer 'Alice' mit dem Passwort 'MyP@sswoRD' auf localhost hinzuzufügen:\",
        \"command\": \"echo -e '---\\n- name: Lokalen Host konfigurieren\\n  hosts: localhost\\n  become: yes\\n  tasks:\\n    - name: Benutzer Alice hinzufügen\\n      ansible.builtin.user:\\n        name: Alice\\n        password: \\\"{{ 'MyP@sswoRD' | password_hash('sha512') }}\\\"\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Führen Sie das Playbook aus, um den Benutzer zu erstellen:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  "es")
    question="Existe un proyecto de Ansible en $project_dir con un archivo 'playbook.yml' que apunta a 'localhost'. Siguiendo las mejores prácticas de Ansible, actualiza el playbook para añadir un usuario llamado 'Alice' con la contraseña 'MyP@sswoRD' en 'localhost' usando el módulo 'ansible.builtin.user'. Incluye la directiva 'become' para asegurar los privilegios necesarios y verifica que el usuario esté creado."
    hint="Modifica 'playbook.yml' para apuntar a 'localhost', añade la directiva 'become: yes' a nivel de juego, e incluye una tarea usando el módulo 'ansible.builtin.user' para crear 'Alice' con la contraseña especificada (hasheada por seguridad). Ejecuta el playbook para crear el usuario."
    instructions="[
      {
        \"instruction\": \"Navega al directorio del proyecto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Actualiza 'playbook.yml' para añadir el usuario 'Alice' con la contraseña 'MyP@sswoRD' en localhost:\",
        \"command\": \"echo -e '---\\n- name: Configurar localhost\\n  hosts: localhost\\n  become: yes\\n  tasks:\\n    - name: Añadir usuario Alice\\n      ansible.builtin.user:\\n        name: Alice\\n        password: \\\"{{ 'MyP@sswoRD' | password_hash('sha512') }}\\\"\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Ejecuta el playbook para crear el usuario:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  "it")
    question="Esiste un progetto Ansible in $project_dir con un file 'playbook.yml' che punta a 'localhost'. Seguendo le migliori pratiche di Ansible, aggiorna il playbook per aggiungere un utente chiamato 'Alice' con la password 'MyP@sswoRD' su 'localhost' usando il modulo 'ansible.builtin.user'. Includi la direttiva 'become' per garantire i privilegi necessari e verifica che l'utente sia creato."
    hint="Modifica 'playbook.yml' per puntare a 'localhost', aggiungi la direttiva 'become: yes' a livello di gioco, e includi un compito usando il modulo 'ansible.builtin.user' per creare 'Alice' con la password specificata (hashata per sicurezza). Esegui il playbook per creare l'utente."
    instructions="[
      {
        \"instruction\": \"Naviga nella directory del progetto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aggiorna 'playbook.yml' per aggiungere l'utente 'Alice' con la password 'MyP@sswoRD' su localhost:\",
        \"command\": \"echo -e '---\\n- name: Configurare localhost\\n  hosts: localhost\\n  become: yes\\n  tasks:\\n    - name: Aggiungere l\\'utente Alice\\n      ansible.builtin.user:\\n        name: Alice\\n        password: \\\"{{ 'MyP@sswoRD' | password_hash('sha512') }}\\\"\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Esegui il playbook per creare l'utente:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  *)
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file targeting 'localhost'. Following Ansible best practices, update the playbook to add a user named 'Alice' with the password 'MyP@sswoRD' on 'localhost' using the 'ansible.builtin.user' module. Include the 'become' directive to ensure proper privileges, and verify that the user is created."
    hint="Modify 'playbook.yml' to target 'localhost', add the 'become: yes' directive at the play level, and include a task using the 'ansible.builtin.user' module to create 'Alice' with the specified password (hashed for security). Run the playbook to create the user."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to add user 'Alice' with password 'MyP@sswoRD' on localhost:\",
        \"command\": \"echo -e '---\\n- name: Configure localhost\\n  hosts: localhost\\n  become: yes\\n  tasks:\\n    - name: Add user Alice\\n      ansible.builtin.user:\\n        name: Alice\\n        password: \\\"{{ 'MyP@sswoRD' | password_hash('sha512') }}\\\"\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Run the playbook to create the user:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
esac

display=$(cat <<EOF
{
  "question": "$question",
  "type": "button",
  "hint": "$hint",
  "instructions": $instructions,
  "text": "Check",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}
EOF
)

# Use jq to pretty print the JSON (optional)
echo "$display" | jq .