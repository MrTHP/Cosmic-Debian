#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║       COSMIC Desktop Manager for Debian (via COPR/alien)    ║
# ║       Modes: install | update | uninstall | status          ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# ─── Couleurs / Colors ───────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Détection de la langue / Language detection ─────────────────
# Priorité : LANGUAGE > LANG > LC_ALL > LC_MESSAGES, fallback EN
detect_lang() {
    local lang_var="${LANGUAGE:-${LANG:-${LC_ALL:-${LC_MESSAGES:-}}}}"
    # Extraire les deux premiers caractères (ex: "fr_CA.UTF-8" → "fr")
    local lang_code="${lang_var:0:2}"
    if [[ "${lang_code,,}" == "fr" ]]; then
        echo "fr"
    else
        echo "en"
    fi
}

LANG_CODE=$(detect_lang)

# ─── Système de traduction / Translation system ──────────────────
t() {
    local key="$1"
    if [[ "$LANG_CODE" == "fr" ]]; then
        case "$key" in
            # Usage
            usage_header)       echo "Usage:" ;;
            usage_install)      echo "Installe COSMIC Desktop (première installation)" ;;
            usage_update)       echo "Met à jour COSMIC vers les versions les plus récentes" ;;
            usage_uninstall)    echo "Désinstalle complètement COSMIC et restaure le système" ;;
            usage_status)       echo "Affiche les packages installés et leurs versions" ;;
            usage_noarg)        echo "Sans argument, affiche ce menu interactif." ;;

            # Menu interactif
            menu_title)         echo "COSMIC Desktop Manager pour Debian" ;;
            menu_installed)     echo "● COSMIC installé" ;;
            menu_not_installed) echo "○ COSMIC non installé" ;;
            menu_status_label)  echo "Statut" ;;
            menu_1)             echo "Installer" ;;
            menu_2)             echo "Mettre à jour" ;;
            menu_3)             echo "Désinstaller" ;;
            menu_4)             echo "Voir le statut" ;;
            menu_5)             echo "Quitter" ;;
            menu_choice)        echo "Choix [1-5]:" ;;
            menu_invalid)       echo "Choix invalide." ;;

            # Dépendances
            deps_missing)       echo "Installation des dépendances manquantes:" ;;

            # Architecture
            arch_unsupported)   echo "Architecture non supportée." ;;
            arch_ok)            echo "Architecture:" ;;

            # Fetch packages
            fetch_meta)         echo "Récupération des métadonnées du dépôt COPR..." ;;
            fetch_meta_ok)      echo "Métadonnées:" ;;
            fetch_no_contact)   echo "Impossible de contacter le dépôt COPR." ;;
            fetch_no_primary)   echo "Impossible de trouver primary.xml.gz dans le dépôt." ;;
            fetch_dl_fail)      echo "Échec du téléchargement/décompression de primary.xml." ;;
            fetch_pkgs_found)   echo "packages uniques trouvés." ;;

            # Install package
            pkg_cached)         echo "Cache:" ;;
            pkg_downloading)    echo "Téléchargement..." ;;
            pkg_dl_failed)      echo "Échec téléchargement:" ;;
            pkg_converting)     echo "Installation via alien..." ;;
            pkg_install_failed) echo "Échec installation" ;;

            # do_install
            install_header)     echo "=== Installation de COSMIC Desktop ===" ;;
            install_already)    echo "COSMIC semble déjà installé (manifeste trouvé)." ;;
            install_hint)       echo "Utilisez 'update' pour mettre à jour, ou 'uninstall' d'abord." ;;
            install_done_box1)  echo "╔════════════════════════════════════════╗" ;;
            install_done_box2)  echo "║       Installation terminée !          ║" ;;
            install_done_box3)  echo "╚════════════════════════════════════════╝" ;;
            install_total)      echo "Total traités  :" ;;
            install_success)    echo "Succès         :" ;;
            install_failed)     echo "Échecs         :" ;;
            install_relogin)    echo "→ Déconnectez-vous et sélectionnez 'COSMIC' dans votre gestionnaire de session." ;;

            # reconstruct_manifest
            recon_no_manifest)  echo "Aucun manifeste trouvé — détection des packages COSMIC via dpkg..." ;;
            recon_none_found)   echo "Aucun package COSMIC détecté par dpkg non plus. COSMIC n'est pas installé." ;;
            recon_done)         echo "packages COSMIC détectés." ;;  # preceded by count
            recon_ts_note)      echo "(Timestamps mis à 0 → toutes les versions seront mises à jour)" ;;
            recon_rebuilt)      echo "Manifeste reconstruit :" ;;

            # do_update
            update_header)      echo "=== Mise à jour de COSMIC Desktop ===" ;;
            update_already)     echo "✓ Déjà à jour" ;;
            update_available)   echo "↑ Mise à jour disponible →" ;;
            update_new)         echo "+ Nouveau package →" ;;
            update_summary)     echo "─── Résumé de la mise à jour ───" ;;
            update_checked)     echo "Packages vérifiés :" ;;
            update_updated)     echo "Mis à jour / installés :" ;;
            update_skipped)     echo "Déjà à jour :" ;;
            update_failures)    echo "Échecs :" ;;
            update_restart)     echo "→ Redémarrez ou reconnectez-vous pour appliquer les changements." ;;
            update_uptodate)    echo "→ COSMIC est déjà à jour. Aucune action nécessaire." ;;

            # do_uninstall
            uninstall_header)   echo "=== Désinstallation de COSMIC Desktop ===" ;;
            uninstall_list)     echo "Packages à désinstaller:" ;;
            uninstall_warn1)    echo "⚠  Cette opération supprimera tous les packages COSMIC installés." ;;
            uninstall_warn2)    echo "   Votre système retournera à son état pré-COSMIC." ;;
            uninstall_confirm)  echo "Confirmer la désinstallation ? [oui/non] :" ;;
            uninstall_yes)      echo "oui" ;;
            uninstall_cancelled) echo "Désinstallation annulée." ;;
            uninstall_removing) echo "Désinstallation en cours..." ;;
            uninstall_pkg)      echo "✗ Suppression:" ;;
            uninstall_notfound) echo "(non trouvé dans dpkg, ignoré)" ;;
            uninstall_autoremove) echo "Nettoyage des dépendances orphelines..." ;;
            uninstall_summary)  echo "─── Résumé de la désinstallation ───" ;;
            uninstall_removed)  echo "Packages supprimés :" ;;
            uninstall_ignored)  echo "Non trouvés (ignorés) :" ;;
            uninstall_done)     echo "✓ COSMIC Desktop désinstallé. Votre système est restauré." ;;
            uninstall_reboot)   echo "→ Redémarrez pour s'assurer que la session COSMIC est retirée du gestionnaire." ;;
            uninstall_del_cache) echo "Supprimer le cache des fichiers RPM" ;;
            uninstall_cache_yes) echo "oui" ;;
            uninstall_cache_del) echo "Cache supprimé." ;;
            uninstall_cache_kept) echo "Cache conservé dans:" ;;

            # do_status
            status_header)      echo "=== Statut de COSMIC Desktop ===" ;;
            status_no_manifest) echo "Aucun manifeste trouvé — COSMIC n'est pas installé via ce script." ;;
            status_dpkg_list)   echo "Packages COSMIC détectés par dpkg:" ;;
            status_none)        echo "(aucun)" ;;
            status_manifest)    echo "Manifeste :" ;;
            status_count)       echo "Packages installés :" ;;
            status_col_pkg)     echo "Package" ;;
            status_col_ver)     echo "Version" ;;
            status_col_date)    echo "Date install" ;;
            status_hint)        echo "Conseil : lancez '$0 update' pour vérifier si des mises à jour sont disponibles." ;;

            # Erreurs génériques
            err_unknown_cmd)    echo "Commande inconnue:" ;;
        esac
    else
        # English
        case "$key" in
            # Usage
            usage_header)       echo "Usage:" ;;
            usage_install)      echo "Install COSMIC Desktop (first-time installation)" ;;
            usage_update)       echo "Update COSMIC to the latest versions" ;;
            usage_uninstall)    echo "Completely remove COSMIC and restore the system" ;;
            usage_status)       echo "Show installed packages and their versions" ;;
            usage_noarg)        echo "Without argument, shows this interactive menu." ;;

            # Interactive menu
            menu_title)         echo "COSMIC Desktop Manager for Debian" ;;
            menu_installed)     echo "● COSMIC installed" ;;
            menu_not_installed) echo "○ COSMIC not installed" ;;
            menu_status_label)  echo "Status" ;;
            menu_1)             echo "Install" ;;
            menu_2)             echo "Update" ;;
            menu_3)             echo "Uninstall" ;;
            menu_4)             echo "View status" ;;
            menu_5)             echo "Quit" ;;
            menu_choice)        echo "Choice [1-5]:" ;;
            menu_invalid)       echo "Invalid choice." ;;

            # Dependencies
            deps_missing)       echo "Installing missing dependencies:" ;;

            # Architecture
            arch_unsupported)   echo "Unsupported architecture." ;;
            arch_ok)            echo "Architecture:" ;;

            # Fetch packages
            fetch_meta)         echo "Fetching COPR repository metadata..." ;;
            fetch_meta_ok)      echo "Metadata:" ;;
            fetch_no_contact)   echo "Unable to reach the COPR repository." ;;
            fetch_no_primary)   echo "Could not find primary.xml.gz in the repository." ;;
            fetch_dl_fail)      echo "Failed to download/decompress primary.xml." ;;
            fetch_pkgs_found)   echo "unique packages found." ;;

            # Install package
            pkg_cached)         echo "Cached:" ;;
            pkg_downloading)    echo "Downloading..." ;;
            pkg_dl_failed)      echo "Download failed:" ;;
            pkg_converting)     echo "Converting and installing via alien..." ;;
            pkg_install_failed) echo "Installation failed" ;;

            # do_install
            install_header)     echo "=== Installing COSMIC Desktop ===" ;;
            install_already)    echo "COSMIC appears already installed (manifest found)." ;;
            install_hint)       echo "Use 'update' to upgrade, or 'uninstall' first." ;;
            install_done_box1)  echo "╔════════════════════════════════════════╗" ;;
            install_done_box2)  echo "║       Installation complete!           ║" ;;
            install_done_box3)  echo "╚════════════════════════════════════════╝" ;;
            install_total)      echo "Total processed :" ;;
            install_success)    echo "Success         :" ;;
            install_failed)     echo "Failures        :" ;;
            install_relogin)    echo "→ Log out and select 'COSMIC' in your session manager." ;;

            # reconstruct_manifest
            recon_no_manifest)  echo "No manifest found — detecting COSMIC packages via dpkg..." ;;
            recon_none_found)   echo "No COSMIC packages detected by dpkg either. COSMIC is not installed." ;;
            recon_done)         echo "COSMIC packages detected." ;;
            recon_ts_note)      echo "(Timestamps set to 0 → all versions will be updated)" ;;
            recon_rebuilt)      echo "Manifest rebuilt:" ;;

            # do_update
            update_header)      echo "=== Updating COSMIC Desktop ===" ;;
            update_already)     echo "✓ Already up to date" ;;
            update_available)   echo "↑ Update available →" ;;
            update_new)         echo "+ New package →" ;;
            update_summary)     echo "─── Update summary ───" ;;
            update_checked)     echo "Packages checked    :" ;;
            update_updated)     echo "Updated / installed :" ;;
            update_skipped)     echo "Already up to date  :" ;;
            update_failures)    echo "Failures            :" ;;
            update_restart)     echo "→ Restart or log out/in to apply the changes." ;;
            update_uptodate)    echo "→ COSMIC is already up to date. Nothing to do." ;;

            # do_uninstall
            uninstall_header)   echo "=== Uninstalling COSMIC Desktop ===" ;;
            uninstall_list)     echo "Packages to remove:" ;;
            uninstall_warn1)    echo "⚠  This will remove all installed COSMIC packages." ;;
            uninstall_warn2)    echo "   Your system will be restored to its pre-COSMIC state." ;;
            uninstall_confirm)  echo "Confirm uninstall? [yes/no] :" ;;
            uninstall_yes)      echo "yes" ;;
            uninstall_cancelled) echo "Uninstall cancelled." ;;
            uninstall_removing) echo "Removing packages..." ;;
            uninstall_pkg)      echo "✗ Removing:" ;;
            uninstall_notfound) echo "(not found in dpkg, skipped)" ;;
            uninstall_autoremove) echo "Cleaning up orphaned dependencies..." ;;
            uninstall_summary)  echo "─── Uninstall summary ───" ;;
            uninstall_removed)  echo "Packages removed   :" ;;
            uninstall_ignored)  echo "Not found (skipped):" ;;
            uninstall_done)     echo "✓ COSMIC Desktop removed. Your system is restored." ;;
            uninstall_reboot)   echo "→ Reboot to ensure the COSMIC session is removed from the login manager." ;;
            uninstall_del_cache) echo "Delete the RPM cache files" ;;
            uninstall_cache_yes) echo "yes" ;;
            uninstall_cache_del) echo "Cache deleted." ;;
            uninstall_cache_kept) echo "Cache kept in:" ;;

            # do_status
            status_header)      echo "=== COSMIC Desktop Status ===" ;;
            status_no_manifest) echo "No manifest found — COSMIC was not installed via this script." ;;
            status_dpkg_list)   echo "COSMIC packages detected by dpkg:" ;;
            status_none)        echo "(none)" ;;
            status_manifest)    echo "Manifest :" ;;
            status_count)       echo "Installed packages :" ;;
            status_col_pkg)     echo "Package" ;;
            status_col_ver)     echo "Version" ;;
            status_col_date)    echo "Install date" ;;
            status_hint)        echo "Tip: run '$0 update' to check for available updates." ;;

            # Generic errors
            err_unknown_cmd)    echo "Unknown command:" ;;
        esac
    fi
}

# ─── Chemins & constantes ────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$SCRIPT_DIR/cosmic-cache"
MANIFEST="$CACHE_DIR/installed-packages.manifest"
BASE_URL="https://download.copr.fedorainfracloud.org/results/ryanabx/cosmic-epoch/fedora-43-x86_64"
REPODATA_URL="$BASE_URL/repodata"

# ─── Aide ────────────────────────────────────────────────────────
usage() {
    echo -e "${BOLD}$(t usage_header)${NC}  $0 [COMMAND]"
    echo ""
    echo -e "  ${GREEN}install${NC}    $(t usage_install)"
    echo -e "  ${YELLOW}update${NC}     $(t usage_update)"
    echo -e "  ${RED}uninstall${NC}  $(t usage_uninstall)"
    echo -e "  ${CYAN}status${NC}     $(t usage_status)"
    echo ""
    echo -e "  $(t usage_noarg)"
    exit 0
}

# ─── Menu interactif ─────────────────────────────────────────────
interactive_menu() {
    local title
    title=$(t menu_title)
    local title_len=${#title}
    local box_width=44
    local pad=$(( (box_width - title_len - 2) / 2 ))
    local pad_str
    pad_str=$(printf '%*s' "$pad" '')

    echo -e "\n${BOLD}${CYAN}╔$(printf '═%.0s' $(seq 1 $((box_width - 2))))╗${NC}"
    echo -e "${BOLD}${CYAN}║${pad_str} ${title} ${pad_str}║${NC}"
    echo -e "${BOLD}${CYAN}╚$(printf '═%.0s' $(seq 1 $((box_width - 2))))╝${NC}\n"

    COSMIC_INSTALLED=false
    [[ -f "$MANIFEST" ]] && COSMIC_INSTALLED=true

    if $COSMIC_INSTALLED; then
        PKG_COUNT=$(wc -l < "$MANIFEST" 2>/dev/null || echo 0)
        echo -e "  $(t menu_status_label) : ${GREEN}$(t menu_installed)${NC} ($PKG_COUNT packages)\n"
    else
        echo -e "  $(t menu_status_label) : ${RED}$(t menu_not_installed)${NC}\n"
    fi

    echo -e "  ${BOLD}1)${NC} ${GREEN}$(t menu_1)${NC} COSMIC Desktop"
    echo -e "  ${BOLD}2)${NC} ${YELLOW}$(t menu_2)${NC} COSMIC Desktop"
    echo -e "  ${BOLD}3)${NC} ${RED}$(t menu_3)${NC} COSMIC Desktop"
    echo -e "  ${BOLD}4)${NC} ${CYAN}$(t menu_4)${NC}"
    echo -e "  ${BOLD}5)${NC} $(t menu_5)"
    echo ""
    read -rp "  $(t menu_choice) " CHOICE

    case "$CHOICE" in
        1) do_install ;;
        2) do_update ;;
        3) do_uninstall ;;
        4) do_status ;;
        5) exit 0 ;;
        *) echo -e "${RED}$(t menu_invalid)${NC}"; exit 1 ;;
    esac
}

# ─── Vérifications communes ──────────────────────────────────────
check_deps() {
    local missing=()
    for cmd in curl alien gunzip date; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}$(t deps_missing) ${missing[*]}${NC}"
        sudo apt update -qq
        sudo apt install -y alien curl gzip 2>/dev/null
    fi
}

check_arch() {
    local arch
    arch=$(uname -m)
    if [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]]; then
        echo -e "${RED}$(t arch_unsupported) '$arch'${NC}"
        exit 1
    fi
    echo -e "${GREEN}$(t arch_ok) $arch${NC}"
}

# ─── Récupération des packages depuis COPR ───────────────────────
fetch_latest_packages() {
    echo -e "\n${YELLOW}$(t fetch_meta)${NC}"

    local directory_html primary_xml_gz primary_xml_gz_url
    directory_html=$(curl -sf "$REPODATA_URL/" || { echo -e "${RED}$(t fetch_no_contact)${NC}"; exit 1; })

    primary_xml_gz=$(echo "$directory_html" | grep -oP "(?<=<a href=')[0-9a-f]*-primary\.xml\.gz(?=')" | head -n1)

    if [[ -z "$primary_xml_gz" ]]; then
        echo -e "${RED}$(t fetch_no_primary)${NC}"
        exit 1
    fi

    primary_xml_gz_url="$REPODATA_URL/$primary_xml_gz"
    echo -e "${GREEN}$(t fetch_meta_ok) $primary_xml_gz${NC}"
    curl -sf "$primary_xml_gz_url" | gunzip > "$CACHE_DIR/primary.xml"

    if [[ ! -s "$CACHE_DIR/primary.xml" ]]; then
        echo -e "${RED}$(t fetch_dl_fail)${NC}"
        exit 1
    fi
}

parse_packages() {
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

    declare -gA PKG_URL PKG_TIME PKG_VERSION

    while IFS='|' read -r pkgname epoch version buildtime url; do
        if [[ -z "${PKG_TIME[$pkgname]:-}" ]] || [[ "$buildtime" -gt "${PKG_TIME[$pkgname]}" ]]; then
            PKG_URL["$pkgname"]="$url"
            PKG_TIME["$pkgname"]="$buildtime"
            PKG_VERSION["$pkgname"]="$version"
        fi
    done < <(sort -t'|' -k1,1 -k4,4rn "$temp_list")

    rm -f "$temp_list"
    echo -e "${GREEN}${#PKG_URL[@]} $(t fetch_pkgs_found)${NC}\n"
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
        echo -e "  ${CYAN}↺${NC} $(t pkg_cached) $filename"
    else
        echo -e "  ${YELLOW}↓${NC} $(t pkg_downloading)"
        if ! curl -Lsf -o "$CACHE_DIR/$filename" "$full_url"; then
            echo -e "  ${RED}✗${NC} $(t pkg_dl_failed) $filename"
            return 1
        fi
    fi

    echo -e "  ${YELLOW}⚙${NC} $(t pkg_converting)"
    if sudo alien -d -i "$CACHE_DIR/$filename" 2>&1 | grep -qi "error"; then
        echo -e "  ${RED}✗${NC} $(t pkg_install_failed)"
        return 1
    fi

    grep -v "^$pkgname|" "$MANIFEST" > "$MANIFEST.tmp" 2>/dev/null || true
    mv "$MANIFEST.tmp" "$MANIFEST" 2>/dev/null || true
    echo "$pkgname|$version|$timestamp|$filename" >> "$MANIFEST"

    echo -e "  ${GREEN}✓${NC} $pkgname v$version ($date_display)"
    return 0
}

# ─── INSTALL ─────────────────────────────────────────────────────
do_install() {
    echo -e "\n${BOLD}${GREEN}$(t install_header)${NC}\n"

    if [[ -f "$MANIFEST" ]]; then
        echo -e "${YELLOW}$(t install_already)${NC}"
        echo -e "$(t install_hint)"
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
    echo -e "${YELLOW}$(t install_relogin)${NC}\n"
}

# ─── Reconstruction du manifeste depuis dpkg ─────────────────────
reconstruct_manifest() {
    echo -e "${YELLOW}$(t recon_no_manifest)${NC}"

    local dpkg_cosmic
    dpkg_cosmic=$(dpkg -l | awk '/^ii/ && /cosmic/ {print $2}' || true)

    if [[ -z "$dpkg_cosmic" ]]; then
        echo -e "${RED}$(t recon_none_found)${NC}"
        exit 1
    fi

    mkdir -p "$CACHE_DIR"
    echo "$dpkg_cosmic" | while read -r pkg; do
        local ver
        ver=$(dpkg -l "$pkg" 2>/dev/null | awk '/^ii/ {print $3}' | head -n1 || echo "unknown")
        echo "$pkg|$ver|0|unknown"
    done > "$MANIFEST"

    local count
    count=$(wc -l < "$MANIFEST")
    echo -e "${GREEN}$(t recon_rebuilt) $count $(t recon_done)${NC}"
    echo -e "${CYAN}$(t recon_ts_note)${NC}\n"
}

# ─── UPDATE ──────────────────────────────────────────────────────
do_update() {
    echo -e "\n${BOLD}${YELLOW}$(t update_header)${NC}\n"

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

        local installed_time=""
        installed_time=$(grep "^$pkgname|" "$MANIFEST" 2>/dev/null | cut -d'|' -f3 || true)

        echo -e "${YELLOW}[$counter/$total]${NC} ${BOLD}$pkgname${NC}"

        if [[ -n "$installed_time" ]] && [[ "$new_time" -le "$installed_time" ]]; then
            echo -e "  ${GREEN}$(t update_already) (v$new_version)${NC}"
            skipped=$((skipped + 1))
            continue
        fi

        if [[ -n "$installed_time" ]]; then
            echo -e "  ${CYAN}$(t update_available) v$new_version${NC}"
        else
            echo -e "  ${CYAN}$(t update_new) v$new_version${NC}"
        fi

        if install_package "$pkgname"; then
            updated=$((updated + 1))
        else
            failed=$((failed + 1))
        fi
        echo ""
    done

    rm -f "$CACHE_DIR/primary.xml"

    echo -e "\n${BOLD}$(t update_summary)${NC}"
    echo -e "  $(t update_checked) $total"
    echo -e "  ${GREEN}$(t update_updated) $updated${NC}"
    echo -e "  $(t update_skipped) $skipped"
    [[ $failed -gt 0 ]] && echo -e "  ${RED}$(t update_failures) $failed${NC}"
    echo ""

    if [[ $updated -gt 0 ]]; then
        echo -e "${YELLOW}$(t update_restart)${NC}\n"
    else
        echo -e "${GREEN}$(t update_uptodate)${NC}\n"
    fi
}

# ─── UNINSTALL ───────────────────────────────────────────────────
do_uninstall() {
    echo -e "\n${BOLD}${RED}$(t uninstall_header)${NC}\n"

    if [[ ! -f "$MANIFEST" ]]; then
        reconstruct_manifest
    fi

    INSTALLED=$(cut -d'|' -f1 "$MANIFEST" | sort -u)
    echo -e "$(t uninstall_list)"
    echo "$INSTALLED" | while read -r pkg; do echo -e "  - $pkg"; done
    echo ""

    echo -e "${RED}$(t uninstall_warn1)${NC}"
    echo -e "${RED}$(t uninstall_warn2)${NC}"
    echo ""

    local confirm_word
    confirm_word=$(t uninstall_yes)
    read -rp "$(t uninstall_confirm) " CONFIRM

    if [[ "$CONFIRM" != "$confirm_word" ]]; then
        echo -e "${YELLOW}$(t uninstall_cancelled)${NC}"
        exit 0
    fi

    local removed=0 not_found=0

    echo -e "\n${YELLOW}$(t uninstall_removing)${NC}\n"

    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        echo -e "  ${RED}$(t uninstall_pkg)${NC} $pkg"
        if sudo apt remove -y "$pkg" 2>/dev/null; then
            removed=$((removed + 1))
        else
            DEB_NAME=$(dpkg -l | awk "/^ii/ && /$pkg/ {print \$2}" | head -n1 || true)
            if [[ -n "$DEB_NAME" ]]; then
                sudo apt remove -y "$DEB_NAME" 2>/dev/null && removed=$((removed + 1)) || not_found=$((not_found + 1))
            else
                echo -e "    ${YELLOW}($(t uninstall_notfound))${NC}"
                not_found=$((not_found + 1))
            fi
        fi
    done <<< "$INSTALLED"

    echo -e "\n${YELLOW}$(t uninstall_autoremove)${NC}"
    sudo apt autoremove -y 2>/dev/null || true

    rm -f "$MANIFEST"
    echo ""
    echo -e "${BOLD}$(t uninstall_summary)${NC}"
    echo -e "  ${GREEN}$(t uninstall_removed) $removed${NC}"
    [[ $not_found -gt 0 ]] && echo -e "  ${YELLOW}$(t uninstall_ignored) $not_found${NC}"
    echo ""
    echo -e "${GREEN}$(t uninstall_done)${NC}"
    echo -e "${YELLOW}$(t uninstall_reboot)${NC}\n"

    if [[ -d "$CACHE_DIR" ]]; then
        local cache_size
        cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
        local cache_confirm_word
        cache_confirm_word=$(t uninstall_cache_yes)
        read -rp "$(t uninstall_del_cache) ($cache_size) ? [$cache_confirm_word/no] : " DEL_CACHE
        if [[ "$DEL_CACHE" == "$cache_confirm_word" ]]; then
            rm -rf "$CACHE_DIR"
            echo -e "${GREEN}$(t uninstall_cache_del)${NC}"
        else
            echo -e "${YELLOW}$(t uninstall_cache_kept) $CACHE_DIR${NC}"
        fi
    fi
}

# ─── STATUS ──────────────────────────────────────────────────────
do_status() {
    echo -e "\n${BOLD}${CYAN}$(t status_header)${NC}\n"

    if [[ ! -f "$MANIFEST" ]]; then
        echo -e "${RED}$(t status_no_manifest)${NC}"
        echo ""
        echo -e "$(t status_dpkg_list)"
        dpkg -l | awk '/^ii/ && /cosmic/ {printf "  %-40s %s\n", $2, $3}' || echo "  $(t status_none)"
        exit 0
    fi

    local total
    total=$(wc -l < "$MANIFEST")
    echo -e "  $(t status_manifest) $MANIFEST"
    echo -e "  $(t status_count) ${GREEN}$total${NC}"
    echo ""
    echo -e "  ${BOLD}$(printf '%-35s %-15s %s' "$(t status_col_pkg)" "$(t status_col_ver)" "$(t status_col_date)")${NC}"
    echo -e "  $(printf '%.0s─' {1..60})"

    while IFS='|' read -r pkgname version timestamp filename; do
        local date_str
        date_str=$(date -d "@$timestamp" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
        printf "  %-35s %-15s %s\n" "$pkgname" "$version" "$date_str"
    done < "$MANIFEST"

    echo ""
    echo -e "${YELLOW}$(t status_hint)${NC}\n"
}

# ─── Résumé générique / Generic summary ──────────────────────────
print_summary() {
    local total="$1" success="$2" failed="$3"
    echo -e "\n${GREEN}$(t install_done_box1)${NC}"
    echo -e "${GREEN}$(t install_done_box2)${NC}"
    echo -e "${GREEN}$(t install_done_box3)${NC}"
    echo -e "  $(t install_total) $total"
    echo -e "  ${GREEN}$(t install_success) $success${NC}"
    [[ $failed -gt 0 ]] && echo -e "  ${RED}$(t install_failed) $failed${NC}"
    echo ""
}

# ─── Point d'entrée / Entry point ────────────────────────────────
case "${1:-}" in
    install)   do_install   ;;
    update)    do_update    ;;
    uninstall) do_uninstall ;;
    status)    do_status    ;;
    -h|--help) usage        ;;
    "")        interactive_menu ;;
    *)
        echo -e "${RED}$(t err_unknown_cmd) $1${NC}"
        usage
        ;;
esac
