#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Check if Ansible is not installed AND not functional
if ! command -v ansible >/dev/null 2>&1 && ! ansible --version >/dev/null 2>&1; then
  # Update package lists and install Ansible silently
  #sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y ansible-core >/dev/null 2>&1
  wget http://ftp.ubuntu.com/ubuntu/ubuntu/pool/universe/a/ansible-core/ansible-core_2.16.3-0ubuntu2_all.deb -O /tmp/ansible-core_2.16.3-0ubuntu2_all.deb >/dev/null 2>&1
  sudo chmod +x /tmp/ansible-core_2.16.3-0ubuntu2_all.deb >/dev/null 2>&1
  sudo dpkg -i /tmp/ansible-core_2.16.3-0ubuntu2_all.deb >/dev/null 2>&1
  sudo rm -f /tmp/ansible-core_2.16.3-0ubuntu2_all.deb >/dev/null 2>&1
fi


project_dir="/home/ansible_user/ansible_role_project"

# Create the project directory
if [[ ! -d "$project_dir" ]]; then
  mkdir "$project_dir"
  #echo "Directory $project_dir created."
fi

cd "$project_dir"

# Create a basic playbook with tasks not organized into roles
cat <<EOF > playbook.yml
---
- name: Configure web server
  hosts: localhost
  tasks:
    - name: Install Apache
      ansible.builtin.apt:
        name: apache2
        state: present
    - name: Start Apache service
      ansible.builtin.service:
        name: apache2
        state: started
EOF

case "$lang" in
  "en")
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file containing tasks to install and start Apache. Following Ansible best practices, refactor these tasks into a role named 'webserver' to improve modularity and reusability. Then, update 'playbook.yml' to use this role."
    hint="Create a 'roles' directory with a 'webserver' role, move the tasks into 'tasks/main.yml' under that role, and update the playbook to call the role instead of listing tasks directly."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Create the roles directory structure for 'webserver':\",
        \"command\": \"mkdir -p roles/webserver/tasks\"
      },
      {
        \"instruction\": \"Create 'main.yml' in the 'webserver' role with the tasks:\",
        \"command\": \"echo -e '---\\n- name: Install Apache\\n  ansible.builtin.apt:\\n    name: apache2\\n    state: present\\n- name: Start Apache service\\n  ansible.builtin.service:\\n    name: apache2\\n    state: started' > roles/webserver/tasks/main.yml\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to use the 'webserver' role:\",
        \"command\": \"echo -e '---\\n- name: Configure web server\\n  hosts: localhost\\n  roles:\\n    - webserver' > playbook.yml\"
      }
    ]"
    ;;
  "fr")
    question="Il existe un projet Ansible dans $project_dir avec un fichier 'playbook.yml' contenant des tâches pour installer et démarrer Apache. En suivant les bonnes pratiques Ansible, refactorisez ces tâches dans un rôle nommé 'webserver' pour améliorer la modularité et la réutilisabilité. Ensuite, mettez à jour 'playbook.yml' pour utiliser ce rôle."
    hint="Créez un répertoire 'roles' avec un rôle 'webserver', déplacez les tâches dans 'tasks/main.yml' sous ce rôle, et mettez à jour le playbook pour appeler le rôle au lieu de lister les tâches directement."
    instructions="[
      {
        \"instruction\": \"Naviguez vers le répertoire du projet:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Créez la structure de répertoires pour le rôle 'webserver':\",
        \"command\": \"mkdir -p roles/webserver/tasks\"
      },
      {
        \"instruction\": \"Créez 'main.yml' dans le rôle 'webserver' avec les tâches:\",
        \"command\": \"echo -e '---\\n- name: Installer Apache\\n  ansible.builtin.apt:\\n    name: apache2\\n    state: present\\n- name: Démarrer le service Apache\\n  ansible.builtin.service:\\n    name: apache2\\n    state: started' > roles/webserver/tasks/main.yml\"
      },
      {
        \"instruction\": \"Mettez à jour 'playbook.yml' pour utiliser le rôle 'webserver':\",
        \"command\": \"echo -e '---\\n- name: Configurer le serveur web\\n  hosts: localhost\\n  roles:\\n    - webserver' > playbook.yml\"
      }
    ]"
    ;;
  "de")
    question="Es gibt ein Ansible-Projekt in $project_dir mit einer Datei 'playbook.yml', die Aufgaben zum Installieren und Starten von Apache enthält. Refaktorisieren Sie diese Aufgaben gemäß Ansible-Best-Practices in eine Rolle namens 'webserver', um Modularität und Wiederverwendbarkeit zu verbessern. Aktualisieren Sie dann 'playbook.yml', um diese Rolle zu verwenden."
    hint="Erstellen Sie ein 'roles'-Verzeichnis mit einer 'webserver'-Rolle, verschieben Sie die Aufgaben in 'tasks/main.yml' unter dieser Rolle, und aktualisieren Sie das Playbook, um die Rolle aufzurufen, anstatt Aufgaben direkt aufzulisten."
    instructions="[
      {
        \"instruction\": \"Wechseln Sie zum Projektverzeichnis:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Erstellen Sie die Verzeichnisstruktur für die Rolle 'webserver':\",
        \"command\": \"mkdir -p roles/webserver/tasks\"
      },
      {
        \"instruction\": \"Erstellen Sie 'main.yml' in der Rolle 'webserver' mit den Aufgaben:\",
        \"command\": \"echo -e '---\\n- name: Apache installieren\\n  ansible.builtin.apt:\\n    name: apache2\\n    state: present\\n- name: Apache-Dienst starten\\n  ansible.builtin.service:\\n    name: apache2\\n    state: started' > roles/webserver/tasks/main.yml\"
      },
      {
        \"instruction\": \"Aktualisieren Sie 'playbook.yml', um die Rolle 'webserver' zu verwenden:\",
        \"command\": \"echo -e '---\\n- name: Webserver konfigurieren\\n  hosts: localhost\\n  roles:\\n    - webserver' > playbook.yml\"
      }
    ]"
    ;;
  "es")
    question="Existe un proyecto de Ansible en $project_dir con un archivo 'playbook.yml' que contiene tareas para instalar y arrancar Apache. Siguiendo las mejores prácticas de Ansible, refactorice estas tareas en un rol llamado 'webserver' para mejorar la modularidad y la reutilización. Luego, actualice 'playbook.yml' para usar este rol."
    hint="Cree un directorio 'roles' con un rol 'webserver', mueva las tareas a 'tasks/main.yml' bajo ese rol, y actualice el playbook para invocar el rol en lugar de listar las tareas directamente."
    instructions="[
      {
        \"instruction\": \"Navega al directorio del proyecto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Crea la estructura de directorios para el rol 'webserver':\",
        \"command\": \"mkdir -p roles/webserver/tasks\"
      },
      {
        \"instruction\": \"Crea 'main.yml' en el rol 'webserver' con las tareas:\",
        \"command\": \"echo -e '---\\n- name: Instalar Apache\\n  ansible.builtin.apt:\\n    name: apache2\\n    state: present\\n- name: Iniciar el servicio Apache\\n  ansible.builtin.service:\\n    name: apache2\\n    state: started' > roles/webserver/tasks/main.yml\"
      },
      {
        \"instruction\": \"Actualiza 'playbook.yml' para usar el rol 'webserver':\",
        \"command\": \"echo -e '---\\n- name: Configurar el servidor web\\n  hosts: localhost\\n  roles:\\n    - webserver' > playbook.yml\"
      }
    ]"
    ;;
  "it")
    question="Esiste un progetto Ansible in $project_dir con un file 'playbook.yml' che contiene compiti per installare e avviare Apache. Seguendo le migliori pratiche di Ansible, rifattorizza questi compiti in un ruolo chiamato 'webserver' per migliorare la modularità e la riutilizzabilità. Quindi, aggiorna 'playbook.yml' per utilizzare questo ruolo."
    hint="Crea una directory 'roles' con un ruolo 'webserver', sposta i compiti in 'tasks/main.yml' sotto quel ruolo, e aggiorna il playbook per richiamare il ruolo invece di elencare direttamente i compiti."
    instructions="[
      {
        \"instruction\": \"Naviga nella directory del progetto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Crea la struttura delle directory per il ruolo 'webserver':\",
        \"command\": \"mkdir -p roles/webserver/tasks\"
      },
      {
        \"instruction\": \"Crea 'main.yml' nel ruolo 'webserver' con i compiti:\",
        \"command\": \"echo -e '---\\n- name: Installare Apache\\n  ansible.builtin.apt:\\n    name: apache2\\n    state: present\\n- name: Avviare il servizio Apache\\n  ansible.builtin.service:\\n    name: apache2\\n    state: started' > roles/webserver/tasks/main.yml\"
      },
      {
        \"instruction\": \"Aggiorna 'playbook.yml' per usare il ruolo 'webserver':\",
        \"command\": \"echo -e '---\\n- name: Configurare il server web\\n  hosts: localhost\\n  roles:\\n    - webserver' > playbook.yml\"
      }
    ]"
    ;;
  *)
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file containing tasks to install and start Apache. Following Ansible best practices, refactor these tasks into a role named 'webserver' to improve modularity and reusability. Then, update 'playbook.yml' to use this role."
    hint="Create a 'roles' directory with a 'webserver' role, move the tasks into 'tasks/main.yml' under that role, and update the playbook to call the role instead of listing tasks directly."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Create the roles directory structure for 'webserver':\",
        \"command\": \"mkdir -p roles/webserver/tasks\"
      },
      {
        \"instruction\": \"Create 'main.yml' in the 'webserver' role with the tasks:\",
        \"command\": \"echo -e '---\\n- name: Install Apache\\n  ansible.builtin.apt:\\n    name: apache2\\n    state: present\\n- name: Start Apache service\\n  ansible.builtin.service:\\n    name: apache2\\n    state: started' > roles/webserver/tasks/main.yml\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to use the 'webserver' role:\",
        \"command\": \"echo -e '---\\n- name: Configure web server\\n  hosts: localhost\\n  roles:\\n    - webserver' > playbook.yml\"
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