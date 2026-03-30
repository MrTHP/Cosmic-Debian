# COSMIC Desktop Manager pour Debian

Ce script permet d'installer, mettre à jour ou désinstaller le gestionnaire de bureau **COSMIC** sur Debian en utilisant des paquets RPM convertis via `alien`.

---

## Description

COSMIC est un environnement de bureau moderne développé par System76 pour Pop!_OS. Ce script facilite son installation sur Debian en récupérant les paquets RPM depuis un dépôt COPR, en les convertissant en `.deb`, et en les installant automatiquement.

**Note :** Le script détecte automatiquement la langue de votre système et affiche les messages en français ou en anglais en conséquence.

---

# COSMIC Desktop Manager for Debian

This script allows you to install, update, or uninstall the **COSMIC** desktop environment on Debian using RPM packages converted via `alien`.

---

## Description

COSMIC is a modern desktop environment developed by System76 for Pop!_OS. This script makes it easy to install on Debian by fetching RPM packages from a COPR repository, converting them to `.deb`, and installing them automatically.

**Note:** The script automatically detects your system language and displays messages in French or English accordingly.

---

## Prerequisites

- A Debian system (tested on Debian 12 and later).
- The following tools must be installed:
  - `wget`
  - `alien`
  - `dpkg`
  - `sudo`

---

## Installation des Prérequis / Installing Prerequisites

Si les outils nécessaires ne sont pas installés / If the required tools are not installed:

```bash
sudo apt update && sudo apt install -y wget alien dpkg
```

---

## Utilisation / Usage

### 1. Télécharger le script / Download the Script

```bash
wget https://raw.githubusercontent.com/MrTHP/Cosmic-Debian/refs/heads/main/cosmic-debian.sh
chmod +x cosmic-debian.sh
```

---

### 2. Exécuter le script / Run the Script

#### Installer COSMIC / Install COSMIC

```bash
./cosmic-debian.sh install
```

#### Mettre à jour COSMIC / Update COSMIC

```bash
./cosmic-debian.sh update
```

#### Désinstaller COSMIC / Uninstall COSMIC

```bash
./cosmic-debian.sh uninstall
```

---

## Options Disponibles / Available Options


| Option      | Description                                                                                                |
| ----------- | ---------------------------------------------------------------------------------------------------------- |
| `install`   | Télécharge, convertit et installe les paquets COSMIC. / Downloads, converts, and installs COSMIC packages. |
| `update`    | Met à jour les paquets COSMIC déjà installés. / Updates already installed COSMIC packages.                 |
| `uninstall` | Désinstalle les paquets COSMIC et nettoie le cache. / Uninstalls COSMIC packages and cleans the cache.     |


---

## Avertissements / Warnings

- Ce script utilise `alien` pour convertir des paquets RPM en `.deb`. Cela peut entraîner des incompatibilités. / This script uses `alien` to convert RPM packages to `.deb`, which may cause incompatibilities.
- Assurez-vous de sauvegarder vos données avant d'exécuter le script. / Make sure to back up your data before running the script.
- Le script doit être exécuté en tant qu'utilisateur avec des privilèges `sudo`. / The script must be run as a user with `sudo` privileges.

---

## Notes / Notes

- Le script crée un dossier `cosmic-cache` dans le répertoire courant pour stocker les paquets téléchargés. / The script creates a `cosmic-cache` folder in the current directory to store downloaded packages.
- Les paquets sont téléchargés depuis [COPR](https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/). / Packages are downloaded from [COPR](https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/).
- En cas d'erreur, vérifiez les messages en couleur pour diagnostiquer le problème. / In case of errors, check the color-coded messages to diagnose the issue.

---

## Contributions

Les contributions sont les bienvenues ! Ouvrez une issue ou soumettez une pull request sur le dépôt GitHub. / Contributions are welcome! Open an issue or submit a pull request on the GitHub repository.

---

## Licence / License

Ce script est distribué sous la licence MIT. Voir le fichier `LICENSE` pour plus de détails. / This script is distributed under the MIT license. See the `LICENSE` file for more details.
