// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Super Linux Utility';

  @override
  String get appAlreadyRunning =>
      'L\'application est déjà en cours d\'exécution.';

  @override
  String get trayCheckUpdates => 'Vérifier les mises à jour du système';

  @override
  String get trayCleanLinuxCache => 'Vider le cache Linux';

  @override
  String get trayRemoveTempFiles => 'Supprimer les fichiers temporaires';

  @override
  String get trayCpuGpuTemp => 'Température CPU, GPU';

  @override
  String get trayDiskUsage => 'Utilisation du disque';

  @override
  String get trayMemoryUsage => 'Utilisation mémoire RAM';

  @override
  String get trayShutdownTimer => 'Arrêt automatique';

  @override
  String get trayShowMainWindow => 'Afficher la fenêtre principale';

  @override
  String get trayCpuGpuUsage => 'Utilisation CPU, GPU';

  @override
  String get trayExit => 'Quitter';

  @override
  String get cleanupLinuxCache => 'Vider le cache';

  @override
  String get cleanupLinuxCacheDesc =>
      'Vider le cache mémoire du noyau (drop_caches). Nécessite le mot de passe administrateur.';

  @override
  String get cleanupLinuxCacheSuccess => 'Cache Linux vidé avec succès.';

  @override
  String get cleanupLinuxCacheError => 'Erreur lors du vidage du cache.';

  @override
  String get tabServices => 'Services';

  @override
  String get tabStartupApps => 'Applications au Démarrage';

  @override
  String get tabCleanup => 'Nettoyage';

  @override
  String get tabInstalledApps => 'Applications Installées';

  @override
  String get tabMonitor => 'Moniteur';

  @override
  String get tabDiskAnalyzer => 'Analyseur de Disque';

  @override
  String get tabAppearance => 'Apparence GNOME';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabRecovery => 'Récupération Système';

  @override
  String get tabGrub => 'GRUB';

  @override
  String get tabKernel => 'Noyau';

  @override
  String get tabSettings => 'Paramètres';

  @override
  String get modeStandard => 'Standard';

  @override
  String get modeAdvanced => 'Avancé';

  @override
  String get warningTitle => 'ATTENTION';

  @override
  String get warningSubtitle => 'Application pour Utilisateurs Experts';

  @override
  String get warningMessage =>
      'Cette application permet de modifier des configurations critiques du système d\'exploitation Linux.';

  @override
  String get warningGrub => 'Modifications GRUB';

  @override
  String get warningGrubDesc =>
      'Une modification incorrecte du chargeur de démarrage peut empêcher le système de démarrer.';

  @override
  String get warningKernel => 'Suppression du Noyau';

  @override
  String get warningKernelDesc =>
      'Supprimer des noyaux essentiels peut rendre le système inutilisable.';

  @override
  String get warningServices => 'Gestion des Services';

  @override
  String get warningServicesDesc =>
      'Désactiver des services critiques peut causer des dysfonctionnements du système.';

  @override
  String get warningCleanup => 'Nettoyage des Fichiers';

  @override
  String get warningCleanupDesc =>
      'Supprimer des fichiers système peut compromettre la stabilité.';

  @override
  String get warningBackup =>
      'Il est recommandé de créer une sauvegarde du système avant d\'utiliser cette application.';

  @override
  String get warningDontShow => 'Ne plus afficher cet avertissement';

  @override
  String get warningAccept => 'J\'ai Compris, Continuer';

  @override
  String get passwordSetupTitle => 'Configuration du Mot de Passe';

  @override
  String get passwordSetupDesc =>
      'Pour utiliser les fonctionnalités qui nécessitent des privilèges administrateur, vous devez configurer le mot de passe système.';

  @override
  String get passwordLabel => 'Mot de Passe';

  @override
  String get passwordHint => 'Entrez le mot de passe administrateur';

  @override
  String get passwordConfirm => 'Confirmer le Mot de Passe';

  @override
  String get passwordConfirmHint => 'Ré-entrez le mot de passe';

  @override
  String get passwordSave => 'Enregistrer le Mot de Passe';

  @override
  String get passwordSkip => 'Ignorer pour l\'instant';

  @override
  String get passwordSaved =>
      'Mot de passe enregistré de manière sécurisée à l\'aide du trousseau système.';

  @override
  String get passwordError => 'Erreur lors de l\'enregistrement';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordEmpty => 'Entrez un mot de passe';

  @override
  String get passwordRequired => 'Mot de Passe Requis';

  @override
  String get passwordRequiredMessage =>
      'Le mot de passe administrateur est requis pour accéder à tous les répertoires. Le mot de passe sera enregistré de manière sécurisée.';

  @override
  String get settingsPasswordTitle => 'Mot de Passe Administrateur';

  @override
  String get settingsPasswordDesc =>
      'Enregistrez le mot de passe administrateur pour utiliser les fonctionnalités qui nécessitent des privilèges sudo.';

  @override
  String get settingsPasswordSaved =>
      'Mot de passe enregistré. Vous pouvez le modifier ou le supprimer.';

  @override
  String get settingsPasswordConfigured => 'Mot de passe configuré';

  @override
  String get settingsPasswordUpdate => 'Mettre à Jour le Mot de Passe';

  @override
  String get settingsPasswordDelete => 'Supprimer';

  @override
  String get settingsThemeTitle => 'Thème de l\'Application';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeSystemDesc => 'Suit les paramètres du système';

  @override
  String get settingsInfoTitle => 'Informations';

  @override
  String get settingsInfoDesc => 'Cette application vous aide à :';

  @override
  String get settingsInfoItem1 =>
      'Trouver les services systemd qui ralentissent le démarrage';

  @override
  String get settingsInfoItem2 => 'Gérer les applications au démarrage';

  @override
  String get settingsInfoItem3 =>
      'Nettoyer les fichiers temporaires du système';

  @override
  String get loading => 'Chargement...';

  @override
  String get loadingSettings => 'Chargement des paramètres système';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Enregistrer';

  @override
  String get themeRestartMessage =>
      'Le thème sera appliqué après le redémarrage de l\'application';

  @override
  String get themeApplied => 'Thème appliqué avec succès';

  @override
  String get settingsFontTitle => 'Police et Taille du Texte';

  @override
  String get settingsFontDesc =>
      'Personnalisez la police et la taille du texte utilisées dans toute l\'application.';

  @override
  String get settingsSystemTrayTitle => 'Zone de notification';

  @override
  String get settingsSystemTrayDesc =>
      'Afficher l\'icône de l\'app dans la zone de notification pour les actions rapides. Nécessite les dépendances système (libappindicator).';

  @override
  String get settingsTrayDepsOk => 'Dépendances installées.';

  @override
  String get settingsTrayDepsMissing =>
      'Dépendances manquantes. Installez-les pour activer la zone de notification.';

  @override
  String get settingsSystemTrayEnable => 'Activer la zone de notification';

  @override
  String get settingsTrayInstallDeps => 'Installer les dépendances';

  @override
  String get settingsCloseToTray =>
      'Rester dans la zone de notification à la fermeture';

  @override
  String get settingsCloseToTrayDesc =>
      'Si activé, fermer ou réduire la fenêtre garde l\'app dans la zone de notification.';

  @override
  String get settingsCloseToTrayOn => 'Réduire dans la zone activé.';

  @override
  String get settingsCloseToTrayOff =>
      'Réduire dans la zone désactivé. Fermer la fenêtre quittera l\'app.';

  @override
  String get settingsTrayEnabled => 'Zone de notification activée.';

  @override
  String get settingsTrayDisabled =>
      'Zone de notification désactivée. Redémarrez l\'app pour appliquer.';

  @override
  String get settingsStartMinimized =>
      'Démarrer l\'app réduite dans la zone de notification';

  @override
  String get settingsStartMinimizedDesc =>
      'Si activé, l\'app démarre sans afficher la fenêtre principale, uniquement l\'icône dans la zone de notification.';

  @override
  String get settingsStartMinimizedOn =>
      'Démarrage réduit activé. Au prochain lancement, l\'app s\'ouvrira uniquement dans la zone.';

  @override
  String get settingsStartMinimizedOff => 'Démarrage réduit désactivé.';

  @override
  String get settingsStartAtLogin =>
      'Démarrer l\'app à l\'ouverture de session';

  @override
  String get settingsStartAtLoginDesc =>
      'Si activé, l\'app démarre automatiquement à la connexion.';

  @override
  String get settingsStartAtLoginOn => 'Démarrage à la connexion activé.';

  @override
  String get settingsStartAtLoginOff => 'Démarrage à la connexion désactivé.';

  @override
  String get settingsStartAtLoginError =>
      'Impossible de modifier le démarrage à la connexion.';

  @override
  String get fontFamily => 'Famille de Police';

  @override
  String get fontSize => 'Taille de Police';

  @override
  String get fontDefault => 'Par défaut (Roboto)';

  @override
  String get fontRestartMessage =>
      'La police sera appliquée après le redémarrage de l\'application';

  @override
  String get themeApplyError => 'Erreur lors de l\'application du thème';

  @override
  String get userThemesExtensionMessage =>
      'Pour des thèmes Shell complets, installez l\'extension User Themes depuis extensions.gnome.org';

  @override
  String get themeRequiresOcsUrl =>
      'Ce thème nécessite ocs-url pour être installé correctement';

  @override
  String get installOcsUrl => 'Installer ocs-url';

  @override
  String get ocsUrlNotInstalled =>
      'ocs-url n\'est pas installé. Certains thèmes peuvent ne pas fonctionner correctement.';

  @override
  String get ocsUrlInstalled => 'ocs-url installé avec succès !';

  @override
  String get ocsUrlInstallError =>
      'Erreur lors de l\'installation de ocs-url. Vérifiez que le mot de passe est correct et que le gestionnaire de paquets est disponible.';

  @override
  String get installingOcsUrl => 'Installation de ocs-url en cours...';

  @override
  String get installingOcsUrlDescription =>
      'Cette opération est effectuée automatiquement au premier lancement.';

  @override
  String get themeToolsMessage =>
      'Pour installer des thèmes depuis OpenDesktop.org/Pling.com, installez ocs-url ou PLing-store. Certains thèmes nécessitent ces outils pour fonctionner correctement.';

  @override
  String get refresh => 'Actualiser';

  @override
  String get search => 'Rechercher';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get start => 'Démarrer';

  @override
  String get stop => 'Arrêter';

  @override
  String get restart => 'Redémarrer';

  @override
  String get enable => 'Activer';

  @override
  String get disable => 'Désactiver';

  @override
  String get remove => 'Supprimer';

  @override
  String get kill => 'Terminer';

  @override
  String get killForce => 'Forcer l\'Arrêt';

  @override
  String get processes => 'Processus';

  @override
  String get system => 'Système';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => 'Mémoire';

  @override
  String get disk => 'Disque';

  @override
  String get gpu => 'Carte Graphique';

  @override
  String get usage => 'Utilisation';

  @override
  String get total => 'Total';

  @override
  String get used => 'Utilisé';

  @override
  String get free => 'Libre';

  @override
  String get model => 'Modèle';

  @override
  String get driver => 'Pilote';

  @override
  String get temperature => 'Température';

  @override
  String get version => 'Version';

  @override
  String get creator => 'Créateur';

  @override
  String get creatorName => 'Marco Di Giangiacomo';

  @override
  String get appDescription =>
      'Super Linux Utility est une application complète pour la gestion avancée du système Linux. Elle offre des outils puissants pour optimiser les performances, gérer les services, les applications et personnaliser l\'apparence du système.';

  @override
  String get features => 'Caractéristiques';

  @override
  String get appExpertUsers =>
      'Application conçue pour les utilisateurs experts Linux';

  @override
  String get languageSelectionTitle => 'Sélection de la Langue';

  @override
  String get languageSelectionDesc =>
      'Sélectionnez la langue de l\'application';

  @override
  String get languageItalian => 'Italien';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String get settingsLanguageTitle => 'Langue de l\'Application';

  @override
  String get settingsLanguageDesc => 'Sélectionnez la langue de l\'interface';

  @override
  String get languageRestartMessage =>
      'La langue sera appliquée au redémarrage de l\'application';

  @override
  String get servicesSlow => 'Services Lents';

  @override
  String get servicesAll => 'Tous les Services';

  @override
  String get servicesDisabled => 'Désactivés';

  @override
  String get analyzeAll => 'Analyser Tout';

  @override
  String get status => 'État';

  @override
  String get startupTime => 'Temps de démarrage';

  @override
  String get noServicesFound => 'Aucun service trouvé.';

  @override
  String get reEnable => 'Réactiver';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get cleanupConfirmTitle => 'Confirmer le nettoyage';

  @override
  String get cleanupConfirmMessage =>
      'Voulez-vous supprimer tous les fichiers temporaires ? Cette opération ne peut pas être annulée.';

  @override
  String get cleanupSuccess => 'Nettoyage terminé avec succès !';

  @override
  String get cleanupPartialSuccess =>
      'Nettoyage terminé avec quelques erreurs.';

  @override
  String get protectedSystemApp => 'Application Système Protégée';

  @override
  String cannotDisableSystemApp(String appName) {
    return 'Impossible de désactiver \"$appName\" car c\'est une application système essentielle.';
  }

  @override
  String get systemAppsRequired =>
      'Les applications système sont nécessaires au bon fonctionnement de l\'environnement de bureau et ne peuvent pas être désactivées.';

  @override
  String get checkingDependencies => 'Vérification des dépendances...';

  @override
  String get warning => '⚠️ Avertissement';

  @override
  String get packagesDependingOnThis => 'Paquets qui dépendent de ceci:';

  @override
  String get areYouSure => 'Êtes-vous sûr de vouloir continuer?';

  @override
  String get confirmRemoval => 'Confirmer la suppression';

  @override
  String removeAppQuestion(String appName) {
    return 'Voulez-vous supprimer $appName?';
  }

  @override
  String get searchApp => 'Rechercher une application';

  @override
  String get all => 'Tous';

  @override
  String get searchProcess => 'Rechercher un processus';

  @override
  String processesSelected(int count) {
    return '$count processus sélectionné';
  }

  @override
  String processesSelectedPlural(int count) {
    return '$count processus sélectionnés';
  }

  @override
  String get app => 'App';

  @override
  String get cpuPercent => 'CPU %';

  @override
  String get name => 'Nom';

  @override
  String get pid => 'PID';

  @override
  String get user => 'Utilisateur';

  @override
  String get noProcessesFound => 'Aucun processus trouvé.';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get terminateAll => 'Tout terminer';

  @override
  String get terminateAllForce => 'Forcer l\'arrêt de tout';

  @override
  String get cannotLoadSystemInfo =>
      'Impossible de charger les informations système.';

  @override
  String get cores => 'Cœurs';

  @override
  String get threads => 'Threads';

  @override
  String get grubInvalidContent =>
      'Le contenu du fichier GRUB n\'est pas valide';

  @override
  String get grubConfirmSave => 'Confirmer l\'enregistrement';

  @override
  String get grubSaveWarning =>
      'Vous êtes sur le point de modifier la configuration GRUB. Cette opération:';

  @override
  String get grubWillCreateBackup => '• Créera une sauvegarde automatique';

  @override
  String get grubWillSave => '• Enregistrera les modifications';

  @override
  String get grubWillUpdate => '• Mettra à jour GRUB';

  @override
  String get grubWarning =>
      'ATTENTION: Des modifications incorrectes peuvent empêcher le système de démarrer!';

  @override
  String get saveAndUpdate => 'Enregistrer et mettre à jour';

  @override
  String get grubSavedSuccess =>
      'Configuration GRUB enregistrée et mise à jour avec succès';

  @override
  String get grubSaveError => 'Erreur lors de l\'enregistrement';

  @override
  String get reload => 'Recharger';

  @override
  String get restoreBackup => 'Restaurer la sauvegarde';

  @override
  String get restoreBackupQuestion =>
      'Voulez-vous restaurer la sauvegarde de la configuration GRUB?';

  @override
  String get restore => 'Restaurer';

  @override
  String get backupRestoredSuccess => 'Sauvegarde restaurée avec succès';

  @override
  String get backupRestoreError =>
      'Erreur lors de la restauration de la sauvegarde';

  @override
  String get kernelCannotRemoveActive =>
      'Impossible de supprimer le noyau actuellement actif';

  @override
  String get removeKernel => 'Supprimer le noyau';

  @override
  String removeKernelQuestion(String version) {
    return 'Voulez-vous supprimer le noyau $version?';
  }

  @override
  String get thisOperation => 'Cette opération:';

  @override
  String get willRemovePackage => '• Supprimera le paquet du noyau';

  @override
  String get willUpdateGrub => '• Mettra à jour GRUB';

  @override
  String get kernelWarning =>
      'ATTENTION: Assurez-vous d\'avoir au moins un noyau fonctionnel!';

  @override
  String kernelRemovedSuccess(String version) {
    return 'Noyau $version supprimé avec succès';
  }

  @override
  String get kernelRemoveError => 'Erreur lors de la suppression du noyau';

  @override
  String get setDefaultKernel => 'Définir le noyau par défaut';

  @override
  String setDefaultKernelQuestion(String version) {
    return 'Voulez-vous définir $version comme noyau par défaut?';
  }

  @override
  String get set => 'Définir';

  @override
  String kernelSetDefaultSuccess(String version) {
    return 'Noyau $version défini comme par défaut';
  }

  @override
  String get kernelSetDefaultError =>
      'Erreur lors de la définition du noyau par défaut';

  @override
  String get keepMax => 'Conserver max:';

  @override
  String get cleanupKernels => 'Nettoyage du noyau';

  @override
  String keepOnlyRecentKernels(int count) {
    return 'Voulez-vous conserver uniquement les $count noyaux les plus récents?';
  }

  @override
  String totalKernels(int count) {
    return 'Noyaux totaux: $count';
  }

  @override
  String kernelsToKeep(int count) {
    return 'Noyaux à conserver: $count';
  }

  @override
  String kernelsToRemove(int count) {
    return 'Noyaux à supprimer: $count';
  }

  @override
  String get cleanupKernelsWarning =>
      'ATTENTION: Seuls les noyaux non utilisés seront supprimés.';

  @override
  String get cleanup => 'Nettoyer';

  @override
  String get kernelCleanupSuccess => 'Nettoyage du noyau terminé avec succès';

  @override
  String get kernelCleanupError => 'Erreur lors du nettoyage du noyau';

  @override
  String get invalidKernelCount =>
      'Entrez un nombre valide de noyaux à conserver';

  @override
  String get noKernelsFound => 'Aucun noyau installé trouvé';

  @override
  String get updateGrub => 'Mettre à jour GRUB';

  @override
  String get updateGrubQuestion =>
      'Voulez-vous mettre à jour GRUB? Cette opération mettra à jour la configuration du chargeur de démarrage.';

  @override
  String get grubUpdateSuccess => 'GRUB mis à jour avec succès';

  @override
  String get grubUpdateError => 'Erreur lors de la mise à jour de GRUB';

  @override
  String get rebootSystem => 'Redémarrer le système';

  @override
  String get rebootSystemQuestion =>
      'Voulez-vous redémarrer le système? Toutes les applications ouvertes seront fermées.';

  @override
  String get rebootSystemSuccess => 'Le système redémarre...';

  @override
  String get rebootSystemError => 'Erreur lors du redémarrage du système';

  @override
  String get package => 'Paquet';

  @override
  String get size => 'Taille';

  @override
  String get setAsDefault => 'Définir comme par défaut';

  @override
  String get refreshDimensions => 'Actualiser les dimensions';

  @override
  String get cleanupTempFiles => 'Nettoyer les fichiers temporaires';

  @override
  String get disableApp => 'Désactiver l\'application';

  @override
  String get onlyDisable => 'Désactiver uniquement';

  @override
  String get systemApps => 'Applications système';

  @override
  String get close => 'Fermer';

  @override
  String get updateStartupApps => 'Mettre à jour les applications au démarrage';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get scaleFactor => 'Facteur d\'échelle:';

  @override
  String get maximize => 'Maximiser';

  @override
  String get minimize => 'Minimiser';

  @override
  String get positioning => 'Positionnement:';

  @override
  String get left => 'Gauche';

  @override
  String get right => 'Droite';

  @override
  String get buttonOrder => 'Ordre des boutons:';

  @override
  String get attachedDialogs => 'Boîtes de dialogue attachées';

  @override
  String get centerNewWindows => 'Centrer les nouvelles fenêtres';

  @override
  String get resizeWithSecondaryClick =>
      'Redimensionner avec le clic secondaire';

  @override
  String get raiseOnFocus => 'Élever les fenêtres lorsqu\'elles ont le focus';

  @override
  String get backgroundImageUpdated => 'Image de fond mise à jour!';

  @override
  String get backgroundImageError =>
      'Erreur lors de la mise à jour de l\'image.';

  @override
  String get preferredFonts => 'Polices Préférées';

  @override
  String get interfaceText => 'Texte de l\'Interface';

  @override
  String get documentText => 'Texte du Document';

  @override
  String get fixedWidthText => 'Texte à Espacement Fixe';

  @override
  String get rendering => 'Rendu';

  @override
  String get hinting => 'Hinting';

  @override
  String get full => 'Complet';

  @override
  String get medium => 'Moyen';

  @override
  String get light => 'Léger';

  @override
  String get antialiasing => 'Anticrénelage';

  @override
  String get subpixelLCD => 'Sous-pixel (pour écrans LCD)';

  @override
  String get standardGrayscale => 'Standard (niveaux de gris)';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get preview => 'Aperçu:';

  @override
  String get noImageSelected => 'Aucune image sélectionnée';

  @override
  String get command => 'Commande:';

  @override
  String get comment => 'Commentaire:';

  @override
  String get enabledApps => 'Applications Activées';

  @override
  String get disabledApps => 'Applications Désactivées';

  @override
  String get noStartupAppsFound => 'Aucune application au démarrage trouvée.';

  @override
  String get enabledStatus => 'Activée';

  @override
  String get disabledStatus => 'Désactivée';

  @override
  String get styles => 'Styles';

  @override
  String get cursor => 'Curseur';

  @override
  String get icons => 'Icônes';

  @override
  String get legacyApps => 'Applications Anciennes';

  @override
  String get background => 'Arrière-plan';

  @override
  String get defaultImage => 'Image par Défaut';

  @override
  String get darkImage => 'Image Style Sombre';

  @override
  String get adjustment => 'Ajustement';

  @override
  String get noneOption => 'Aucun';

  @override
  String get wallpaper => 'Fond d\'écran';

  @override
  String get centered => 'Centré';

  @override
  String get scaled => 'Redimensionné';

  @override
  String get stretched => 'Étiré';

  @override
  String get zoom => 'Zoom';

  @override
  String get spanned => 'Étendu';

  @override
  String get windowBehavior => 'Comportement des Fenêtres';

  @override
  String get titlebarButtons => 'Boutons de la Barre de Titre';

  @override
  String get clickActions => 'Actions de Clic';

  @override
  String get windowFocus => 'Focus de la Fenêtre';

  @override
  String get doubleClick => 'Double Clic';

  @override
  String get middleClick => 'Clic Central';

  @override
  String get rightClick => 'Clic Droit';

  @override
  String get toggleMaximize => 'Basculer Maximiser';

  @override
  String get toggleMaximizeHorizontal => 'Basculer Maximiser Horizontalement';

  @override
  String get toggleMaximizeVertical => 'Basculer Maximiser Verticalement';

  @override
  String get toggleShade => 'Basculer Ombre';

  @override
  String get toggleMenu => 'Basculer Menu';

  @override
  String get lower => 'Réduire';

  @override
  String get menu => 'Menu';

  @override
  String get clickForFocus => 'Clic pour le focus';

  @override
  String get focusOnHover => 'Focus au survol';

  @override
  String get focusFollowsMouse => 'Le focus suit la souris';

  @override
  String get clickForFocusDesc =>
      'Les fenêtres auront le focus lorsque vous cliquez dessus.';

  @override
  String get focusOnHoverDesc =>
      'La fenêtre a le focus lorsque vous passez la souris dessus. Les fenêtres conservent le focus lorsque vous passez sur le bureau.';

  @override
  String get focusFollowsMouseDesc =>
      'La fenêtre a le focus lorsque vous passez la souris dessus. Passer sur le bureau supprime le focus de la fenêtre précédente.';

  @override
  String get someProcessesNotTerminated =>
      'Certains processus n\'ont pas été terminés correctement';

  @override
  String get errorDisabling => 'Erreur lors de la désactivation';

  @override
  String appReEnabled(String appName) {
    return 'Application $appName réactivée';
  }

  @override
  String get errorEnabling => 'Erreur lors de l\'activation';

  @override
  String removeAppFromStartup(String appName) {
    return 'Voulez-vous supprimer $appName du démarrage?';
  }

  @override
  String appRemoved(String appName) {
    return 'Application $appName supprimée';
  }

  @override
  String get errorRemoving => 'Erreur lors de la suppression';

  @override
  String get terminateProcesses => 'Terminer les Processus';

  @override
  String get noProcessesRunning =>
      'Aucun processus en cours d\'exécution pour cette application';

  @override
  String get cache => 'Cache';

  @override
  String get swap => 'Swap';

  @override
  String get filesystem => 'Système de fichiers';

  @override
  String get temperatureUnit => '°C';

  @override
  String get removing => 'Suppression en cours...';

  @override
  String get versionLabel => 'Version:';

  @override
  String get selectBasePath => 'Sélectionner le chemin de base:';

  @override
  String get root => 'Racine';

  @override
  String get home => 'Accueil';

  @override
  String get externalDisks => 'Disques externes:';

  @override
  String get selectPathToAnalyze => 'Sélectionner un chemin à analyser';

  @override
  String get totalSize => 'Taille totale';

  @override
  String get files => 'Fichiers';

  @override
  String get directories => 'Répertoires';

  @override
  String get excluded => 'Exclu';

  @override
  String get exclude => 'Exclure';

  @override
  String get include => 'Inclure';

  @override
  String get analyzing => 'Analyse en cours...';

  @override
  String get addExcludedFolder => 'Ajouter un Dossier Exclu';

  @override
  String get enterFolderPath =>
      'Entrez le chemin du dossier à exclure du nettoyage:';

  @override
  String get folderPath => 'Chemin du dossier';

  @override
  String get folderExcluded => 'Dossier ajouté aux exclusions';

  @override
  String get folderNotFound => 'Dossier introuvable';

  @override
  String get add => 'Ajouter';

  @override
  String get goBack => 'Retour';

  @override
  String get goForward => 'Avancer';

  @override
  String get goToRoot => 'Aller à la racine';

  @override
  String get moveToTrash => 'Déplacer vers la corbeille';

  @override
  String moveToTrashConfirm(String name) {
    return 'Voulez-vous déplacer \"$name\" vers la corbeille?';
  }

  @override
  String get move => 'Déplacer';

  @override
  String get movedToTrash => 'Déplacé vers la corbeille';

  @override
  String get errorMovingToTrash =>
      'Erreur lors du déplacement vers la corbeille';

  @override
  String get deleteFromRootWarning => 'AVERTISSEMENT: Suppression depuis Root';

  @override
  String deleteFromRootMessage(String name) {
    return 'Vous êtes sur le point de supprimer \"$name\" du répertoire racine du système. Cette opération nécessite des privilèges d\'administrateur et peut être irréversible. Êtes-vous sûr de vouloir continuer?';
  }

  @override
  String get deletePermanently => 'Supprimer Définitivement';

  @override
  String get emptyDirectory => 'Répertoire vide';

  @override
  String get cannotPreviewFile => 'Impossible de prévisualiser le fichier';

  @override
  String get fileType => 'Type de fichier';

  @override
  String get unknown => 'Inconnu';

  @override
  String get directory => 'Répertoire';

  @override
  String get file => 'Fichier';

  @override
  String get rename => 'Renommer';

  @override
  String get newName => 'Nouveau nom';

  @override
  String get details => 'Détails';

  @override
  String get renamedSuccessfully => 'Renommé avec succès';

  @override
  String get renameError => 'Erreur lors du renommage';

  @override
  String get type => 'Type';

  @override
  String get permissions => 'Permissions';

  @override
  String get owner => 'Propriétaire';

  @override
  String get modified => 'Modifié';

  @override
  String get path => 'Chemin';

  @override
  String get usedSpace => 'Espace Utilisé';

  @override
  String get freeSpace => 'Espace Libre';

  @override
  String get pages => 'Pages';

  @override
  String get title => 'Titre';

  @override
  String get artist => 'Artiste';

  @override
  String get duration => 'Durée';

  @override
  String get bitrate => 'Débit';

  @override
  String get resolution => 'Résolution';

  @override
  String get codec => 'Codec';

  @override
  String get showSystemFiles => 'Afficher les fichiers système';

  @override
  String get hideSystemFiles => 'Masquer les fichiers système';

  @override
  String appDisabled(String appName) {
    return 'Application $appName désactivée';
  }

  @override
  String appDisabledAndProcessesTerminated(String appName) {
    return 'Application $appName désactivée et processus terminés';
  }

  @override
  String terminateProcessesQuestion(int count, String appName) {
    return 'Voulez-vous terminer $count processus de \"$appName\"?';
  }

  @override
  String get totalSpaceToFree => 'Espace total à libérer:';

  @override
  String get foldersWithErrors => 'Dossiers avec erreurs:';

  @override
  String andOthers(int count) {
    return 'et $count autres';
  }

  @override
  String get recoveryDescription =>
      'Cette section contient des outils pour restaurer les fonctions système altérées. Les commandes sont automatiquement adaptées en fonction de la distribution Linux détectée.';

  @override
  String get recoveryRestartPipewire => 'Redémarrer Pipewire';

  @override
  String get recoveryRestartPipewireDesc =>
      'Redémarre les services Pipewire, Pipewire-Pulse et Wireplumber pour corriger les problèmes audio.';

  @override
  String get recoveryRestoreNetwork => 'Restaurer les Services Réseau';

  @override
  String get recoveryRestoreNetworkDesc =>
      'Redémarre les services réseau (NetworkManager, systemd-networkd) pour corriger les problèmes de connexion.';

  @override
  String get recoveryRebuildGrub => 'Reconstruire GRUB';

  @override
  String get recoveryRebuildGrubDesc =>
      'Reconstruit la configuration GRUB et met à jour le chargeur de démarrage. Une sauvegarde automatique est créée.';

  @override
  String get recoveryRestoreFlathub => 'Restaurer Flathub';

  @override
  String get recoveryRestoreFlathubDesc =>
      'Restaure le dépôt Flathub pour Flatpak et met à jour les métadonnées des applications.';

  @override
  String get recoveryRestoreRepos => 'Restaurer les Dépôts';

  @override
  String get recoveryRestoreReposDesc =>
      'Met à jour et restaure les dépôts du gestionnaire de paquets (APT, DNF, Pacman) pour corriger les problèmes de mise à jour.';

  @override
  String get recoveryCheckUpdates => 'Vérifier les Mises à Jour';

  @override
  String get recoveryCheckUpdatesDesc =>
      'Vérifie les mises à jour disponibles pour tous les gestionnaires de paquets installés (APT, DNF, Pacman, Snap, Flatpak).';

  @override
  String get recoveryPerformUpdates => 'Effectuer les Mises à Jour';

  @override
  String get recoveryPerformUpdatesConfirm =>
      'Voulez-vous effectuer les mises à jour disponibles? Cette opération peut prendre un certain temps.';

  @override
  String get execute => 'Exécuter';

  @override
  String get viewOutput => 'Voir la Sortie';

  @override
  String get infoServices => 'Services';

  @override
  String get infoServicesAnalysis => 'Analyse des services système';

  @override
  String get infoServicesAnalysisDesc =>
      'Identifie les services qui ralentissent le démarrage du système en utilisant systemd-analyze blame';

  @override
  String get infoServicesManagement => 'Gestion des services';

  @override
  String get infoServicesManagementDesc =>
      'Active, désactive et redémarre les services système avec un contrôle complet';

  @override
  String get infoServicesStatus => 'Affichage du statut';

  @override
  String get infoServicesStatusDesc =>
      'Affiche le statut de tous les services (actifs, inactifs, échoués)';

  @override
  String get infoStartupApps => 'Apps au Démarrage';

  @override
  String get infoStartupAppsManagement =>
      'Gestion des applications au démarrage';

  @override
  String get infoStartupAppsManagementDesc =>
      'Voir et gérer toutes les applications qui démarrent automatiquement';

  @override
  String get infoStartupAppsProtection => 'Protection des apps système';

  @override
  String get infoStartupAppsProtectionDesc =>
      'Empêche la désactivation accidentelle d\'applications système critiques';

  @override
  String get infoStartupAppsTermination => 'Terminaison des processus';

  @override
  String get infoStartupAppsTerminationDesc =>
      'Option pour terminer les processus d\'une app lorsqu\'elle est désactivée';

  @override
  String get infoCleanup => 'Nettoyage du Système';

  @override
  String get infoCleanupTempFiles => 'Recherche de fichiers temporaires';

  @override
  String get infoCleanupTempFilesDesc =>
      'Trouve automatiquement les fichiers temporaires d\'applications courantes (navigateur, IDE, développement)';

  @override
  String get infoCleanupCache => 'Nettoyage du cache';

  @override
  String get infoCleanupCacheDesc =>
      'Supprime le cache système et des applications pour libérer de l\'espace';

  @override
  String get infoCleanupTrash => 'Gestion de la corbeille';

  @override
  String get infoCleanupTrashDesc =>
      'Vide la corbeille et nettoie les fichiers temporaires en toute sécurité';

  @override
  String get infoInstalledApps => 'Apps Installées';

  @override
  String get infoInstalledAppsManagement => 'Gestion de plusieurs paquets';

  @override
  String get infoInstalledAppsManagementDesc =>
      'Voir les apps installées via APT, Snap, Flatpak et GNOME';

  @override
  String get infoInstalledAppsDependencies => 'Vérification des dépendances';

  @override
  String get infoInstalledAppsDependenciesDesc =>
      'Vérifie les dépendances avant la suppression pour éviter les problèmes';

  @override
  String get infoInstalledAppsWarnings => 'Avertissements de sécurité';

  @override
  String get infoInstalledAppsWarningsDesc =>
      'Avertit lorsqu\'un paquet est utilisé par d\'autres logiciels ou le système';

  @override
  String get infoMonitor => 'Moniteur Système';

  @override
  String get infoMonitorProcesses => 'Surveillance des processus';

  @override
  String get infoMonitorProcessesDesc =>
      'Voir tous les processus actifs avec utilisation CPU, mémoire et disque';

  @override
  String get infoMonitorSorting => 'Tri avancé';

  @override
  String get infoMonitorSortingDesc =>
      'Trie les processus par CPU ou mémoire en ordre croissant ou décroissant';

  @override
  String get infoMonitorTermination => 'Terminaison des processus';

  @override
  String get infoMonitorTerminationDesc =>
      'Termine les processus qui ne répondent pas directement depuis l\'interface';

  @override
  String get infoMonitorSystemInfo => 'Informations système';

  @override
  String get infoMonitorSystemInfoDesc =>
      'Affiche les détails sur CPU, RAM, disques et carte graphique';

  @override
  String get infoAppearance => 'Personnalisation de l\'Apparence';

  @override
  String get infoAppearanceFonts => 'Gestion des polices';

  @override
  String get infoAppearanceFontsDesc =>
      'Configure les polices pour l\'interface, les documents et le texte monospace avec aperçus';

  @override
  String get infoAppearanceRendering => 'Rendu avancé';

  @override
  String get infoAppearanceRenderingDesc =>
      'Contrôle le hinting, l\'antialiasing et le facteur d\'échelle';

  @override
  String get infoAppearanceThemes => 'Thèmes et icônes';

  @override
  String get infoAppearanceThemesDesc =>
      'Personnalise les thèmes de curseur, icônes et applications héritées avec aperçus';

  @override
  String get infoAppearanceWallpaper => 'Fond d\'écran';

  @override
  String get infoAppearanceWallpaperDesc =>
      'Définit les images de fond pour le thème clair et sombre';

  @override
  String get infoAppearanceWindows => 'Comportement des fenêtres';

  @override
  String get infoAppearanceWindowsDesc =>
      'Configure les actions de clic, les boutons de la barre de titre et le focus des fenêtres';

  @override
  String get infoGrub => 'Éditeur GRUB (Mode Avancé)';

  @override
  String get infoGrubEditor => 'Éditeur de configuration GRUB';

  @override
  String get infoGrubEditorDesc =>
      'Modifie directement le fichier /etc/default/grub avec éditeur intégré';

  @override
  String get infoGrubBackup => 'Sauvegarde automatique';

  @override
  String get infoGrubBackupDesc =>
      'Crée des sauvegardes automatiques avant chaque modification';

  @override
  String get infoGrubUpdate => 'Mise à jour GRUB';

  @override
  String get infoGrubUpdateDesc =>
      'Applique les modifications et met à jour le chargeur de démarrage';

  @override
  String get infoGrubRestore => 'Restauration de sauvegarde';

  @override
  String get infoGrubRestoreDesc =>
      'Restaure facilement une configuration précédente';

  @override
  String get infoKernel => 'Gestion du Kernel (Mode Avancé)';

  @override
  String get infoKernelList => 'Liste des kernels installés';

  @override
  String get infoKernelListDesc =>
      'Voir tous les kernels installés avec version et taille';

  @override
  String get infoKernelRemoval => 'Suppression du kernel';

  @override
  String get infoKernelRemovalDesc =>
      'Supprime les anciens kernels en toute sécurité (protège le kernel actuel)';

  @override
  String get infoKernelDefault => 'Paramètre kernel par défaut';

  @override
  String get infoKernelDefaultDesc => 'Choisit quel kernel démarrer par défaut';

  @override
  String get infoKernelCleanup => 'Nettoyage automatique';

  @override
  String get infoKernelCleanupDesc =>
      'Conserve uniquement un nombre spécifié de kernels les plus récents';

  @override
  String get infoSecurity => 'Sécurité';

  @override
  String get infoSecurityPassword => 'Gestion des mots de passe';

  @override
  String get infoSecurityPasswordDesc =>
      'Enregistre le mot de passe administrateur en toute sécurité pour les opérations sudo';

  @override
  String get infoSecurityWarning => 'Avertissement utilisateurs experts';

  @override
  String get infoSecurityWarningDesc =>
      'Écran d\'avertissement initial pour utilisateurs experts';

  @override
  String get infoSecurityMode => 'Mode Standard/Avancé';

  @override
  String get infoSecurityModeDesc =>
      'Sépare les fonctionnalités de base des avancées (GRUB, Kernel)';

  @override
  String get recoveryCheckUpdatesComplete =>
      'Recherche de mises à jour terminée';

  @override
  String recoveryCheckUpdatesError(String error) {
    return 'Erreur lors de la recherche de mises à jour: $error';
  }

  @override
  String get diskAnalyzerMainDirectories => 'Répertoires Principaux';

  @override
  String get hardwareSuggestionsTitle =>
      'Suggestions GRUB basées sur le Matériel';

  @override
  String get hardwareSuggestionsDescription =>
      'Les suggestions suivantes sont basées sur l\'analyse de votre configuration matérielle:';

  @override
  String get hardwareSuggestionsPriorityHigh => 'Élevée';

  @override
  String get hardwareSuggestionsPriorityMedium => 'Moyenne';

  @override
  String get hardwareSuggestionsPriorityLow => 'Faible';

  @override
  String get hardwareSuggestionsApply => 'Appliquer';

  @override
  String get hardwareSuggestionsCancel => 'Annuler';

  @override
  String get settingsPasswordSecurityMessage =>
      'Le mot de passe est enregistré en toute sécurité à l\'aide du trousseau système.';

  @override
  String get tabShutdownScheduler => 'Arrêt Automatique';

  @override
  String get shutdownInfoTitle => 'Arrêt Automatique';

  @override
  String get shutdownInfoDescription =>
      'Configurez l\'arrêt automatique du PC à des heures programmées. Utilise les temporisateurs systemd pour garantir la compatibilité avec toutes les distributions Linux modernes.';

  @override
  String get shutdownSystemdRequired => 'systemd Requis';

  @override
  String get shutdownSystemdRequiredDesc =>
      'Cette fonctionnalité nécessite systemd, disponible sur Fedora, Ubuntu, Arch, Debian et autres distributions Linux modernes.';

  @override
  String get shutdownPasswordRequired =>
      'Mot de passe requis. Configurez le mot de passe dans les paramètres.';

  @override
  String get shutdownActiveTimers => 'Temporisateurs Actifs';

  @override
  String get shutdownCreateTimer => 'Créer un Nouveau Temporisateur';

  @override
  String get shutdownScheduleType => 'Type de Planification';

  @override
  String get shutdownScheduleDaily => 'Quotidienne';

  @override
  String get shutdownScheduleWeekly => 'Hebdomadaire';

  @override
  String get shutdownScheduleMonthly => 'Mensuelle';

  @override
  String get shutdownTime => 'Heure';

  @override
  String get shutdownSelectTime => 'Sélectionner l\'Heure';

  @override
  String get shutdownSelectDays => 'Sélectionner les Jours';

  @override
  String get shutdownSelectDayOfMonth => 'Sélectionner le Jour du Mois';

  @override
  String get shutdownDayOfMonth => 'Jour du Mois';

  @override
  String get shutdownDaySunday => 'Dimanche';

  @override
  String get shutdownDayMonday => 'Lundi';

  @override
  String get shutdownDayTuesday => 'Mardi';

  @override
  String get shutdownDayWednesday => 'Mercredi';

  @override
  String get shutdownDayThursday => 'Jeudi';

  @override
  String get shutdownDayFriday => 'Vendredi';

  @override
  String get shutdownDaySaturday => 'Samedi';

  @override
  String get shutdownTimerCreated => 'Temporisateur d\'arrêt créé avec succès';

  @override
  String get shutdownTimerRemoved =>
      'Temporisateur d\'arrêt supprimé avec succès';

  @override
  String get shutdownRemoveConfirm =>
      'Voulez-vous supprimer ce temporisateur d\'arrêt?';

  @override
  String get shutdownNextRun => 'Prochaine exécution';

  @override
  String get shutdownStatusInactive => 'Inactif';

  @override
  String get shutdownWeeklyDaysRequired =>
      'Sélectionnez au moins un jour de la semaine';

  @override
  String get shutdownMonthlyDayRequired => 'Sélectionnez un jour du mois';

  @override
  String get shutdownOpenSettings => 'Ouvrir les Paramètres';

  @override
  String get shutdownEditTimer => 'Modifier le Temporisateur';

  @override
  String get shutdownTimerDetails => 'Détails du Temporisateur';

  @override
  String get diskCacheGenerating =>
      'Lecture et génération du cache en cours... (première fois uniquement)';

  @override
  String get licenseActivate => 'Activer la version avancée';

  @override
  String get licenseActivateButton => 'Activer';

  @override
  String get licenseName => 'Prénom';

  @override
  String get licenseSurname => 'Nom';

  @override
  String get licenseEmail => 'E-mail';

  @override
  String get licenseCode => 'Code de licence';

  @override
  String get licenseRequired => 'Ce champ est obligatoire';

  @override
  String get licenseActivateSuccess => 'Version avancée activée avec succès.';

  @override
  String get licenseActivateError =>
      'Code invalide. Vérifiez nom, prénom et e-mail.';

  @override
  String get licenseActivatePremium => 'Activer / Premium';

  @override
  String get licenseActivateCardTitle => 'Activer la version avancée';

  @override
  String get licenseActivateCardDesc =>
      'Entrez vos informations et le code de licence reçu pour débloquer GRUB, Kernel et Recovery.';
}
