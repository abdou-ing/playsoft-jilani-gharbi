#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

project_dir="/home/ansible_user/ansible_collection_project"

# Create the project directory
if [[ ! -d "$project_dir" ]]; then
  mkdir "$project_dir"
  #echo "Directory $project_dir created."
fi

cd "$project_dir"

# Create a basic playbook without a collection
cat <<EOF > playbook.yml
---
- name: Configure system
  hosts: localhost
  tasks:
    - name: Install a package
      ansible.builtin.apt:
        name: vim
        state: present
EOF

case "$lang" in
  "en")
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file that installs the 'vim' package. Following Ansible best practices, install the 'community.general' collection and update the playbook to use the 'community.general.timezone' module to set the system timezone to 'UTC'."
    hint="Use the 'ansible-galaxy' command to install the 'community.general' collection, then add a task to the playbook using the 'community.general.timezone' module with the 'name' parameter set to 'UTC'."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Install the 'community.general' collection:\",
        \"command\": \"ansible-galaxy collection install community.general\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to include a task using 'community.general.timezone':\",
        \"command\": \"echo -e '---\\n- name: Configure system\\n  hosts: localhost\\n  tasks:\\n    - name: Install a package\\n      ansible.builtin.apt:\\n        name: vim\\n        state: present\\n    - name: Set timezone to UTC\\n      community.general.timezone:\\n        name: UTC' > playbook.yml\"
      }
    ]"
    ;;
  "fr")
    question="Il existe un projet Ansible dans $project_dir avec un fichier 'playbook.yml' qui installe le paquet 'vim'. En suivant les bonnes pratiques Ansible, installez la collection 'community.general' et mettez à jour le playbook pour utiliser le module 'community.general.timezone' afin de définir le fuseau horaire du système sur 'UTC'."
    hint="Utilisez la commande 'ansible-galaxy' pour installer la collection 'community.general', puis ajoutez une tâche au playbook utilisant le module 'community.general.timezone' avec le paramètre 'name' défini sur 'UTC'."
    instructions="[
      {
        \"instruction\": \"Naviguez vers le répertoire du projet:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Installez la collection 'community.general':\",
        \"command\": \"ansible-galaxy collection install community.general\"
      },
      {
        \"instruction\": \"Mettez à jour 'playbook.yml' pour inclure une tâche utilisant 'community.general.timezone':\",
        \"command\": \"echo -e '---\\n- name: Configurer le système\\n  hosts: localhost\\n  tasks:\\n    - name: Installer un paquet\\n      ansible.builtin.apt:\\n        name: vim\\n        state: present\\n    - name: Définir le fuseau horaire sur UTC\\n      community.general.timezone:\\n        name: UTC' > playbook.yml\"
      }
    ]"
    ;;
  "de")
    question="Es gibt ein Ansible-Projekt in $project_dir mit einer Datei 'playbook.yml', die das Paket 'vim' installiert. Installieren Sie gemäß Ansible-Best-Practices die Sammlung 'community.general' und aktualisieren Sie das Playbook, um das Modul 'community.general.timezone' zu verwenden, um die Systemzeitzone auf 'UTC' zu setzen."
    hint="Verwenden Sie den Befehl 'ansible-galaxy', um die Sammlung 'community.general' zu installieren, und fügen Sie dann eine Aufgabe zum Playbook hinzu, die das Modul 'community.general.timezone' mit dem Parameter 'name' auf 'UTC' verwendet."
    instructions="[
      {
        \"instruction\": \"Wechseln Sie zum Projektverzeichnis:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Installieren Sie die Sammlung 'community.general':\",
        \"command\": \"ansible-galaxy collection install community.general\"
      },
      {
        \"instruction\": \"Aktualisieren Sie 'playbook.yml', um eine Aufgabe mit 'community.general.timezone' einzufügen:\",
        \"command\": \"echo -e '---\\n- name: System konfigurieren\\n  hosts: localhost\\n  tasks:\\n    - name: Ein Paket installieren\\n      ansible.builtin.apt:\\n        name: vim\\n        state: present\\n    - name: Zeitzone auf UTC setzen\\n      community.general.timezone:\\n        name: UTC' > playbook.yml\"
      }
    ]"
    ;;
  "es")
    question="Existe un proyecto de Ansible en $project_dir con un archivo 'playbook.yml' que instala el paquete 'vim'. Siguiendo las mejores prácticas de Ansible, instala la colección 'community.general' y actualiza el playbook para usar el módulo 'community.general.timezone' para establecer la zona horaria del sistema en 'UTC'."
    hint="Usa el comando 'ansible-galaxy' para instalar la colección 'community.general', luego agrega una tarea al playbook usando el módulo 'community.general.timezone' con el parámetro 'name' establecido en 'UTC'."
    instructions="[
      {
        \"instruction\": \"Navega al directorio del proyecto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Instala la colección 'community.general':\",
        \"command\": \"ansible-galaxy collection install community.general\"
      },
      {
        \"instruction\": \"Actualiza 'playbook.yml' para incluir una tarea usando 'community.general.timezone':\",
        \"command\": \"echo -e '---\\n- name: Configurar el sistema\\n  hosts: localhost\\n  tasks:\\n    - name: Instalar un paquete\\n      ansible.builtin.apt:\\n        name: vim\\n        state: present\\n    - name: Establecer la zona horaria en UTC\\n      community.general.timezone:\\n        name: UTC' > playbook.yml\"
      }
    ]"
    ;;
  "it")
    question="Esiste un progetto Ansible in $project_dir con un file 'playbook.yml' che installa il pacchetto 'vim'. Seguendo le migliori pratiche di Ansible, installa la collezione 'community.general' e aggiorna il playbook per utilizzare il modulo 'community.general.timezone' per impostare il fuso orario del sistema su 'UTC'."
    hint="Usa il comando 'ansible-galaxy' per installare la collezione 'community.general', quindi aggiungi un compito al playbook usando il modulo 'community.general.timezone' con il parametro 'name' impostato su 'UTC'."
    instructions="[
      {
        \"instruction\": \"Naviga nella directory del progetto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Installa la collezione 'community.general':\",
        \"command\": \"ansible-galaxy collection install community.general\"
      },
      {
        \"instruction\": \"Aggiorna 'playbook.yml' per includere un compito usando 'community.general.timezone':\",
        \"command\": \"echo -e '---\\n- name: Configurare il sistema\\n  hosts: localhost\\n  tasks:\\n    - name: Installare un pacchetto\\n      ansible.builtin.apt:\\n        name: vim\\n        state: present\\n    - name: Impostare il fuso orario su UTC\\n      community.general.timezone:\\n        name: UTC' > playbook.yml\"
      }
    ]"
    ;;
  *)
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file that installs the 'vim' package. Following Ansible best practices, install the 'community.general' collection and update the playbook to use the 'community.general.timezone' module to set the system timezone to 'UTC'."
    hint="Use the 'ansible-galaxy' command to install the 'community.general' collection, then add a task to the playbook using the 'community.general.timezone' module with the 'name' parameter set to 'UTC'."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Install the 'community.general' collection:\",
        \"command\": \"ansible-galaxy collection install community.general\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to include a task using 'community.general.timezone':\",
        \"command\": \"echo -e '---\\n- name: Configure system\\n  hosts: localhost\\n  tasks:\\n    - name: Install a package\\n      ansible.builtin.apt:\\n        name: vim\\n        state: present\\n    - name: Set timezone to UTC\\n      community.general.timezone:\\n        name: UTC' > playbook.yml\"
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