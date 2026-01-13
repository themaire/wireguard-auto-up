# Troubleshooting WireGuard Auto-Up

## Problème résolu : Le tunnel ne se lance pas au boot

### Symptômes
- Le tunnel WireGuard ne démarre pas automatiquement au boot du serveur
- Exécution manuelle du script fonctionne correctement
- Logs montrent des erreurs "Temporary failure in name resolution"
- Messages d'erreur "RTNETLINK answers: File exists" indiquant des exécutions simultanées

### Causes identifiées

1. **Résolution DNS non disponible au démarrage**
   - Le service WireGuard tentait de résoudre `si-10.cen-champagne-ardenne.org:51820` avant que le DNS ne soit opérationnel
   - Le service démarrait trop tôt dans la séquence de boot

2. **Exécutions simultanées multiples**
   - Le service systemd ET la tâche cron se lançaient au même moment
   - Le lockfile basique avec `touch` n'était pas assez rapide pour éviter les conflits

3. **Paquet manquant**
   - `resolvconf` n'était pas installé, causant des erreurs lors de la configuration DNS

### Solutions appliquées

#### 1. Installation de resolvconf
```bash
apt install -y openresolv
```

#### 2. Modification du service systemd
Fichier : `/etc/systemd/system/wg-pbs2rosieres.service`

```ini
[Unit]
Description=Vérifier et lancer le tunnel WireGuard pbs2rosieres si nécessaire
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/wg-check-and-up.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Changement clé : `After=network-online.target` au lieu de `network.target` pour attendre que le réseau soit vraiment disponible.

#### 3. Amélioration du script avec vérification DNS et flock

Script final : `/usr/local/bin/wg-check-and-up.sh`

```bash
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
```

**Améliorations clés :**
- **Lock atomique avec `flock`** : Empêche vraiment les exécutions simultanées
- **Vérification DNS active** : Attend jusqu'à 60 secondes que le DNS soit disponible
- **Logging détaillé** : Permet de diagnostiquer les problèmes

#### 4. Configuration cron maintenue
```cron
*/15 * * * * /usr/local/bin/wg-check-and-up.sh
```

La tâche cron vérifie toutes les 15 minutes si le tunnel est actif et le relance si nécessaire.

### Résultat

✅ Le tunnel WireGuard démarre automatiquement au boot après ~5-10 secondes d'attente DNS  
✅ Pas d'exécutions simultanées grâce à flock  
✅ Vérifications périodiques toutes les 15 minutes via cron  
✅ Logging complet dans `/var/log/wg-check.log`

### Commandes de vérification

```bash
# Vérifier l'état du tunnel
wg show

# Vérifier les logs
tail -30 /var/log/wg-check.log

# Vérifier le service systemd
systemctl status wg-pbs2rosieres.service

# Tester manuellement le script
/usr/local/bin/wg-check-and-up.sh
```

### Notes importantes

- L'interface doit être nommée `pbs2rosieres` (ou modifier `INTERFACE` dans le script)
- Le fichier de configuration doit être `/etc/wireguard/pbs2rosieres.conf`
- Le endpoint DNS `si-10.cen-champagne-ardenne.org` doit être résolvable
- Pour un autre tunnel, adapter `DNS_CHECK_HOST` dans le script

---

**Date de résolution :** 13 janvier 2026  
**Serveur :** Proxmox Backup Server (Debian Trixie)
