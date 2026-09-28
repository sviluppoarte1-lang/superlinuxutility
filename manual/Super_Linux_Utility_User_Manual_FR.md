# Super Linux Utility v2.0.6
# Manuel Utilisateur Complet — Français

---

## Table des matières

1. [Introduction](#1-introduction)
2. [Configuration requise](#2-configuration-requise)
3. [Installation](#3-installation)
4. [Premier lancement](#4-premier-lancement)
5. [Mode Standard — Toutes les fonctionnalités](#5-mode-standard)
   - 5.1 Services
   - 5.2 Applications au démarrage
   - 5.3 Nettoyage
   - 5.4 Applications installées
   - 5.5 Moniteur système
   - 5.6 Analyseur de disque
   - 5.7 Santé des disques SMART
   - 5.8 Gestionnaire de périphériques
   - 5.9 Récupération
   - 5.10 Optimisations
   - 5.11 Paramètres
   - 5.12 Informations
6. [Mode Avancé — Fonctionnalités supplémentaires](#6-mode-avancé)
   - 6.1 Éditeur GRUB
   - 6.2 Benchmark
7. [Zone de notification système](#7-zone-de-notification-système)
8. [Mises à jour automatiques](#8-mises-a-jour-automatiques)
9. [Dépannage](#9-dépannage)
10. [Foire aux questions](#10-faq)
11. [Glossaire](#11-glossaire)

---

## 1. Introduction

**Super Linux Utility** est une application complète de gestion système pour Linux. Elle fournit une interface graphique moderne pour gérer les services, les applications au démarrage, nettoyer les fichiers temporaires, surveiller les performances du système, analyser les disques, gérer les périphériques matériels, et bien plus encore.

L'application est disponible en deux éditions :

- **Standard (Gratuit) :** Tous les outils essentiels de gestion système — services, applications au démarrage, nettoyage, applications installées, moniteur, analyseur de disque, santé SMART, gestionnaire de périphériques, récupération, optimisations et paramètres.
- **Avancé (Payant) :** Tout ce qui est inclus dans Standard, plus l'éditeur GRUB et la suite Benchmark.

**Distributions prises en charge :** Ubuntu, Debian, Linux Mint, LMDE, Pop!_OS, Zorin, elementary, MX Linux, Fedora, RHEL, CentOS, Arch Linux, Manjaro, EndeavourOS, CachyOS, KDE neon.

**Environnements de bureau pris en charge :** GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt.

---

## 2. Configuration requise

- **Système d'exploitation :** Linux (64 bits)
- **Espace disque :** ~200 Mo installés
- **RAM :** 512 Mo minimum, 2 Go recommandés
- **Dépendances :** GTK3, GLib 2.0+
- **Facultatif :** `libappindicator` pour la zone de notification système, `smartmontools` pour la santé des disques SMART

---

## 3. Installation

### AppImage (Recommandé)
```bash
chmod +x super-linux-utility-2.0.6-x86_64.AppImage
./super-linux-utility-2.0.6-x86_64.AppImage
```

### Debian/Ubuntu (.deb)
```bash
sudo dpkg -i super-linux-utility_2.0.6_amd64.deb
sudo apt-get install -f
```

### À partir des sources
```bash
git clone https://github.com/sviluppoarte1-lang/superlinuxutility.git
cd superlinuxutility
flutter build linux
```

---

## 4. Premier lancement

Lorsque vous ouvrez Super Linux Utility pour la première fois, trois écrans de configuration s'affichent séquentiellement :

### 4.1 Sélection de la langue
Choisissez votre langue préférée parmi : italien, anglais, français, espagnol, allemand, portugais. La langue sélectionnée s'applique à tous les boutons, menus, messages et descriptions de l'application.

### 4.2 Écran d'avertissement
Un avertissement vous rappelle que cette application peut modifier des configurations système critiques (amorçage GRUB, noyau, services). Il est fortement recommandé de créer une sauvegarde du système avant d'utiliser les fonctionnalités avancées. Cochez « Ne plus afficher cet avertissement » pour l'ignorer lors des prochains lancements.

### 4.3 Configuration du mot de passe
Pour utiliser les fonctionnalités qui modifient le système (nettoyage, gestion des services, édition GRUB, etc.), l'application a besoin de votre mot de passe administrateur (sudo). Le mot de passe est stocké de manière sécurisée à l'aide du trousseau de clés du système. Vous pouvez ignorer cette étape et la configurer plus tard dans les Paramètres.

> **Conseil pour les débutants :** Si vous n'êtes pas sûr de devoir entrer votre mot de passe, vous pouvez l'ignorer. La plupart des fonctionnalités en lecture seule (moniteur, analyseur de disque, SMART) fonctionnent sans mot de passe.

---

## 5. Mode Standard — Toutes les fonctionnalités

Le mode standard offre 12 onglets accessibles depuis la barre latérale gauche. Chaque onglet contient des outils spécifiques.

---

### 5.1 Services

**Objectif :** Afficher et gérer les services systemd qui tournent sur votre système.

**Onglets :**
- **Services lents :** Liste les services qui prennent plus de 2 secondes à démarrer (détectés via `systemd-analyze blame`). Cela aide à identifier ce qui ralentit votre démarrage.
- **Tous les services :** Liste complète de tous les services systemd avec leur statut (actif, inactif, échoué). Appuyez sur « Analyser tout » pour charger la liste complète.
- **Désactivés :** Affiche tous les services actuellement désactivés.

**Actions par service (appuyez sur le menu à trois points) :**
- **Désactiver :** Empêche le service de démarrer au boot.
- **Réactiver :** Permet au service de démarrer à nouveau au boot.
- **Arrêter :** Arrête immédiatement un service en cours d'exécution.

> **Avertissement pour les débutants :** Ne désactivez pas les services que vous ne reconnaissez pas. Certains services sont essentiels au bon fonctionnement de votre système (par exemple, NetworkManager, PulseAudio, systemd-resolved). En cas de doute, laissez le service activé.

> **Conseil pour les experts :** Utilisez l'onglet « Services lents » pour optimiser le temps de démarrage. Des services comme `snapd`, `plymouth` ou `fwupd` peuvent souvent être désactivés sans risque si vous ne les utilisez pas.

**Nécessite un mot de passe :** Oui (pour les opérations de désactivation/activation/arrêt)

---

### 5.2 Applications au démarrage

**Objectif :** Gérer les applications qui démarrent automatiquement lors de votre connexion.

La liste affiche toutes les entrées de démarrage automatique réparties en sections **Activées** et **Désactivées**. Chaque entrée affiche le nom de l'application, la commande et s'il s'agit d'une application système ou utilisateur.

**Actions par application (appuyez sur le menu à trois points) :**
- **Désactiver :** Empêche l'application de démarrer à la connexion. Si l'application est actuellement en cours d'exécution, on vous demande si vous souhaitez également terminer ses processus.
- **Réactiver :** Réactive une application de démarrage désactivée.
- **Terminer les processus :** Tous les processus en cours d'exécution de cette application sont arrêtés.
- **Supprimer :** Supprime définitivement l'entrée de démarrage automatique.

**Protection des applications système :** Certaines applications (comme GNOME Shell, NetworkManager, les composants KDE Plasma) sont marquées comme protégées et ne peuvent pas être désactivées. Cela empêche les dommages accidentels à votre environnement de bureau.

> **Conseil pour les débutants :** Si vous remarquez que votre ordinateur met du temps à démarrer, consultez l'onglet Applications au démarrage. La désactivation d'applications inutiles (comme les clients de stockage cloud ou les applications de chat que vous n'utilisez pas au démarrage) peut accélérer considérablement la connexion.

> **Conseil pour les experts :** L'application crée des remplacements au niveau utilisateur pour les entrées de démarrage automatique système dans `/etc/xdg/autostart/` au lieu de modifier les fichiers système. C'est sûr et réversible.

**Nécessite un mot de passe :** Non

---

### 5.3 Nettoyage

**Objectif :** Libérer de l'espace disque en supprimant les fichiers temporaires, les caches et en vidant le cache de pages Linux.

**Ligne de boutons :**
- **Actualiser les tailles :** Recalcule la taille de tous les dossiers temp/cache détectés.
- **Nettoyer les fichiers temporaires (bouton orange) :** Supprime les fichiers temporaires de tous les dossiers listés. Un dialogue de confirmation apparaît avant la suppression. Vous pouvez exclure des dossiers spécifiques en appuyant sur l'icône de bascule à côté de chaque dossier.

**Cache de pages Linux :**
- **Bouton Vider le cache :** Libère le cache de pages du noyau en exécutant `sync && echo 1 > /proc/sys/vm/drop_caches`. C'est sûr et ne supprime aucune donnée utilisateur — cela vide uniquement les lectures de fichiers en cache de la RAM.

**Nettoyage de la RAM :**
- Affiche l'utilisation actuelle de la RAM (utilisée / totale / pourcentage).
- **Bouton Nettoyer la RAM :** Vide le cache de pages, les dentries et les inodes en exécutant `sync && echo 3 > /proc/sys/vm/drop_caches`. Cela libère plus de mémoire que le vidage de cache basique. Affiche la quantité de mémoire libérée après l'opération.

**Nettoyage automatique de la RAM :**
- Configurez dans **Paramètres > Nettoyage RAM** pour vider automatiquement la RAM à des intervalles : Jamais, 5 min, 10 min, 15 min ou 30 min.
- S'exécute en arrière-plan à l'intervalle configuré.

**Ajouter un dossier exclu :** Ajoutez des dossiers personnalisés à exclure du nettoyage. Utile pour préserver les répertoires de cache d'applications spécifiques.

> **Conseil pour les débutants :** Utilisez « Nettoyer les fichiers temporaires » régulièrement pour libérer de l'espace disque. Les boutons « Vider le cache » et « Nettoyer la RAM » sont sûrs — ils ne suppriment aucun fichier personnel.

> **Conseil pour les experts :** Le nettoyeur de RAM utilise `echo 3` (vide le cache de pages + dentries + inodes), ce qui est plus agressif que `echo 1` (cache de pages uniquement). Utilisez-le quand vous avez besoin de récupérer rapidement de la mémoire, par exemple avant de lancer une application gourmande en mémoire.

**Nécessite un mot de passe :** Oui (pour le vidage du cache et le nettoyage de la RAM)

---

### 5.4 Applications installées

**Objectif :** Afficher et désinstaller les applications de tous les gestionnaires de paquets.

**Gestionnaires de paquets pris en charge :**
- **APT** (Debian/Ubuntu/Mint)
- **Snap** (Paquets universels Linux)
- **Flatpak** (Applications sandboxées)
- **GNOME** (Applications de bureau via des fichiers .desktop)

**Fonctionnalités :**
- **Recherche :** Filtrez les applications par nom ou description.
- **Puces de filtre :** Basculez entre les vues Toutes, APT, Snap, Flatpak, GNOME.
- **Désinstallation par application :** Appuyez sur le menu à trois points et sélectionnez « Supprimer ». L'application vérifie d'abord les dépendances — si d'autres paquets dépendent de celui que vous souhaitez supprimer, un dialogue d'avertissement vous affiche la liste.

> **Avertissement pour les débutants :** Soyez prudent lors de la désinstallation de paquets système. Si vous n'êtes pas sûr, recherchez d'abord le nom du paquet en ligne.

> **Conseil pour les experts :** La vérification des dépendances utilise `apt-cache depends` et `apt-cache rdepends --installed` pour afficher les dépendances directes et inversées.

**Nécessite un mot de passe :** Oui (pour la suppression de paquets)

---

### 5.5 Moniteur système

**Objectif :** Surveillance en temps réel des processus, du processeur, de la RAM, du disque et du GPU.

Cet écran possède trois sous-onglets :

#### Onglet Processus
- Affiche tous les processus en cours d'exécution groupés par nom d'application.
- **Colonnes :** Nom de l'application, CPU%, Mémoire — appuyez sur un en-tête de colonne pour trier.
- **Jauges CPU/RAM/GPU** sur le côté droit affichent l'utilisation en temps réel.
- **Actions par groupe :** Sélectionner tout, Terminer tout, Forcer l'arrêt de tout.
- **Mode multi-sélection :** Cochez plusieurs groupes de processus, puis tuez-les tous en une fois.
- Actualisation automatique toutes les 5 secondes.

#### Onglet Système
Affiche les informations matérielles sous forme de cartes :
- **Processeur :** Modèle, cœurs, threads, barre d'utilisation, fréquence d'horloge.
- **Mémoire :** Totale, utilisée, libre, en cache, utilisation du swap.
- **Disque :** Nom du périphérique par disque, système de fichiers, barre d'utilisation.
- **GPU :** Modèle, pilote, pourcentage d'utilisation, mémoire, température (si disponible).
- **Serveur d'affichage :** Détection Wayland/X11/XWayland, environnement de bureau, variables d'environnement clés.

#### Onglet État
Tableau de bord en lecture seule de l'état du système avec quatre sections :
- **Noyau :** Version, informations de compilation, mode THP, zswap, régulateur, planificateur d'E/S.
- **Sécurité :** AppArmor, SELinux, Secure Boot, état du pare-feu, état SSH, mises à jour automatiques.
- **Virtualisation :** Support de virtualisation CPU, KVM, IOMMU, VFIO, KSM, Docker, libvirt.
- **Imprimantes :** État du service CUPS, imprimantes installées, pilotes d'impression.

> **Conseil pour les débutants :** L'onglet Processus vous aide à trouver quelle application utilise trop de CPU ou de mémoire. Appuyez sur un groupe de processus pour voir les processus individuels.

> **Conseil pour les experts :** L'onglet État fournit un audit rapide de la sécurité et de la virtualisation. Vérifiez l'état du pare-feu, SSH et Secure Boot en un coup d'œil.

**Nécessite un mot de passe :** Non

---

### 5.6 Analyseur de disque

**Objectif :** Naviguer dans votre système de fichiers, visualiser l'utilisation du disque et gérer les fichiers.

**Navigation :**
- **Accueil / Système de fichiers / Disques externes :** Sélection rapide des chemins de base.
- **Précédent / Suivant :** Naviguez dans l'historique.
- **Tri :** Par taille (croissant/décroissant) ou alphabétiquement.
- **Menu supplémentaire :** Basculez la visibilité des fichiers cachés/système.

**Fonctionnalités :**
- **Diagramme circulaire :** Visualise la distribution de la taille des répertoires.
- **Avis de première analyse :** Lorsqu'un disque est analysé pour la première fois, un avis informatif s'affiche vous informant que l'indexation est en cours et que la première analyse peut prendre un certain temps.
- **Actions sur les fichiers/répertoires :**
  - **Déplacer vers la corbeille :** Suppression sûre vers la corbeille (avec confirmation).
  - **Renommer :** Renommez les fichiers ou répertoires.
  - **Afficher les détails :** Consultez le chemin, la taille, le type, les permissions, le propriétaire, la date de modification.

> **Avertissement :** La suppression de fichiers du système de fichiers racine (`/`) nécessite des privilèges administrateur et est irréversible. Soyez très prudent.

> **Conseil pour les débutants :** Commencez par analyser votre répertoire personnel pour trouver les grands dossiers qui prennent de l'espace (par exemple, `~/.cache`, `~/.local/share/Trash`).

**Nécessite un mot de passe :** Oui (pour la suppression depuis les chemins racine)

---

### 5.7 Santé des disques SMART

**Objectif :** Surveiller la santé des disques durs et SSD à l'aide des données S.M.A.R.T.

**Fonctionnalités :**
- **Sélecteur de disque :** Choisissez le disque à inspecter dans le menu déroulant.
- **État de santé :** Affiche RÉUSSIT ou ÉCHOUÉ avec la température et les heures de fonctionnement.
- **Détection USB :** Identifie les disques connectés en USB et avertit que les ponts USB-SATA peuvent limiter les données SMART.
- **Tableau des attributs :** Affiche tous les attributs SMART (ID, nom, valeur, pire, seuil, brut). Les attributs échoués sont surlignés en rouge.
- **Auto-tests :**
  - **Test court :** Analyse rapide (~2 minutes).
  - **Test étendu :** Analyse approfondie (peut prendre plusieurs heures selon la taille du disque).
  Les résultats apparaissent dans le tableau des attributs une fois le test terminé.

**Si smartctl n'est pas installé :** L'application propose d'installer `smartmontools` automatiquement.

> **Conseil pour les débutants :** Vérifiez la santé de votre disque chaque mois. Un statut « ÉCHOUÉ » ou des attributs marqués en rouge indiquent que le disque peut nécessiter un remplacement prochain.

> **Conseil pour les experts :** L'application prend en charge l'analyse multi-distributions (lsblk + smartctl --scan + fallback /sys/block/). Les ponts USB-SATA sont testés avec `smartctl -d sat`.

**Nécessite un mot de passe :** Oui (pour installer smartctl et exécuter les auto-tests)

---

### 5.8 Gestionnaire de périphériques

**Objectif :** Afficher, activer et désactiver les périphériques matériels — similaire au Gestionnaire de périphériques Windows.

**Fonctionnalités :**
- **Arborescence des périphériques :** Tous les périphériques matériels (PCI, USB, bloc, réseau) groupés par catégorie : Cartes d'affichage, Cartes réseau, Audio/vidéo, Contrôleurs USB, Stockage, Processeur, Périphériques d'entrée, Multimédia.
- **Barre de recherche :** Filtrez les périphériques par nom ou description.
- **Filtre afficher les désactivés :** Basculez pour afficher uniquement les périphériques désactivés.

**Actions par périphérique (appuyez pour développer, puis menu à trois points) :**
- **Activer/Désactiver :** Basculez l'état du périphérique avec un dialogue de confirmation. Nécessite le mot de passe sudo.
- **Panneau de propriétés :** Affiche des informations détaillées — statut, type de bus, fabricant, pilote, identifiants fabricant/périphérique.

**Protection des périphériques :** Les périphériques critiques (Host bridge, PCI bridge, ISA bridge, IOMMU, SMBus, Processeur) ne peuvent pas être désactivés pour éviter l'instabilité du système.

**Persistance :** Les périphériques désactivés sont enregistrés dans `/etc/slu_disabled_devices.conf` et un service systemd est créé pour réappliquer la désactivation à chaque démarrage. Cela garantit que vos paramètres survivent aux redémarrages.

> **Avertissement pour les débutants :** Ne désactivez pas les périphériques que vous ne reconnaissez pas. La désactivation d'une carte réseau vous déconnectera d'Internet. La désactivation d'une carte d'affichage peut faire planter votre bureau.

> **Conseil pour les experts :** Le mécanisme de persistance utilise sysfs (`echo 0 > enable` pour PCI, `echo 0 > authorized` pour USB, `ip link set X down` pour le réseau) avec un service systemd.

**Nécessite un mot de passe :** Oui (pour les opérations d'activation/désactivation)

---

### 5.9 Récupération

**Objectif :** Restaurer les fonctions système modifiées, vérifier les mises à jour et installer des logiciels.

#### Opérations de récupération
| Opération | Description |
|-----------|------------|
| **Redémarrer Pipewire** | Redémarre PipeWire, PipeWire-Pulse et Wireplumber pour résoudre les problèmes audio. |
| **Restaurer le réseau** | Redémarre NetworkManager ou systemd-networkd pour résoudre les problèmes de connexion. |
| **Reconstruire GRUB** | Exécute `update-grub` pour régénérer la configuration de l'amorçage. |
| **Restaurer Flathub** | Réajoute le remote Flathub pour Flatpak. |
| **Restaurer les dépôts** | Met à jour et restaure les dépôts de paquets pour votre distribution. |
| **Corriger la mise en veille automatique WiFi** | Désactive la mise en veille automatique USB pour les adaptateurs WiFi afin d'empêcher les déconnexions aléatoires. |

Chaque opération affiche un bouton « Voir la sortie » pour inspecter la sortie de la commande.

#### Onglet Vérification des mises à jour
- **Vérifier les mises à jour :** Exécute la commande de mise à jour appropriée du gestionnaire de paquets (`apt update`, `dnf check-update`, `pacman -Sy`).
- Les résultats affichent les mises à jour disponibles par gestionnaire de paquets (APT, DNF, Pacman, Snap, Flatpak).
- **Appliquer les mises à jour :** Télécharge et installe toutes les mises à jour disponibles avec progression en temps réel.

#### Onglet Installateur de logiciels
Installateurs en un clic pour les logiciels essentiels :
- **FFmpeg :** Framework multimédia pour l'encodage/décodage audio et vidéo.
- **yt-dlp :** Téléchargeur de vidéos prenant en charge de nombreux sites web.
- **Bibliothèques système :** Bibliothèques système essentielles qui peuvent être manquantes.
- **Codecs :** Codecs vidéo et audio pour les formats courants.
- **rsync :** Outil efficace de synchronisation et de transfert de fichiers.

**Nécessite un mot de passe :** Oui

---

### 5.10 Optimisations

**Objectif :** Réglage des performances système pour le swap et DaVinci Resolve.

#### Onglet Swap
- Affiche les informations actuelles sur le swap : taille de la RAM, swap total/utilisé, valeur de swappiness, périphérique de swap.
- Fournit des recommandations basées sur votre configuration :
  - Créer un fichier swap s'il n'en existe aucun.
  - Ajuster la valeur de swappiness.
  - Activer ou désactiver zram.
- Chaque recommandation possède un bouton « Exécuter » qui applique la modification suggérée.

#### Onglet DaVinci Resolve
- Applique les correctifs Linux courants pour Blackmagic DaVinci Resolve :
  - Corriger les chemins des bibliothèques CUDA.
  - Définir les permissions GPU correctes.
  - Installer les dépendances manquantes.
- Chaque correctif indique s'il nécessite un redémarrage et s'il a été appliqué.

> **Conseil pour les débutants :** Si vous utilisez DaVinci Resolve sur Linux et rencontrez des problèmes de GPU, allez dans cet onglet et appliquez tous les correctifs.

> **Conseil pour les experts :** Les recommandations de swap analysent votre `/proc/meminfo` et votre configuration de swap pour fournir les suggestions les plus appropriées.

**Nécessite un mot de passe :** Oui

---

### 5.11 Paramètres

Configurez les préférences de l'application :

#### Mot de passe
- Enregistrez, mettez à jour ou supprimez votre mot de passe administrateur.
- Le mot de passe est stocké à l'aide du trousseau de clés du système (encodé en base64 dans SharedPreferences).

#### Langue
- Choisissez parmi 6 langues : italien, anglais, français, espagnol, allemand, portugais.
- Les modifications prennent effet après le redémarrage de l'application.

#### Thème
- **Clair / Système :** Choisissez le schéma de couleurs de l'application.
- « Système » suit le paramètre de thème de votre environnement de bureau.

#### Police
- **Famille de polices :** Choisissez parmi les polices système disponibles.
- **Taille de police :** Curseur de 10sp à 24sp.

#### Zone de notification système (uniquement Linux)
- **Activer la zone de notification système :** Affichez/masquez l'icône de l'application dans la zone de notification.
- **Fermer vers la zone de notification :** Gardez l'application en cours d'exécution dans la zone de notification lorsque vous fermez la fenêtre.
- **Démarrer minimisé :** Lancez l'application minimisée dans la zone de notification.
- **Démarrer à la connexion :** Démarrez automatiquement l'application lorsque vous vous connectez (utilise le démarrage automatique XDG).
- **Installer les dépendances :** Installe `libayatana-appindicator` s'il est manquant.

#### Vérification automatique des mises à jour
- Définissez la fréquence de vérification des mises à jour système par l'application (Jamais, 15 min, 30 min, 1 h, 6 h, 12 h, quotidien).
- **Mise à jour automatique depuis GitHub :** Télécharge et installe automatiquement le dernier `.deb` depuis les versions GitHub.

#### Nettoyage de la RAM
- Définissez un intervalle automatique pour vider le cache de pages Linux et la RAM : **Jamais**, **5 minutes**, **10 minutes**, **15 minutes**, **30 minutes**.
- S'exécute en arrière-plan à l'intervalle configuré.

#### Planificateur d'arrêt
- Ouvre l'écran du minuterie d'arrêt automatique (voir Section 7).

---

### 5.12 Informations

**Objectif :** Écran « À propos » avec les informations de l'application.

- Version de l'application, créateur et description.
- Liste des fonctionnalités organisée par catégorie.
- Licence et avertissement (GPL).
- **Bouton Activation de licence** (uniquement version Avancée) : Entrez votre clé de licence pour débloquer les fonctionnalités avancées.
- **Bouton PayPal** (uniquement version Avancée) : Achetez une licence pour 19,99 EUR.
- Lien vers le site web du projet.

---

## 6. Mode Avancé — Fonctionnalités supplémentaires

Le mode avancé débloque 2 onglets supplémentaires et étend l'écran Optimisations existant. Nécessite une clé de licence achetée (ou version Personnelle/Test).

Pour basculer entre le mode Standard et le mode Avancé, utilisez les boutons de mode dans la zone supérieure droite de la barre latérale.

---

### 6.1 Éditeur GRUB

**Objectif :** Modifier la configuration de l'amorçage GRUB en toute sécurité.

**Fonctionnalités :**
- **Éditeur de texte :** Modifiez directement `/etc/default/grub` dans un éditeur de texte intégré.
- **Enregistrer et mettre à jour :** Enregistre la configuration, crée une sauvegarde automatique et exécute `update-grub` (ou l'équivalent pour votre distribution).
- **Suggestions matérielles :** Analyse votre matériel et suggère des paramètres du noyau :
  - NVIDIA modeset, iommu, threadirqs, zswap, elevator, etc.
  - Chaque suggestion possède un badge de priorité (haute/moyenne/basse).
  - Appuyez sur « Appliquer » pour insérer la suggestion dans l'éditeur.
- **Restaurer la sauvegarde :** Rétablissez la dernière sauvegarde en cas de problème.
- **Indicateur de modifications non enregistrées :** Une bannière orange apparaît lorsque vous avez des modifications non enregistrées.

**Commandes de reconstruction GRUB par distribution :**
- Debian/Ubuntu : `update-grub`
- Fedora : `grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
- Arch : `grub-mkconfig -o /boot/grub/grub.cfg`

> **Avertissement :** Des modifications GRUB incorrectes peuvent empêcher votre système de démarrer. Conservez toujours une sauvegarde. Si votre système ne parvient pas à démarrer, utilisez une clé USB live pour restaurer `/etc/default/grub` à partir de la sauvegarde.

**Nécessite un mot de passe :** Oui

---

### 6.2 Benchmark

**Objectif :** Mesurer les performances matérielles de votre système.

Quatre catégories de benchmark :

| Benchmark | Ce qu'il mesure |
|-----------|-----------------|
| **CPU** | Puissance de traitement multi-cœurs et mono-cœur. Résultats comparés aux références Intel, AMD et Apple. |
| **GPU** | Performances graphiques avec `glmark2`. Résultats comparés aux GPU de référence NVIDIA et AMD. |
| **Disque** | Vitesse de lecture/écriture séquentielle. Résultats comparés aux références NVMe, SSD et HDD. |
| **Réseau** | Test de vitesse Internet. Résultats comparés aux vitesses réseau de référence. |

Chaque benchmark affiche :
- Votre score.
- Le matériel de référence le plus proche correspondant.
- Une évaluation (Excellent, Bon, Moyen, Inférieur à la moyenne, Faible).

> **Conseil :** Exécutez les benchmarks après des modifications système (nouveau noyau, nouveaux pilotes) pour voir si les performances se sont améliorées.

**Nécessite un mot de passe :** Non

---

## 7. Zone de notification système

Lorsqu'elle est activée dans les Paramètres, Super Linux Utility place une icône dans la zone de notification (zone des notifications). Faites un clic droit sur l'icône pour accéder à :

| Élément du menu | Action |
|-----------------|--------|
| **Afficher la fenêtre principale** | Met la fenêtre de l'application au premier plan. |
| **Vérifier les mises à jour** | Ouvre le dialogue de vérification des mises à jour. |
| **Nettoyer les fichiers temporaires et le cache** | Navigue vers l'onglet Nettoyage. |
| **Température CPU, GPU** | Navigue vers l'onglet Moniteur. |
| **Utilisation du disque** | Navigue vers l'onglet Analyseur de disque. |
| **Utilisation de la mémoire** | Affiche l'utilisation actuelle de la RAM. |
| **Santé des disques (SMART)** | Navigue vers l'onglet SMART. |
| **Arrêt automatique** | Ouvre le dialogue de minuterie d'arrêt. |
| **Utilisation CPU, GPU** | Ouvre un dialogue de gestionnaire des tâches. |
| **Quitter** | Ferme l'application.**

Le texte de l'icône de la zone de notification affiche la température CPU/GPU et l'utilisation de la mémoire en temps réel.

---

## 8. Mises à jour automatiques

### Vérification des mises à jour système
Configurable dans Paramètres > Vérification automatique des mises à jour. Lorsqu'elle est activée, l'application vérifie périodiquement les mises à jour dans tous les gestionnaires de paquets installés (APT, DNF, Pacman, Snap, Flatpak). Les notifications de mise à jour apparaissent sous forme de dialogues avec des cases à cocher par paquet.

### Auto-mise à jour de l'application
Lorsqu'elle est activée dans Paramètres > Mise à jour automatique depuis GitHub, l'application vérifie les versions GitHub pour les paquets `.deb` plus récents correspondant à votre édition (Standard/Avancé). Télécharge et installe automatiquement en utilisant `sudo dpkg -i`.

---

## 9. Dépannage

### Erreur « Mot de passe non enregistré »
Allez dans Paramètres > Mot de passe et réentrez votre mot de passe sudo. Le mot de passe est stocké dans le trousseau de clés du système.

### L'onglet SMART n'affiche aucun disque
Installez `smartmontools` : l'application proposera de le faire automatiquement. Si vous utilisez un adaptateur USB-SATA, les données SMART peuvent être limitées.

### Les modifications GRUB ne sont pas appliquées (mode Avancé)
Assurez-vous d'avoir appuyé sur « Enregistrer et mettre à jour » (et pas seulement « Enregistrer »). L'application doit exécuter `update-grub` avec des privilèges administrateur.

### L'icône de la zone de notification n'est pas visible
Installez la dépendance requise : `sudo apt install libayatana-appindicator-3-dev`. Puis redémarrez l'application.

### L'AppImage ne démarre pas
L'AppImage utilise un runtime statique et devrait fonctionner sans FUSE. Si cela échoue toujours :
```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./super-linux-utility-*.AppImage
```

### Le Gestionnaire de périphériques ne peut pas désactiver un périphérique
Certains périphériques sont protégés car leur désactivation ferait planter le système. L'application affiche un message lorsqu'un périphérique ne peut pas être désactivé.

---

## 10. FAQ

**Q : Est-il sûr d'utiliser cette application ?**
R : Les fonctionnalités du mode standard sont sûres pour tous les utilisateurs. Le mode avancé modifie GRUB — créez toujours une sauvegarde avant d'utiliser les fonctionnalités GRUB.

**Q : L'application envoie-t-elle des données quelque part ?**
R : Non. L'application ne collecte ni ne transmet aucune donnée utilisateur. Les seules opérations réseau sont la vérification des mises à jour (depuis GitHub ou votre gestionnaire de paquets).

**Q : Puis-je utiliser l'application sur Fedora/Arch ?**
R : Oui. L'application détecte automatiquement votre distribution et adapte toutes les commandes en conséquence (APT, DNF, Pacman).

**Q : Que se passe-t-il si je désactive un service critique ?**
R : L'application protège les services essentiels de l'environnement de bureau (GNOME, KDE, etc.) contre la désactivation. Cependant, soyez toujours prudent avec les services inconnus.

**Q : Comment restaurer GRUB si le système ne démarre pas ?**
R : Démarrez depuis une clé USB live, montez votre partition racine et copiez `/etc/default/grub.backup` vers `/etc/default/grub`. Puis exécutez `sudo update-grub`.

**Q : Puis-je désactiver n'importe quel périphérique matériel ?**
R : Le Gestionnaire de périphériques protège les périphériques système critiques (CPU, ponts, IOMMU) contre la désactivation. Vous pouvez désactiver en toute sécurité les périphériques non essentiels comme les périphériques USB ou les cartes réseau secondaires.

---

## 11. Glossaire

| Terme | Définition |
|-------|------------|
| **APT** | Advanced Package Tool — Gestionnaire de paquets Debian/Ubuntu. |
| **Gestionnaire de périphériques** | Outil pour afficher, activer et désactiver les périphériques matériels. |
| **DNF** | Dandified YUM — Gestionnaire de paquets Fedora/RHEL. |
| **Flatpak** | Format d'empaquetage d'applications sandboxé pour Linux. |
| **GRUB** | Grand Unified Bootloader — le programme qui charge Linux au démarrage. |
| **Noyau** | Le cœur du système d'exploitation Linux. |
| **PCI** | Peripheral Component Interconnect — bus standard pour les périphériques internes. |
| **Pacman** | Gestionnaire de paquets pour Arch Linux et ses dérivés. |
| **PipeWire** | Serveur audio/vidéo moderne pour Linux. |
| **SMART** | Self-Monitoring, Analysis and Reporting Technology — système de santé des disques durs. |
| **Snap** | Format de paquets universel Linux par Canonical. |
| **systemd** | Système d'initialisation et gestionnaire de services pour Linux. |
| **systemctl** | Outil en ligne de commande pour gérer les services systemd. |
| **Swap** | Espace disque utilisé comme RAM virtuelle lorsque la RAM physique est pleine. |
| **sysfs** | Système de fichiers virtuel exposant les données des périphériques noyau (`/sys/`). |
| **USB** | Universal Serial Bus — standard pour les périphériques externes. |
| **Wayland** | Protocole de serveur d'affichage moderne remplaçant X11. |
| **X11** | Protocole de serveur d'affichage traditionnel pour Linux. |
| **zram** | Périphérique de swap basé sur la RAM compressée. |

---

*Super Linux Utility v2.0.6 — Manuel Utilisateur*
*Créé par Marco Di Giangiacomo*
*Licence : GPL v3*
