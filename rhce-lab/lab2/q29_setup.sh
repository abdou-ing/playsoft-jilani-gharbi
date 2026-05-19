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
chown ansible_user:ansible_user $code_path
playbook_name="nginx_playbook.yml"

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="You need to create an Ansible playbook '$playbook_name' (under $code_path) to install and configure an nginx web server on a localhost."
    hint="Write a YAML playbook file with a task to install nginx, ensure the service is running, and test its status."
    instructions="[
                  {
                    \"instruction\": \"Navigate to $code_path\",
                    \"command\": \"cd $code_path\"
                  },
                  {
                    \"instruction\": \"Create a new playbook file named '$playbook_name' with the following structure\",
                    \"command\": \"echo -e \\\"---\\\\n- hosts: localhost\\\\n  become: true\\\\n  tasks:\\\\n    - name: Update apt cache and install nginx\\\\n      ansible.builtin.apt:\\\\n        name: nginx\\\\n        state: present\\\\n        update_cache: yes\\\\n\\\\n    - name: Ensure nginx is running\\\\n      ansible.builtin.service:\\\\n        name: nginx\\\\n        state: started\\\\n\\\" | cat > $playbook_name\"
                  },
                  {
                    \"instruction\": \"Run the playbook to install and configure nginx\",
                    \"command\": \"ansible-playbook $playbook_name\"
                  },
                  {
                    \"instruction\": \"Verify that nginx is running by using the 'curl http://localhost' command\",
                    \"command\": \"curl http://localhost\"
                  }
                ]"
    ;;
  "fr")
    question="Vous devez créer un playbook Ansible '$playbook_name' (dans $code_path) pour installer et configurer un serveur web nginx sur localhost."
    hint="Écrivez un fichier de playbook YAML avec une tâche pour installer nginx, assurer que le service est en cours d'exécution et tester son statut."
    instructions="[
                  {
                    \"instruction\": \"Accédez à $code_path\",
                    \"command\": \"cd $code_path\"
                  },
                  {
                    \"instruction\": \"Créez un nouveau fichier de playbook nommé '$playbook_name' avec la structure suivante\",
                    \"command\": \"echo -e \\\"---\\\\n- hosts: localhost\\\\n  become: true\\\\n  tasks:\\\\n    - name: Mettre à jour le cache apt et installer nginx\\\\n      ansible.builtin.apt:\\\\n        name: nginx\\\\n        state: present\\\\n        update_cache: yes\\\\n\\\\n    - name: Assurer que nginx est en cours d'exécution\\\\n      ansible.builtin.service:\\\\n        name: nginx\\\\n        state: started\\\\n\\\" | cat > $playbook_name\"
                  },
                  {
                    \"instruction\": \"Exécutez le playbook pour installer et configurer nginx\",
                    \"command\": \"ansible-playbook $playbook_name\"
                  },
                  {
                    \"instruction\": \"Vérifiez que nginx est en cours d'exécution en utilisant la commande 'curl http://localhost'\",
                    \"command\": \"curl http://localhost\"
                  }
                ]"
    ;;
  "de")
    question="Sie müssen ein Ansible-Playbook '$playbook_name' (in $code_path) erstellen, um einen nginx-Webserver auf localhost zu installieren und zu konfigurieren."
    hint="Schreiben Sie eine YAML-Playbook-Datei mit einer Aufgabe, um nginx zu installieren, sicherzustellen, dass der Dienst läuft, und seinen Status zu testen."
    instructions="[
                  {
                    \"instruction\": \"Wechseln Sie nach $code_path\",
                    \"command\": \"cd $code_path\"
                  },
                  {
                    \"instruction\": \"Erstellen Sie eine neue Playbook-Datei namens '$playbook_name' mit der folgenden Struktur\",
                    \"command\": \"echo -e \\\"---\\\\n- hosts: localhost\\\\n  become: true\\\\n  tasks:\\\\n    - name: Aktualisieren Sie den apt-Cache und installieren Sie nginx\\\\n      ansible.builtin.apt:\\\\n        name: nginx\\\\n        state: present\\\\n        update_cache: yes\\\\n\\\\n    - name: Stellen Sie sicher, dass nginx läuft\\\\n      ansible.builtin.service:\\\\n        name: nginx\\\\n        state: started\\\\n\\\" | cat > $playbook_name\"
                  },
                  {
                    \"instruction\": \"Führen Sie das Playbook aus, um nginx zu installieren und zu konfigurieren\",
                    \"command\": \"ansible-playbook $playbook_name\"
                  },
                  {
                    \"instruction\": \"Überprüfen Sie, ob nginx läuft, indem Sie den Befehl 'curl http://localhost' verwenden\",
                    \"command\": \"curl http://localhost\"
                  }
                ]"
    ;;
  "es")
    question="Necesitas crear un playbook de Ansible '$playbook_name' (en $code_path) para instalar y configurar un servidor web nginx en localhost."
    hint="Escribe un archivo de playbook YAML con una tarea para instalar nginx, asegurar que el servicio esté en ejecución y probar su estado."
    instructions="[
                  {
                    \"instruction\": \"Navega a $code_path\",
                    \"command\": \"cd $code_path\"
                  },
                  {
                    \"instruction\": \"Crea un nuevo archivo de playbook llamado '$playbook_name' con la siguiente estructura\",
                    \"command\": \"echo -e \\\"---\\\\n- hosts: localhost\\\\n  become: true\\\\n  tasks:\\\\n    - name: Actualizar la caché de apt e instalar nginx\\\\n      ansible.builtin.apt:\\\\n        name: nginx\\\\n        state: present\\\\n        update_cache: yes\\\\n\\\\n    - name: Asegurar que nginx esté en ejecución\\\\n      ansible.builtin.service:\\\\n        name: nginx\\\\n        state: started\\\\n\\\" | cat > $playbook_name\"
                  },
                  {
                    \"instruction\": \"Ejecuta el playbook para instalar y configurar nginx\",
                    \"command\": \"ansible-playbook $playbook_name\"
                  },
                  {
                    \"instruction\": \"Verifica que nginx esté en ejecución usando el comando 'curl http://localhost'\",
                    \"command\": \"curl http://localhost\"
                  }
                ]"
    ;;
  "it")
    question="Devi creare un playbook Ansible '$playbook_name' (in $code_path) per installare e configurare un server web nginx su localhost."
    hint="Scrivi un file di playbook YAML con un'attività per installare nginx, assicurarti che il servizio sia in esecuzione e testarne lo stato."
    instructions="[
                  {
                    \"instruction\": \"Vai a $code_path\",
                    \"command\": \"cd $code_path\"
                  },
                  {
                    \"instruction\": \"Crea un nuovo file di playbook chiamato '$playbook_name' con la seguente struttura\",
                    \"command\": \"echo -e \\\"---\\\\n- hosts: localhost\\\\n  become: true\\\\n  tasks:\\\\n    - name: Aggiorna la cache di apt e installa nginx\\\\n      ansible.builtin.apt:\\\\n        name: nginx\\\\n        state: present\\\\n        update_cache: yes\\\\n\\\\n    - name: Assicurati che nginx sia in esecuzione\\\\n      ansible.builtin.service:\\\\n        name: nginx\\\\n        state: started\\\\n\\\" | cat > $playbook_name\"
                  },
                  {
                    \"instruction\": \"Esegui il playbook per installare e configurare nginx\",
                    \"command\": \"ansible-playbook $playbook_name\"
                  },
                  {
                    \"instruction\": \"Verifica che nginx sia in esecuzione usando il comando 'curl http://localhost'\",
                    \"command\": \"curl http://localhost\"
                  }
                ]"
    ;;
  *)
    # Default to English if the language is not supported
    question="You need to create an Ansible playbook '$playbook_name' (under $code_path) to install and configure an nginx web server on a localhost."
    hint="Write a YAML playbook file with a task to install nginx, ensure the service is running, and test its status."
    instructions="[
                  {
                    \"instruction\": \"Navigate to $code_path\",
                    \"command\": \"cd $code_path\"
                  },
                  {
                    \"instruction\": \"Create a new playbook file named '$playbook_name' with the following structure\",
                    \"command\": \"echo -e \\\"---\\\\n- hosts: localhost\\\\n  become: true\\\\n  tasks:\\\\n    - name: Update apt cache and install nginx\\\\n      ansible.builtin.apt:\\\\n        name: nginx\\\\n        state: present\\\\n        update_cache: yes\\\\n\\\\n    - name: Ensure nginx is running\\\\n      ansible.builtin.service:\\\\n        name: nginx\\\\n        state: started\\\\n\\\" | cat > $playbook_name\"
                  },
                  {
                    \"instruction\": \"Run the playbook to install and configure nginx\",
                    \"command\": \"ansible-playbook $playbook_name\"
                  },
                  {
                    \"instruction\": \"Verify that nginx is running by using the 'curl http://localhost' command\",
                    \"command\": \"curl http://localhost\"
                  }
                ]"
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