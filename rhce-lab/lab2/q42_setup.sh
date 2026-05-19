#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

project_dir="/home/ansible_user/ansible_idempotency_project"

# Create the project directory
if [[ ! -d "$project_dir" ]]; then
  mkdir "$project_dir"
  #echo "Directory $project_dir created."
fi

cd "$project_dir"

# Create a basic playbook with a non-idempotent task
cat <<EOF > playbook.yml
---
- name: Configure system
  hosts: localhost
  tasks:
    - name: Create directory with mkdir
      ansible.builtin.command: mkdir /tmp/myapp
EOF

case "$lang" in
  "en")
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file that uses the 'ansible.builtin.command' module to create a directory '/tmp/myapp' with 'mkdir'. This task is not idempotent and will fail if the directory already exists. Following Ansible best practices, refactor the playbook to use the 'ansible.builtin.file' module to create the directory '/tmp/myapp' idempotently, ensuring it only changes the system if the directory doesn’t exist."
    hint="Replace the 'command' module with the 'file' module, setting 'state: directory' to create '/tmp/myapp' only if it’s not already present. Idempotency means the task should succeed without errors and only apply changes when needed."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to use the 'ansible.builtin.file' module idempotently:\",
        \"command\": \"echo -e '---\\n- name: Configure system\\n  hosts: localhost\\n  tasks:\\n    - name: Ensure /tmp/myapp directory exists\\n      ansible.builtin.file:\\n        path: /tmp/myapp\\n        state: directory' > playbook.yml\"
      }
    ]"
    ;;
  "fr")
    question="Il existe un projet Ansible dans $project_dir avec un fichier 'playbook.yml' qui utilise le module 'ansible.builtin.command' pour créer un répertoire '/tmp/myapp' avec 'mkdir'. Cette tâche n'est pas idempotente et échouera si le répertoire existe déjà. En suivant les bonnes pratiques Ansible, refactorisez le playbook pour utiliser le module 'ansible.builtin.file' afin de créer le répertoire '/tmp/myapp' de manière idempotente, en s'assurant qu'il ne modifie le système que si le répertoire n'existe pas."
    hint="Remplacez le module 'command' par le module 'file', en définissant 'state: directory' pour créer '/tmp/myapp' uniquement s'il n'est pas déjà présent. L'idempotence signifie que la tâche doit réussir sans erreur et n'appliquer des changements que lorsque nécessaire."
    instructions="[
      {
        \"instruction\": \"Naviguez vers le répertoire du projet:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Mettez à jour 'playbook.yml' pour utiliser le module 'ansible.builtin.file' de manière idempotente:\",
        \"command\": \"echo -e '---\\n- name: Configurer le système\\n  hosts: localhost\\n  tasks:\\n    - name: Assurer que le répertoire /tmp/myapp existe\\n      ansible.builtin.file:\\n        path: /tmp/myapp\\n        state: directory' > playbook.yml\"
      }
    ]"
    ;;
  "de")
    question="Es gibt ein Ansible-Projekt in $project_dir mit einer Datei 'playbook.yml', die das Modul 'ansible.builtin.command' verwendet, um ein Verzeichnis '/tmp/myapp' mit 'mkdir' zu erstellen. Diese Aufgabe ist nicht idempotent und schlägt fehl, wenn das Verzeichnis bereits existiert. Refaktorisieren Sie das Playbook gemäß Ansible-Best-Practices, um das Modul 'ansible.builtin.file' zu verwenden, damit das Verzeichnis '/tmp/myapp' idempotent erstellt wird und nur dann Änderungen vornimmt, wenn das Verzeichnis nicht existiert."
    hint="Ersetzen Sie das 'command'-Modul durch das 'file'-Modul und setzen Sie 'state: directory', um '/tmp/myapp' nur zu erstellen, wenn es noch nicht vorhanden ist. Idempotenz bedeutet, dass die Aufgabe ohne Fehler erfolgreich ist und nur bei Bedarf Änderungen anwendet."
    instructions="[
      {
        \"instruction\": \"Wechseln Sie zum Projektverzeichnis:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aktualisieren Sie 'playbook.yml', um das Modul 'ansible.builtin.file' idempotent zu verwenden:\",
        \"command\": \"echo -e '---\\n- name: System konfigurieren\\n  hosts: localhost\\n  tasks:\\n    - name: Sicherstellen, dass das Verzeichnis /tmp/myapp existiert\\n      ansible.builtin.file:\\n        path: /tmp/myapp\\n        state: directory' > playbook.yml\"
      }
    ]"
    ;;
  "es")
    question="Existe un proyecto de Ansible en $project_dir con un archivo 'playbook.yml' que usa el módulo 'ansible.builtin.command' para crear un directorio '/tmp/myapp' con 'mkdir'. Esta tarea no es idempotente y fallará si el directorio ya existe. Siguiendo las mejores prácticas de Ansible, refactorice el playbook para usar el módulo 'ansible.builtin.file' para crear el directorio '/tmp/myapp' de forma idempotente, asegurando que solo cambie el sistema si el directorio no existe."
    hint="Reemplace el módulo 'command' por el módulo 'file', estableciendo 'state: directory' para crear '/tmp/myapp' solo si no está presente. La idempotencia significa que la tarea debe ejecutarse sin errores y aplicar cambios solo cuando sea necesario."
    instructions="[
      {
        \"instruction\": \"Navega al directorio del proyecto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Actualiza 'playbook.yml' para usar el módulo 'ansible.builtin.file' de forma idempotente:\",
        \"command\": \"echo -e '---\\n- name: Configurar el sistema\\n  hosts: localhost\\n  tasks:\\n    - name: Asegurar que el directorio /tmp/myapp exista\\n      ansible.builtin.file:\\n        path: /tmp/myapp\\n        state: directory' > playbook.yml\"
      }
    ]"
    ;;
  "it")
    question="Esiste un progetto Ansible in $project_dir con un file 'playbook.yml' che utilizza il modulo 'ansible.builtin.command' per creare una directory '/tmp/myapp' con 'mkdir'. Questo compito non è idempotente e fallirà se la directory esiste già. Seguendo le migliori pratiche di Ansible, rifattorizza il playbook per utilizzare il modulo 'ansible.builtin.file' per creare la directory '/tmp/myapp' in modo idempotente, assicurando che modifichi il sistema solo se la directory non esiste."
    hint="Sostituisci il modulo 'command' con il modulo 'file', impostando 'state: directory' per creare '/tmp/myapp' solo se non è già presente. L'idempotenza significa che il compito deve riuscire senza errori e applicare modifiche solo quando necessario."
    instructions="[
      {
        \"instruction\": \"Naviga nella directory del progetto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aggiorna 'playbook.yml' per usare il modulo 'ansible.builtin.file' in modo idempotente:\",
        \"command\": \"echo -e '---\\n- name: Configurare il sistema\\n  hosts: localhost\\n  tasks:\\n    - name: Assicurare che la directory /tmp/myapp esista\\n      ansible.builtin.file:\\n        path: /tmp/myapp\\n        state: directory' > playbook.yml\"
      }
    ]"
    ;;
  *)
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file that uses the 'ansible.builtin.command' module to create a directory '/tmp/myapp' with 'mkdir'. This task is not idempotent and will fail if the directory already exists. Following Ansible best practices, refactor the playbook to use the 'ansible.builtin.file' module to create the directory '/tmp/myapp' idempotently, ensuring it only changes the system if the directory doesn’t exist."
    hint="Replace the 'command' module with the 'file' module, setting 'state: directory' to create '/tmp/myapp' only if it’s not already present. Idempotency means the task should succeed without errors and only apply changes when needed."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to use the 'ansible.builtin.file' module idempotently:\",
        \"command\": \"echo -e '---\\n- name: Configure system\\n  hosts: localhost\\n  tasks:\\n    - name: Ensure /tmp/myapp directory exists\\n      ansible.builtin.file:\\n        path: /tmp/myapp\\n        state: directory' > playbook.yml\"
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