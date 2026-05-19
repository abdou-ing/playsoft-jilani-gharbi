#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

sudo apt remove ansible ansible-core -y >/dev/null 2>&1
sudo rm $(which ansible) >/dev/null 2>&1

project_dir="/home/ansible_user/ansible_install_project"

# Create the project directory
if [[ ! -d "$project_dir" ]]; then
  mkdir "$project_dir"
  #echo "Directory $project_dir created."
fi

cd "$project_dir"

# Create a README file explaining the task
cat <<EOF > README.md
# Ansible Installation Project

This directory is set up to practice Ansible automation. However, Ansible is not yet installed on this system.
EOF

case "$lang" in
  "en")
    question="There is a directory in $project_dir prepared for Ansible automation, but Ansible is not installed on the system. Following best practices, install Ansible using the system's package manager (apt on Ubuntu) to enable automation tasks."
    hint="Use 'apt' to install Ansible on Ubuntu. Ensure you update the package list first and use sudo for elevated privileges."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update the package list:\",
        \"command\": \"sudo apt update\"
      },
      {
        \"instruction\": \"Install Ansible:\",
        \"command\": \"sudo apt install -y ansible\"
      }
    ]"
    ;;
  "fr")
    question="Il existe un répertoire dans $project_dir préparé pour l'automatisation Ansible, mais Ansible n'est pas installé sur le système. En suivant les bonnes pratiques, installez Ansible en utilisant le gestionnaire de paquets du système (apt sur Ubuntu) pour permettre les tâches d'automatisation."
    hint="Utilisez 'apt' pour installer Ansible sur Ubuntu. Assurez-vous de mettre à jour la liste des paquets d'abord et utilisez sudo pour des privilèges élevés."
    instructions="[
      {
        \"instruction\": \"Naviguez vers le répertoire du projet:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Mettez à jour la liste des paquets:\",
        \"command\": \"sudo apt update\"
      },
      {
        \"instruction\": \"Installez Ansible:\",
        \"command\": \"sudo apt install -y ansible\"
      }
    ]"
    ;;
  "de")
    question="Es gibt ein Verzeichnis in $project_dir, das für Ansible-Automatisierung vorbereitet ist, aber Ansible ist nicht auf dem System installiert. Installieren Sie Ansible gemäß Best Practices mit dem Paketmanager des Systems (apt auf Ubuntu), um Automatisierungsaufgaben zu ermöglichen."
    hint="Verwenden Sie 'apt', um Ansible auf Ubuntu zu installieren. Stellen Sie sicher, dass Sie zuerst die Paketliste aktualisieren und sudo für erhöhte Berechtigungen verwenden."
    instructions="[
      {
        \"instruction\": \"Wechseln Sie zum Projektverzeichnis:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aktualisieren Sie die Paketliste:\",
        \"command\": \"sudo apt update\"
      },
      {
        \"instruction\": \"Installieren Sie Ansible:\",
        \"command\": \"sudo apt install -y ansible\"
      }
    ]"
    ;;
  "es")
    question="Existe un directorio en $project_dir preparado para la automatización con Ansible, pero Ansible no está instalado en el sistema. Siguiendo las mejores prácticas, instala Ansible usando el gestor de paquetes del sistema (apt en Ubuntu) para habilitar las tareas de automatización."
    hint="Usa 'apt' para instalar Ansible en Ubuntu. Asegúrate de actualizar la lista de paquetes primero y usa sudo para privilegios elevados."
    instructions="[
      {
        \"instruction\": \"Navega al directorio del proyecto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Actualiza la lista de paquetes:\",
        \"command\": \"sudo apt update\"
      },
      {
        \"instruction\": \"Instala Ansible:\",
        \"command\": \"sudo apt install -y ansible\"
      }
    ]"
    ;;
  "it")
    question="Esiste una directory in $project_dir preparata per l'automazione con Ansible, ma Ansible non è installato sul sistema. Seguendo le migliori pratiche, installa Ansible usando il gestore dei pacchetti del sistema (apt su Ubuntu) per abilitare le attività di automazione."
    hint="Usa 'apt' per installare Ansible su Ubuntu. Assicurati di aggiornare prima l'elenco dei pacchetti e usa sudo per privilegi elevati."
    instructions="[
      {
        \"instruction\": \"Naviga nella directory del progetto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aggiorna l'elenco dei pacchetti:\",
        \"command\": \"sudo apt update\"
      },
      {
        \"instruction\": \"Installa Ansible:\",
        \"command\": \"sudo apt install -y ansible\"
      }
    ]"
    ;;
  *)
    question="There is a directory in $project_dir prepared for Ansible automation, but Ansible is not installed on the system. Following best practices, install Ansible using the system's package manager (apt on Ubuntu) to enable automation tasks."
    hint="Use 'apt' to install Ansible on Ubuntu. Ensure you update the package list first and use sudo for elevated privileges."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update the package list:\",
        \"command\": \"sudo apt update\"
      },
      {
        \"instruction\": \"Install Ansible:\",
        \"command\": \"sudo apt install -y ansible\"
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