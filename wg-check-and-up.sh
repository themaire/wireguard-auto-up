#!/bin/bash

INTERFACE="pbs2rosieres"
LOGFILE="/var/log/wg-check.log"

# Fonction pour logger
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGFILE"
}

# Vérifier si l'interface WireGuard est déjà active
if ip link show "$INTERFACE" &> /dev/null; then
    log "Le tunnel VPN $INTERFACE est déjà actif."
else
    log "Le tunnel VPN $INTERFACE n'est pas actif. Tentative de lancement..."
    wg-quick up "$INTERFACE" 2>> "$LOGFILE"
    if [ $? -eq 0 ]; then
        log "Tunnel VPN $INTERFACE lancé avec succès."
    else
        log "ERREUR: Impossible de lancer le tunnel VPN $INTERFACE. Vérifiez la configuration ou la connectivité réseau."
        exit 1
    fi
fi
