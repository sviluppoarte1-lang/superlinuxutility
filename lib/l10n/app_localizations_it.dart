// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Super Linux Utility';

  @override
  String get appAlreadyRunning => 'L\'applicazione è già in esecuzione.';

  @override
  String get trayCheckUpdates => 'Verifica aggiornamenti di sistema';

  @override
  String get trayCleanLinuxCache => 'Pulisci Cache Linux';

  @override
  String get trayRemoveTempFiles => 'Rimuovi File temporanei';

  @override
  String get trayCleanTempFilesAndCache => 'Pulisci file temporanei e cache';

  @override
  String get trayCleanVram => 'Ripulisci VRAM (reset GPU)';

  @override
  String get trayCpuGpuTemp => 'Temperatura CPU, GPU';

  @override
  String get trayDiskUsage => 'Uso del disco';

  @override
  String get trayMemoryUsage => 'Uso memoria RAM';

  @override
  String get trayShutdownTimer => 'Spegnimento automatico';

  @override
  String get trayShowMainWindow => 'Visualizza schermata principale';

  @override
  String get trayCpuGpuUsage => 'Uso CPU, GPU';

  @override
  String get trayExit => 'Esci';

  @override
  String get cleanupLinuxCache => 'Pulisci Cache';

  @override
  String get cleanupLinuxCacheDesc =>
      'Svuota la cache di pagina del kernel (drop_caches). Richiede password amministratore.';

  @override
  String get cleanupLinuxCacheSuccess => 'Cache Linux pulita con successo.';

  @override
  String get cleanupLinuxCacheError => 'Errore durante la pulizia della cache.';

  @override
  String get cleanupVram => 'Pulisci VRAM';

  @override
  String get cleanupVramConfirmTitle => 'Reset della GPU';

  @override
  String get cleanupVramConfirmMessage =>
      'Proverò a resettare la scheda grafica per liberare la VRAM. Richiede password amministratore e può causare un\'interruzione temporanea dello schermo. Continuare?';

  @override
  String get cleanupVramSuccess => 'VRAM ripulita (reset GPU) con successo.';

  @override
  String get cleanupVramError =>
      'Impossibile ripulire la VRAM (reset GPU fallito).';

  @override
  String get tabServices => 'Servizi';

  @override
  String get tabStartupApps => 'App Avvio';

  @override
  String get tabCleanup => 'Pulizia';

  @override
  String get tabInstalledApps => 'App Installate';

  @override
  String get tabMonitor => 'Monitor';

  @override
  String get tabDiskAnalyzer => 'Analizzatore Disco';

  @override
  String get tabAppearance => 'Aspetto GNOME';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabRecovery => 'Recovery di Sistema';

  @override
  String get tabGrub => 'GRUB';

  @override
  String get tabKernel => 'Kernel';

  @override
  String get tabSettings => 'Impostazioni';

  @override
  String get modeStandard => 'Standard';

  @override
  String get modeAdvanced => 'Avanzata';

  @override
  String get warningTitle => 'ATTENZIONE';

  @override
  String get warningSubtitle => 'Applicazione per Utenti Esperti';

  @override
  String get warningMessage =>
      'Questa applicazione consente di modificare configurazioni critiche del sistema operativo Linux.';

  @override
  String get warningGrub => 'Modifiche a GRUB';

  @override
  String get warningGrubDesc =>
      'La modifica errata del bootloader può impedire l\'avvio del sistema.';

  @override
  String get warningKernel => 'Rimozione Kernel';

  @override
  String get warningKernelDesc =>
      'Rimuovere kernel essenziali può rendere il sistema inutilizzabile.';

  @override
  String get warningServices => 'Gestione Servizi';

  @override
  String get warningServicesDesc =>
      'Disabilitare servizi critici può causare malfunzionamenti del sistema.';

  @override
  String get warningCleanup => 'Pulizia File';

  @override
  String get warningCleanupDesc =>
      'Eliminare file di sistema può compromettere la stabilità.';

  @override
  String get warningBackup =>
      'Si consiglia di creare backup del sistema prima di utilizzare questa applicazione.';

  @override
  String get warningDontShow => 'Non mostrare più questo avviso';

  @override
  String get warningAccept => 'Ho Capito, Procedi';

  @override
  String get passwordSetupTitle => 'Configurazione Password';

  @override
  String get passwordSetupDesc =>
      'Per utilizzare le funzionalità che richiedono privilegi amministratore, è necessario configurare la password di sistema.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Inserisci la password di amministratore';

  @override
  String get passwordConfirm => 'Conferma Password';

  @override
  String get passwordConfirmHint => 'Reinserisci la password';

  @override
  String get passwordSave => 'Salva Password';

  @override
  String get passwordSkip => 'Salta per ora';

  @override
  String get passwordSaved =>
      'Password salvata in modo sicuro utilizzando il keyring del sistema.';

  @override
  String get passwordError => 'Errore durante il salvataggio';

  @override
  String get passwordMismatch => 'Le password non corrispondono';

  @override
  String get passwordEmpty => 'Inserisci una password';

  @override
  String get passwordRequired => 'Password Richiesta';

  @override
  String get passwordRequiredMessage =>
      'Per accedere a tutte le directory è necessaria la password di amministratore. La password verrà salvata in modo sicuro.';

  @override
  String get settingsPasswordTitle => 'Password Amministratore';

  @override
  String get settingsPasswordDesc =>
      'Salva la password di amministratore per utilizzare le funzionalità che richiedono privilegi sudo.';

  @override
  String get settingsPasswordSaved =>
      'Password salvata. Puoi cambiarla o eliminarla.';

  @override
  String get settingsPasswordConfigured => 'Password configurata';

  @override
  String get settingsPasswordUpdate => 'Aggiorna Password';

  @override
  String get settingsPasswordDelete => 'Elimina';

  @override
  String get settingsThemeTitle => 'Tema Applicazione';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeSystemDesc => 'Segue le impostazioni del sistema';

  @override
  String get settingsInfoTitle => 'Informazioni';

  @override
  String get settingsInfoDesc => 'Questa applicazione ti aiuta a:';

  @override
  String get settingsInfoItem1 =>
      'Trovare servizi systemd che rallentano l\'avvio';

  @override
  String get settingsInfoItem2 => 'Gestire applicazioni all\'avvio';

  @override
  String get settingsInfoItem3 => 'Pulire file temporanei del sistema';

  @override
  String get loading => 'Caricamento in corso...';

  @override
  String get loadingSettings => 'Sto caricando le impostazioni del sistema';

  @override
  String get error => 'Errore';

  @override
  String get retry => 'Riprova';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get delete => 'Elimina';

  @override
  String get save => 'Salva';

  @override
  String get themeRestartMessage =>
      'Il tema verrà applicato al riavvio dell\'applicazione';

  @override
  String get themeApplied => 'Tema applicato con successo';

  @override
  String get settingsFontTitle => 'Font e Dimensione Testo';

  @override
  String get settingsFontDesc =>
      'Personalizza il font e la dimensione del testo utilizzata in tutta l\'applicazione.';

  @override
  String get settingsSystemTrayTitle => 'System Tray';

  @override
  String get settingsSystemTrayDesc =>
      'Mostra l\'icona dell\'app nella system tray per comandi rapidi. Richiede le dipendenze di sistema (libappindicator).';

  @override
  String get settingsTrayDepsOk => 'Dipendenze installate.';

  @override
  String get settingsTrayDepsMissing =>
      'Dipendenze mancanti. Installa per abilitare la system tray.';

  @override
  String get settingsSystemTrayEnable => 'Abilita system tray';

  @override
  String get settingsTrayInstallDeps => 'Installa dipendenze';

  @override
  String get settingsCloseToTray => 'Rimani in tray alla chiusura';

  @override
  String get settingsCloseToTrayDesc =>
      'Se attivo, chiudendo o riducendo a icona la finestra l\'app resta in esecuzione nella system tray.';

  @override
  String get settingsCloseToTrayOn => 'Chiusura in tray attivata.';

  @override
  String get settingsCloseToTrayOff =>
      'Chiusura in tray disattivata. La chiusura della finestra terminerà l\'app.';

  @override
  String get settingsTrayEnabled => 'System tray abilitato.';

  @override
  String get settingsTrayDisabled =>
      'System tray disabilitato. Riavvia l\'app per applicare.';

  @override
  String get settingsStartMinimized => 'Avvia l\'app ridotta a icona';

  @override
  String get settingsStartMinimizedDesc =>
      'Se attivo, l\'app si avvia senza mostrare la finestra principale, solo l\'icona nella system tray.';

  @override
  String get settingsStartMinimizedOn =>
      'Avvio ridotto a icona attivato. Al prossimo avvio l\'app aprirà solo in tray.';

  @override
  String get settingsStartMinimizedOff => 'Avvio ridotto a icona disattivato.';

  @override
  String get settingsStartAtLogin => 'Avvia l\'app all\'avvio del sistema';

  @override
  String get settingsStartAtLoginDesc =>
      'Se attivo, l\'app si avvia automaticamente al login.';

  @override
  String get settingsStartAtLoginOn =>
      'Avvio al login attivato. L\'app si avvierà al login.';

  @override
  String get settingsStartAtLoginOff => 'Avvio al login disattivato.';

  @override
  String get settingsStartAtLoginError =>
      'Impossibile modificare l\'avvio al login.';

  @override
  String get settingsAutoUpdateCheckTitle =>
      'Verifica aggiornamenti automatica';

  @override
  String get settingsAutoUpdateCheckDesc =>
      'Controlla gli aggiornamenti di sistema automaticamente con la frequenza scelta.';

  @override
  String get settingsAutoUpdateCheckInterval => 'Verifica aggiornamenti';

  @override
  String get settingsAutoUpdateNever => 'Mai';

  @override
  String get settingsAutoUpdateEvery15Min => 'Ogni 15 minuti';

  @override
  String get settingsAutoUpdateEvery30Min => 'Ogni 30 minuti';

  @override
  String get settingsAutoUpdateEvery1Hour => 'Ogni 1 ora';

  @override
  String get settingsAutoUpdateEvery6Hours => 'Ogni 6 ore';

  @override
  String get settingsAutoUpdateEvery12Hours => 'Ogni 12 ore';

  @override
  String get settingsAutoUpdateEveryDay => 'Ogni giorno';

  @override
  String get settingsAutoAppUpdateFromGithubTitle =>
      'Aggiornamento automatico app da GitHub';

  @override
  String get settingsAutoAppUpdateFromGithubDesc =>
      'Se attivo, l\'app scarica e installa periodicamente l\'ultimo .deb di questa edizione dalle release GitHub. Richiede password amministratore salvata e funziona solo se sopra è attiva la verifica periodica aggiornamenti di sistema.';

  @override
  String get updateCheckAptNone => 'APT: Nessun aggiornamento disponibile';

  @override
  String get updateCheckAptPhasedOnly =>
      'APT: Nessun aggiornamento installabile subito (solo rollout scaglionato)';

  @override
  String updateCheckAptHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APT: $count aggiornamenti disponibili',
      one: 'APT: $count aggiornamento disponibile',
    );
    return '$_temp0';
  }

  @override
  String updateCheckAptPhasedExtra(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APT: $count aggiornamenti scaglionati rilevati',
      one: 'APT: $count aggiornamento scaglionato rilevato',
    );
    return '$_temp0';
  }

  @override
  String updateCheckAptError(String error) {
    return 'APT: Errore durante la verifica: $error';
  }

  @override
  String get updateCheckDnfNone => 'DNF: Nessun aggiornamento disponibile';

  @override
  String updateCheckDnfHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DNF: $count aggiornamenti disponibili',
      one: 'DNF: $count aggiornamento disponibile',
    );
    return '$_temp0';
  }

  @override
  String updateCheckDnfError(String error) {
    return 'DNF: Errore durante la verifica: $error';
  }

  @override
  String get updateCheckPacmanNone =>
      'Pacman: Nessun aggiornamento disponibile';

  @override
  String updateCheckPacmanHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pacman: $count aggiornamenti disponibili',
      one: 'Pacman: $count aggiornamento disponibile',
    );
    return '$_temp0';
  }

  @override
  String updateCheckPacmanError(String error) {
    return 'Pacman: Errore durante la verifica: $error';
  }

  @override
  String get updateCheckSnapNone => 'Snap: Nessun aggiornamento disponibile';

  @override
  String updateCheckSnapHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Snap: $count aggiornamenti disponibili',
      one: 'Snap: $count aggiornamento disponibile',
    );
    return '$_temp0';
  }

  @override
  String updateCheckSnapError(String error) {
    return 'Snap: Errore durante la verifica: $error';
  }

  @override
  String get updateCheckFlatpakNone =>
      'Flatpak: Nessun aggiornamento disponibile';

  @override
  String updateCheckFlatpakHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flatpak: $count aggiornamenti disponibili',
      one: 'Flatpak: $count aggiornamento disponibile',
    );
    return '$_temp0';
  }

  @override
  String updateCheckFlatpakError(String error) {
    return 'Flatpak: Errore durante la verifica: $error';
  }

  @override
  String updateCheckSummaryPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pacchetti',
      one: '$count pacchetto',
      zero: '0 pacchetti',
    );
    return '$_temp0';
  }

  @override
  String updatesAvailableCount(int count) {
    return '$count aggiornamenti disponibili';
  }

  @override
  String get updatesAvailableDialogTitle => 'Aggiornamenti disponibili';

  @override
  String updatesAvailableDialogMessage(int count) {
    return '$count aggiornamenti disponibili. Vuoi applicarli ora?';
  }

  @override
  String get applyNow => 'Applica ora';

  @override
  String get postpone => 'Rimanda';

  @override
  String get fontFamily => 'Famiglia Font';

  @override
  String get fontSize => 'Dimensione Font';

  @override
  String get fontDefault => 'Default (Roboto)';

  @override
  String get fontRestartMessage =>
      'Il font verrà applicato al riavvio dell\'applicazione';

  @override
  String get themeApplyError => 'Errore nell\'applicazione del tema';

  @override
  String get userThemesExtensionMessage =>
      'Per temi Shell completi, installa l\'estensione User Themes da extensions.gnome.org';

  @override
  String get themeRequiresOcsUrl =>
      'Questo tema richiede ocs-url per essere installato correttamente';

  @override
  String get installOcsUrl => 'Installa ocs-url';

  @override
  String get ocsUrlNotInstalled =>
      'ocs-url non è installato. Alcuni temi potrebbero non funzionare correttamente.';

  @override
  String get ocsUrlInstalled => 'ocs-url installato con successo!';

  @override
  String get ocsUrlInstallError =>
      'Errore durante l\'installazione di ocs-url. Verifica che la password sia corretta e che il package manager sia disponibile.';

  @override
  String get installingOcsUrl => 'Installazione ocs-url in corso...';

  @override
  String get installingOcsUrlDescription =>
      'Questa operazione viene eseguita automaticamente al primo avvio.';

  @override
  String get themeToolsMessage =>
      'Per installare temi da OpenDesktop.org/Pling.com, installa ocs-url o PLing-store. Alcuni temi richiedono questi strumenti per funzionare correttamente.';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get search => 'Cerca';

  @override
  String get noResults => 'Nessun risultato trovato';

  @override
  String get enabled => 'Abilitato';

  @override
  String get disabled => 'Disabilitato';

  @override
  String get active => 'Attivo';

  @override
  String get inactive => 'Inattivo';

  @override
  String get start => 'Avvia';

  @override
  String get stop => 'Ferma';

  @override
  String get restart => 'Riavvia';

  @override
  String get enable => 'Abilita';

  @override
  String get disable => 'Disabilita';

  @override
  String get remove => 'Rimuovi';

  @override
  String get kill => 'Termina';

  @override
  String get killForce => 'Termina forzatamente';

  @override
  String get processes => 'Processi';

  @override
  String get system => 'Sistema';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => 'Memoria';

  @override
  String get disk => 'Disco';

  @override
  String get gpu => 'Scheda Video';

  @override
  String get usage => 'Uso';

  @override
  String get total => 'Totale';

  @override
  String get used => 'Usata';

  @override
  String get free => 'Libera';

  @override
  String get model => 'Modello';

  @override
  String get driver => 'Driver';

  @override
  String get temperature => 'Temperatura';

  @override
  String get version => 'Versione';

  @override
  String get creator => 'Creatore';

  @override
  String get creatorName => 'Marco Di Giangiacomo';

  @override
  String get appDescription =>
      'Super Linux Utility è un\'applicazione completa per la gestione avanzata del sistema Linux. Offre strumenti potenti per ottimizzare le prestazioni, gestire servizi, applicazioni e personalizzare l\'aspetto del sistema.';

  @override
  String get features => 'Caratteristiche';

  @override
  String get appExpertUsers =>
      'Applicazione progettata per utenti esperti Linux';

  @override
  String get infoProjectWebsite => 'Sito web del progetto';

  @override
  String get applicationIdLabel => 'ID applicazione (desktop)';

  @override
  String get updatesPendingPackagesTitle =>
      'Pacchetti in coda (ultimo controllo)';

  @override
  String updatesProgressCurrent(String detail) {
    return 'Avanzamento: $detail';
  }

  @override
  String get updatesCommandOutputTitle => 'Output del comando';

  @override
  String get disclaimerLicenseTitle => 'Licenza e Disclaimer';

  @override
  String get disclaimerGplNotice =>
      'Questa applicazione è software libero; puoi ridistribuirlo e/o modificarlo secondo i termini della GNU General Public License pubblicata dalla Free Software Foundation, versione 3 della Licenza o (a tua scelta) successiva.';

  @override
  String get disclaimerNoWarranty =>
      'Questo programma è distribuito nella speranza che sia utile, ma SENZA ALCUNA GARANZIA; senza nemmeno la garanzia implicita di COMMERCIABILITÀ o IDONEITÀ PER UN PARTICOLARE SCOPO. Vedere la GNU General Public License per i dettagli.';

  @override
  String get disclaimerCopyright =>
      'Copyright (c) 2024-2025 Marco Di Giangiacomo. Tutti i diritti riservati sotto GPL-3.0.';

  @override
  String get payWithPaypal => 'Paga con PayPal';

  @override
  String get purchaseLicenseViaPaypal =>
      'La versione Advanced costa 19,99 €. Per acquistare una licenza paga tramite PayPal. Dopo il pagamento andato a buon fine riceverai il codice licenza via email. Senza un pagamento valido l\'app non può essere attivata.';

  @override
  String get languageSelectionTitle => 'Selezione Lingua';

  @override
  String get languageSelectionDesc => 'Seleziona la lingua per l\'applicazione';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'Inglese';

  @override
  String get languageFrench => 'Francese';

  @override
  String get languageSpanish => 'Spagnolo';

  @override
  String get languageGerman => 'Tedesco';

  @override
  String get languagePortuguese => 'Portoghese';

  @override
  String get settingsLanguageTitle => 'Lingua Applicazione';

  @override
  String get settingsLanguageDesc => 'Seleziona la lingua dell\'interfaccia';

  @override
  String get languageRestartMessage =>
      'La lingua verrà applicata al riavvio dell\'applicazione';

  @override
  String get servicesSlow => 'Servizi Lenti';

  @override
  String get servicesAll => 'Tutti i Servizi';

  @override
  String get servicesDisabled => 'Disabilitati';

  @override
  String get analyzeAll => 'Analizza Tutti';

  @override
  String get status => 'Stato';

  @override
  String get startupTime => 'Tempo avvio';

  @override
  String get noServicesFound => 'Nessun servizio trovato.';

  @override
  String get reEnable => 'Riabilita';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get cleanupConfirmTitle => 'Conferma pulizia';

  @override
  String get cleanupConfirmMessage =>
      'Vuoi eliminare tutti i file temporanei? Questa operazione non può essere annullata.';

  @override
  String get cleanupSuccess => 'Pulizia completata con successo!';

  @override
  String get cleanupPartialSuccess => 'Pulizia completata con alcuni errori.';

  @override
  String get protectedSystemApp => 'App di Sistema Protetta';

  @override
  String cannotDisableSystemApp(String appName) {
    return 'Non è possibile disabilitare \"$appName\" perché è un\'applicazione di sistema essenziale.';
  }

  @override
  String get systemAppsRequired =>
      'Le app di sistema sono necessarie per il corretto funzionamento del desktop environment e non possono essere disabilitate.';

  @override
  String get checkingDependencies => 'Controllo dipendenze...';

  @override
  String get warning => '⚠️ Avviso';

  @override
  String get packagesDependingOnThis => 'Pacchetti che dipendono da questo:';

  @override
  String get areYouSure => 'Sei sicuro di voler procedere?';

  @override
  String get confirmRemoval => 'Conferma rimozione';

  @override
  String removeAppQuestion(String appName) {
    return 'Vuoi rimuovere $appName?';
  }

  @override
  String get searchApp => 'Cerca app';

  @override
  String get all => 'Tutti';

  @override
  String get searchProcess => 'Cerca processo';

  @override
  String processesSelected(int count) {
    return '$count processo selezionato';
  }

  @override
  String processesSelectedPlural(int count) {
    return '$count processi selezionati';
  }

  @override
  String get app => 'App';

  @override
  String get cpuPercent => 'CPU %';

  @override
  String get name => 'Nome';

  @override
  String get pid => 'PID';

  @override
  String get user => 'Utente';

  @override
  String get noProcessesFound => 'Nessun processo trovato.';

  @override
  String get selectAll => 'Seleziona tutti';

  @override
  String get terminateAll => 'Termina tutti';

  @override
  String get terminateAllForce => 'Termina forzatamente tutti';

  @override
  String get cannotLoadSystemInfo =>
      'Impossibile caricare le informazioni di sistema.';

  @override
  String get cores => 'Core';

  @override
  String get threads => 'Threads';

  @override
  String get grubInvalidContent => 'Il contenuto del file GRUB non è valido';

  @override
  String get grubConfirmSave => 'Conferma Salvataggio';

  @override
  String get grubSaveWarning =>
      'Stai per modificare la configurazione di GRUB. Questa operazione:';

  @override
  String get grubWillCreateBackup => '• Creerà un backup automatico';

  @override
  String get grubWillSave => '• Salverà le modifiche';

  @override
  String get grubWillUpdate => '• Aggiornerà GRUB';

  @override
  String get grubWarning =>
      'ATTENZIONE: Modifiche errate possono impedire l\'avvio del sistema!';

  @override
  String get saveAndUpdate => 'Salva e Aggiorna';

  @override
  String get grubSavedSuccess =>
      'Configurazione GRUB salvata e aggiornata con successo';

  @override
  String get grubSaveError => 'Errore durante il salvataggio';

  @override
  String get reload => 'Ricarica';

  @override
  String get restoreBackup => 'Ripristina Backup';

  @override
  String get restoreBackupQuestion =>
      'Vuoi ripristinare il backup della configurazione GRUB?';

  @override
  String get restore => 'Ripristina';

  @override
  String get backupRestoredSuccess => 'Backup ripristinato con successo';

  @override
  String get backupRestoreError => 'Errore durante il ripristino del backup';

  @override
  String get kernelCannotRemoveActive =>
      'Non è possibile rimuovere il kernel attualmente in uso';

  @override
  String get removeKernel => 'Rimuovi Kernel';

  @override
  String removeKernelQuestion(String version) {
    return 'Vuoi rimuovere il kernel $version?';
  }

  @override
  String get thisOperation => 'Questa operazione:';

  @override
  String get willRemovePackage => '• Rimuoverà il pacchetto del kernel';

  @override
  String get willUpdateGrub => '• Aggiornerà GRUB';

  @override
  String get kernelWarning =>
      'ATTENZIONE: Assicurati di avere almeno un kernel funzionante!';

  @override
  String kernelRemovedSuccess(String version) {
    return 'Kernel $version rimosso con successo';
  }

  @override
  String get kernelRemoveError => 'Errore durante la rimozione del kernel';

  @override
  String get setDefaultKernel => 'Imposta kernel predefinito (GRUB)';

  @override
  String setDefaultKernelQuestion(String version) {
    return 'Impostare $version come kernel predefinito al prossimo avvio? Verranno usati comandi GRUB con privilegi di amministratore.';
  }

  @override
  String get set => 'Imposta';

  @override
  String kernelSetDefaultSuccess(String version) {
    return 'Kernel $version impostato come predefinito in GRUB';
  }

  @override
  String get kernelSetDefaultError =>
      'Errore durante l\'impostazione del kernel default';

  @override
  String get keepMax => 'Mantieni max:';

  @override
  String get cleanupKernels => 'Pulizia Kernel';

  @override
  String keepOnlyRecentKernels(int count) {
    return 'Vuoi mantenere solo i $count kernel più recenti?';
  }

  @override
  String totalKernels(int count) {
    return 'Kernel totali: $count';
  }

  @override
  String kernelsToKeep(int count) {
    return 'Kernel da mantenere: $count';
  }

  @override
  String kernelsToRemove(int count) {
    return 'Kernel da rimuovere: $count';
  }

  @override
  String get cleanupKernelsWarning =>
      'ATTENZIONE: Verranno rimossi solo i kernel non in uso.';

  @override
  String get cleanup => 'Pulisci';

  @override
  String get kernelCleanupSuccess => 'Pulizia kernel completata con successo';

  @override
  String get kernelCleanupError => 'Errore durante la pulizia dei kernel';

  @override
  String get invalidKernelCount =>
      'Inserisci un numero valido di kernel da mantenere';

  @override
  String get noKernelsFound => 'Nessun kernel installato trovato';

  @override
  String get updateGrub => 'Aggiorna GRUB';

  @override
  String get updateGrubQuestion =>
      'Vuoi aggiornare GRUB? Questa operazione aggiornerà la configurazione del bootloader.';

  @override
  String get grubUpdateSuccess => 'GRUB aggiornato con successo';

  @override
  String get grubUpdateError => 'Errore durante l\'aggiornamento di GRUB';

  @override
  String get rebootSystem => 'Riavvia Sistema';

  @override
  String get rebootSystemQuestion =>
      'Vuoi riavviare il sistema? Tutte le applicazioni aperte verranno chiuse.';

  @override
  String get rebootSystemSuccess => 'Il sistema si sta riavviando...';

  @override
  String get rebootSystemError => 'Errore durante il riavvio del sistema';

  @override
  String get package => 'Pacchetto';

  @override
  String get size => 'Dimensione';

  @override
  String get setAsDefault => 'Imposta come predefinito';

  @override
  String get refreshDimensions => 'Aggiorna Dimensioni';

  @override
  String get cleanupTempFiles => 'Pulisci File Temporanei';

  @override
  String get disableApp => 'Disabilita App';

  @override
  String get onlyDisable => 'Solo Disabilita';

  @override
  String get systemApps => 'App di Sistema';

  @override
  String get close => 'Chiudi';

  @override
  String get updateStartupApps => 'Aggiorna App all\'Avvio';

  @override
  String get saving => 'Salvataggio...';

  @override
  String get scaleFactor => 'Fattore di scala:';

  @override
  String get maximize => 'Massimizzare';

  @override
  String get minimize => 'Minimizzare';

  @override
  String get positioning => 'Posizionamento:';

  @override
  String get left => 'Sinistra';

  @override
  String get right => 'Destra';

  @override
  String get buttonOrder => 'Ordine pulsanti:';

  @override
  String get attachedDialogs => 'Finestre di dialogo allegate';

  @override
  String get centerNewWindows => 'Accentra le nuove finestre';

  @override
  String get resizeWithSecondaryClick => 'Ridimensiona con il clic secondario';

  @override
  String get raiseOnFocus => 'Sollevare le finestre quando hanno il focus';

  @override
  String get backgroundImageUpdated => 'Immagine di sfondo aggiornata!';

  @override
  String get backgroundImageError =>
      'Errore durante l\'aggiornamento dell\'immagine.';

  @override
  String get preferredFonts => 'Caratteri preferiti';

  @override
  String get interfaceText => 'Testo dell\'interfaccia';

  @override
  String get documentText => 'Testo del documento';

  @override
  String get fixedWidthText => 'Testo a spaziatura fissa';

  @override
  String get rendering => 'Rendering';

  @override
  String get hinting => 'Hinting';

  @override
  String get full => 'Pieno';

  @override
  String get medium => 'Medio';

  @override
  String get light => 'Leggero';

  @override
  String get antialiasing => 'Antialiasing';

  @override
  String get subpixelLCD => 'Subpixel (per gli schermi LCD)';

  @override
  String get standardGrayscale => 'Standard (scala di grigi)';

  @override
  String get dimensions => 'Dimensioni';

  @override
  String get preview => 'Anteprima:';

  @override
  String get noImageSelected => 'Nessuna immagine selezionata';

  @override
  String get command => 'Comando:';

  @override
  String get comment => 'Commento:';

  @override
  String get enabledApps => 'App Abilitate';

  @override
  String get disabledApps => 'App Disabilitate';

  @override
  String get noStartupAppsFound => 'Nessuna app all\'avvio trovata.';

  @override
  String get enabledStatus => 'Abilitata';

  @override
  String get disabledStatus => 'Disabilitata';

  @override
  String get styles => 'Stili';

  @override
  String get cursor => 'Cursore';

  @override
  String get icons => 'Icone';

  @override
  String get legacyApps => 'Applicazioni datate';

  @override
  String get background => 'Sfondo';

  @override
  String get defaultImage => 'Immagine predefinita';

  @override
  String get darkImage => 'Immagine in Stile Scuro';

  @override
  String get adjustment => 'Regolazione';

  @override
  String get noneOption => 'Nessuno';

  @override
  String get wallpaper => 'Sfondo';

  @override
  String get centered => 'Centrato';

  @override
  String get scaled => 'Scalato';

  @override
  String get stretched => 'Allungato';

  @override
  String get zoom => 'Zoom';

  @override
  String get spanned => 'Esteso';

  @override
  String get windowBehavior => 'Comportamento Finestre';

  @override
  String get titlebarButtons => 'Pulsanti barra del titolo';

  @override
  String get clickActions => 'Fare clic su Azioni';

  @override
  String get windowFocus => 'Focus della finestra';

  @override
  String get doubleClick => 'Doppio clic';

  @override
  String get middleClick => 'Clic centrale';

  @override
  String get rightClick => 'Clic secondario';

  @override
  String get toggleMaximize => 'Toggle Maximize';

  @override
  String get toggleMaximizeHorizontal => 'Toggle Maximize Horizontalmente';

  @override
  String get toggleMaximizeVertical => 'Toggle Maximize Verticalmente';

  @override
  String get toggleShade => 'Toggle Shade';

  @override
  String get toggleMenu => 'Toggle Menu';

  @override
  String get lower => 'Lower';

  @override
  String get menu => 'Menu';

  @override
  String get clickForFocus => 'Fare clic per il focus';

  @override
  String get focusOnHover => 'Focus al passaggio';

  @override
  String get focusFollowsMouse => 'Il fuoco segue il mouse';

  @override
  String get clickForFocusDesc =>
      'Le finestre avranno il focus quando si fa clic su di loro.';

  @override
  String get focusOnHoverDesc =>
      'La finestra ha il focus quando si passa sopra col puntatore. Le finestre rimangono con il focus quando si passa sulla scrivania.';

  @override
  String get focusFollowsMouseDesc =>
      'La finestra ha il focus quando si passa sopra col puntatore. Passare sulla scrivania rimuove il focus dalla finestra precedente.';

  @override
  String get someProcessesNotTerminated =>
      'Alcuni processi non sono stati terminati correttamente';

  @override
  String get errorDisabling => 'Errore durante la disabilitazione';

  @override
  String appReEnabled(String appName) {
    return 'App $appName riabilitata';
  }

  @override
  String get errorEnabling => 'Errore durante l\'abilitazione';

  @override
  String removeAppFromStartup(String appName) {
    return 'Vuoi rimuovere $appName dall\'avvio?';
  }

  @override
  String appRemoved(String appName) {
    return 'App $appName rimossa';
  }

  @override
  String get errorRemoving => 'Errore durante la rimozione';

  @override
  String get terminateProcesses => 'Termina Processi';

  @override
  String get noProcessesRunning =>
      'Nessun processo in esecuzione per questa app';

  @override
  String get cache => 'Cache';

  @override
  String get swap => 'Swap';

  @override
  String get filesystem => 'Filesystem';

  @override
  String get temperatureUnit => '°C';

  @override
  String get removing => 'Rimozione in corso...';

  @override
  String get versionLabel => 'Versione:';

  @override
  String get selectBasePath => 'Seleziona percorso base:';

  @override
  String get root => 'Root';

  @override
  String get home => 'Home';

  @override
  String get externalDisks => 'Dischi esterni:';

  @override
  String get selectPathToAnalyze => 'Seleziona un percorso da analizzare';

  @override
  String get totalSize => 'Dimensione totale';

  @override
  String get files => 'File';

  @override
  String get directories => 'Directory';

  @override
  String get excluded => 'Esclusa';

  @override
  String get exclude => 'Escludi';

  @override
  String get include => 'Includi';

  @override
  String get analyzing => 'Analisi in corso...';

  @override
  String get addExcludedFolder => 'Aggiungi Cartella Esclusa';

  @override
  String get enterFolderPath =>
      'Inserisci il percorso della cartella da escludere dalla pulizia:';

  @override
  String get folderPath => 'Percorso cartella';

  @override
  String get folderExcluded => 'Cartella aggiunta alle esclusioni';

  @override
  String get folderNotFound => 'Cartella non trovata';

  @override
  String get add => 'Aggiungi';

  @override
  String get goBack => 'Indietro';

  @override
  String get goForward => 'Avanti';

  @override
  String get goToRoot => 'Vai alla radice';

  @override
  String get moveToTrash => 'Sposta nel cestino';

  @override
  String moveToTrashConfirm(String name) {
    return 'Vuoi spostare \"$name\" nel cestino?';
  }

  @override
  String get move => 'Sposta';

  @override
  String get movedToTrash => 'Spostato nel cestino';

  @override
  String get errorMovingToTrash => 'Errore durante lo spostamento nel cestino';

  @override
  String get deleteFromRootWarning => 'ATTENZIONE: Eliminazione dalla Root';

  @override
  String deleteFromRootMessage(String name) {
    return 'Stai per eliminare \"$name\" dalla directory root del sistema. Questa operazione richiede privilegi amministratore e può essere irreversibile. Sei sicuro di voler procedere?';
  }

  @override
  String get deletePermanently => 'Elimina Definitivamente';

  @override
  String get emptyDirectory => 'Directory vuota';

  @override
  String get cannotPreviewFile =>
      'Impossibile visualizzare l\'anteprima del file';

  @override
  String get fileType => 'Tipo file';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get directory => 'Directory';

  @override
  String get file => 'File';

  @override
  String get rename => 'Rinomina';

  @override
  String get newName => 'Nuovo nome';

  @override
  String get details => 'Dettagli';

  @override
  String get renamedSuccessfully => 'Rinominato con successo';

  @override
  String get renameError => 'Errore durante la rinomina';

  @override
  String get type => 'Tipo';

  @override
  String get permissions => 'Permessi';

  @override
  String get owner => 'Proprietario';

  @override
  String get modified => 'Modificato';

  @override
  String get path => 'Percorso';

  @override
  String get usedSpace => 'Spazio Occupato';

  @override
  String get freeSpace => 'Spazio Libero';

  @override
  String get pages => 'Pagine';

  @override
  String get title => 'Titolo';

  @override
  String get artist => 'Artista';

  @override
  String get duration => 'Durata';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get resolution => 'Risoluzione';

  @override
  String get codec => 'Codec';

  @override
  String get showSystemFiles => 'Mostra file di sistema';

  @override
  String get hideSystemFiles => 'Nascondi file di sistema';

  @override
  String appDisabled(String appName) {
    return 'App $appName disabilitata';
  }

  @override
  String appDisabledAndProcessesTerminated(String appName) {
    return 'App $appName disabilitata e processi terminati';
  }

  @override
  String terminateProcessesQuestion(int count, String appName) {
    return 'Vuoi terminare $count processo/i di \"$appName\"?';
  }

  @override
  String get totalSpaceToFree => 'Spazio totale da liberare:';

  @override
  String get foldersWithErrors => 'Cartelle con errori:';

  @override
  String andOthers(int count) {
    return 'e altre $count';
  }

  @override
  String get recoveryDescription =>
      'Questa sezione contiene strumenti per ripristinare funzioni alterate del sistema. I comandi sono adattati automaticamente in base alla distribuzione Linux rilevata.';

  @override
  String get recoveryRestartPipewire => 'Riavvia Pipewire';

  @override
  String get recoveryRestartPipewireDesc =>
      'Riavvia i servizi Pipewire, Pipewire-Pulse e Wireplumber per risolvere problemi audio.';

  @override
  String get recoveryRestoreNetwork => 'Ripristina Servizi di Rete';

  @override
  String get recoveryRestoreNetworkDesc =>
      'Riavvia i servizi di rete (NetworkManager, systemd-networkd) per risolvere problemi di connessione.';

  @override
  String get recoveryRebuildGrub => 'Ricostruisci GRUB';

  @override
  String get recoveryRebuildGrubDesc =>
      'Ricostruisce la configurazione GRUB e aggiorna il bootloader. Viene creato un backup automatico.';

  @override
  String get recoveryRestoreFlathub => 'Ripristina Flathub';

  @override
  String get recoveryRestoreFlathubDesc =>
      'Ripristina il repository Flathub per Flatpak e aggiorna i metadati delle app.';

  @override
  String get recoveryRestoreRepos => 'Ripristina Repository';

  @override
  String get recoveryRestoreReposDesc =>
      'Aggiorna e ripristina i repository del package manager (APT, DNF, Pacman) per risolvere problemi di aggiornamento.';

  @override
  String get recoveryCheckUpdates => 'Ricerca Aggiornamenti';

  @override
  String get recoveryCheckUpdatesDesc =>
      'Verifica la disponibilità di aggiornamenti per tutti i package manager installati (APT, DNF, Pacman, Snap, Flatpak).';

  @override
  String get recoveryPerformUpdates => 'Esegui Aggiornamenti';

  @override
  String get recoveryPerformUpdatesConfirm =>
      'Vuoi eseguire gli aggiornamenti disponibili? Questa operazione potrebbe richiedere del tempo.';

  @override
  String get recoveryTabRecovery => 'Recovery';

  @override
  String get recoveryTabCheckUpdates => 'Verifica Aggiornamenti';

  @override
  String get recoveryTabSoftwareInstaller => 'Installatore Software di Sistema';

  @override
  String get recoverySoftwareInstallerDesc =>
      'Scarica e installa automaticamente software di sistema essenziale.';

  @override
  String get recoveryInstallFfmpeg => 'FFmpeg';

  @override
  String get recoveryInstallFfmpegDesc =>
      'Framework multimediale per codifica/decodifica audio e video.';

  @override
  String get recoveryInstallYtDlp => 'yt-dlp';

  @override
  String get recoveryInstallYtDlpDesc => 'Scaricatore video per molti siti.';

  @override
  String get recoveryInstallSystemLibs => 'Librerie di sistema';

  @override
  String get recoveryInstallSystemLibsDesc =>
      'Librerie di sistema essenziali che spesso si possono corrompere.';

  @override
  String get recoveryInstallCodecs => 'Codec video e audio';

  @override
  String get recoveryInstallCodecsDesc =>
      'Codec per riprodurre formati video e audio comuni.';

  @override
  String get recoveryInstallRsync => 'rsync';

  @override
  String get recoveryInstallRsyncDesc =>
      'Strumento efficiente per sincronizzazione e trasferimento file.';

  @override
  String get install => 'Installa';

  @override
  String get execute => 'Esegui';

  @override
  String get viewOutput => 'Visualizza Output';

  @override
  String get infoServices => 'Servizi';

  @override
  String get infoServicesAnalysis => 'Analisi servizi di sistema';

  @override
  String get infoServicesAnalysisDesc =>
      'Identifica i servizi che rallentano l\'avvio del sistema utilizzando systemd-analyze blame';

  @override
  String get infoServicesManagement => 'Gestione servizi';

  @override
  String get infoServicesManagementDesc =>
      'Abilita, disabilita e riavvia servizi di sistema con controllo completo';

  @override
  String get infoServicesStatus => 'Visualizzazione stato';

  @override
  String get infoServicesStatusDesc =>
      'Mostra lo stato di tutti i servizi (attivi, inattivi, falliti)';

  @override
  String get infoStartupApps => 'App all\'Avvio';

  @override
  String get infoStartupAppsManagement => 'Gestione applicazioni all\'avvio';

  @override
  String get infoStartupAppsManagementDesc =>
      'Visualizza e gestisci tutte le applicazioni che si avviano automaticamente';

  @override
  String get infoStartupAppsProtection => 'Protezione app di sistema';

  @override
  String get infoStartupAppsProtectionDesc =>
      'Previene la disabilitazione accidentale di applicazioni critiche del sistema';

  @override
  String get infoStartupAppsTermination => 'Terminazione processi';

  @override
  String get infoStartupAppsTerminationDesc =>
      'Opzione per terminare i processi di un\'app quando viene disabilitata';

  @override
  String get infoCleanup => 'Pulizia Sistema';

  @override
  String get infoCleanupTempFiles => 'Ricerca file temporanei';

  @override
  String get infoCleanupTempFilesDesc =>
      'Trova automaticamente file temporanei di applicazioni comuni (browser, IDE, sviluppo)';

  @override
  String get infoCleanupCache => 'Pulizia cache';

  @override
  String get infoCleanupCacheDesc =>
      'Elimina cache di sistema e applicazioni per liberare spazio';

  @override
  String get infoCleanupTrash => 'Gestione cestino';

  @override
  String get infoCleanupTrashDesc =>
      'Svuota il cestino e pulisce file temporanei in modo sicuro';

  @override
  String get infoInstalledApps => 'App Installate';

  @override
  String get infoInstalledAppsManagement => 'Gestione pacchetti multipli';

  @override
  String get infoInstalledAppsManagementDesc =>
      'Visualizza app installate tramite APT, Snap, Flatpak e GNOME';

  @override
  String get infoInstalledAppsDependencies => 'Controllo dipendenze';

  @override
  String get infoInstalledAppsDependenciesDesc =>
      'Verifica le dipendenze prima della rimozione per evitare problemi';

  @override
  String get infoInstalledAppsWarnings => 'Avvisi di sicurezza';

  @override
  String get infoInstalledAppsWarningsDesc =>
      'Avvisa quando un pacchetto è utilizzato da altri software o dal sistema';

  @override
  String get infoMonitor => 'Monitor Sistema';

  @override
  String get infoMonitorProcesses => 'Monitoraggio processi';

  @override
  String get infoMonitorProcessesDesc =>
      'Visualizza tutti i processi attivi con uso CPU, memoria e disco';

  @override
  String get infoMonitorSorting => 'Ordinamento avanzato';

  @override
  String get infoMonitorSortingDesc =>
      'Ordina processi per CPU o memoria in ordine crescente o decrescente';

  @override
  String get infoMonitorTermination => 'Terminazione processi';

  @override
  String get infoMonitorTerminationDesc =>
      'Termina processi non rispondenti direttamente dall\'interfaccia';

  @override
  String get infoMonitorSystemInfo => 'Informazioni sistema';

  @override
  String get infoMonitorSystemInfoDesc =>
      'Mostra dettagli su CPU, RAM, dischi e scheda video';

  @override
  String get infoAppearance => 'Personalizzazione Aspetto';

  @override
  String get infoAppearanceFonts => 'Gestione font';

  @override
  String get infoAppearanceFontsDesc =>
      'Configura font per interfaccia, documenti e testo monospazio con anteprime';

  @override
  String get infoAppearanceRendering => 'Rendering avanzato';

  @override
  String get infoAppearanceRenderingDesc =>
      'Controlla hinting, antialiasing e fattore di scala';

  @override
  String get infoAppearanceThemes => 'Temi e icone';

  @override
  String get infoAppearanceThemesDesc =>
      'Personalizza temi cursore, icone e applicazioni legacy con anteprime';

  @override
  String get infoAppearanceWallpaper => 'Sfondo desktop';

  @override
  String get infoAppearanceWallpaperDesc =>
      'Imposta immagini di sfondo per tema chiaro e scuro';

  @override
  String get infoAppearanceWindows => 'Comportamento finestre';

  @override
  String get infoAppearanceWindowsDesc =>
      'Configura azioni click, pulsanti barra titolo e focus delle finestre';

  @override
  String get infoGrub => 'GRUB Editor (Modalità Avanzata)';

  @override
  String get infoGrubEditor => 'Editor configurazione GRUB';

  @override
  String get infoGrubEditorDesc =>
      'Modifica direttamente il file /etc/default/grub con editor integrato';

  @override
  String get infoGrubBackup => 'Backup automatico';

  @override
  String get infoGrubBackupDesc =>
      'Crea backup automatici prima di ogni modifica';

  @override
  String get infoGrubUpdate => 'Aggiornamento GRUB';

  @override
  String get infoGrubUpdateDesc =>
      'Applica le modifiche e aggiorna il bootloader';

  @override
  String get infoGrubRestore => 'Ripristino backup';

  @override
  String get infoGrubRestoreDesc =>
      'Ripristina facilmente una configurazione precedente';

  @override
  String get infoKernel => 'Gestione Kernel (Modalità Avanzata)';

  @override
  String get infoKernelList => 'Lista kernel installati';

  @override
  String get infoKernelListDesc =>
      'Visualizza tutti i kernel installati con versione e dimensione';

  @override
  String get infoKernelRemoval => 'Rimozione kernel';

  @override
  String get infoKernelRemovalDesc =>
      'Rimuovi kernel vecchi in modo sicuro (protegge il kernel corrente)';

  @override
  String get infoKernelDefault => 'Impostazione kernel predefinito';

  @override
  String get infoKernelDefaultDesc => 'Scegli quale kernel avviare di default';

  @override
  String get infoKernelCleanup => 'Pulizia automatica';

  @override
  String get infoKernelCleanupDesc =>
      'Mantieni solo un numero specificato di kernel più recenti';

  @override
  String get infoSecurity => 'Sicurezza';

  @override
  String get infoSecurityPassword => 'Gestione password';

  @override
  String get infoSecurityPasswordDesc =>
      'Salva la password di amministratore in modo sicuro per operazioni sudo';

  @override
  String get infoSecurityWarning => 'Avviso utenti esperti';

  @override
  String get infoSecurityWarningDesc =>
      'Schermata di avviso iniziale per utenti esperti';

  @override
  String get infoSecurityMode => 'Modalità Standard/Avanzata';

  @override
  String get infoSecurityModeDesc =>
      'Separa funzionalità base da quelle avanzate (GRUB, Kernel)';

  @override
  String get recoveryCheckUpdatesComplete => 'Ricerca aggiornamenti completata';

  @override
  String recoveryCheckUpdatesError(String error) {
    return 'Errore durante la ricerca degli aggiornamenti: $error';
  }

  @override
  String get diskAnalyzerMainDirectories => 'Directory Principali';

  @override
  String get hardwareSuggestionsTitle => 'Suggerimenti GRUB basati su Hardware';

  @override
  String get hardwareSuggestionsDescription =>
      'I seguenti suggerimenti sono basati sull\'analisi della tua configurazione hardware:';

  @override
  String get hardwareSuggestionsPriorityHigh => 'Alta';

  @override
  String get hardwareSuggestionsPriorityMedium => 'Media';

  @override
  String get hardwareSuggestionsPriorityLow => 'Bassa';

  @override
  String get hardwareSuggestionsApply => 'Applica';

  @override
  String get hardwareSuggestionsCancel => 'Annulla';

  @override
  String get settingsPasswordSecurityMessage =>
      'La password viene salvata in modo sicuro utilizzando il keyring del sistema.';

  @override
  String get tabShutdownScheduler => 'Spegnimento Automatico';

  @override
  String get shutdownInfoTitle => 'Spegnimento Automatico';

  @override
  String get shutdownInfoDescription =>
      'Configura lo spegnimento automatico del PC a orari prestabiliti. Utilizza systemd timers per garantire la compatibilità con tutte le distribuzioni Linux moderne.';

  @override
  String get shutdownSystemdRequired => 'systemd Richiesto';

  @override
  String get shutdownSystemdRequiredDesc =>
      'Questa funzionalità richiede systemd, disponibile su Fedora, Ubuntu, Arch, Debian e altre distribuzioni Linux moderne.';

  @override
  String get shutdownPasswordRequired =>
      'Password richiesta. Configura la password nelle impostazioni.';

  @override
  String get shutdownActiveTimers => 'Timer Attivi';

  @override
  String get shutdownCreateTimer => 'Crea Nuovo Timer';

  @override
  String get shutdownScheduleType => 'Tipo di Programmazione';

  @override
  String get shutdownScheduleDaily => 'Giornaliera';

  @override
  String get shutdownScheduleWeekly => 'Settimanale';

  @override
  String get shutdownScheduleMonthly => 'Mensile';

  @override
  String get shutdownTime => 'Ora';

  @override
  String get shutdownSelectTime => 'Seleziona Ora';

  @override
  String get shutdownSelectDays => 'Seleziona Giorni';

  @override
  String get shutdownSelectDayOfMonth => 'Seleziona Giorno del Mese';

  @override
  String get shutdownDayOfMonth => 'Giorno del Mese';

  @override
  String get shutdownDaySunday => 'Domenica';

  @override
  String get shutdownDayMonday => 'Lunedì';

  @override
  String get shutdownDayTuesday => 'Martedì';

  @override
  String get shutdownDayWednesday => 'Mercoledì';

  @override
  String get shutdownDayThursday => 'Giovedì';

  @override
  String get shutdownDayFriday => 'Venerdì';

  @override
  String get shutdownDaySaturday => 'Sabato';

  @override
  String get shutdownTimerCreated => 'Timer di spegnimento creato con successo';

  @override
  String get shutdownTimerRemoved =>
      'Timer di spegnimento rimosso con successo';

  @override
  String get shutdownRemoveConfirm =>
      'Vuoi rimuovere questo timer di spegnimento?';

  @override
  String get shutdownNextRun => 'Prossima esecuzione';

  @override
  String get shutdownStatusInactive => 'Inattivo';

  @override
  String get shutdownWeeklyDaysRequired =>
      'Seleziona almeno un giorno della settimana';

  @override
  String get shutdownMonthlyDayRequired => 'Seleziona un giorno del mese';

  @override
  String get shutdownOpenSettings => 'Apri Impostazioni Spegnimento';

  @override
  String get shutdownEditTimer => 'Modifica Timer';

  @override
  String get shutdownTimerDetails => 'Dettagli Timer';

  @override
  String get diskCacheGenerating =>
      'Lettura e generazione cache in corso... (vale la prima volta)';

  @override
  String get licenseActivate => 'Attiva versione avanzata';

  @override
  String get licenseActivateButton => 'Attiva';

  @override
  String get licenseName => 'Nome';

  @override
  String get licenseSurname => 'Cognome';

  @override
  String get licenseEmail => 'Email';

  @override
  String get licenseCode => 'Codice licenza';

  @override
  String get licenseRequired => 'Questo campo è obbligatorio';

  @override
  String get licenseActivateSuccess =>
      'Versione avanzata attivata con successo.';

  @override
  String get licenseActivateError =>
      'Codice non valido. Verifica nome, cognome e email.';

  @override
  String get licenseActivatePremium => 'Attiva / Premium';

  @override
  String get licenseActivateCardTitle => 'Attiva versione avanzata';

  @override
  String get licenseActivateCardDesc =>
      'La versione Advanced costa 19,99 €. Inserisci i tuoi dati e il codice licenza ricevuto dopo il pagamento andato a buon fine per sbloccare GRUB, Kernel e Recovery. Senza un pagamento valido l\'app non può essere attivata.';
}
