#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║       COSMIC Desktop Manager pour Debian (via COPR/alien)   ║
# ║       Modes: install | update | uninstall                    ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# ─── Couleurs ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Chemins & constantes ────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$SCRIPT_DIR/cosmic-cache"
MANIFEST="$CACHE_DIR/installed-packages.manifest"
BASE_URL="https://download.copr.fedorainfracloud.org/results/ryanabx/cosmic-epoch/fedora-43-x86_64"
REPODATA_URL="$BASE_URL/repodata"

# ─── Aide ────────────────────────────────────────────────────────
usage() {
    echo -e "${BOLD}Usage:${NC}  $0 [COMMANDE]"
    echo ""
    echo -e "  ${GREEN}install${NC}    Installe COSMIC Desktop (première installation)"
    echo -e "  ${YELLOW}update${NC}     Met à jour COSMIC vers les versions les plus récentes"
    echo -e "  ${RED}uninstall${NC}  Désinstalle complètement COSMIC et restaure le système"
    echo -e "  ${CYAN}status${NC}     Affiche les packages installés et leurs versions"
    echo ""
    echo -e "  Sans argument, affiche ce menu interactif."
    exit 0
}

# ─── Menu interactif ─────────────────────────────────────────────
interactive_menu() {
    echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║   COSMIC Desktop Manager pour Debian     ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}\n"

    COSMIC_INSTALLED=false
    [[ -f "$MANIFEST" ]] && COSMIC_INSTALLED=true

    if $COSMIC_INSTALLED; then
        PKG_COUNT=$(wc -l < "$MANIFEST" 2>/dev/null || echo 0)
        echo -e "  Statut : ${GREEN}● COSMIC installé${NC} ($PKG_COUNT packages)\n"
    else
        echo -e "  Statut : ${RED}○ COSMIC non installé${NC}\n"
    fi

    echo -e "  ${BOLD}1)${NC} ${GREEN}Installer${NC} COSMIC Desktop"
    echo -e "  ${BOLD}2)${NC} ${YELLOW}Mettre à jour${NC} COSMIC Desktop"
    echo -e "  ${BOLD}3)${NC} ${RED}Désinstaller${NC} COSMIC Desktop"
    echo -e "  ${BOLD}4)${NC} ${CYAN}Voir le statut${NC} de l'installation"
    echo -e "  ${BOLD}5)${NC} Quitter"
    echo ""
    read -rp "  Choix [1-5]: " CHOICE

    case "$CHOICE" in
        1) do_install ;;
        2) do_update ;;
        3) do_uninstall ;;
        4) do_status ;;
        5) exit 0 ;;
        *) echo -e "${RED}Choix invalide.${NC}"; exit 1 ;;
    esac
}

# ─── Vérifications communes ──────────────────────────────────────
check_deps() {
    local missing=()
    for cmd in curl alien gunzip date; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Installation des dépendances manquantes: ${missing[*]}${NC}"
        sudo apt update -qq
        sudo apt install -y alien curl gzip 2>/dev/null
    fi
}

check_arch() {
    local arch
    arch=$(uname -m)
    if [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]]; then
        echo -e "${RED}Architecture '$arch' non supportée.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Architecture: $arch${NC}"
}

# ─── Récupération des packages depuis COPR ───────────────────────
fetch_latest_packages() {
    echo -e "\n${YELLOW}Récupération des métadonnées du dépôt COPR...${NC}"

    local directory_html primary_xml_gz primary_xml_gz_url
    directory_html=$(curl -sf "$REPODATA_URL/" || { echo -e "${RED}Impossible de contacter le dépôt COPR.${NC}"; exit 1; })

    primary_xml_gz=$(echo "$directory_html" | grep -oP "(?<=<a href=')[0-9a-f]*-primary\.xml\.gz(?=')" | head -n1)

    if [[ -z "$primary_xml_gz" ]]; then
        echo -e "${RED}Impossible de trouver primary.xml.gz dans le dépôt.${NC}"
        exit 1
    fi

    primary_xml_gz_url="$REPODATA_URL/$primary_xml_gz"
    echo -e "${GREEN}Métadonnées: $primary_xml_gz${NC}"
    curl -sf "$primary_xml_gz_url" | gunzip > "$CACHE_DIR/primary.xml"

    if [[ ! -s "$CACHE_DIR/primary.xml" ]]; then
        echo -e "${RED}Échec du téléchargement/décompression de primary.xml.${NC}"
        exit 1
    fi
}

parse_packages() {
    # Retourne: nom|version|timestamp|url (triés, un par nom, le plus récent)
    local temp_list
    temp_list=$(mktemp)

    local current_name="" current_version="" current_epoch="" current_time="" current_url=""

    while IFS= read -r line; do
        if [[ $line =~ \<name\>([^\<]+)\</name\> ]]; then
            current_name="${BASH_REMATCH[1]}"
        elif [[ $line =~ \<version[[:space:]]epoch=\"([^\"]*)\".*ver=\"([^\"]*)\" ]]; then
            current_epoch="${BASH_REMATCH[1]}"
            current_version="${BASH_REMATCH[2]}"
        elif [[ $line =~ \<time[[:space:]]file=\"([0-9]+)\" ]]; then
            current_time="${BASH_REMATCH[1]}"
        elif [[ $line =~ \<location[[:space:]]href=\"([^\"]+)\" ]]; then
            current_url="${BASH_REMATCH[1]}"
            if [[ -n "$current_name" && -n "$current_time" && -n "$current_url" ]]; then
                if [[ ! "$current_name" =~ debug ]] && [[ ! "$current_url" =~ src\.rpm$ ]]; then
                    echo "$current_name|${current_epoch}|${current_version}|${current_time}|${current_url}" >> "$temp_list"
                fi
            fi
            current_name="" current_version="" current_epoch="" current_time="" current_url=""
        fi
    done < "$CACHE_DIR/primary.xml"

    # Garder la version la plus récente par package
    declare -gA PKG_URL PKG_TIME PKG_VERSION

    while IFS='|' read -r pkgname epoch version buildtime url; do
        if [[ -z "${PKG_TIME[$pkgname]:-}" ]] || [[ "$buildtime" -gt "${PKG_TIME[$pkgname]}" ]]; then
            PKG_URL["$pkgname"]="$url"
            PKG_TIME["$pkgname"]="$buildtime"
            PKG_VERSION["$pkgname"]="$version"
        fi
    done < <(sort -t'|' -k1,1 -k4,4rn "$temp_list")

    rm -f "$temp_list"
    echo -e "${GREEN}${#PKG_URL[@]} packages uniques trouvés.${NC}\n"
}

# ─── Téléchargement + installation d'un package ──────────────────
install_package() {
    local pkgname="$1"
    local url="${PKG_URL[$pkgname]}"
    local version="${PKG_VERSION[$pkgname]}"
    local timestamp="${PKG_TIME[$pkgname]}"
    local filename
    filename=$(basename "$url")
    local full_url="$BASE_URL/$url"
    local date_display
    date_display=$(date -d "@$timestamp" "+%Y-%m-%d" 2>/dev/null || echo "unknown")

    if [[ -f "$CACHE_DIR/$filename" ]]; then
        echo -e "  ${CYAN}↺${NC} Cache: $filename"
    else
        echo -e "  ${YELLOW}↓${NC} Téléchargement..."
        if ! curl -Lsf -o "$CACHE_DIR/$filename" "$full_url"; then
            echo -e "  ${RED}✗${NC} Échec téléchargement: $filename"
            return 1
        fi
    fi

    echo -e "  ${YELLOW}⚙${NC} Installation via alien..."
    if sudo alien -d -i "$CACHE_DIR/$filename" 2>&1 | grep -qi "error"; then
        echo -e "  ${RED}✗${NC} Échec installation"
        return 1
    fi

    # Enregistrer dans le manifeste: nom|version|timestamp|filename
    # Supprimer entrée précédente si existe (pour update)
    grep -v "^$pkgname|" "$MANIFEST" > "$MANIFEST.tmp" 2>/dev/null || true
    mv "$MANIFEST.tmp" "$MANIFEST" 2>/dev/null || true
    echo "$pkgname|$version|$timestamp|$filename" >> "$MANIFEST"

    echo -e "  ${GREEN}✓${NC} $pkgname v$version ($date_display)"
    return 0
}

# ─── INSTALL ─────────────────────────────────────────────────────
do_install() {
    echo -e "\n${BOLD}${GREEN}=== Installation de COSMIC Desktop ===${NC}\n"

    if [[ -f "$MANIFEST" ]]; then
        echo -e "${YELLOW}COSMIC semble déjà installé (manifeste trouvé).${NC}"
        echo -e "Utilisez ${BOLD}update${NC} pour mettre à jour, ou ${BOLD}uninstall${NC} d'abord."
        exit 0
    fi

    check_deps
    check_arch
    mkdir -p "$CACHE_DIR"
    touch "$MANIFEST"

    fetch_latest_packages
    parse_packages

    local counter=0 success=0 failed=0 total=${#PKG_URL[@]}

    for pkgname in $(echo "${!PKG_URL[@]}" | tr ' ' '\n' | sort); do
        counter=$((counter + 1))
        echo -e "${YELLOW}[$counter/$total]${NC} ${BOLD}$pkgname${NC} v${PKG_VERSION[$pkgname]}"
        if install_package "$pkgname"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
        fi
        echo ""
    done

    rm -f "$CACHE_DIR/primary.xml"
    print_summary "$total" "$success" "$failed"
    echo -e "${YELLOW}→ Déconnectez-vous et sélectionnez 'COSMIC' dans votre gestionnaire de session.${NC}\n"
}

# ─── Reconstruction du manifeste depuis dpkg ─────────────────────
reconstruct_manifest() {
    echo -e "${YELLOW}Aucun manifeste trouvé — détection des packages COSMIC via dpkg...${NC}"

    local dpkg_cosmic
    dpkg_cosmic=$(dpkg -l | awk '/^ii/ && /cosmic/ {print $2}' || true)

    if [[ -z "$dpkg_cosmic" ]]; then
        echo -e "${RED}Aucun package COSMIC détecté par dpkg non plus. COSMIC n'est pas installé.${NC}"
        exit 1
    fi

    mkdir -p "$CACHE_DIR"
    # Générer un manifeste minimal: nom|version_inconnue|0|inconnu
    # timestamp=0 force la réinstallation/update de tout
    echo "$dpkg_cosmic" | while read -r pkg; do
        local ver
        ver=$(dpkg -l "$pkg" 2>/dev/null | awk '/^ii/ {print $3}' | head -n1 || echo "unknown")
        echo "$pkg|$ver|0|unknown"
    done > "$MANIFEST"

    local count
    count=$(wc -l < "$MANIFEST")
    echo -e "${GREEN}Manifeste reconstruit : $count packages COSMIC détectés.${NC}"
    echo -e "${CYAN}(Timestamps mis à 0 → toutes les versions seront mises à jour)${NC}\n"
}

# ─── UPDATE ──────────────────────────────────────────────────────
do_update() {
    echo -e "\n${BOLD}${YELLOW}=== Mise à jour de COSMIC Desktop ===${NC}\n"

    if [[ ! -f "$MANIFEST" ]]; then
        reconstruct_manifest
    fi

    check_deps
    mkdir -p "$CACHE_DIR"

    fetch_latest_packages
    parse_packages

    local counter=0 updated=0 skipped=0 failed=0 total=${#PKG_URL[@]}

    for pkgname in $(echo "${!PKG_URL[@]}" | tr ' ' '\n' | sort); do
        counter=$((counter + 1))
        local new_time="${PKG_TIME[$pkgname]}"
        local new_version="${PKG_VERSION[$pkgname]}"

        # Chercher le timestamp déjà installé dans le manifeste
        local installed_time=""
        installed_time=$(grep "^$pkgname|" "$MANIFEST" 2>/dev/null | cut -d'|' -f3 || true)

        echo -e "${YELLOW}[$counter/$total]${NC} ${BOLD}$pkgname${NC}"

        if [[ -n "$installed_time" ]] && [[ "$new_time" -le "$installed_time" ]]; then
            echo -e "  ${GREEN}✓${NC} Déjà à jour (v$new_version)"
            skipped=$((skipped + 1))
            continue
        fi

        if [[ -n "$installed_time" ]]; then
            echo -e "  ${CYAN}↑${NC} Mise à jour disponible → v$new_version"
        else
            echo -e "  ${CYAN}+${NC} Nouveau package → v$new_version"
        fi

        if install_package "$pkgname"; then
            updated=$((updated + 1))
        else
            failed=$((failed + 1))
        fi
        echo ""
    done

    rm -f "$CACHE_DIR/primary.xml"

    echo -e "\n${BOLD}─── Résumé de la mise à jour ───${NC}"
    echo -e "  Packages vérifiés : $total"
    echo -e "  ${GREEN}Mis à jour / installés : $updated${NC}"
    echo -e "  Déjà à jour : $skipped"
    [[ $failed -gt 0 ]] && echo -e "  ${RED}Échecs : $failed${NC}"
    echo ""

    if [[ $updated -gt 0 ]]; then
        echo -e "${YELLOW}→ Redémarrez ou reconnectez-vous pour appliquer les changements.${NC}\n"
    else
        echo -e "${GREEN}→ COSMIC est déjà à jour. Aucune action nécessaire.${NC}\n"
    fi
}

# ─── UNINSTALL ───────────────────────────────────────────────────
do_uninstall() {
    echo -e "\n${BOLD}${RED}=== Désinstallation de COSMIC Desktop ===${NC}\n"

    if [[ ! -f "$MANIFEST" ]]; then
        reconstruct_manifest
    fi

    INSTALLED=$(cut -d'|' -f1 "$MANIFEST" | sort -u)
    echo -e "Packages à désinstaller:"
    echo "$INSTALLED" | while read -r pkg; do echo -e "  - $pkg"; done
    echo ""

    echo -e "${RED}⚠  Cette opération supprimera tous les packages COSMIC installés.${NC}"
    echo -e "${RED}   Votre système retournera à son état pré-COSMIC.${NC}"
    echo ""
    read -rp "Confirmer la désinstallation ? [oui/non] : " CONFIRM

    if [[ "$CONFIRM" != "oui" ]]; then
        echo -e "${YELLOW}Désinstallation annulée.${NC}"
        exit 0
    fi

    local removed=0 not_found=0

    echo -e "\n${YELLOW}Désinstallation en cours...${NC}\n"

    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        echo -e "  ${RED}✗${NC} Suppression: $pkg"
        if sudo apt remove -y "$pkg" 2>/dev/null; then
            removed=$((removed + 1))
        else
            # alien peut renommer les packages, essayer avec dpkg
            DEB_NAME=$(dpkg -l | awk "/^ii/ && /$pkg/ {print \$2}" | head -n1 || true)
            if [[ -n "$DEB_NAME" ]]; then
                sudo apt remove -y "$DEB_NAME" 2>/dev/null && removed=$((removed + 1)) || not_found=$((not_found + 1))
            else
                echo -e "    ${YELLOW}(non trouvé dans dpkg, ignoré)${NC}"
                not_found=$((not_found + 1))
            fi
        fi
    done <<< "$INSTALLED"

    # Nettoyage autoremove
    echo -e "\n${YELLOW}Nettoyage des dépendances orphelines...${NC}"
    sudo apt autoremove -y 2>/dev/null || true

    # Supprimer le manifeste et le cache
    rm -f "$MANIFEST"
    echo ""
    echo -e "${BOLD}─── Résumé de la désinstallation ───${NC}"
    echo -e "  ${GREEN}Packages supprimés : $removed${NC}"
    [[ $not_found -gt 0 ]] && echo -e "  ${YELLOW}Non trouvés (ignorés) : $not_found${NC}"
    echo ""
    echo -e "${GREEN}✓ COSMIC Desktop désinstallé. Votre système est restauré.${NC}"
    echo -e "${YELLOW}→ Redémarrez pour s'assurer que la session COSMIC est retirée du gestionnaire.${NC}\n"

    # Supprimer le cache RPM si l'utilisateur le souhaite
    if [[ -d "$CACHE_DIR" ]]; then
        read -rp "Supprimer le cache des fichiers RPM ($(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)) ? [oui/non] : " DEL_CACHE
        if [[ "$DEL_CACHE" == "oui" ]]; then
            rm -rf "$CACHE_DIR"
            echo -e "${GREEN}Cache supprimé.${NC}"
        else
            echo -e "${YELLOW}Cache conservé dans: $CACHE_DIR${NC}"
        fi
    fi
}

# ─── STATUS ──────────────────────────────────────────────────────
do_status() {
    echo -e "\n${BOLD}${CYAN}=== Statut de COSMIC Desktop ===${NC}\n"

    if [[ ! -f "$MANIFEST" ]]; then
        echo -e "${RED}Aucun manifeste trouvé — COSMIC n'est pas installé via ce script.${NC}"
        echo ""
        echo -e "Packages COSMIC détectés par dpkg:"
        dpkg -l | awk '/^ii/ && /cosmic/ {printf "  %-40s %s\n", $2, $3}' || echo "  (aucun)"
        exit 0
    fi

    local total
    total=$(wc -l < "$MANIFEST")
    echo -e "  Manifeste : $MANIFEST"
    echo -e "  Packages installés : ${GREEN}$total${NC}"
    echo ""
    echo -e "  ${BOLD}$(printf '%-35s %-15s %s' 'Package' 'Version' 'Date install')${NC}"
    echo -e "  $(printf '%.0s─' {1..60})"

    while IFS='|' read -r pkgname version timestamp filename; do
        local date_str
        date_str=$(date -d "@$timestamp" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
        printf "  %-35s %-15s %s\n" "$pkgname" "$version" "$date_str"
    done < "$MANIFEST"

    echo ""

    # Vérifier rapidement si une mise à jour est disponible (sans télécharger XML)
    echo -e "${YELLOW}Conseil : lancez '$0 update' pour vérifier si des mises à jour sont disponibles.${NC}\n"
}

# ─── Résumé générique ────────────────────────────────────────────
print_summary() {
    local total="$1" success="$2" failed="$3"
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       Installation terminée !          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo -e "  Total traités  : $total"
    echo -e "  ${GREEN}Succès         : $success${NC}"
    [[ $failed -gt 0 ]] && echo -e "  ${RED}Échecs         : $failed${NC}"
    echo ""
}

# ─── Point d'entrée ──────────────────────────────────────────────
case "${1:-}" in
    install)   do_install   ;;
    update)    do_update    ;;
    uninstall) do_uninstall ;;
    status)    do_status    ;;
    -h|--help) usage        ;;
    "")        interactive_menu ;;
    *)
        echo -e "${RED}Commande inconnue: $1${NC}"
        usage
        ;;
esac
