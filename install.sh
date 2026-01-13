#!/bin/bash

# Script d'installation pour WireGuard Auto-Up

echo "Installation de WireGuard Auto-Up..."

# Copier le script
cp wg-check-and-up.sh /usr/local/bin/
chmod +x /usr/local/bin/wg-check-and-up.sh
echo "Script copié vers /usr/local/bin/"

# Copier la configuration exemple (modifiez-la avant !)
cp tunnel.conf /etc/wireguard/
echo "Configuration exemple copiée vers /etc/wireguard/tunnel.conf"

# Copier le service systemd
cp wg-tunnel.service /etc/systemd/system/
echo "Service systemd copié"

# Recharger systemd
systemctl daemon-reload
echo "Systemd rechargé"

# Activer le service
systemctl enable wg-tunnel.service
echo "Service activé pour démarrage automatique"

# Ajouter la tâche cron (toutes les 15 minutes uniquement, pas @reboot car géré par systemd)
(crontab -l 2>/dev/null | grep -v "wg-check-and-up.sh" ; echo "*/15 * * * * /usr/local/bin/wg-check-and-up.sh") | crontab -
echo "Tâche cron ajoutée (vérification toutes les 15 minutes)"

# Créer le fichier de log
touch /var/log/wg-check.log
chmod 600 /var/log/wg-check.log
echo "Fichier de log créé"

echo "Installation terminée ! Modifiez /etc/wireguard/tunnel.conf avec votre vraie config, puis redémarrez ou lancez manuellement."
