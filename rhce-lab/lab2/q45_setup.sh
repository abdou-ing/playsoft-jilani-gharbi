#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

project_dir="/home/ansible_user/ansible_default_inventory_project"

# Create the project directory
if [[ ! -d "$project_dir" ]]; then
  mkdir "$project_dir"
  #echo "Directory $project_dir created."
fi

cd "$project_dir"

# Create an empty playbook
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
    question="You are connected to an Ansible controller node in $project_dir. Following Ansible best practices, append a new group named 'dbservers' with two hosts, 'db1' and 'db2', to the default inventory file '/etc/ansible/hosts'."
    hint="Edit '/etc/ansible/hosts' to append a new section '[dbservers]' with 'db1' and 'db2' at the end of the file."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory on the controller:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Append the 'dbservers' group with 'db1' and 'db2' to '/etc/ansible/hosts' (requires sudo):\",
        \"command\": \"echo -e '\\n[dbservers]\\ndb1\\ndb2' | sudo tee -a /etc/ansible/hosts\"
      }
      
    ]"
    ;;
  "fr")
    question="Vous êtes connecté à un nœud contrôleur Ansible dans $project_dir. En suivant les bonnes pratiques Ansible, ajoutez en append un nouveau groupe nommé 'dbservers' avec deux hôtes, 'db1' et 'db2', au fichier d'inventaire par défaut '/etc/ansible/hosts'."
    hint="Modifiez '/etc/ansible/hosts' pour ajouter une nouvelle section '[dbservers]' avec 'db1' et 'db2' à la fin du fichier."
    instructions="[
      {
        \"instruction\": \"Naviguez vers le répertoire du projet sur le contrôleur:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Ajoutez en append le groupe 'dbservers' avec 'db1' et 'db2' à '/etc/ansible/hosts' (nécessite sudo):\",
        \"command\": \"echo -e '\\n[dbservers]\\ndb1\\ndb2' | sudo tee -a /etc/ansible/hosts\"
      }
    ]"
    ;;
  "de")
    question="Sie sind mit einem Ansible-Controller-Knoten in $project_dir verbunden. Fügen Sie gemäß Ansible-Best-Practices eine neue Gruppe namens 'dbservers' mit zwei Hosts, 'db1' und 'db2', an die Standard-Inventardatei '/etc/ansible/hosts' "
    hint="Bearbeiten Sie '/etc/ansible/hosts', um am Ende der Datei einen neuen Abschnitt '[dbservers]' mit 'db1' und 'db2' hinzuzufügen."
    instructions="[
      {
        \"instruction\": \"Wechseln Sie zum Projektverzeichnis auf dem Controller:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Fügen Sie die Gruppe 'dbservers' mit 'db1' und 'db2' an '/etc/ansible/hosts' an (erfordert sudo):\",
        \"command\": \"echo -e '\\n[dbservers]\\ndb1\\ndb2' | sudo tee -a /etc/ansible/hosts\"
      }
    ]"
    ;;
  "es")
    question="Estás conectado a un nodo controlador de Ansible en $project_dir. Siguiendo las mejores prácticas de Ansible, añade al final del archivo de inventario por defecto '/etc/ansible/hosts' un nuevo grupo llamado 'dbservers' con dos hosts, 'db1' y 'db2'."
    hint="Edita '/etc/ansible/hosts' para añadir al final del archivo una nueva sección '[dbservers]' con 'db1' y 'db2'."
    instructions="[
      {
        \"instruction\": \"Navega al directorio del proyecto en el controlador:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Añade al final del archivo '/etc/ansible/hosts' el grupo 'dbservers' con 'db1' y 'db2' (requiere sudo):\",
        \"command\": \"echo -e '\\n[dbservers]\\ndb1\\ndb2' | sudo tee -a /etc/ansible/hosts\"
      }
    ]"
    ;;
  "it")
    question="Sei connesso a un nodo controller Ansible in $project_dir. Seguendo le migliori pratiche di Ansible, aggiungi alla fine del file di inventario predefinito '/etc/ansible/hosts' un nuovo gruppo chiamato 'dbservers' con due host, 'db1' e 'db2'."
    hint="Modifica '/etc/ansible/hosts' per aggiungere alla fine del file una nuova sezione '[dbservers]' con 'db1' e 'db2'."
    instructions="[
      {
        \"instruction\": \"Naviga nella directory del progetto sul controller:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aggiungi alla fine del file '/etc/ansible/hosts' il gruppo 'dbservers' con 'db1' e 'db2' (richiede sudo):\",
        \"command\": \"echo -e '\\n[dbservers]\\ndb1\\ndb2' | sudo tee -a /etc/ansible/hosts\"
      }
    ]"
    ;;
  *)
    question="You are connected to an Ansible controller node in $project_dir. Following Ansible best practices, append a new group named 'dbservers' with two hosts, 'db1' and 'db2', to the default inventory file '/etc/ansible/hosts'. "
    hint="Edit '/etc/ansible/hosts' to append a new section '[dbservers]' with 'db1' and 'db2' at the end of the file."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory on the controller:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Append the 'dbservers' group with 'db1' and 'db2' to '/etc/ansible/hosts' (requires sudo):\",
        \"command\": \"echo -e '\\n[dbservers]\\ndb1\\ndb2' | sudo tee -a /etc/ansible/hosts\"
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