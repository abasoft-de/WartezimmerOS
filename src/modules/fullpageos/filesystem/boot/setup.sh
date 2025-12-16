#!/bin/bash
#User Input
read -p "Bitte geben Sie den Token ein: " token
if [ -z "$token" ]; then
  echo "Token darf nicht leer sein!"
  exit 1
fi

read -p "Bitte geben Sie die IP-Adresse ein: " ip_address
if [ -z "$ip_address" ]; then
  echo "IP-Adresse darf nicht leer sein!"
  exit 1
fi

# API Abfragen
full_api_url="http://${ip_address}:8000/extern/wrm/api/waitingroom-monitor/generate-link?token=${token}"
response=$(curl -s "$full_api_url")
response_clean=$(echo "$response" | sed 's/"//g')

if [ -z "$response_clean" ]; then
  echo "Keine Antwort vom Server erhalten. Überprüfen Sie die API-URL oder den Token."
  exit 1
fi

#WZM-Link erstellen
final_link="http://${ip_address}:3000${response_clean}"
echo "Der generierte Link ist: $final_link"

#Config-Datei überschreiben
config_file="/boot/firmware/fullpageos.txt"

if [ ! -f "$config_file" ]; then
  echo "Konfigurationsdatei $config_file wurde nicht gefunden."
  exit 1
fi

echo "$final_link" > "$config_file"

if grep -q "$final_link" "$config_file"; then
  echo "Die Datei wurde erfolgreich mit dem neuen Link überschrieben."
else
  echo "Ein Fehler ist beim Überschreiben der Datei aufgetreten."
  exit 1
fi
