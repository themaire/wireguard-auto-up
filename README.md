# WireGuard Auto-Up

Ce projet fournit un script Bash intelligent pour vérifier et lancer automatiquement un tunnel WireGuard si nécessaire, intégré à un service systemd et une tâche cron.

## Fonctionnalités

- Vérification automatique de l'état du tunnel VPN.
- Lancement seulement si le tunnel n'est pas actif.
- Logging détaillé des actions et erreurs.
- Service systemd pour démarrage automatique au boot.
- Tâche cron pour vérifications périodiques (toutes les 15 minutes par défaut).

## Installation

1. Clonez ce repo ou copiez les fichiers dans un dossier.
2. Modifiez `tunnel.conf` avec votre configuration WireGuard réelle.
3. Exécutez le script d'installation : `./install.sh`
   - Cela copiera les fichiers aux bons endroits, activera le service et la tâche cron.

## Configuration

- **wg-check-and-up.sh** : Script principal. Modifiez `INTERFACE` et `LOGFILE` si nécessaire.
- **wg-tunnel.service** : Fichier de service systemd.
- **tunnel.conf** : Exemple de configuration WireGuard. Remplacez par votre vraie config.
- **install.sh** : Script d'installation automatique.

## Utilisation

Après installation :
- Le service démarre automatiquement au boot.
- La tâche cron vérifie toutes les 15 minutes.
- Logs dans `/var/log/wg-check.log`.

Pour tester manuellement : `sudo systemctl start wg-tunnel`

## Personnalisation

- Changez l'interface dans le script (par défaut : pbs2rosieres).
- Modifiez la fréquence cron dans `install.sh` ou manuellement avec `crontab -e`.

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.
