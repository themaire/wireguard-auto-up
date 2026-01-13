#!/bin/bash

INTERFACE="pbs2rosieres"
LOGFILE="/var/log/wg-check.log"
LOCKFILE="/var/lock/wg-check.lock"
DNS_CHECK_HOST="si-10.cen-champagne-ardenne.org"

# Fonction pour logger
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGFILE"
}

# Utiliser flock pour un lock atomique
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    log "Une autre instance du script est déjà en cours d'exécution (flock)."
    exit 0
fi

# Attendre que le DNS soit disponible (max 60 secondes)
DNS_READY=0
for i in {1..12}; do
    if host "$DNS_CHECK_HOST" &>/dev/null; then
        DNS_READY=1
        log "DNS disponible, résolution de $DNS_CHECK_HOST OK"
        break
    fi
    log "DNS pas encore disponible, attente... (tentative $i/12)"
    sleep 5
done

if [ $DNS_READY -eq 0 ]; then
    log "ERREUR: DNS toujours indisponible après 60 secondes. Abandon."
    exit 1
fi

# Vérifier si l'interface WireGuard est déjà active
if ip link show "$INTERFACE" &> /dev/null; then
    log "Le tunnel VPN $INTERFACE est déjà actif."
else
    log "Le tunnel VPN $INTERFACE n'est pas actif. Tentative de lancement..."
    wg-quick up "$INTERFACE" 2>> "$LOGFILE"
    if [ $? -eq 0 ]; then
        log "Tunnel VPN $INTERFACE lancé avec succès."
    else
        log "ERREUR: Impossible de lancer le tunnel VPN $INTERFACE."
        exit 1
    fi
fi