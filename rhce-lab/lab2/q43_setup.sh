#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

project_dir="/home/ansible_user/ansible_nginx_localhost_project"

# Create the project directory
if [[ ! -d "$project_dir" ]]; then
  mkdir "$project_dir"
  echo "Directory $project_dir created."
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
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file targeting 'localhost'. Following Ansible best practices, update the playbook to install the 'nginx' package on 'localhost' using the 'ansible.builtin.apt' module and ensure it is actually installed."
    hint="Modify 'playbook.yml' to include a task that uses the 'ansible.builtin.apt' module to install 'nginx' with 'state: present'. Ensure the playbook remains targeted at 'localhost' and run it to install nginx."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to install nginx on localhost:\",
        \"command\": \"echo -e '---\\n- name: Configure localhost\\n  hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Install nginx\\n      ansible.builtin.apt:\\n        name: nginx\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Run the playbook to install nginx:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  "fr")
    question="Il existe un projet Ansible dans $project_dir avec un fichier 'playbook.yml' ciblant 'localhost'. En suivant les bonnes pratiques Ansible, mettez à jour le playbook pour installer le paquet 'nginx' sur 'localhost' en utilisant le module 'ansible.builtin.apt' et assurez-vous qu'il est réellement installé."
    hint="Modifiez 'playbook.yml' pour inclure une tâche qui utilise le module 'ansible.builtin.apt' pour installer 'nginx' avec 'state: present'. Assurez-vous que le playbook reste ciblé sur 'localhost' et exécutez-le pour installer nginx."
    instructions="[
      {
        \"instruction\": \"Naviguez vers le répertoire du projet:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Mettez à jour 'playbook.yml' pour installer nginx sur localhost:\",
        \"command\": \"echo -e '---\\n- name: Configurer localhost\\n  hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Installer nginx\\n      ansible.builtin.apt:\\n        name: nginx\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Exécutez le playbook pour installer nginx:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  "de")
    question="Es gibt ein Ansible-Projekt in $project_dir mit einer Datei 'playbook.yml', die 'localhost' als Ziel hat. Aktualisieren Sie das Playbook gemäß Ansible-Best-Practices, um das Paket 'nginx' auf 'localhost' mit dem Modul 'ansible.builtin.apt' zu installieren und stellen Sie sicher, dass es tatsächlich installiert ist."
    hint="Ändern Sie 'playbook.yml', um eine Aufgabe einzufügen, die das Modul 'ansible.builtin.apt' verwendet, um 'nginx' mit 'state: present' zu installieren. Stellen Sie sicher, dass das Playbook weiterhin 'localhost' als Ziel hat und führen Sie es aus, um nginx zu installieren."
    instructions="[
      {
        \"instruction\": \"Wechseln Sie zum Projektverzeichnis:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aktualisieren Sie 'playbook.yml', um nginx auf localhost zu installieren:\",
        \"command\": \"echo -e '---\\n- name: Lokalen Host konfigurieren\\n  hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Nginx installieren\\n      ansible.builtin.apt:\\n        name: nginx\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Führen Sie das Playbook aus, um nginx zu installieren:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  "es")
    question="Existe un proyecto de Ansible en $project_dir con un archivo 'playbook.yml' que apunta a 'localhost'. Siguiendo las mejores prácticas de Ansible, actualiza el playbook para instalar el paquete 'nginx' en 'localhost' usando el módulo 'ansible.builtin.apt' y asegúrate de que esté realmente instalado."
    hint="Modifica 'playbook.yml' para incluir una tarea que use el módulo 'ansible.builtin.apt' para instalar 'nginx' con 'state: present'. Asegúrate de que el playbook siga apuntando a 'localhost' y ejecútalo para instalar nginx."
    instructions="[
      {
        \"instruction\": \"Navega al directorio del proyecto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Actualiza 'playbook.yml' para instalar nginx en localhost:\",
        \"command\": \"echo -e '---\\n- name: Configurar localhost\\n  hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Instalar nginx\\n      ansible.builtin.apt:\\n        name: nginx\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Ejecuta el playbook para instalar nginx:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  "it")
    question="Esiste un progetto Ansible in $project_dir con un file 'playbook.yml' che punta a 'localhost'. Seguendo le migliori pratiche di Ansible, aggiorna il playbook per installare il pacchetto 'nginx' su 'localhost' usando il modulo 'ansible.builtin.apt' e assicurati che sia realmente installato."
    hint="Modifica 'playbook.yml' per includere un compito che utilizzi il modulo 'ansible.builtin.apt' per installare 'nginx' con 'state: present'. Assicurati che il playbook continui a puntare a 'localhost' ed eseguilo per installare nginx."
    instructions="[
      {
        \"instruction\": \"Naviga nella directory del progetto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aggiorna 'playbook.yml' per installare nginx su localhost:\",
        \"command\": \"echo -e '---\\n- name: Configure localhost\\n  hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Installare nginx\\n      ansible.builtin.apt:\\n        name: nginx\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Esegui il playbook per installare nginx:\",
        \"command\": \"ansible-playbook playbook.yml\"
      }
    ]"
    ;;
  *)
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file targeting 'localhost'. Following Ansible best practices, update the playbook to install the 'nginx' package on 'localhost' using the 'ansible.builtin.apt' module and ensure it is actually installed."
    hint="Modify 'playbook.yml' to include a task that uses the 'ansible.builtin.apt' module to install 'nginx' with 'state: present'. Ensure the playbook remains targeted at 'localhost' and run it to install nginx."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to install nginx on localhost:\",
        \"command\": \"echo -e '---\\n- name: Configure localhost\\n  hosts: localhost\\n  become: true\\n  tasks:\\n    - name: Install nginx\\n      ansible.builtin.apt:\\n        name: nginx\\n        state: present' > playbook.yml\"
      },
      {
        \"instruction\": \"Run the playbook to install nginx:\",
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