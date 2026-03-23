// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Super Linux Utility';

  @override
  String get appAlreadyRunning => 'Die Anwendung läuft bereits.';

  @override
  String get trayCheckUpdates => 'System-Updates prüfen';

  @override
  String get trayCleanLinuxCache => 'Linux-Cache leeren';

  @override
  String get trayRemoveTempFiles => 'Temporäre Dateien entfernen';

  @override
  String get trayCleanTempFilesAndCache =>
      'Temporäre Dateien und Cache bereinigen';

  @override
  String get trayCleanVram => 'VRAM leeren (GPU-Reset)';

  @override
  String get trayCpuGpuTemp => 'CPU-, GPU-Temperatur';

  @override
  String get trayDiskUsage => 'Festplattennutzung';

  @override
  String get trayMemoryUsage => 'Speichernutzung';

  @override
  String get trayShutdownTimer => 'Automatisches Herunterfahren';

  @override
  String get trayShowMainWindow => 'Hauptfenster anzeigen';

  @override
  String get trayCpuGpuUsage => 'CPU-, GPU-Auslastung';

  @override
  String get trayExit => 'Beenden';

  @override
  String get cleanupLinuxCache => 'Cache leeren';

  @override
  String get cleanupLinuxCacheDesc =>
      'Kernel-Seitencache leeren (drop_caches). Erfordert Administratorpasswort.';

  @override
  String get cleanupLinuxCacheSuccess => 'Linux-Cache erfolgreich geleert.';

  @override
  String get cleanupLinuxCacheError => 'Fehler beim Leeren des Caches.';

  @override
  String get cleanupVram => 'VRAM leeren';

  @override
  String get cleanupVramConfirmTitle => 'GPU-Reset';

  @override
  String get cleanupVramConfirmMessage =>
      'Ich versuche, die Grafikkarte zurückzusetzen, um die VRAM freizugeben. Erfordert ein Administratorpasswort und kann eine temporäre Unterbrechung des Bildschirms verursachen. Fortfahren?';

  @override
  String get cleanupVramSuccess => 'VRAM erfolgreich geleert (GPU-Reset).';

  @override
  String get cleanupVramError =>
      'VRAM konnte nicht geleert werden (GPU-Reset fehlgeschlagen).';

  @override
  String get tabServices => 'Dienste';

  @override
  String get tabStartupApps => 'Startprogramme';

  @override
  String get tabCleanup => 'Bereinigung';

  @override
  String get tabInstalledApps => 'Installierte Apps';

  @override
  String get tabMonitor => 'Monitor';

  @override
  String get tabDiskAnalyzer => 'Festplatten-Analysator';

  @override
  String get tabAppearance => 'GNOME Erscheinungsbild';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabRecovery => 'System-Wiederherstellung';

  @override
  String get tabGrub => 'GRUB';

  @override
  String get tabKernel => 'Kernel';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get modeStandard => 'Standard';

  @override
  String get modeAdvanced => 'Erweitert';

  @override
  String get warningTitle => 'WARNUNG';

  @override
  String get warningSubtitle => 'Anwendung für Experten';

  @override
  String get warningMessage =>
      'Diese Anwendung ermöglicht die Änderung kritischer Konfigurationen des Linux-Betriebssystems.';

  @override
  String get warningGrub => 'GRUB-Änderungen';

  @override
  String get warningGrubDesc =>
      'Eine falsche Änderung des Bootloaders kann verhindern, dass das System startet.';

  @override
  String get warningKernel => 'Kernel-Entfernung';

  @override
  String get warningKernelDesc =>
      'Das Entfernen essentieller Kernel kann das System unbrauchbar machen.';

  @override
  String get warningServices => 'Dienstverwaltung';

  @override
  String get warningServicesDesc =>
      'Das Deaktivieren kritischer Dienste kann zu Systemfehlfunktionen führen.';

  @override
  String get warningCleanup => 'Dateibereinigung';

  @override
  String get warningCleanupDesc =>
      'Das Löschen von Systemdateien kann die Stabilität beeinträchtigen.';

  @override
  String get warningBackup =>
      'Es wird empfohlen, vor der Verwendung dieser Anwendung ein System-Backup zu erstellen.';

  @override
  String get warningDontShow => 'Diese Warnung nicht mehr anzeigen';

  @override
  String get warningAccept => 'Verstanden, Fortfahren';

  @override
  String get passwordSetupTitle => 'Passwort-Konfiguration';

  @override
  String get passwordSetupDesc =>
      'Um Funktionen zu verwenden, die Administratorrechte erfordern, müssen Sie das Systempasswort konfigurieren.';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get passwordHint => 'Administrator-Passwort eingeben';

  @override
  String get passwordConfirm => 'Passwort Bestätigen';

  @override
  String get passwordConfirmHint => 'Passwort erneut eingeben';

  @override
  String get passwordSave => 'Passwort Speichern';

  @override
  String get passwordSkip => 'Jetzt Überspringen';

  @override
  String get passwordSaved =>
      'Passwort sicher im System-Schlüsselbund gespeichert.';

  @override
  String get passwordError => 'Fehler beim Speichern';

  @override
  String get passwordMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get passwordEmpty => 'Passwort eingeben';

  @override
  String get passwordRequired => 'Passwort Erforderlich';

  @override
  String get passwordRequiredMessage =>
      'Administrator-Passwort ist erforderlich, um auf alle Verzeichnisse zuzugreifen. Das Passwort wird sicher gespeichert.';

  @override
  String get settingsPasswordTitle => 'Administrator-Passwort';

  @override
  String get settingsPasswordDesc =>
      'Speichern Sie das Administrator-Passwort, um Funktionen zu verwenden, die sudo-Rechte erfordern.';

  @override
  String get settingsPasswordSaved =>
      'Passwort gespeichert. Sie können es ändern oder löschen.';

  @override
  String get settingsPasswordConfigured => 'Passwort konfiguriert';

  @override
  String get settingsPasswordUpdate => 'Passwort Aktualisieren';

  @override
  String get settingsPasswordDelete => 'Löschen';

  @override
  String get settingsThemeTitle => 'Anwendungs-Design';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemDesc => 'Folgt den Systemeinstellungen';

  @override
  String get settingsInfoTitle => 'Informationen';

  @override
  String get settingsInfoDesc => 'Diese Anwendung hilft Ihnen:';

  @override
  String get settingsInfoItem1 =>
      'systemd-Dienste finden, die den Start verlangsamen';

  @override
  String get settingsInfoItem2 => 'Startprogramme verwalten';

  @override
  String get settingsInfoItem3 => 'Temporäre Systemdateien bereinigen';

  @override
  String get loading => 'Lädt...';

  @override
  String get loadingSettings => 'Systemeinstellungen werden geladen';

  @override
  String get error => 'Fehler';

  @override
  String get retry => 'Wiederholen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get themeRestartMessage =>
      'Das Design wird nach dem Neustart der Anwendung angewendet';

  @override
  String get themeApplied => 'Design erfolgreich angewendet';

  @override
  String get settingsFontTitle => 'Schriftart und Textgröße';

  @override
  String get settingsFontDesc =>
      'Passen Sie die Schriftart und Textgröße an, die in der gesamten Anwendung verwendet wird.';

  @override
  String get settingsSystemTrayTitle => 'System Tray';

  @override
  String get settingsSystemTrayDesc =>
      'App-Symbol in der Systemleiste für Schnellaktionen anzeigen. Erfordert Systemabhängigkeiten (libappindicator).';

  @override
  String get settingsTrayDepsOk => 'Abhängigkeiten installiert.';

  @override
  String get settingsTrayDepsMissing =>
      'Abhängigkeiten fehlen. Installieren Sie sie, um die Systemleiste zu aktivieren.';

  @override
  String get settingsSystemTrayEnable => 'System Tray aktivieren';

  @override
  String get settingsTrayInstallDeps => 'Abhängigkeiten installieren';

  @override
  String get settingsCloseToTray => 'Beim Schließen in Tray belassen';

  @override
  String get settingsCloseToTrayDesc =>
      'Wenn aktiviert, bleibt die App beim Schließen oder Minimieren des Fensters in der Systemleiste.';

  @override
  String get settingsCloseToTrayOn => 'In Tray belassen aktiviert.';

  @override
  String get settingsCloseToTrayOff =>
      'In Tray belassen deaktiviert. Schließen beendet die App.';

  @override
  String get settingsTrayEnabled => 'System Tray aktiviert.';

  @override
  String get settingsTrayDisabled =>
      'System Tray deaktiviert. App neu starten, um zu übernehmen.';

  @override
  String get settingsStartMinimized => 'App minimiert in Tray starten';

  @override
  String get settingsStartMinimizedDesc =>
      'Wenn aktiviert, startet die App ohne Hauptfenster, nur mit Tray-Symbol.';

  @override
  String get settingsStartMinimizedOn =>
      'Minimiert starten aktiviert. Beim nächsten Start nur in Tray.';

  @override
  String get settingsStartMinimizedOff => 'Minimiert starten deaktiviert.';

  @override
  String get settingsStartAtLogin => 'App beim Systemstart starten';

  @override
  String get settingsStartAtLoginDesc =>
      'Wenn aktiviert, startet die App automatisch bei der Anmeldung.';

  @override
  String get settingsStartAtLoginOn => 'Start bei Anmeldung aktiviert.';

  @override
  String get settingsStartAtLoginOff => 'Start bei Anmeldung deaktiviert.';

  @override
  String get settingsStartAtLoginError =>
      'Einstellung „Start bei Anmeldung“ konnte nicht geändert werden.';

  @override
  String get settingsAutoUpdateCheckTitle => 'Automatische Update-Prüfung';

  @override
  String get settingsAutoUpdateCheckDesc =>
      'Systemupdates automatisch in der gewählten Zeitspanne prüfen.';

  @override
  String get settingsAutoUpdateCheckInterval => 'Nach Updates suchen';

  @override
  String get settingsAutoUpdateNever => 'Nie';

  @override
  String get settingsAutoUpdateEvery15Min => 'Alle 15 Minuten';

  @override
  String get settingsAutoUpdateEvery30Min => 'Alle 30 Minuten';

  @override
  String get settingsAutoUpdateEvery1Hour => 'Jede Stunde';

  @override
  String get settingsAutoUpdateEvery6Hours => 'Alle 6 Stunden';

  @override
  String get settingsAutoUpdateEvery12Hours => 'Alle 12 Stunden';

  @override
  String get settingsAutoUpdateEveryDay => 'Täglich';

  @override
  String get settingsAutoAppUpdateFromGithubTitle =>
      'App automatisch von GitHub aktualisieren';

  @override
  String get settingsAutoAppUpdateFromGithubDesc =>
      'Wenn aktiviert, lädt die App regelmäßig das neueste .deb dieser Edition von den GitHub-Releases herunter und installiert es. Erfordert ein gespeichertes Administratorpasswort und die automatische Systemupdate-Prüfung oben muss aktiviert sein.';

  @override
  String get updateCheckAptNone => 'APT: Keine Updates verfügbar';

  @override
  String get updateCheckAptPhasedOnly =>
      'APT: Derzeit keine sofort installierbaren Updates (nur gestaffeltes Rollout)';

  @override
  String updateCheckAptHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APT: $count Updates verfügbar',
      one: 'APT: $count Update verfügbar',
    );
    return '$_temp0';
  }

  @override
  String updateCheckAptPhasedExtra(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APT: $count gestaffelte Updates erkannt',
      one: 'APT: $count gestaffeltes Update erkannt',
    );
    return '$_temp0';
  }

  @override
  String updateCheckAptError(String error) {
    return 'APT: Fehler bei der Prüfung: $error';
  }

  @override
  String get updateCheckDnfNone => 'DNF: Keine Updates verfügbar';

  @override
  String updateCheckDnfHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DNF: $count Updates verfügbar',
      one: 'DNF: $count Update verfügbar',
    );
    return '$_temp0';
  }

  @override
  String updateCheckDnfError(String error) {
    return 'DNF: Fehler bei der Prüfung: $error';
  }

  @override
  String get updateCheckPacmanNone => 'Pacman: Keine Updates verfügbar';

  @override
  String updateCheckPacmanHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pacman: $count Updates verfügbar',
      one: 'Pacman: $count Update verfügbar',
    );
    return '$_temp0';
  }

  @override
  String updateCheckPacmanError(String error) {
    return 'Pacman: Fehler bei der Prüfung: $error';
  }

  @override
  String get updateCheckSnapNone => 'Snap: Keine Updates verfügbar';

  @override
  String updateCheckSnapHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Snap: $count Updates verfügbar',
      one: 'Snap: $count Update verfügbar',
    );
    return '$_temp0';
  }

  @override
  String updateCheckSnapError(String error) {
    return 'Snap: Fehler bei der Prüfung: $error';
  }

  @override
  String get updateCheckFlatpakNone => 'Flatpak: Keine Updates verfügbar';

  @override
  String updateCheckFlatpakHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flatpak: $count Updates verfügbar',
      one: 'Flatpak: $count Update verfügbar',
    );
    return '$_temp0';
  }

  @override
  String updateCheckFlatpakError(String error) {
    return 'Flatpak: Fehler bei der Prüfung: $error';
  }

  @override
  String updateCheckSummaryPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pakete',
      one: '$count Paket',
      zero: '0 Pakete',
    );
    return '$_temp0';
  }

  @override
  String updatesAvailableCount(int count) {
    return '$count Updates verfügbar';
  }

  @override
  String get updatesAvailableDialogTitle => 'Updates verfügbar';

  @override
  String updatesAvailableDialogMessage(int count) {
    return '$count Updates verfügbar. Möchten Sie sie jetzt anwenden?';
  }

  @override
  String get applyNow => 'Jetzt anwenden';

  @override
  String get postpone => 'Später';

  @override
  String get fontFamily => 'Schriftfamilie';

  @override
  String get fontSize => 'Textgröße';

  @override
  String get fontDefault => 'Standard (Roboto)';

  @override
  String get fontRestartMessage =>
      'Die Schriftart wird nach dem Neustart der Anwendung angewendet';

  @override
  String get themeApplyError => 'Fehler beim Anwenden des Designs';

  @override
  String get userThemesExtensionMessage =>
      'Für vollständige Shell-Designs installieren Sie die User Themes-Erweiterung von extensions.gnome.org';

  @override
  String get themeRequiresOcsUrl =>
      'Dieses Design erfordert ocs-url für die korrekte Installation';

  @override
  String get installOcsUrl => 'ocs-url installieren';

  @override
  String get ocsUrlNotInstalled =>
      'ocs-url ist nicht installiert. Einige Designs funktionieren möglicherweise nicht korrekt.';

  @override
  String get ocsUrlInstalled => 'ocs-url erfolgreich installiert!';

  @override
  String get ocsUrlInstallError =>
      'Fehler beim Installieren von ocs-url. Überprüfen Sie, ob das Passwort korrekt ist und ob der Paketmanager verfügbar ist.';

  @override
  String get installingOcsUrl => 'ocs-url wird installiert...';

  @override
  String get installingOcsUrlDescription =>
      'Diese Operation wird beim ersten Start automatisch ausgeführt.';

  @override
  String get themeToolsMessage =>
      'Um Designs von OpenDesktop.org/Pling.com zu installieren, installieren Sie ocs-url oder PLing-store. Einige Designs erfordern diese Tools, um korrekt zu funktionieren.';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get search => 'Suchen';

  @override
  String get noResults => 'Keine Ergebnisse gefunden';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get active => 'Aktiv';

  @override
  String get inactive => 'Inaktiv';

  @override
  String get start => 'Starten';

  @override
  String get stop => 'Stoppen';

  @override
  String get restart => 'Neustarten';

  @override
  String get enable => 'Aktivieren';

  @override
  String get disable => 'Deaktivieren';

  @override
  String get remove => 'Entfernen';

  @override
  String get kill => 'Beenden';

  @override
  String get killForce => 'Erzwingen Beenden';

  @override
  String get processes => 'Prozesse';

  @override
  String get system => 'System';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => 'Arbeitsspeicher';

  @override
  String get disk => 'Festplatte';

  @override
  String get gpu => 'Grafikkarte';

  @override
  String get usage => 'Nutzung';

  @override
  String get total => 'Gesamt';

  @override
  String get used => 'Verwendet';

  @override
  String get free => 'Frei';

  @override
  String get model => 'Modell';

  @override
  String get driver => 'Treiber';

  @override
  String get temperature => 'Temperatur';

  @override
  String get version => 'Version';

  @override
  String get creator => 'Ersteller';

  @override
  String get creatorName => 'Marco Di Giangiacomo';

  @override
  String get appDescription =>
      'Super Linux Utility ist eine vollständige Anwendung für die erweiterte Linux-Systemverwaltung. Sie bietet leistungsstarke Tools zur Leistungsoptimierung, Verwaltung von Diensten, Anwendungen und Anpassung des System-Erscheinungsbilds.';

  @override
  String get features => 'Funktionen';

  @override
  String get appExpertUsers => 'Anwendung für Linux-Experten entwickelt';

  @override
  String get infoProjectWebsite => 'Projekt-Website';

  @override
  String get applicationIdLabel => 'Anwendungs-ID (Desktop)';

  @override
  String get updatesPendingPackagesTitle =>
      'Ausstehende Pakete (letzte Prüfung)';

  @override
  String updatesProgressCurrent(String detail) {
    return 'Fortschritt: $detail';
  }

  @override
  String get updatesCommandOutputTitle => 'Befehlsausgabe';

  @override
  String get disclaimerLicenseTitle => 'Lizenz und Haftungsausschluss';

  @override
  String get disclaimerGplNotice =>
      'Diese Anwendung ist freie Software; Sie können sie unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, Version 3 der Lizenz oder (nach Ihrer Wahl) einer späteren Version weiterverbreiten und/oder modifizieren.';

  @override
  String get disclaimerNoWarranty =>
      'Dieses Programm wird in der Hoffnung verteilt, dass es nützlich ist, aber OHNE JEDE GEWÄHRLEISTUNG; ohne sogar die implizite Gewährleistung der MARKTGÄNGIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK. Weitere Details finden Sie in der GNU General Public License.';

  @override
  String get disclaimerCopyright =>
      'Copyright (c) 2024-2025 Marco Di Giangiacomo. Alle Rechte vorbehalten unter GPL-3.0.';

  @override
  String get payWithPaypal => 'Mit PayPal bezahlen';

  @override
  String get purchaseLicenseViaPaypal =>
      'Die Advanced-Version kostet 19,99 €. Um eine Lizenz zu erwerben, zahlen Sie per PayPal. Nach erfolgreicher Zahlung erhalten Sie Ihren Lizenzschlüssel per E-Mail. Ohne gültige Zahlung kann die Anwendung nicht aktiviert werden.';

  @override
  String get languageSelectionTitle => 'Sprachauswahl';

  @override
  String get languageSelectionDesc =>
      'Wählen Sie die Sprache für die Anwendung';

  @override
  String get languageItalian => 'Italienisch';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageSpanish => 'Spanisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languagePortuguese => 'Portugiesisch';

  @override
  String get settingsLanguageTitle => 'Anwendungssprache';

  @override
  String get settingsLanguageDesc =>
      'Wählen Sie die Sprache der Benutzeroberfläche';

  @override
  String get languageRestartMessage =>
      'Die Sprache wird beim Neustart der Anwendung angewendet';

  @override
  String get servicesSlow => 'Langsame Dienste';

  @override
  String get servicesAll => 'Alle Dienste';

  @override
  String get servicesDisabled => 'Deaktiviert';

  @override
  String get analyzeAll => 'Alle Analysieren';

  @override
  String get status => 'Status';

  @override
  String get startupTime => 'Startzeit';

  @override
  String get noServicesFound => 'Keine Dienste gefunden.';

  @override
  String get reEnable => 'Reaktivieren';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get cleanupConfirmTitle => 'Bereinigung bestätigen';

  @override
  String get cleanupConfirmMessage =>
      'Möchten Sie alle temporären Dateien löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get cleanupSuccess => 'Bereinigung erfolgreich abgeschlossen!';

  @override
  String get cleanupPartialSuccess =>
      'Bereinigung mit einigen Fehlern abgeschlossen.';

  @override
  String get protectedSystemApp => 'Geschützte Systemanwendung';

  @override
  String cannotDisableSystemApp(String appName) {
    return '\"$appName\" kann nicht deaktiviert werden, da es eine wesentliche Systemanwendung ist.';
  }

  @override
  String get systemAppsRequired =>
      'Systemanwendungen sind für das ordnungsgemäße Funktionieren der Desktop-Umgebung erforderlich und können nicht deaktiviert werden.';

  @override
  String get checkingDependencies => 'Abhängigkeiten werden überprüft...';

  @override
  String get warning => '⚠️ Warnung';

  @override
  String get packagesDependingOnThis => 'Pakete, die davon abhängen:';

  @override
  String get areYouSure => 'Sind Sie sicher, dass Sie fortfahren möchten?';

  @override
  String get confirmRemoval => 'Entfernung bestätigen';

  @override
  String removeAppQuestion(String appName) {
    return 'Möchten Sie $appName entfernen?';
  }

  @override
  String get searchApp => 'App suchen';

  @override
  String get all => 'Alle';

  @override
  String get searchProcess => 'Prozess suchen';

  @override
  String processesSelected(int count) {
    return '$count Prozess ausgewählt';
  }

  @override
  String processesSelectedPlural(int count) {
    return '$count Prozesse ausgewählt';
  }

  @override
  String get app => 'App';

  @override
  String get cpuPercent => 'CPU %';

  @override
  String get name => 'Name';

  @override
  String get pid => 'PID';

  @override
  String get user => 'Benutzer';

  @override
  String get noProcessesFound => 'Keine Prozesse gefunden.';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get terminateAll => 'Alle beenden';

  @override
  String get terminateAllForce => 'Alle erzwingen beenden';

  @override
  String get cannotLoadSystemInfo =>
      'Systeminformationen können nicht geladen werden.';

  @override
  String get cores => 'Kerne';

  @override
  String get threads => 'Threads';

  @override
  String get grubInvalidContent => 'GRUB-Dateiinhalt ist nicht gültig';

  @override
  String get grubConfirmSave => 'Speichern bestätigen';

  @override
  String get grubSaveWarning =>
      'Sie sind dabei, die GRUB-Konfiguration zu ändern. Diese Operation:';

  @override
  String get grubWillCreateBackup => '• Erstellt ein automatisches Backup';

  @override
  String get grubWillSave => '• Speichert die Änderungen';

  @override
  String get grubWillUpdate => '• Aktualisiert GRUB';

  @override
  String get grubWarning =>
      'WARNUNG: Falsche Änderungen können verhindern, dass das System startet!';

  @override
  String get saveAndUpdate => 'Speichern und aktualisieren';

  @override
  String get grubSavedSuccess =>
      'GRUB-Konfiguration erfolgreich gespeichert und aktualisiert';

  @override
  String get grubSaveError => 'Fehler beim Speichern';

  @override
  String get reload => 'Neu laden';

  @override
  String get restoreBackup => 'Backup wiederherstellen';

  @override
  String get restoreBackupQuestion =>
      'Möchten Sie das GRUB-Konfigurations-Backup wiederherstellen?';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get backupRestoredSuccess => 'Backup erfolgreich wiederhergestellt';

  @override
  String get backupRestoreError => 'Fehler beim Wiederherstellen des Backups';

  @override
  String get kernelCannotRemoveActive =>
      'Derzeit aktiven Kernel kann nicht entfernt werden';

  @override
  String get removeKernel => 'Kernel entfernen';

  @override
  String removeKernelQuestion(String version) {
    return 'Möchten Sie den Kernel $version entfernen?';
  }

  @override
  String get thisOperation => 'Diese Operation:';

  @override
  String get willRemovePackage => '• Entfernt das Kernel-Paket';

  @override
  String get willUpdateGrub => '• Aktualisiert GRUB';

  @override
  String get kernelWarning =>
      'WARNUNG: Stellen Sie sicher, dass Sie mindestens einen funktionierenden Kernel haben!';

  @override
  String kernelRemovedSuccess(String version) {
    return 'Kernel $version erfolgreich entfernt';
  }

  @override
  String get kernelRemoveError => 'Fehler beim Entfernen des Kernels';

  @override
  String get setDefaultKernel => 'Standard-Kernel festlegen';

  @override
  String setDefaultKernelQuestion(String version) {
    return 'Möchten Sie $version als Standard-Kernel festlegen?';
  }

  @override
  String get set => 'Festlegen';

  @override
  String kernelSetDefaultSuccess(String version) {
    return 'Kernel $version als Standard festgelegt';
  }

  @override
  String get kernelSetDefaultError =>
      'Fehler beim Festlegen des Standard-Kernels';

  @override
  String get keepMax => 'Maximal behalten:';

  @override
  String get cleanupKernels => 'Kernel-Bereinigung';

  @override
  String keepOnlyRecentKernels(int count) {
    return 'Möchten Sie nur die $count neuesten Kernel behalten?';
  }

  @override
  String totalKernels(int count) {
    return 'Kernel insgesamt: $count';
  }

  @override
  String kernelsToKeep(int count) {
    return 'Zu behaltende Kernel: $count';
  }

  @override
  String kernelsToRemove(int count) {
    return 'Zu entfernende Kernel: $count';
  }

  @override
  String get cleanupKernelsWarning =>
      'WARNUNG: Es werden nur nicht verwendete Kernel entfernt.';

  @override
  String get cleanup => 'Bereinigen';

  @override
  String get kernelCleanupSuccess =>
      'Kernel-Bereinigung erfolgreich abgeschlossen';

  @override
  String get kernelCleanupError => 'Fehler bei der Kernel-Bereinigung';

  @override
  String get invalidKernelCount =>
      'Geben Sie eine gültige Anzahl von zu behaltenden Kerneln ein';

  @override
  String get noKernelsFound => 'Keine installierten Kernel gefunden';

  @override
  String get updateGrub => 'GRUB aktualisieren';

  @override
  String get updateGrubQuestion =>
      'Möchten Sie GRUB aktualisieren? Dieser Vorgang aktualisiert die Bootloader-Konfiguration.';

  @override
  String get grubUpdateSuccess => 'GRUB erfolgreich aktualisiert';

  @override
  String get grubUpdateError => 'Fehler beim Aktualisieren von GRUB';

  @override
  String get rebootSystem => 'System neu starten';

  @override
  String get rebootSystemQuestion =>
      'Möchten Sie das System neu starten? Alle geöffneten Anwendungen werden geschlossen.';

  @override
  String get rebootSystemSuccess => 'Das System wird neu gestartet...';

  @override
  String get rebootSystemError => 'Fehler beim Neustarten des Systems';

  @override
  String get package => 'Paket';

  @override
  String get size => 'Größe';

  @override
  String get setAsDefault => 'Als Standard festlegen';

  @override
  String get refreshDimensions => 'Dimensionen aktualisieren';

  @override
  String get cleanupTempFiles => 'Temporäre Dateien bereinigen';

  @override
  String get disableApp => 'App deaktivieren';

  @override
  String get onlyDisable => 'Nur deaktivieren';

  @override
  String get systemApps => 'System-Apps';

  @override
  String get close => 'Schließen';

  @override
  String get updateStartupApps => 'Startprogramme aktualisieren';

  @override
  String get saving => 'Speichern...';

  @override
  String get scaleFactor => 'Skalierungsfaktor:';

  @override
  String get maximize => 'Maximieren';

  @override
  String get minimize => 'Minimieren';

  @override
  String get positioning => 'Positionierung:';

  @override
  String get left => 'Links';

  @override
  String get right => 'Rechts';

  @override
  String get buttonOrder => 'Schaltflächenreihenfolge:';

  @override
  String get attachedDialogs => 'Angehängte Dialoge';

  @override
  String get centerNewWindows => 'Neue Fenster zentrieren';

  @override
  String get resizeWithSecondaryClick => 'Mit sekundärem Klick ändern';

  @override
  String get raiseOnFocus => 'Fenster anheben, wenn sie den Fokus haben';

  @override
  String get backgroundImageUpdated => 'Hintergrundbild aktualisiert!';

  @override
  String get backgroundImageError => 'Fehler beim Aktualisieren des Bildes.';

  @override
  String get preferredFonts => 'Bevorzugte Schriftarten';

  @override
  String get interfaceText => 'Interface-Text';

  @override
  String get documentText => 'Dokument-Text';

  @override
  String get fixedWidthText => 'Text mit fester Breite';

  @override
  String get rendering => 'Rendering';

  @override
  String get hinting => 'Hinting';

  @override
  String get full => 'Voll';

  @override
  String get medium => 'Mittel';

  @override
  String get light => 'Leicht';

  @override
  String get antialiasing => 'Kantenglättung';

  @override
  String get subpixelLCD => 'Subpixel (für LCD-Bildschirme)';

  @override
  String get standardGrayscale => 'Standard (Graustufen)';

  @override
  String get dimensions => 'Abmessungen';

  @override
  String get preview => 'Vorschau:';

  @override
  String get noImageSelected => 'Kein Bild ausgewählt';

  @override
  String get command => 'Befehl:';

  @override
  String get comment => 'Kommentar:';

  @override
  String get enabledApps => 'Aktivierte Apps';

  @override
  String get disabledApps => 'Deaktivierte Apps';

  @override
  String get noStartupAppsFound => 'Keine Startprogramme gefunden.';

  @override
  String get enabledStatus => 'Aktiviert';

  @override
  String get disabledStatus => 'Deaktiviert';

  @override
  String get styles => 'Stile';

  @override
  String get cursor => 'Cursor';

  @override
  String get icons => 'Symbole';

  @override
  String get legacyApps => 'Legacy-Anwendungen';

  @override
  String get background => 'Hintergrund';

  @override
  String get defaultImage => 'Standardbild';

  @override
  String get darkImage => 'Dunkles Stilbild';

  @override
  String get adjustment => 'Anpassung';

  @override
  String get noneOption => 'Keine';

  @override
  String get wallpaper => 'Hintergrundbild';

  @override
  String get centered => 'Zentriert';

  @override
  String get scaled => 'Skaliert';

  @override
  String get stretched => 'Gestreckt';

  @override
  String get zoom => 'Zoom';

  @override
  String get spanned => 'Überspannt';

  @override
  String get windowBehavior => 'Fensterverhalten';

  @override
  String get titlebarButtons => 'Titelleisten-Schaltflächen';

  @override
  String get clickActions => 'Klick-Aktionen';

  @override
  String get windowFocus => 'Fensterfokus';

  @override
  String get doubleClick => 'Doppelklick';

  @override
  String get middleClick => 'Mittlerer Klick';

  @override
  String get rightClick => 'Rechtsklick';

  @override
  String get toggleMaximize => 'Maximieren Umschalten';

  @override
  String get toggleMaximizeHorizontal => 'Maximieren Horizontal Umschalten';

  @override
  String get toggleMaximizeVertical => 'Maximieren Vertikal Umschalten';

  @override
  String get toggleShade => 'Schatten Umschalten';

  @override
  String get toggleMenu => 'Menü Umschalten';

  @override
  String get lower => 'Senken';

  @override
  String get menu => 'Menü';

  @override
  String get clickForFocus => 'Klicken für Fokus';

  @override
  String get focusOnHover => 'Fokus beim Überfahren';

  @override
  String get focusFollowsMouse => 'Fokus folgt Maus';

  @override
  String get clickForFocusDesc =>
      'Fenster haben Fokus, wenn Sie darauf klicken.';

  @override
  String get focusOnHoverDesc =>
      'Das Fenster hat Fokus, wenn Sie mit der Maus darüber fahren. Fenster behalten Fokus beim Überfahren des Desktops.';

  @override
  String get focusFollowsMouseDesc =>
      'Das Fenster hat Fokus, wenn Sie mit der Maus darüber fahren. Überfahren des Desktops entfernt Fokus vom vorherigen Fenster.';

  @override
  String get someProcessesNotTerminated =>
      'Einige Prozesse wurden nicht korrekt beendet';

  @override
  String get errorDisabling => 'Fehler beim Deaktivieren';

  @override
  String appReEnabled(String appName) {
    return 'App $appName reaktiviert';
  }

  @override
  String get errorEnabling => 'Fehler beim Aktivieren';

  @override
  String removeAppFromStartup(String appName) {
    return 'Möchten Sie $appName vom Start entfernen?';
  }

  @override
  String appRemoved(String appName) {
    return 'App $appName entfernt';
  }

  @override
  String get errorRemoving => 'Fehler beim Entfernen';

  @override
  String get terminateProcesses => 'Prozesse Beenden';

  @override
  String get noProcessesRunning => 'Keine Prozesse für diese App laufen';

  @override
  String get cache => 'Cache';

  @override
  String get swap => 'Swap';

  @override
  String get filesystem => 'Dateisystem';

  @override
  String get temperatureUnit => '°C';

  @override
  String get removing => 'Entfernen...';

  @override
  String get versionLabel => 'Version:';

  @override
  String get selectBasePath => 'Basis-Pfad auswählen:';

  @override
  String get root => 'Root';

  @override
  String get home => 'Home';

  @override
  String get externalDisks => 'Externe Festplatten:';

  @override
  String get selectPathToAnalyze => 'Einen Pfad zum Analysieren auswählen';

  @override
  String get totalSize => 'Gesamtgröße';

  @override
  String get files => 'Dateien';

  @override
  String get directories => 'Verzeichnisse';

  @override
  String get excluded => 'Ausgeschlossen';

  @override
  String get exclude => 'Ausschließen';

  @override
  String get include => 'Einschließen';

  @override
  String get analyzing => 'Analysiere...';

  @override
  String get addExcludedFolder => 'Ausgeschlossenen Ordner Hinzufügen';

  @override
  String get enterFolderPath =>
      'Geben Sie den Pfad des Ordners ein, der von der Bereinigung ausgeschlossen werden soll:';

  @override
  String get folderPath => 'Ordnerpfad';

  @override
  String get folderExcluded => 'Ordner zu Ausschlüssen hinzugefügt';

  @override
  String get folderNotFound => 'Ordner nicht gefunden';

  @override
  String get add => 'Hinzufügen';

  @override
  String get goBack => 'Zurück';

  @override
  String get goForward => 'Vorwärts';

  @override
  String get goToRoot => 'Zur Wurzel gehen';

  @override
  String get moveToTrash => 'In den Papierkorb verschieben';

  @override
  String moveToTrashConfirm(String name) {
    return 'Möchten Sie \"$name\" in den Papierkorb verschieben?';
  }

  @override
  String get move => 'Verschieben';

  @override
  String get movedToTrash => 'In den Papierkorb verschoben';

  @override
  String get errorMovingToTrash => 'Fehler beim Verschieben in den Papierkorb';

  @override
  String get deleteFromRootWarning => 'WARNUNG: Löschen aus Root';

  @override
  String deleteFromRootMessage(String name) {
    return 'Sie sind dabei, \"$name\" aus dem System-Root-Verzeichnis zu löschen. Dieser Vorgang erfordert Administratorrechte und kann irreversibel sein. Sind Sie sicher, dass Sie fortfahren möchten?';
  }

  @override
  String get deletePermanently => 'Dauerhaft löschen';

  @override
  String get emptyDirectory => 'Leeres Verzeichnis';

  @override
  String get cannotPreviewFile => 'Datei kann nicht angezeigt werden';

  @override
  String get fileType => 'Dateityp';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get directory => 'Verzeichnis';

  @override
  String get file => 'Datei';

  @override
  String get rename => 'Umbenennen';

  @override
  String get newName => 'Neuer Name';

  @override
  String get details => 'Details';

  @override
  String get renamedSuccessfully => 'Erfolgreich umbenannt';

  @override
  String get renameError => 'Fehler beim Umbenennen';

  @override
  String get type => 'Typ';

  @override
  String get permissions => 'Berechtigungen';

  @override
  String get owner => 'Eigentümer';

  @override
  String get modified => 'Geändert';

  @override
  String get path => 'Pfad';

  @override
  String get usedSpace => 'Belegter Speicher';

  @override
  String get freeSpace => 'Freier Speicher';

  @override
  String get pages => 'Seiten';

  @override
  String get title => 'Titel';

  @override
  String get artist => 'Künstler';

  @override
  String get duration => 'Dauer';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get resolution => 'Auflösung';

  @override
  String get codec => 'Codec';

  @override
  String get showSystemFiles => 'Systemdateien anzeigen';

  @override
  String get hideSystemFiles => 'Systemdateien ausblenden';

  @override
  String appDisabled(String appName) {
    return 'App $appName deaktiviert';
  }

  @override
  String appDisabledAndProcessesTerminated(String appName) {
    return 'App $appName deaktiviert und Prozesse beendet';
  }

  @override
  String terminateProcessesQuestion(int count, String appName) {
    return 'Möchten Sie $count Prozess/e von \"$appName\" beenden?';
  }

  @override
  String get totalSpaceToFree => 'Gesamter Speicherplatz zum Freigeben:';

  @override
  String get foldersWithErrors => 'Ordner mit Fehlern:';

  @override
  String andOthers(int count) {
    return 'und $count weitere';
  }

  @override
  String get recoveryDescription =>
      'Dieser Abschnitt enthält Tools zur Wiederherstellung geänderter Systemfunktionen. Befehle werden automatisch an die erkannte Linux-Distribution angepasst.';

  @override
  String get recoveryRestartPipewire => 'Pipewire Neustarten';

  @override
  String get recoveryRestartPipewireDesc =>
      'Startet Pipewire, Pipewire-Pulse und Wireplumber-Dienste neu, um Audio-Probleme zu beheben.';

  @override
  String get recoveryRestoreNetwork => 'Netzwerkdienste Wiederherstellen';

  @override
  String get recoveryRestoreNetworkDesc =>
      'Startet Netzwerkdienste (NetworkManager, systemd-networkd) neu, um Verbindungsprobleme zu beheben.';

  @override
  String get recoveryRebuildGrub => 'GRUB Neu Erstellen';

  @override
  String get recoveryRebuildGrubDesc =>
      'Erstellt die GRUB-Konfiguration neu und aktualisiert den Bootloader. Ein automatisches Backup wird erstellt.';

  @override
  String get recoveryRestoreFlathub => 'Flathub Wiederherstellen';

  @override
  String get recoveryRestoreFlathubDesc =>
      'Stellt das Flathub-Repository für Flatpak wieder her und aktualisiert App-Metadaten.';

  @override
  String get recoveryRestoreRepos => 'Repositorys Wiederherstellen';

  @override
  String get recoveryRestoreReposDesc =>
      'Aktualisiert und stellt Paketmanager-Repositorys (APT, DNF, Pacman) wieder her, um Update-Probleme zu beheben.';

  @override
  String get recoveryCheckUpdates => 'Nach Updates Suchen';

  @override
  String get recoveryCheckUpdatesDesc =>
      'Sucht nach verfügbaren Updates für alle installierten Paketmanager (APT, DNF, Pacman, Snap, Flatpak).';

  @override
  String get recoveryPerformUpdates => 'Updates Durchführen';

  @override
  String get recoveryPerformUpdatesConfirm =>
      'Möchten Sie die verfügbaren Updates durchführen? Dieser Vorgang kann einige Zeit dauern.';

  @override
  String get recoveryTabRecovery => 'Recovery';

  @override
  String get recoveryTabCheckUpdates => 'Nach Updates suchen';

  @override
  String get recoveryTabSoftwareInstaller => 'System-Software-Installer';

  @override
  String get recoverySoftwareInstallerDesc =>
      'Lädt und installiert wichtige Systemsoftware automatisch.';

  @override
  String get recoveryInstallFfmpeg => 'FFmpeg';

  @override
  String get recoveryInstallFfmpegDesc =>
      'Multimedia-Framework für Audio- und Video-Enkodierung/-Dekodierung.';

  @override
  String get recoveryInstallYtDlp => 'yt-dlp';

  @override
  String get recoveryInstallYtDlpDesc => 'Video-Downloader für viele Websites.';

  @override
  String get recoveryInstallSystemLibs => 'Systembibliotheken';

  @override
  String get recoveryInstallSystemLibsDesc =>
      'Wichtige Systembibliotheken, die oft benötigt werden und beschädigt werden können.';

  @override
  String get recoveryInstallCodecs => 'Video- und Audiocodecs';

  @override
  String get recoveryInstallCodecsDesc =>
      'Codecs für gängige Video- und Audioformate.';

  @override
  String get recoveryInstallRsync => 'rsync';

  @override
  String get recoveryInstallRsyncDesc =>
      'Effizientes Tool für Dateisync und -übertragung.';

  @override
  String get install => 'Installieren';

  @override
  String get execute => 'Ausführen';

  @override
  String get viewOutput => 'Ausgabe Anzeigen';

  @override
  String get infoServices => 'Dienste';

  @override
  String get infoServicesAnalysis => 'Systemdienstanalyse';

  @override
  String get infoServicesAnalysisDesc =>
      'Identifiziert Dienste, die den Systemstart verlangsamen, mit systemd-analyze blame';

  @override
  String get infoServicesManagement => 'Dienstverwaltung';

  @override
  String get infoServicesManagementDesc =>
      'Aktivieren, deaktivieren und Neustarten von Systemdiensten mit vollständiger Kontrolle';

  @override
  String get infoServicesStatus => 'Statusanzeige';

  @override
  String get infoServicesStatusDesc =>
      'Zeigt den Status aller Dienste an (aktiv, inaktiv, fehlgeschlagen)';

  @override
  String get infoStartupApps => 'Start-Apps';

  @override
  String get infoStartupAppsManagement => 'Verwaltung von Startanwendungen';

  @override
  String get infoStartupAppsManagementDesc =>
      'Anzeigen und Verwalten aller Anwendungen, die automatisch starten';

  @override
  String get infoStartupAppsProtection => 'System-App-Schutz';

  @override
  String get infoStartupAppsProtectionDesc =>
      'Verhindert versehentliches Deaktivieren kritischer Systemanwendungen';

  @override
  String get infoStartupAppsTermination => 'Prozessbeendigung';

  @override
  String get infoStartupAppsTerminationDesc =>
      'Option zum Beenden von App-Prozessen beim Deaktivieren';

  @override
  String get infoCleanup => 'Systembereinigung';

  @override
  String get infoCleanupTempFiles => 'Suche nach temporären Dateien';

  @override
  String get infoCleanupTempFilesDesc =>
      'Findet automatisch temporäre Dateien von gängigen Anwendungen (Browser, IDE, Entwicklung)';

  @override
  String get infoCleanupCache => 'Cache-Bereinigung';

  @override
  String get infoCleanupCacheDesc =>
      'Löscht System- und Anwendungscache, um Speicherplatz freizugeben';

  @override
  String get infoCleanupTrash => 'Papierkorbverwaltung';

  @override
  String get infoCleanupTrashDesc =>
      'Leert den Papierkorb und bereinigt temporäre Dateien sicher';

  @override
  String get infoInstalledApps => 'Installierte Apps';

  @override
  String get infoInstalledAppsManagement => 'Verwaltung mehrerer Pakete';

  @override
  String get infoInstalledAppsManagementDesc =>
      'Zeigt Apps an, die über APT, Snap, Flatpak und GNOME installiert wurden';

  @override
  String get infoInstalledAppsDependencies => 'Abhängigkeitsprüfung';

  @override
  String get infoInstalledAppsDependenciesDesc =>
      'Prüft Abhängigkeiten vor dem Entfernen, um Probleme zu vermeiden';

  @override
  String get infoInstalledAppsWarnings => 'Sicherheitswarnungen';

  @override
  String get infoInstalledAppsWarningsDesc =>
      'Warnt, wenn ein Paket von anderer Software oder dem System verwendet wird';

  @override
  String get infoMonitor => 'Systemmonitor';

  @override
  String get infoMonitorProcesses => 'Prozessüberwachung';

  @override
  String get infoMonitorProcessesDesc =>
      'Zeigt alle aktiven Prozesse mit CPU-, Speicher- und Festplattennutzung an';

  @override
  String get infoMonitorSorting => 'Erweiterte Sortierung';

  @override
  String get infoMonitorSortingDesc =>
      'Sortiert Prozesse nach CPU oder Speicher in auf- oder absteigender Reihenfolge';

  @override
  String get infoMonitorTermination => 'Prozessbeendigung';

  @override
  String get infoMonitorTerminationDesc =>
      'Beendet nicht reagierende Prozesse direkt über die Benutzeroberfläche';

  @override
  String get infoMonitorSystemInfo => 'Systeminformationen';

  @override
  String get infoMonitorSystemInfoDesc =>
      'Zeigt Details zu CPU, RAM, Festplatten und Grafikkarte an';

  @override
  String get infoAppearance => 'Erscheinungsbild-Anpassung';

  @override
  String get infoAppearanceFonts => 'Schriftartenverwaltung';

  @override
  String get infoAppearanceFontsDesc =>
      'Konfiguriert Schriftarten für Benutzeroberfläche, Dokumente und Monospace-Text mit Vorschau';

  @override
  String get infoAppearanceRendering => 'Erweiterte Darstellung';

  @override
  String get infoAppearanceRenderingDesc =>
      'Steuert Hinting, Antialiasing und Skalierungsfaktor';

  @override
  String get infoAppearanceThemes => 'Designs und Symbole';

  @override
  String get infoAppearanceThemesDesc =>
      'Passt Cursor-Designs, Symbole und Legacy-Anwendungen mit Vorschau an';

  @override
  String get infoAppearanceWallpaper => 'Desktop-Hintergrund';

  @override
  String get infoAppearanceWallpaperDesc =>
      'Legt Hintergrundbilder für helles und dunkles Design fest';

  @override
  String get infoAppearanceWindows => 'Fensterverhalten';

  @override
  String get infoAppearanceWindowsDesc =>
      'Konfiguriert Klickaktionen, Titelleisten-Schaltflächen und Fensterfokus';

  @override
  String get infoGrub => 'GRUB-Editor (Erweiterter Modus)';

  @override
  String get infoGrubEditor => 'GRUB-Konfigurationseditor';

  @override
  String get infoGrubEditorDesc =>
      'Bearbeitet die Datei /etc/default/grub direkt mit integriertem Editor';

  @override
  String get infoGrubBackup => 'Automatische Sicherung';

  @override
  String get infoGrubBackupDesc =>
      'Erstellt automatische Sicherungen vor jeder Änderung';

  @override
  String get infoGrubUpdate => 'GRUB-Update';

  @override
  String get infoGrubUpdateDesc =>
      'Wendet Änderungen an und aktualisiert den Bootloader';

  @override
  String get infoGrubRestore => 'Sicherungswiederherstellung';

  @override
  String get infoGrubRestoreDesc =>
      'Stellt eine vorherige Konfiguration einfach wieder her';

  @override
  String get infoKernel => 'Kernel-Verwaltung (Erweiterter Modus)';

  @override
  String get infoKernelList => 'Liste installierter Kernel';

  @override
  String get infoKernelListDesc =>
      'Zeigt alle installierten Kernel mit Version und Größe an';

  @override
  String get infoKernelRemoval => 'Kernel-Entfernung';

  @override
  String get infoKernelRemovalDesc =>
      'Entfernt alte Kernel sicher (schützt aktuellen Kernel)';

  @override
  String get infoKernelDefault => 'Standard-Kernel-Einstellung';

  @override
  String get infoKernelDefaultDesc =>
      'Wählt, welcher Kernel standardmäßig gestartet werden soll';

  @override
  String get infoKernelCleanup => 'Automatische Bereinigung';

  @override
  String get infoKernelCleanupDesc =>
      'Behält nur eine bestimmte Anzahl der neuesten Kernel';

  @override
  String get infoSecurity => 'Sicherheit';

  @override
  String get infoSecurityPassword => 'Passwortverwaltung';

  @override
  String get infoSecurityPasswordDesc =>
      'Speichert das Administrator-Passwort sicher für sudo-Operationen';

  @override
  String get infoSecurityWarning => 'Warnung für erfahrene Benutzer';

  @override
  String get infoSecurityWarningDesc =>
      'Anfänglicher Warnbildschirm für erfahrene Benutzer';

  @override
  String get infoSecurityMode => 'Standard/Erweiterter Modus';

  @override
  String get infoSecurityModeDesc =>
      'Trennt grundlegende Funktionen von erweiterten (GRUB, Kernel)';

  @override
  String get recoveryCheckUpdatesComplete =>
      'Aktualisierungssuche abgeschlossen';

  @override
  String recoveryCheckUpdatesError(String error) {
    return 'Fehler bei der Aktualisierungssuche: $error';
  }

  @override
  String get diskAnalyzerMainDirectories => 'Hauptverzeichnisse';

  @override
  String get hardwareSuggestionsTitle =>
      'GRUB-Vorschläge basierend auf Hardware';

  @override
  String get hardwareSuggestionsDescription =>
      'Die folgenden Vorschläge basieren auf der Analyse Ihrer Hardware-Konfiguration:';

  @override
  String get hardwareSuggestionsPriorityHigh => 'Hoch';

  @override
  String get hardwareSuggestionsPriorityMedium => 'Mittel';

  @override
  String get hardwareSuggestionsPriorityLow => 'Niedrig';

  @override
  String get hardwareSuggestionsApply => 'Anwenden';

  @override
  String get hardwareSuggestionsCancel => 'Abbrechen';

  @override
  String get settingsPasswordSecurityMessage =>
      'Das Passwort wird sicher im System-Keyring gespeichert.';

  @override
  String get tabShutdownScheduler => 'Automatisches Herunterfahren';

  @override
  String get shutdownInfoTitle => 'Automatisches Herunterfahren';

  @override
  String get shutdownInfoDescription =>
      'Konfigurieren Sie das automatische Herunterfahren des PCs zu festgelegten Zeiten. Verwendet systemd-Timer für Kompatibilität mit allen modernen Linux-Distributionen.';

  @override
  String get shutdownSystemdRequired => 'systemd Erforderlich';

  @override
  String get shutdownSystemdRequiredDesc =>
      'Diese Funktion erfordert systemd, verfügbar auf Fedora, Ubuntu, Arch, Debian und anderen modernen Linux-Distributionen.';

  @override
  String get shutdownPasswordRequired =>
      'Passwort erforderlich. Konfigurieren Sie das Passwort in den Einstellungen.';

  @override
  String get shutdownActiveTimers => 'Aktive Timer';

  @override
  String get shutdownCreateTimer => 'Neuen Timer Erstellen';

  @override
  String get shutdownScheduleType => 'Zeitplantyp';

  @override
  String get shutdownScheduleDaily => 'Täglich';

  @override
  String get shutdownScheduleWeekly => 'Wöchentlich';

  @override
  String get shutdownScheduleMonthly => 'Monatlich';

  @override
  String get shutdownTime => 'Zeit';

  @override
  String get shutdownSelectTime => 'Zeit Auswählen';

  @override
  String get shutdownSelectDays => 'Tage Auswählen';

  @override
  String get shutdownSelectDayOfMonth => 'Tag des Monats Auswählen';

  @override
  String get shutdownDayOfMonth => 'Tag des Monats';

  @override
  String get shutdownDaySunday => 'Sonntag';

  @override
  String get shutdownDayMonday => 'Montag';

  @override
  String get shutdownDayTuesday => 'Dienstag';

  @override
  String get shutdownDayWednesday => 'Mittwoch';

  @override
  String get shutdownDayThursday => 'Donnerstag';

  @override
  String get shutdownDayFriday => 'Freitag';

  @override
  String get shutdownDaySaturday => 'Samstag';

  @override
  String get shutdownTimerCreated => 'Herunterfahr-Timer erfolgreich erstellt';

  @override
  String get shutdownTimerRemoved => 'Herunterfahr-Timer erfolgreich entfernt';

  @override
  String get shutdownRemoveConfirm =>
      'Möchten Sie diesen Herunterfahr-Timer entfernen?';

  @override
  String get shutdownNextRun => 'Nächste Ausführung';

  @override
  String get shutdownStatusInactive => 'Inaktiv';

  @override
  String get shutdownWeeklyDaysRequired =>
      'Wählen Sie mindestens einen Tag der Woche aus';

  @override
  String get shutdownMonthlyDayRequired =>
      'Wählen Sie einen Tag des Monats aus';

  @override
  String get shutdownOpenSettings => 'Einstellungen Öffnen';

  @override
  String get shutdownEditTimer => 'Timer Bearbeiten';

  @override
  String get shutdownTimerDetails => 'Timer-Details';

  @override
  String get diskCacheGenerating =>
      'Cache wird gelesen und generiert... (nur beim ersten Mal)';

  @override
  String get licenseActivate => 'Erweiterte Version aktivieren';

  @override
  String get licenseActivateButton => 'Aktivieren';

  @override
  String get licenseName => 'Vorname';

  @override
  String get licenseSurname => 'Nachname';

  @override
  String get licenseEmail => 'E-Mail';

  @override
  String get licenseCode => 'Lizenzschlüssel';

  @override
  String get licenseRequired => 'Dieses Feld ist erforderlich';

  @override
  String get licenseActivateSuccess =>
      'Erweiterte Version erfolgreich aktiviert.';

  @override
  String get licenseActivateError =>
      'Ungültiger Code. Name, Nachname und E-Mail prüfen.';

  @override
  String get licenseActivatePremium => 'Aktivieren / Premium';

  @override
  String get licenseActivateCardTitle => 'Erweiterte Version aktivieren';

  @override
  String get licenseActivateCardDesc =>
      'Die Advanced-Version kostet 19,99 €. Geben Sie Ihre Daten und den Lizenzschlüssel ein, den Sie nach erfolgreicher Zahlung erhalten haben, um GRUB-, Kernel- und Recovery-Tools freizuschalten. Ohne gültige Zahlung kann die Anwendung nicht aktiviert werden.';
}
