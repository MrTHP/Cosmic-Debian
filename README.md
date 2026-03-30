
# COSMIC Desktop Manager pour Debian

Ce script permet d'installer, mettre à jour ou désinstaller le gestionnaire de bureau **COSMIC** sur Debian en utilisant des paquets RPM convertis via `alien`.

## Description

COSMIC est un environnement de bureau moderne développé par System76 pour Pop!_OS. Ce script facilite son installation sur Debian en récupérant les paquets RPM depuis un dépôt COPR, en les convertissant en `.deb`, et en les installant automatiquement.

## Prérequis

- Un système Debian (testé sur Debian 12 et ultérieur).
- Les outils suivants doivent être installés :
  - `wget`
  - `alien`
  - `dpkg`
  - `sudo`

## Installation des Prérequis

Si les outils nécessaires ne sont pas installés, exécutez :
```bash
sudo apt update && sudo apt install -y wget alien dpkg
```

## Utilisation

### 1. Télécharger le script
```bash
wget https://raw.githubusercontent.com/MrTHP/Cosmic-Debian/refs/heads/main/cosmic-debian.sh 
chmod +x cosmic-debian.sh
```

### 2. Exécuter le script

#### Installer COSMIC
```bash
./cosmic-debian.sh install
```

#### Mettre à jour COSMIC
```bash
./cosmic-debian.sh update
```

#### Désinstaller COSMIC
```bash
./cosmic-debian.sh uninstall
```

## Options Disponibles

| Option      | Description                                                                 |
|-------------|-----------------------------------------------------------------------------|
| `install`   | Télécharge, convertit et installe les paquets COSMIC.                      |
| `update`    | Met à jour les paquets COSMIC déjà installés.                               |
| `uninstall` | Désinstalle les paquets COSMIC et nettoie le cache.                        |

## Avertissements

- Ce script utilise `alien` pour convertir des paquets RPM en `.deb`. Cela peut entraîner des incompatibilités.
- Assurez-vous de sauvegarder vos données avant d'exécuter le script.
- Le script doit être exécuté en tant qu'utilisateur avec des privilèges `sudo`.

## Notes

- Le script crée un dossier `cosmic-cache` dans le répertoire courant pour stocker les paquets téléchargés.
- Les paquets sont téléchargés depuis [COPR](https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/).
- En cas d'erreur, vérifiez les messages en couleur pour diagnostiquer le problème.

## Contributions

Les contributions sont les bienvenues ! Ouvrez une issue ou soumettez une pull request sur le dépôt GitHub.

## Licence

Ce script est distribué sous la licence MIT. Voir le fichier `LICENSE` pour plus de détails.
