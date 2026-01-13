# WireGuard Auto-Up

Ce projet fournit un script Bash intelligent pour vérifier et lancer automatiquement un tunnel WireGuard si nécessaire, intégré à un service systemd et une tâche cron.

## Fonctionnalités

- Vérification automatique de l'état du tunnel VPN.
- Lancement seulement si le tunnel n'est pas actif.
- Lock atomique avec `flock` pour éviter les exécutions simultanées.
- Attente intelligente de la disponibilité DNS avant de lancer le tunnel.
- Logging détaillé des actions et erreurs.
- Service systemd pour démarrage automatique au boot (après attente du réseau complet).
- Tâche cron pour vérifications périodiques (toutes les 15 minutes) comme filet de sécurité.

## Problème résolu

### Problème initial
Le tunnel WireGuard ne démarrait pas automatiquement au boot du serveur (Proxmox Backup Server dans mon cas), bien que le lancement manuel fonctionnait correctement.

### Causes identifiées
1. Le paquet `resolvconf` n'était pas installé
2. Le DNS n'était pas disponible assez tôt au démarrage pour résoudre le hostname distant
3. Le service systemd ET le cron `@reboot` se lançaient simultanément, créant des conflits (erreurs "File exists")
4. Le lockfile simple n'était pas assez rapide pour empêcher les exécutions simultanées

### Solutions appliquées
1. **Installation de openresolv** : `apt install -y openresolv`
2. **Modification du service systemd** pour attendre le réseau complet :
   - Utilisation de `network-online.target` au lieu de `network.target`
   - Ajout de `Wants=network-online.target`
3. **Amélioration du script** avec :
   - Lock atomique avec `flock` au lieu d'un simple fichier
   - Vérification active du DNS (attend jusqu'à 60 secondes que le DNS soit disponible)
   - Logging détaillé de toutes les étapes
4. **Suppression de la ligne `@reboot`** dans le crontab (le service systemd s'en charge au boot)

### Résultat
Le tunnel WireGuard démarre maintenant correctement au boot (après 5-10 secondes d'attente DNS) et est surveillé toutes les 15 minutes pour assurer sa continuité.

## Prérequis

- WireGuard installé (`apt install wireguard`)
- openresolv installé (`apt install openresolv`)
- Accès root pour l'installation

## Installation

1. Clonez ce repo ou copiez les fichiers dans un dossier.
2. Modifiez `tunnel.conf` avec votre configuration WireGuard réelle.
3. Exécutez le script d'installation : `./install.sh`
   - Cela copiera les fichiers aux bons endroits, activera le service et la tâche cron.

## Configuration

- **wg-check-and-up.sh** : Script principal copié vers `/usr/local/bin/`. Modifiez `INTERFACE` et `DNS_CHECK_HOST` si nécessaire.
- **wg-tunnel.service** : Fichier de service systemd qui démarre au boot après attente du réseau.
- **tunnel.conf** : Exemple de configuration WireGuard. Remplacez par votre vraie config avant installation.
- **install.sh** : Script d'installation automatique.

## Utilisation

Après installation :
- Le service démarre automatiquement au boot (après attente du réseau et du DNS).
- La tâche cron vérifie toutes les 15 minutes que le tunnel est actif.
- Logs détaillés dans `/var/log/wg-check.log`.

Commandes utiles :
```bash
# Tester manuellement
sudo systemctl start wg-tunnel

# Vérifier le statut
sudo systemctl status wg-tunnel

# Voir les logs
sudo tail -f /var/log/wg-check.log

# Vérifier l'interface WireGuard
sudo wg show
ip link show pbs2rosieres
```

## Personnalisation

- **Interface** : Changez `INTERFACE="pbs2rosieres"` dans le script.
- **Host DNS à vérifier** : Modifiez `DNS_CHECK_HOST` dans le script.
- **Fréquence cron** : Par défaut toutes les 15 minutes (`*/15 * * * *`). Modifiez dans `install.sh` ou manuellement avec `crontab -e`.
- **Délai d'attente DNS** : Ajustez la boucle dans le script (par défaut 12 tentatives × 5 secondes = 60 secondes).

## Dépannage

### Le tunnel ne démarre pas au boot
1. Vérifiez que `openresolv` est installé : `dpkg -l | grep openresolv`
2. Consultez les logs : `tail -f /var/log/wg-check.log`
3. Vérifiez le statut du service : `systemctl status wg-tunnel`
4. Testez la résolution DNS : `host si-10.cen-champagne-ardenne.org`

### Erreurs "File exists"
Ces erreurs ne devraient plus apparaître grâce au lock `flock`. Si elles persistent, vérifiez qu'il n'y a plus de ligne `@reboot` dans le crontab.

### Le DNS n'est jamais prêt
Augmentez le délai d'attente dans le script ou vérifiez votre configuration réseau.

## Licence

MIT ou ce que vous voulez. Réutilisez librement !
