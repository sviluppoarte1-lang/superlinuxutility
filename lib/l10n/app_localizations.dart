import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// Titolo dell'applicazione
  ///
  /// In it, this message translates to:
  /// **'Super Linux Utility'**
  String get appTitle;

  /// No description provided for @appAlreadyRunning.
  ///
  /// In it, this message translates to:
  /// **'L\'applicazione è già in esecuzione.'**
  String get appAlreadyRunning;

  /// No description provided for @trayCheckUpdates.
  ///
  /// In it, this message translates to:
  /// **'Verifica aggiornamenti di sistema'**
  String get trayCheckUpdates;

  /// No description provided for @trayCleanLinuxCache.
  ///
  /// In it, this message translates to:
  /// **'Pulisci Cache Linux'**
  String get trayCleanLinuxCache;

  /// No description provided for @trayRemoveTempFiles.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi File temporanei'**
  String get trayRemoveTempFiles;

  /// No description provided for @trayCleanTempFilesAndCache.
  ///
  /// In it, this message translates to:
  /// **'Pulisci file temporanei e cache'**
  String get trayCleanTempFilesAndCache;

  /// No description provided for @trayCleanVram.
  ///
  /// In it, this message translates to:
  /// **'Ripulisci VRAM (reset GPU)'**
  String get trayCleanVram;

  /// No description provided for @trayCpuGpuTemp.
  ///
  /// In it, this message translates to:
  /// **'Temperatura CPU, GPU'**
  String get trayCpuGpuTemp;

  /// No description provided for @trayDiskUsage.
  ///
  /// In it, this message translates to:
  /// **'Uso del disco'**
  String get trayDiskUsage;

  /// No description provided for @trayMemoryUsage.
  ///
  /// In it, this message translates to:
  /// **'Uso memoria RAM'**
  String get trayMemoryUsage;

  /// No description provided for @traySmartHealth.
  ///
  /// In it, this message translates to:
  /// **'Salute disco (SMART)'**
  String get traySmartHealth;

  /// No description provided for @trayShutdownTimer.
  ///
  /// In it, this message translates to:
  /// **'Spegnimento automatico'**
  String get trayShutdownTimer;

  /// No description provided for @trayShowMainWindow.
  ///
  /// In it, this message translates to:
  /// **'Visualizza schermata principale'**
  String get trayShowMainWindow;

  /// No description provided for @trayCpuGpuUsage.
  ///
  /// In it, this message translates to:
  /// **'Uso CPU, GPU'**
  String get trayCpuGpuUsage;

  /// No description provided for @trayExit.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get trayExit;

  /// No description provided for @traySettings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get traySettings;

  /// No description provided for @traySystem.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get traySystem;

  /// No description provided for @trayClipboard.
  ///
  /// In it, this message translates to:
  /// **'Appunti'**
  String get trayClipboard;

  /// No description provided for @clipboardTitle.
  ///
  /// In it, this message translates to:
  /// **'Cronologia appunti'**
  String get clipboardTitle;

  /// No description provided for @clipboardEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessun testo copiato finora. Copia un testo e apparirà qui.'**
  String get clipboardEmpty;

  /// No description provided for @clipboardEditTitle.
  ///
  /// In it, this message translates to:
  /// **'Modifica testo'**
  String get clipboardEditTitle;

  /// No description provided for @clipboardSave.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get clipboardSave;

  /// No description provided for @clipboardCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get clipboardCancel;

  /// No description provided for @clipboardDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get clipboardDelete;

  /// No description provided for @clipboardDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare questa voce?'**
  String get clipboardDeleteTitle;

  /// No description provided for @clipboardDeleteBody.
  ///
  /// In it, this message translates to:
  /// **'La voce verrà rimossa definitivamente dalla cronologia.'**
  String get clipboardDeleteBody;

  /// No description provided for @clipboardClearAll.
  ///
  /// In it, this message translates to:
  /// **'Svuota tutto'**
  String get clipboardClearAll;

  /// No description provided for @clipboardClearAllTitle.
  ///
  /// In it, this message translates to:
  /// **'Svuotare la cronologia?'**
  String get clipboardClearAllTitle;

  /// No description provided for @clipboardClearAllBody.
  ///
  /// In it, this message translates to:
  /// **'Tutte le voci salvate verranno eliminate definitivamente.'**
  String get clipboardClearAllBody;

  /// No description provided for @clipboardSaveEntryTxt.
  ///
  /// In it, this message translates to:
  /// **'Salva in TXT'**
  String get clipboardSaveEntryTxt;

  /// No description provided for @clipboardExportAll.
  ///
  /// In it, this message translates to:
  /// **'Esporta tutto in TXT'**
  String get clipboardExportAll;

  /// No description provided for @clipboardSavedTo.
  ///
  /// In it, this message translates to:
  /// **'Salvato in {path}'**
  String clipboardSavedTo(String path);

  /// No description provided for @clipboardSaveFailed.
  ///
  /// In it, this message translates to:
  /// **'Salvataggio non riuscito.'**
  String get clipboardSaveFailed;

  /// No description provided for @clipboardCopiedBack.
  ///
  /// In it, this message translates to:
  /// **'Testo copiato negli appunti.'**
  String get clipboardCopiedBack;

  /// No description provided for @clipboardSettingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Appunti (clipboard)'**
  String get clipboardSettingsTitle;

  /// No description provided for @clipboardSettingsDesc.
  ///
  /// In it, this message translates to:
  /// **'L\'app memorizza automaticamente i testi che copi. Scegli per quante ore conservarli: allo scadere vengono eliminati da soli.'**
  String get clipboardSettingsDesc;

  /// No description provided for @clipboardRetentionLabel.
  ///
  /// In it, this message translates to:
  /// **'Conserva le copie per'**
  String get clipboardRetentionLabel;

  /// No description provided for @clipboardRetentionHours.
  ///
  /// In it, this message translates to:
  /// **'{n} h'**
  String clipboardRetentionHours(int n);

  /// No description provided for @tabBattery.
  ///
  /// In it, this message translates to:
  /// **'Batteria'**
  String get tabBattery;

  /// No description provided for @trayBattery.
  ///
  /// In it, this message translates to:
  /// **'Batteria'**
  String get trayBattery;

  /// No description provided for @trayBatteryHealth.
  ///
  /// In it, this message translates to:
  /// **'Salute batteria'**
  String get trayBatteryHealth;

  /// No description provided for @trayChargeLimit.
  ///
  /// In it, this message translates to:
  /// **'Limite carica'**
  String get trayChargeLimit;

  /// No description provided for @trayPowerProfile.
  ///
  /// In it, this message translates to:
  /// **'Profilo energia'**
  String get trayPowerProfile;

  /// No description provided for @batteryNoBattery.
  ///
  /// In it, this message translates to:
  /// **'Nessuna batteria rilevata'**
  String get batteryNoBattery;

  /// No description provided for @batteryNoBatteryDesc.
  ///
  /// In it, this message translates to:
  /// **'Questa funzione è disponibile solo sui notebook. Su questo sistema non è stata trovata alcuna batteria.'**
  String get batteryNoBatteryDesc;

  /// No description provided for @batteryHealthTitle.
  ///
  /// In it, this message translates to:
  /// **'Salute batteria'**
  String get batteryHealthTitle;

  /// No description provided for @batteryCapacityNow.
  ///
  /// In it, this message translates to:
  /// **'Energia attuale'**
  String get batteryCapacityNow;

  /// No description provided for @batteryCapacityFull.
  ///
  /// In it, this message translates to:
  /// **'Capacità residua'**
  String get batteryCapacityFull;

  /// No description provided for @batteryCapacityDesign.
  ///
  /// In it, this message translates to:
  /// **'Capacità nominale'**
  String get batteryCapacityDesign;

  /// No description provided for @batteryHealthPct.
  ///
  /// In it, this message translates to:
  /// **'Salute'**
  String get batteryHealthPct;

  /// No description provided for @batteryCycles.
  ///
  /// In it, this message translates to:
  /// **'Cicli di carica'**
  String get batteryCycles;

  /// No description provided for @batteryVoltage.
  ///
  /// In it, this message translates to:
  /// **'Tensione'**
  String get batteryVoltage;

  /// No description provided for @batteryPower.
  ///
  /// In it, this message translates to:
  /// **'Potenza'**
  String get batteryPower;

  /// No description provided for @batteryTech.
  ///
  /// In it, this message translates to:
  /// **'Tecnologia'**
  String get batteryTech;

  /// No description provided for @batteryStatus.
  ///
  /// In it, this message translates to:
  /// **'Batteria'**
  String get batteryStatus;

  /// No description provided for @batteryAcOnline.
  ///
  /// In it, this message translates to:
  /// **'In carica (rete)'**
  String get batteryAcOnline;

  /// No description provided for @batteryAcOffline.
  ///
  /// In it, this message translates to:
  /// **'A batteria'**
  String get batteryAcOffline;

  /// No description provided for @batteryCharging.
  ///
  /// In it, this message translates to:
  /// **'In carica'**
  String get batteryCharging;

  /// No description provided for @batteryDischarging.
  ///
  /// In it, this message translates to:
  /// **'In scarica'**
  String get batteryDischarging;

  /// No description provided for @batteryFull.
  ///
  /// In it, this message translates to:
  /// **'Carica completa'**
  String get batteryFull;

  /// No description provided for @batteryUnknown.
  ///
  /// In it, this message translates to:
  /// **'Stato sconosciuto'**
  String get batteryUnknown;

  /// No description provided for @batteryThresholdsTitle.
  ///
  /// In it, this message translates to:
  /// **'Soglie di carica'**
  String get batteryThresholdsTitle;

  /// No description provided for @batteryThresholdsDesc.
  ///
  /// In it, this message translates to:
  /// **'Limita la carica massima (es. 80%) per preservare la batteria. Richiede password amministratore. Supportato su ASUS, ThinkPad, Lenovo e Dell recenti.'**
  String get batteryThresholdsDesc;

  /// No description provided for @batteryThresholdsUnsupported.
  ///
  /// In it, this message translates to:
  /// **'Soglie di carica non supportate su questo hardware.'**
  String get batteryThresholdsUnsupported;

  /// No description provided for @batteryEndLimit.
  ///
  /// In it, this message translates to:
  /// **'Limite massimo di carica'**
  String get batteryEndLimit;

  /// No description provided for @batteryStartLimit.
  ///
  /// In it, this message translates to:
  /// **'Inizio carica'**
  String get batteryStartLimit;

  /// No description provided for @batteryGovernorTitle.
  ///
  /// In it, this message translates to:
  /// **'Governor automatico'**
  String get batteryGovernorTitle;

  /// No description provided for @batteryGovernorDesc.
  ///
  /// In it, this message translates to:
  /// **'Passa a powersave quando scolleghi l\'alimentatore e a performance quando ricarichi. Funziona mentre l\'app è in esecuzione.'**
  String get batteryGovernorDesc;

  /// No description provided for @batteryGovernorAuto.
  ///
  /// In it, this message translates to:
  /// **'Cambio automatico governor'**
  String get batteryGovernorAuto;

  /// No description provided for @batteryGovernorOnAc.
  ///
  /// In it, this message translates to:
  /// **'Governor in carica'**
  String get batteryGovernorOnAc;

  /// No description provided for @batteryGovernorOnBattery.
  ///
  /// In it, this message translates to:
  /// **'Governor a batteria'**
  String get batteryGovernorOnBattery;

  /// No description provided for @batteryGovernorCurrent.
  ///
  /// In it, this message translates to:
  /// **'Governor attuale'**
  String get batteryGovernorCurrent;

  /// No description provided for @batteryApplied.
  ///
  /// In it, this message translates to:
  /// **'Impostazione applicata.'**
  String get batteryApplied;

  /// No description provided for @batteryFailed.
  ///
  /// In it, this message translates to:
  /// **'Operazione non riuscita.'**
  String get batteryFailed;

  /// No description provided for @batteryRefresh.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get batteryRefresh;

  /// No description provided for @cleanupLinuxCache.
  ///
  /// In it, this message translates to:
  /// **'Pulisci Cache'**
  String get cleanupLinuxCache;

  /// No description provided for @cleanupLinuxCacheDesc.
  ///
  /// In it, this message translates to:
  /// **'Svuota la cache di pagina del kernel (drop_caches). Richiede password amministratore.'**
  String get cleanupLinuxCacheDesc;

  /// No description provided for @cleanupLinuxCacheSuccess.
  ///
  /// In it, this message translates to:
  /// **'Cache Linux pulita con successo.'**
  String get cleanupLinuxCacheSuccess;

  /// No description provided for @cleanupLinuxCacheError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante la pulizia della cache.'**
  String get cleanupLinuxCacheError;

  /// No description provided for @advCleanupTitle.
  ///
  /// In it, this message translates to:
  /// **'Pulizia avanzata (log e cache sviluppo)'**
  String get advCleanupTitle;

  /// No description provided for @devPip.
  ///
  /// In it, this message translates to:
  /// **'Cache pip'**
  String get devPip;

  /// No description provided for @devCargo.
  ///
  /// In it, this message translates to:
  /// **'Cache Cargo (Rust)'**
  String get devCargo;

  /// No description provided for @devNpm.
  ///
  /// In it, this message translates to:
  /// **'Cache npm'**
  String get devNpm;

  /// No description provided for @devGo.
  ///
  /// In it, this message translates to:
  /// **'Cache Go'**
  String get devGo;

  /// No description provided for @devGradle.
  ///
  /// In it, this message translates to:
  /// **'Cache Gradle'**
  String get devGradle;

  /// No description provided for @devDocker.
  ///
  /// In it, this message translates to:
  /// **'Immagini Docker inutilizzate'**
  String get devDocker;

  /// No description provided for @devKernelHeaders.
  ///
  /// In it, this message translates to:
  /// **'Vecchi kernel (headers + immagini)'**
  String get devKernelHeaders;

  /// No description provided for @advEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna cache di sviluppo rilevata.'**
  String get advEmpty;

  /// No description provided for @journalTitle.
  ///
  /// In it, this message translates to:
  /// **'Log di sistema (journald)'**
  String get journalTitle;

  /// No description provided for @journalCurrentSize.
  ///
  /// In it, this message translates to:
  /// **'Spazio occupato'**
  String get journalCurrentSize;

  /// No description provided for @journalVacuumTarget.
  ///
  /// In it, this message translates to:
  /// **'Compatta fino a'**
  String get journalVacuumTarget;

  /// No description provided for @journalVacuumNow.
  ///
  /// In it, this message translates to:
  /// **'Compatta'**
  String get journalVacuumNow;

  /// No description provided for @journalLimitLabel.
  ///
  /// In it, this message translates to:
  /// **'Limite permanente'**
  String get journalLimitLabel;

  /// No description provided for @journalLimitApply.
  ///
  /// In it, this message translates to:
  /// **'Applica limite'**
  String get journalLimitApply;

  /// No description provided for @advCleanSelected.
  ///
  /// In it, this message translates to:
  /// **'Pulisci selezionati'**
  String get advCleanSelected;

  /// No description provided for @advCleaned.
  ///
  /// In it, this message translates to:
  /// **'Pulizia completata.'**
  String get advCleaned;

  /// No description provided for @advFailed.
  ///
  /// In it, this message translates to:
  /// **'Pulizia non riuscita.'**
  String get advFailed;

  /// No description provided for @cleanupVram.
  ///
  /// In it, this message translates to:
  /// **'Pulisci VRAM'**
  String get cleanupVram;

  /// No description provided for @cleanupVramConfirmTitle.
  ///
  /// In it, this message translates to:
  /// **'Reset della GPU'**
  String get cleanupVramConfirmTitle;

  /// No description provided for @cleanupVramConfirmMessage.
  ///
  /// In it, this message translates to:
  /// **'Proverò a resettare la scheda grafica per liberare la VRAM. Richiede password amministratore e può causare un\'interruzione temporanea dello schermo. Continuare?'**
  String get cleanupVramConfirmMessage;

  /// No description provided for @cleanupVramSuccess.
  ///
  /// In it, this message translates to:
  /// **'VRAM ripulita (reset GPU) con successo.'**
  String get cleanupVramSuccess;

  /// No description provided for @cleanupVramError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile ripulire la VRAM (reset GPU fallito).'**
  String get cleanupVramError;

  /// No description provided for @ramCleanupTitle.
  ///
  /// In it, this message translates to:
  /// **'Pulizia RAM'**
  String get ramCleanupTitle;

  /// No description provided for @ramCleanup.
  ///
  /// In it, this message translates to:
  /// **'Pulisci RAM'**
  String get ramCleanup;

  /// No description provided for @ramCleanupConfirmTitle.
  ///
  /// In it, this message translates to:
  /// **'Conferma pulizia RAM'**
  String get ramCleanupConfirmTitle;

  /// No description provided for @ramCleanupConfirmMessage.
  ///
  /// In it, this message translates to:
  /// **'La pulizia profonda della RAM svuoterà le cache del kernel (drop_caches) e riciclerà lo swap per liberare la memoria usata da dati inattivi. Non ferma servizi di sistema e non elimina file temporanei. Richiede la password amministratore. Continuare?'**
  String get ramCleanupConfirmMessage;

  /// No description provided for @ramCleanupSuccess.
  ///
  /// In it, this message translates to:
  /// **'Pulizia RAM completata con successo.'**
  String get ramCleanupSuccess;

  /// No description provided for @ramCleanupError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante la pulizia della RAM.'**
  String get ramCleanupError;

  /// No description provided for @ramUsed.
  ///
  /// In it, this message translates to:
  /// **'Usata'**
  String get ramUsed;

  /// No description provided for @ramAvailable.
  ///
  /// In it, this message translates to:
  /// **'Disponibile'**
  String get ramAvailable;

  /// No description provided for @ramCache.
  ///
  /// In it, this message translates to:
  /// **'Cache'**
  String get ramCache;

  /// No description provided for @ramSwap.
  ///
  /// In it, this message translates to:
  /// **'Swap'**
  String get ramSwap;

  /// No description provided for @ramSwapNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuno swap'**
  String get ramSwapNone;

  /// No description provided for @ramFreed.
  ///
  /// In it, this message translates to:
  /// **'Memoria liberata'**
  String get ramFreed;

  /// No description provided for @ramBefore.
  ///
  /// In it, this message translates to:
  /// **'Prima'**
  String get ramBefore;

  /// No description provided for @ramAfter.
  ///
  /// In it, this message translates to:
  /// **'Dopo'**
  String get ramAfter;

  /// No description provided for @ramStepsFailed.
  ///
  /// In it, this message translates to:
  /// **'Passaggi non riusciti'**
  String get ramStepsFailed;

  /// No description provided for @ramCleanupSettingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Pulizia automatica RAM'**
  String get ramCleanupSettingsTitle;

  /// No description provided for @ramCleanupSettingsDesc.
  ///
  /// In it, this message translates to:
  /// **'Esegue automaticamente la pulizia profonda della RAM a intervalli regolari.'**
  String get ramCleanupSettingsDesc;

  /// No description provided for @ramCleanupSettingsInterval.
  ///
  /// In it, this message translates to:
  /// **'Frequenza pulizia RAM'**
  String get ramCleanupSettingsInterval;

  /// No description provided for @ramCleanupNever.
  ///
  /// In it, this message translates to:
  /// **'Mai'**
  String get ramCleanupNever;

  /// No description provided for @ramCleanupEvery5Min.
  ///
  /// In it, this message translates to:
  /// **'Ogni 5 minuti'**
  String get ramCleanupEvery5Min;

  /// No description provided for @ramCleanupEvery10Min.
  ///
  /// In it, this message translates to:
  /// **'Ogni 10 minuti'**
  String get ramCleanupEvery10Min;

  /// No description provided for @ramCleanupEvery15Min.
  ///
  /// In it, this message translates to:
  /// **'Ogni 15 minuti'**
  String get ramCleanupEvery15Min;

  /// No description provided for @ramCleanupEvery30Min.
  ///
  /// In it, this message translates to:
  /// **'Ogni 30 minuti'**
  String get ramCleanupEvery30Min;

  /// No description provided for @ramCleanupAutoEnabled.
  ///
  /// In it, this message translates to:
  /// **'Pulizia automatica RAM attivata (ogni {minutes} minuti).'**
  String ramCleanupAutoEnabled(int minutes);

  /// No description provided for @ramCleanupAutoDisabled.
  ///
  /// In it, this message translates to:
  /// **'Pulizia automatica RAM disattivata.'**
  String get ramCleanupAutoDisabled;

  /// No description provided for @ramCleanupAutoDone.
  ///
  /// In it, this message translates to:
  /// **'Pulizia automatica RAM completata'**
  String get ramCleanupAutoDone;

  /// No description provided for @tabServices.
  ///
  /// In it, this message translates to:
  /// **'Servizi'**
  String get tabServices;

  /// No description provided for @tabStartupApps.
  ///
  /// In it, this message translates to:
  /// **'App Avvio'**
  String get tabStartupApps;

  /// No description provided for @tabCleanup.
  ///
  /// In it, this message translates to:
  /// **'Pulizia'**
  String get tabCleanup;

  /// No description provided for @tabInstalledApps.
  ///
  /// In it, this message translates to:
  /// **'App Installate'**
  String get tabInstalledApps;

  /// No description provided for @tabMonitor.
  ///
  /// In it, this message translates to:
  /// **'Monitor'**
  String get tabMonitor;

  /// No description provided for @tabDiskAnalyzer.
  ///
  /// In it, this message translates to:
  /// **'Analizzatore Disco'**
  String get tabDiskAnalyzer;

  /// No description provided for @tabAppearance.
  ///
  /// In it, this message translates to:
  /// **'Aspetto GNOME'**
  String get tabAppearance;

  /// No description provided for @tabInfo.
  ///
  /// In it, this message translates to:
  /// **'Info'**
  String get tabInfo;

  /// No description provided for @tabRecovery.
  ///
  /// In it, this message translates to:
  /// **'Recovery di Sistema'**
  String get tabRecovery;

  /// No description provided for @tabGrub.
  ///
  /// In it, this message translates to:
  /// **'GRUB'**
  String get tabGrub;

  /// No description provided for @tabKernel.
  ///
  /// In it, this message translates to:
  /// **'Kernel'**
  String get tabKernel;

  /// No description provided for @tabSettings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get tabSettings;

  /// No description provided for @modeStandard.
  ///
  /// In it, this message translates to:
  /// **'Standard'**
  String get modeStandard;

  /// No description provided for @modeAdvanced.
  ///
  /// In it, this message translates to:
  /// **'Avanzata'**
  String get modeAdvanced;

  /// No description provided for @warningTitle.
  ///
  /// In it, this message translates to:
  /// **'ATTENZIONE'**
  String get warningTitle;

  /// No description provided for @warningSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Applicazione per Utenti Esperti'**
  String get warningSubtitle;

  /// No description provided for @warningMessage.
  ///
  /// In it, this message translates to:
  /// **'Questa applicazione consente di modificare configurazioni critiche del sistema operativo Linux.'**
  String get warningMessage;

  /// No description provided for @warningGrub.
  ///
  /// In it, this message translates to:
  /// **'Modifiche a GRUB'**
  String get warningGrub;

  /// No description provided for @warningGrubDesc.
  ///
  /// In it, this message translates to:
  /// **'La modifica errata del bootloader può impedire l\'avvio del sistema.'**
  String get warningGrubDesc;

  /// No description provided for @warningKernel.
  ///
  /// In it, this message translates to:
  /// **'Rimozione Kernel'**
  String get warningKernel;

  /// No description provided for @warningKernelDesc.
  ///
  /// In it, this message translates to:
  /// **'Rimuovere kernel essenziali può rendere il sistema inutilizzabile.'**
  String get warningKernelDesc;

  /// No description provided for @warningServices.
  ///
  /// In it, this message translates to:
  /// **'Gestione Servizi'**
  String get warningServices;

  /// No description provided for @warningServicesDesc.
  ///
  /// In it, this message translates to:
  /// **'Disabilitare servizi critici può causare malfunzionamenti del sistema.'**
  String get warningServicesDesc;

  /// No description provided for @warningCleanup.
  ///
  /// In it, this message translates to:
  /// **'Pulizia File'**
  String get warningCleanup;

  /// No description provided for @warningCleanupDesc.
  ///
  /// In it, this message translates to:
  /// **'Eliminare file di sistema può compromettere la stabilità.'**
  String get warningCleanupDesc;

  /// No description provided for @warningBackup.
  ///
  /// In it, this message translates to:
  /// **'Si consiglia di creare backup del sistema prima di utilizzare questa applicazione.'**
  String get warningBackup;

  /// No description provided for @warningDontShow.
  ///
  /// In it, this message translates to:
  /// **'Non mostrare più questo avviso'**
  String get warningDontShow;

  /// No description provided for @warningAccept.
  ///
  /// In it, this message translates to:
  /// **'Ho Capito, Procedi'**
  String get warningAccept;

  /// No description provided for @passwordSetupTitle.
  ///
  /// In it, this message translates to:
  /// **'Configurazione Password'**
  String get passwordSetupTitle;

  /// No description provided for @passwordSetupDesc.
  ///
  /// In it, this message translates to:
  /// **'Per utilizzare le funzionalità che richiedono privilegi amministratore, è necessario configurare la password di sistema.'**
  String get passwordSetupDesc;

  /// No description provided for @passwordLabel.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la password di amministratore'**
  String get passwordHint;

  /// No description provided for @passwordConfirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma Password'**
  String get passwordConfirm;

  /// No description provided for @passwordConfirmHint.
  ///
  /// In it, this message translates to:
  /// **'Reinserisci la password'**
  String get passwordConfirmHint;

  /// No description provided for @passwordSave.
  ///
  /// In it, this message translates to:
  /// **'Salva Password'**
  String get passwordSave;

  /// No description provided for @passwordSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta per ora'**
  String get passwordSkip;

  /// No description provided for @passwordSaved.
  ///
  /// In it, this message translates to:
  /// **'Password salvata in modo sicuro utilizzando il keyring del sistema.'**
  String get passwordSaved;

  /// No description provided for @passwordError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il salvataggio'**
  String get passwordError;

  /// No description provided for @passwordMismatch.
  ///
  /// In it, this message translates to:
  /// **'Le password non corrispondono'**
  String get passwordMismatch;

  /// No description provided for @passwordEmpty.
  ///
  /// In it, this message translates to:
  /// **'Inserisci una password'**
  String get passwordEmpty;

  /// No description provided for @passwordRequired.
  ///
  /// In it, this message translates to:
  /// **'Password Richiesta'**
  String get passwordRequired;

  /// No description provided for @passwordRequiredMessage.
  ///
  /// In it, this message translates to:
  /// **'Per accedere a tutte le directory è necessaria la password di amministratore. La password verrà salvata in modo sicuro.'**
  String get passwordRequiredMessage;

  /// No description provided for @settingsPasswordTitle.
  ///
  /// In it, this message translates to:
  /// **'Password Amministratore'**
  String get settingsPasswordTitle;

  /// No description provided for @settingsPasswordDesc.
  ///
  /// In it, this message translates to:
  /// **'Salva la password di amministratore per utilizzare le funzionalità che richiedono privilegi sudo.'**
  String get settingsPasswordDesc;

  /// No description provided for @settingsPasswordSaved.
  ///
  /// In it, this message translates to:
  /// **'Password salvata. Puoi cambiarla o eliminarla.'**
  String get settingsPasswordSaved;

  /// No description provided for @settingsPasswordConfigured.
  ///
  /// In it, this message translates to:
  /// **'Password configurata'**
  String get settingsPasswordConfigured;

  /// No description provided for @settingsPasswordUpdate.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna Password'**
  String get settingsPasswordUpdate;

  /// No description provided for @settingsPasswordDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get settingsPasswordDelete;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In it, this message translates to:
  /// **'Tema Applicazione'**
  String get settingsThemeTitle;

  /// No description provided for @themeLight.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeSystemDesc.
  ///
  /// In it, this message translates to:
  /// **'Segue le impostazioni del sistema'**
  String get themeSystemDesc;

  /// No description provided for @settingsInfoTitle.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get settingsInfoTitle;

  /// No description provided for @settingsInfoDesc.
  ///
  /// In it, this message translates to:
  /// **'Questa applicazione ti aiuta a:'**
  String get settingsInfoDesc;

  /// No description provided for @settingsInfoItem1.
  ///
  /// In it, this message translates to:
  /// **'Trovare servizi systemd che rallentano l\'avvio'**
  String get settingsInfoItem1;

  /// No description provided for @settingsInfoItem2.
  ///
  /// In it, this message translates to:
  /// **'Gestire applicazioni all\'avvio'**
  String get settingsInfoItem2;

  /// No description provided for @settingsInfoItem3.
  ///
  /// In it, this message translates to:
  /// **'Pulire file temporanei del sistema'**
  String get settingsInfoItem3;

  /// No description provided for @loading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento in corso...'**
  String get loading;

  /// No description provided for @loadingSettings.
  ///
  /// In it, this message translates to:
  /// **'Sto caricando le impostazioni del sistema'**
  String get loadingSettings;

  /// No description provided for @error.
  ///
  /// In it, this message translates to:
  /// **'Errore'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @themeRestartMessage.
  ///
  /// In it, this message translates to:
  /// **'Il tema verrà applicato al riavvio dell\'applicazione'**
  String get themeRestartMessage;

  /// No description provided for @themeApplied.
  ///
  /// In it, this message translates to:
  /// **'Tema applicato con successo'**
  String get themeApplied;

  /// No description provided for @settingsFontTitle.
  ///
  /// In it, this message translates to:
  /// **'Font e Dimensione Testo'**
  String get settingsFontTitle;

  /// No description provided for @settingsFontDesc.
  ///
  /// In it, this message translates to:
  /// **'Personalizza il font e la dimensione del testo utilizzata in tutta l\'applicazione.'**
  String get settingsFontDesc;

  /// No description provided for @settingsSystemTrayTitle.
  ///
  /// In it, this message translates to:
  /// **'System Tray'**
  String get settingsSystemTrayTitle;

  /// No description provided for @settingsSystemTrayDesc.
  ///
  /// In it, this message translates to:
  /// **'Mostra l\'icona dell\'app nella system tray per comandi rapidi. Richiede le dipendenze di sistema (libappindicator).'**
  String get settingsSystemTrayDesc;

  /// No description provided for @settingsTrayDepsOk.
  ///
  /// In it, this message translates to:
  /// **'Dipendenze installate.'**
  String get settingsTrayDepsOk;

  /// No description provided for @settingsTrayDepsMissing.
  ///
  /// In it, this message translates to:
  /// **'Dipendenze mancanti. Installa per abilitare la system tray.'**
  String get settingsTrayDepsMissing;

  /// No description provided for @settingsSystemTrayEnable.
  ///
  /// In it, this message translates to:
  /// **'Abilita system tray'**
  String get settingsSystemTrayEnable;

  /// No description provided for @settingsTrayInstallDeps.
  ///
  /// In it, this message translates to:
  /// **'Installa dipendenze'**
  String get settingsTrayInstallDeps;

  /// No description provided for @settingsCloseToTray.
  ///
  /// In it, this message translates to:
  /// **'Rimani in tray alla chiusura'**
  String get settingsCloseToTray;

  /// No description provided for @settingsCloseToTrayDesc.
  ///
  /// In it, this message translates to:
  /// **'Se attivo, chiudendo o riducendo a icona la finestra l\'app resta in esecuzione nella system tray.'**
  String get settingsCloseToTrayDesc;

  /// No description provided for @settingsCloseToTrayOn.
  ///
  /// In it, this message translates to:
  /// **'Chiusura in tray attivata.'**
  String get settingsCloseToTrayOn;

  /// No description provided for @settingsCloseToTrayOff.
  ///
  /// In it, this message translates to:
  /// **'Chiusura in tray disattivata. La chiusura della finestra terminerà l\'app.'**
  String get settingsCloseToTrayOff;

  /// No description provided for @settingsTrayEnabled.
  ///
  /// In it, this message translates to:
  /// **'System tray abilitato.'**
  String get settingsTrayEnabled;

  /// No description provided for @settingsTrayDisabled.
  ///
  /// In it, this message translates to:
  /// **'System tray disabilitato. Riavvia l\'app per applicare.'**
  String get settingsTrayDisabled;

  /// No description provided for @settingsStartMinimized.
  ///
  /// In it, this message translates to:
  /// **'Avvia l\'app ridotta a icona'**
  String get settingsStartMinimized;

  /// No description provided for @settingsStartMinimizedDesc.
  ///
  /// In it, this message translates to:
  /// **'Se attivo, l\'app si avvia senza mostrare la finestra principale, solo l\'icona nella system tray.'**
  String get settingsStartMinimizedDesc;

  /// No description provided for @settingsStartMinimizedOn.
  ///
  /// In it, this message translates to:
  /// **'Avvio ridotto a icona attivato. Al prossimo avvio l\'app aprirà solo in tray.'**
  String get settingsStartMinimizedOn;

  /// No description provided for @settingsStartMinimizedOff.
  ///
  /// In it, this message translates to:
  /// **'Avvio ridotto a icona disattivato.'**
  String get settingsStartMinimizedOff;

  /// No description provided for @settingsStartAtLogin.
  ///
  /// In it, this message translates to:
  /// **'Avvia l\'app all\'avvio del sistema'**
  String get settingsStartAtLogin;

  /// No description provided for @settingsStartAtLoginDesc.
  ///
  /// In it, this message translates to:
  /// **'Se attivo, l\'app si avvia automaticamente al login.'**
  String get settingsStartAtLoginDesc;

  /// No description provided for @settingsStartAtLoginOn.
  ///
  /// In it, this message translates to:
  /// **'Avvio al login attivato. L\'app si avvierà al login.'**
  String get settingsStartAtLoginOn;

  /// No description provided for @settingsStartAtLoginOff.
  ///
  /// In it, this message translates to:
  /// **'Avvio al login disattivato.'**
  String get settingsStartAtLoginOff;

  /// No description provided for @settingsStartAtLoginError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile modificare l\'avvio al login.'**
  String get settingsStartAtLoginError;

  /// No description provided for @settingsAutoUpdateCheckTitle.
  ///
  /// In it, this message translates to:
  /// **'Verifica aggiornamenti automatica'**
  String get settingsAutoUpdateCheckTitle;

  /// No description provided for @settingsAutoUpdateCheckDesc.
  ///
  /// In it, this message translates to:
  /// **'Controlla gli aggiornamenti di sistema automaticamente con la frequenza scelta.'**
  String get settingsAutoUpdateCheckDesc;

  /// No description provided for @settingsAutoUpdateCheckInterval.
  ///
  /// In it, this message translates to:
  /// **'Verifica aggiornamenti'**
  String get settingsAutoUpdateCheckInterval;

  /// No description provided for @settingsAutoUpdateNever.
  ///
  /// In it, this message translates to:
  /// **'Mai'**
  String get settingsAutoUpdateNever;

  /// No description provided for @settingsAutoUpdateEvery15Min.
  ///
  /// In it, this message translates to:
  /// **'Ogni 15 minuti'**
  String get settingsAutoUpdateEvery15Min;

  /// No description provided for @settingsAutoUpdateEvery30Min.
  ///
  /// In it, this message translates to:
  /// **'Ogni 30 minuti'**
  String get settingsAutoUpdateEvery30Min;

  /// No description provided for @settingsAutoUpdateEvery1Hour.
  ///
  /// In it, this message translates to:
  /// **'Ogni 1 ora'**
  String get settingsAutoUpdateEvery1Hour;

  /// No description provided for @settingsAutoUpdateEvery6Hours.
  ///
  /// In it, this message translates to:
  /// **'Ogni 6 ore'**
  String get settingsAutoUpdateEvery6Hours;

  /// No description provided for @settingsAutoUpdateEvery12Hours.
  ///
  /// In it, this message translates to:
  /// **'Ogni 12 ore'**
  String get settingsAutoUpdateEvery12Hours;

  /// No description provided for @settingsAutoUpdateEveryDay.
  ///
  /// In it, this message translates to:
  /// **'Ogni giorno'**
  String get settingsAutoUpdateEveryDay;

  /// No description provided for @settingsAutoAppUpdateFromGithubTitle.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento automatico app da GitHub'**
  String get settingsAutoAppUpdateFromGithubTitle;

  /// No description provided for @settingsAutoAppUpdateFromGithubDesc.
  ///
  /// In it, this message translates to:
  /// **'Se attivo, l\'app scarica e installa periodicamente l\'ultimo .deb di questa edizione dalle release GitHub. Richiede password amministratore salvata e funziona solo se sopra è attiva la verifica periodica aggiornamenti di sistema.'**
  String get settingsAutoAppUpdateFromGithubDesc;

  /// No description provided for @updateCheckAptNone.
  ///
  /// In it, this message translates to:
  /// **'APT: Nessun aggiornamento disponibile'**
  String get updateCheckAptNone;

  /// No description provided for @updateCheckAptPhasedOnly.
  ///
  /// In it, this message translates to:
  /// **'APT: Nessun aggiornamento installabile subito (solo rollout scaglionato)'**
  String get updateCheckAptPhasedOnly;

  /// No description provided for @updateCheckAptHasUpdates.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{APT: {count} aggiornamento disponibile} other{APT: {count} aggiornamenti disponibili}}'**
  String updateCheckAptHasUpdates(int count);

  /// No description provided for @updateCheckAptPhasedExtra.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{APT: {count} aggiornamento scaglionato rilevato} other{APT: {count} aggiornamenti scaglionati rilevati}}'**
  String updateCheckAptPhasedExtra(int count);

  /// No description provided for @updateCheckAptError.
  ///
  /// In it, this message translates to:
  /// **'APT: Errore durante la verifica: {error}'**
  String updateCheckAptError(String error);

  /// No description provided for @updateCheckDnfNone.
  ///
  /// In it, this message translates to:
  /// **'DNF: Nessun aggiornamento disponibile'**
  String get updateCheckDnfNone;

  /// No description provided for @updateCheckDnfHasUpdates.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{DNF: {count} aggiornamento disponibile} other{DNF: {count} aggiornamenti disponibili}}'**
  String updateCheckDnfHasUpdates(int count);

  /// No description provided for @updateCheckDnfError.
  ///
  /// In it, this message translates to:
  /// **'DNF: Errore durante la verifica: {error}'**
  String updateCheckDnfError(String error);

  /// No description provided for @updateCheckPacmanNone.
  ///
  /// In it, this message translates to:
  /// **'Pacman: Nessun aggiornamento disponibile'**
  String get updateCheckPacmanNone;

  /// No description provided for @updateCheckPacmanHasUpdates.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{Pacman: {count} aggiornamento disponibile} other{Pacman: {count} aggiornamenti disponibili}}'**
  String updateCheckPacmanHasUpdates(int count);

  /// No description provided for @updateCheckPacmanError.
  ///
  /// In it, this message translates to:
  /// **'Pacman: Errore durante la verifica: {error}'**
  String updateCheckPacmanError(String error);

  /// No description provided for @updateCheckSnapNone.
  ///
  /// In it, this message translates to:
  /// **'Snap: Nessun aggiornamento disponibile'**
  String get updateCheckSnapNone;

  /// No description provided for @updateCheckSnapHasUpdates.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{Snap: {count} aggiornamento disponibile} other{Snap: {count} aggiornamenti disponibili}}'**
  String updateCheckSnapHasUpdates(int count);

  /// No description provided for @updateCheckSnapError.
  ///
  /// In it, this message translates to:
  /// **'Snap: Errore durante la verifica: {error}'**
  String updateCheckSnapError(String error);

  /// No description provided for @updateCheckFlatpakNone.
  ///
  /// In it, this message translates to:
  /// **'Flatpak: Nessun aggiornamento disponibile'**
  String get updateCheckFlatpakNone;

  /// No description provided for @updateCheckFlatpakHasUpdates.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{Flatpak: {count} aggiornamento disponibile} other{Flatpak: {count} aggiornamenti disponibili}}'**
  String updateCheckFlatpakHasUpdates(int count);

  /// No description provided for @updateCheckFlatpakError.
  ///
  /// In it, this message translates to:
  /// **'Flatpak: Errore durante la verifica: {error}'**
  String updateCheckFlatpakError(String error);

  /// No description provided for @updateCheckSummaryPackageCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{0 pacchetti} one{{count} pacchetto} other{{count} pacchetti}}'**
  String updateCheckSummaryPackageCount(int count);

  /// No description provided for @updatesAvailableCount.
  ///
  /// In it, this message translates to:
  /// **'{count} aggiornamenti disponibili'**
  String updatesAvailableCount(int count);

  /// No description provided for @updatesAvailableDialogTitle.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamenti disponibili'**
  String get updatesAvailableDialogTitle;

  /// No description provided for @updatesAvailableDialogMessage.
  ///
  /// In it, this message translates to:
  /// **'{count} aggiornamenti disponibili. Vuoi applicarli ora?'**
  String updatesAvailableDialogMessage(int count);

  /// No description provided for @updatesAvailableDetectedListHeading.
  ///
  /// In it, this message translates to:
  /// **'Rilevati:'**
  String get updatesAvailableDetectedListHeading;

  /// No description provided for @updateLabelPhased.
  ///
  /// In it, this message translates to:
  /// **'{name} (scaglionato — non ancora installabile)'**
  String updateLabelPhased(String name);

  /// No description provided for @updatesPreviewTruncated.
  ///
  /// In it, this message translates to:
  /// **'… e altri {count}'**
  String updatesPreviewTruncated(int count);

  /// No description provided for @updatesAvailablePhasedFooter.
  ///
  /// In it, this message translates to:
  /// **'I pacchetti in rollout graduale non si possono installare subito. \"Applica ora\" aggiorna solo ciò che il sistema consente.'**
  String get updatesAvailablePhasedFooter;

  /// No description provided for @updatesCheckPreviewHeading.
  ///
  /// In it, this message translates to:
  /// **'Elementi interessati:'**
  String get updatesCheckPreviewHeading;

  /// No description provided for @applyNow.
  ///
  /// In it, this message translates to:
  /// **'Applica ora'**
  String get applyNow;

  /// No description provided for @postpone.
  ///
  /// In it, this message translates to:
  /// **'Rimanda'**
  String get postpone;

  /// No description provided for @fontFamily.
  ///
  /// In it, this message translates to:
  /// **'Famiglia Font'**
  String get fontFamily;

  /// No description provided for @fontSize.
  ///
  /// In it, this message translates to:
  /// **'Dimensione Font'**
  String get fontSize;

  /// No description provided for @fontDefault.
  ///
  /// In it, this message translates to:
  /// **'Default (Roboto)'**
  String get fontDefault;

  /// No description provided for @fontRestartMessage.
  ///
  /// In it, this message translates to:
  /// **'Il font verrà applicato al riavvio dell\'applicazione'**
  String get fontRestartMessage;

  /// No description provided for @themeApplyError.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'applicazione del tema'**
  String get themeApplyError;

  /// No description provided for @userThemesExtensionMessage.
  ///
  /// In it, this message translates to:
  /// **'Per temi Shell completi, installa l\'estensione User Themes da extensions.gnome.org'**
  String get userThemesExtensionMessage;

  /// No description provided for @themeRequiresOcsUrl.
  ///
  /// In it, this message translates to:
  /// **'Questo tema richiede ocs-url per essere installato correttamente'**
  String get themeRequiresOcsUrl;

  /// No description provided for @installOcsUrl.
  ///
  /// In it, this message translates to:
  /// **'Installa ocs-url'**
  String get installOcsUrl;

  /// No description provided for @ocsUrlNotInstalled.
  ///
  /// In it, this message translates to:
  /// **'ocs-url non è installato. Alcuni temi potrebbero non funzionare correttamente.'**
  String get ocsUrlNotInstalled;

  /// No description provided for @ocsUrlInstalled.
  ///
  /// In it, this message translates to:
  /// **'ocs-url installato con successo!'**
  String get ocsUrlInstalled;

  /// No description provided for @ocsUrlInstallError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'installazione di ocs-url. Verifica che la password sia corretta e che il package manager sia disponibile.'**
  String get ocsUrlInstallError;

  /// No description provided for @installingOcsUrl.
  ///
  /// In it, this message translates to:
  /// **'Installazione ocs-url in corso...'**
  String get installingOcsUrl;

  /// No description provided for @installingOcsUrlDescription.
  ///
  /// In it, this message translates to:
  /// **'Questa operazione viene eseguita automaticamente al primo avvio.'**
  String get installingOcsUrlDescription;

  /// No description provided for @themeToolsMessage.
  ///
  /// In it, this message translates to:
  /// **'Per installare temi da OpenDesktop.org/Pling.com, installa ocs-url o PLing-store. Alcuni temi richiedono questi strumenti per funzionare correttamente.'**
  String get themeToolsMessage;

  /// No description provided for @refresh.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get refresh;

  /// No description provided for @search.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get search;

  /// No description provided for @noResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato trovato'**
  String get noResults;

  /// No description provided for @enabled.
  ///
  /// In it, this message translates to:
  /// **'Abilitato'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In it, this message translates to:
  /// **'Disabilitato'**
  String get disabled;

  /// No description provided for @active.
  ///
  /// In it, this message translates to:
  /// **'Attivo'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In it, this message translates to:
  /// **'Inattivo'**
  String get inactive;

  /// No description provided for @start.
  ///
  /// In it, this message translates to:
  /// **'Avvia'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In it, this message translates to:
  /// **'Ferma'**
  String get stop;

  /// No description provided for @restart.
  ///
  /// In it, this message translates to:
  /// **'Riavvia'**
  String get restart;

  /// No description provided for @enable.
  ///
  /// In it, this message translates to:
  /// **'Abilita'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In it, this message translates to:
  /// **'Disabilita'**
  String get disable;

  /// No description provided for @remove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get remove;

  /// No description provided for @kill.
  ///
  /// In it, this message translates to:
  /// **'Termina'**
  String get kill;

  /// No description provided for @killForce.
  ///
  /// In it, this message translates to:
  /// **'Termina forzatamente'**
  String get killForce;

  /// No description provided for @processes.
  ///
  /// In it, this message translates to:
  /// **'Processi'**
  String get processes;

  /// No description provided for @system.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get system;

  /// No description provided for @cpu.
  ///
  /// In it, this message translates to:
  /// **'CPU'**
  String get cpu;

  /// No description provided for @memory.
  ///
  /// In it, this message translates to:
  /// **'Memoria'**
  String get memory;

  /// No description provided for @disk.
  ///
  /// In it, this message translates to:
  /// **'Disco'**
  String get disk;

  /// No description provided for @gpu.
  ///
  /// In it, this message translates to:
  /// **'Scheda Video'**
  String get gpu;

  /// No description provided for @usage.
  ///
  /// In it, this message translates to:
  /// **'Uso'**
  String get usage;

  /// No description provided for @total.
  ///
  /// In it, this message translates to:
  /// **'Totale'**
  String get total;

  /// No description provided for @used.
  ///
  /// In it, this message translates to:
  /// **'Usata'**
  String get used;

  /// No description provided for @free.
  ///
  /// In it, this message translates to:
  /// **'Libera'**
  String get free;

  /// No description provided for @model.
  ///
  /// In it, this message translates to:
  /// **'Modello'**
  String get model;

  /// No description provided for @driver.
  ///
  /// In it, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @temperature.
  ///
  /// In it, this message translates to:
  /// **'Temperatura'**
  String get temperature;

  /// No description provided for @version.
  ///
  /// In it, this message translates to:
  /// **'Versione'**
  String get version;

  /// No description provided for @creator.
  ///
  /// In it, this message translates to:
  /// **'Creatore'**
  String get creator;

  /// No description provided for @creatorName.
  ///
  /// In it, this message translates to:
  /// **'Marco Di Giangiacomo'**
  String get creatorName;

  /// No description provided for @appDescription.
  ///
  /// In it, this message translates to:
  /// **'Super Linux Utility è un\'applicazione desktop per la gestione del sistema Linux: servizi, applicazioni di avvio, pulizia, pacchetti installati, monitoraggio delle risorse e impostazioni d\'aspetto.'**
  String get appDescription;

  /// No description provided for @features.
  ///
  /// In it, this message translates to:
  /// **'Caratteristiche'**
  String get features;

  /// No description provided for @appExpertUsers.
  ///
  /// In it, this message translates to:
  /// **'Applicazione progettata per utenti esperti Linux'**
  String get appExpertUsers;

  /// No description provided for @infoProjectWebsite.
  ///
  /// In it, this message translates to:
  /// **'Sito web del progetto'**
  String get infoProjectWebsite;

  /// No description provided for @infoChangelog.
  ///
  /// In it, this message translates to:
  /// **'Registro delle modifiche'**
  String get infoChangelog;

  /// No description provided for @infoChangelogShowAll.
  ///
  /// In it, this message translates to:
  /// **'Vedi registro completo'**
  String get infoChangelogShowAll;

  /// No description provided for @applicationIdLabel.
  ///
  /// In it, this message translates to:
  /// **'ID applicazione (desktop)'**
  String get applicationIdLabel;

  /// No description provided for @updatesPendingPackagesTitle.
  ///
  /// In it, this message translates to:
  /// **'Pacchetti in coda (ultimo controllo)'**
  String get updatesPendingPackagesTitle;

  /// No description provided for @updatesProgressCurrent.
  ///
  /// In it, this message translates to:
  /// **'Avanzamento: {detail}'**
  String updatesProgressCurrent(String detail);

  /// No description provided for @updatesCommandOutputTitle.
  ///
  /// In it, this message translates to:
  /// **'Output del comando'**
  String get updatesCommandOutputTitle;

  /// No description provided for @disclaimerLicenseTitle.
  ///
  /// In it, this message translates to:
  /// **'Licenza e Disclaimer'**
  String get disclaimerLicenseTitle;

  /// No description provided for @disclaimerGplNotice.
  ///
  /// In it, this message translates to:
  /// **'Questa applicazione è software libero; puoi ridistribuirlo e/o modificarlo secondo i termini della GNU General Public License pubblicata dalla Free Software Foundation, versione 3 della Licenza o (a tua scelta) successiva.'**
  String get disclaimerGplNotice;

  /// No description provided for @disclaimerNoWarranty.
  ///
  /// In it, this message translates to:
  /// **'Questo programma è distribuito nella speranza che sia utile, ma SENZA ALCUNA GARANZIA; senza nemmeno la garanzia implicita di COMMERCIABILITÀ o IDONEITÀ PER UN PARTICOLARE SCOPO. Vedere la GNU General Public License per i dettagli.'**
  String get disclaimerNoWarranty;

  /// No description provided for @disclaimerCopyright.
  ///
  /// In it, this message translates to:
  /// **'Copyright (c) 2024-2025 Marco Di Giangiacomo. Tutti i diritti riservati sotto GPL-3.0.'**
  String get disclaimerCopyright;

  /// No description provided for @payWithPaypal.
  ///
  /// In it, this message translates to:
  /// **'Paga con PayPal'**
  String get payWithPaypal;

  /// No description provided for @purchaseLicenseViaPaypal.
  ///
  /// In it, this message translates to:
  /// **'La versione Advanced costa 19,99 €. Per acquistare una licenza paga tramite PayPal. Dopo il pagamento andato a buon fine riceverai il codice licenza via email. Senza un pagamento valido l\'app non può essere attivata.'**
  String get purchaseLicenseViaPaypal;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In it, this message translates to:
  /// **'Selezione Lingua'**
  String get languageSelectionTitle;

  /// No description provided for @languageSelectionDesc.
  ///
  /// In it, this message translates to:
  /// **'Seleziona la lingua per l\'applicazione'**
  String get languageSelectionDesc;

  /// No description provided for @languageItalian.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @languageEnglish.
  ///
  /// In it, this message translates to:
  /// **'Inglese'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In it, this message translates to:
  /// **'Francese'**
  String get languageFrench;

  /// No description provided for @languageSpanish.
  ///
  /// In it, this message translates to:
  /// **'Spagnolo'**
  String get languageSpanish;

  /// No description provided for @languageGerman.
  ///
  /// In it, this message translates to:
  /// **'Tedesco'**
  String get languageGerman;

  /// No description provided for @languagePortuguese.
  ///
  /// In it, this message translates to:
  /// **'Portoghese'**
  String get languagePortuguese;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In it, this message translates to:
  /// **'Lingua Applicazione'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageDesc.
  ///
  /// In it, this message translates to:
  /// **'Seleziona la lingua dell\'interfaccia'**
  String get settingsLanguageDesc;

  /// No description provided for @languageRestartMessage.
  ///
  /// In it, this message translates to:
  /// **'Lingua aggiornata'**
  String get languageRestartMessage;

  /// No description provided for @servicesSlow.
  ///
  /// In it, this message translates to:
  /// **'Servizi Lenti'**
  String get servicesSlow;

  /// No description provided for @servicesAll.
  ///
  /// In it, this message translates to:
  /// **'Tutti i Servizi'**
  String get servicesAll;

  /// No description provided for @servicesDisabled.
  ///
  /// In it, this message translates to:
  /// **'Disabilitati'**
  String get servicesDisabled;

  /// No description provided for @analyzeAll.
  ///
  /// In it, this message translates to:
  /// **'Analizza Tutti'**
  String get analyzeAll;

  /// No description provided for @status.
  ///
  /// In it, this message translates to:
  /// **'Stato'**
  String get status;

  /// No description provided for @startupTime.
  ///
  /// In it, this message translates to:
  /// **'Tempo avvio'**
  String get startupTime;

  /// No description provided for @noServicesFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun servizio trovato.'**
  String get noServicesFound;

  /// No description provided for @reEnable.
  ///
  /// In it, this message translates to:
  /// **'Riabilita'**
  String get reEnable;

  /// No description provided for @yes.
  ///
  /// In it, this message translates to:
  /// **'Sì'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In it, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @cleanupConfirmTitle.
  ///
  /// In it, this message translates to:
  /// **'Conferma pulizia'**
  String get cleanupConfirmTitle;

  /// No description provided for @cleanupConfirmMessage.
  ///
  /// In it, this message translates to:
  /// **'Vuoi eliminare tutti i file temporanei? Questa operazione non può essere annullata.'**
  String get cleanupConfirmMessage;

  /// No description provided for @cleanupSuccess.
  ///
  /// In it, this message translates to:
  /// **'Pulizia completata con successo!'**
  String get cleanupSuccess;

  /// No description provided for @cleanupPartialSuccess.
  ///
  /// In it, this message translates to:
  /// **'Pulizia completata con alcuni errori.'**
  String get cleanupPartialSuccess;

  /// No description provided for @protectedSystemApp.
  ///
  /// In it, this message translates to:
  /// **'App di Sistema Protetta'**
  String get protectedSystemApp;

  /// No description provided for @cannotDisableSystemApp.
  ///
  /// In it, this message translates to:
  /// **'Non è possibile disabilitare \"{appName}\" perché è un\'applicazione di sistema essenziale.'**
  String cannotDisableSystemApp(String appName);

  /// No description provided for @systemAppsRequired.
  ///
  /// In it, this message translates to:
  /// **'Le app di sistema sono necessarie per il corretto funzionamento del desktop environment e non possono essere disabilitate.'**
  String get systemAppsRequired;

  /// No description provided for @checkingDependencies.
  ///
  /// In it, this message translates to:
  /// **'Controllo dipendenze...'**
  String get checkingDependencies;

  /// No description provided for @warning.
  ///
  /// In it, this message translates to:
  /// **'⚠️ Avviso'**
  String get warning;

  /// No description provided for @packagesDependingOnThis.
  ///
  /// In it, this message translates to:
  /// **'Pacchetti che dipendono da questo:'**
  String get packagesDependingOnThis;

  /// No description provided for @areYouSure.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler procedere?'**
  String get areYouSure;

  /// No description provided for @confirmRemoval.
  ///
  /// In it, this message translates to:
  /// **'Conferma rimozione'**
  String get confirmRemoval;

  /// No description provided for @removeAppQuestion.
  ///
  /// In it, this message translates to:
  /// **'Vuoi rimuovere {appName}?'**
  String removeAppQuestion(String appName);

  /// No description provided for @searchApp.
  ///
  /// In it, this message translates to:
  /// **'Cerca app'**
  String get searchApp;

  /// No description provided for @all.
  ///
  /// In it, this message translates to:
  /// **'Tutti'**
  String get all;

  /// No description provided for @searchProcess.
  ///
  /// In it, this message translates to:
  /// **'Cerca processo'**
  String get searchProcess;

  /// No description provided for @processesSelected.
  ///
  /// In it, this message translates to:
  /// **'{count} processo selezionato'**
  String processesSelected(int count);

  /// No description provided for @processesSelectedPlural.
  ///
  /// In it, this message translates to:
  /// **'{count} processi selezionati'**
  String processesSelectedPlural(int count);

  /// No description provided for @app.
  ///
  /// In it, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @cpuPercent.
  ///
  /// In it, this message translates to:
  /// **'CPU %'**
  String get cpuPercent;

  /// No description provided for @name.
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get name;

  /// No description provided for @pid.
  ///
  /// In it, this message translates to:
  /// **'PID'**
  String get pid;

  /// No description provided for @user.
  ///
  /// In it, this message translates to:
  /// **'Utente'**
  String get user;

  /// No description provided for @noProcessesFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun processo trovato.'**
  String get noProcessesFound;

  /// No description provided for @selectAll.
  ///
  /// In it, this message translates to:
  /// **'Seleziona tutti'**
  String get selectAll;

  /// No description provided for @terminateAll.
  ///
  /// In it, this message translates to:
  /// **'Termina tutti'**
  String get terminateAll;

  /// No description provided for @terminateAllForce.
  ///
  /// In it, this message translates to:
  /// **'Termina forzatamente tutti'**
  String get terminateAllForce;

  /// No description provided for @cannotLoadSystemInfo.
  ///
  /// In it, this message translates to:
  /// **'Impossibile caricare le informazioni di sistema.'**
  String get cannotLoadSystemInfo;

  /// No description provided for @cores.
  ///
  /// In it, this message translates to:
  /// **'Core'**
  String get cores;

  /// No description provided for @threads.
  ///
  /// In it, this message translates to:
  /// **'Threads'**
  String get threads;

  /// No description provided for @grubInvalidContent.
  ///
  /// In it, this message translates to:
  /// **'Il contenuto del file GRUB non è valido'**
  String get grubInvalidContent;

  /// No description provided for @grubConfirmSave.
  ///
  /// In it, this message translates to:
  /// **'Conferma Salvataggio'**
  String get grubConfirmSave;

  /// No description provided for @grubSaveWarning.
  ///
  /// In it, this message translates to:
  /// **'Stai per modificare la configurazione di GRUB. Questa operazione:'**
  String get grubSaveWarning;

  /// No description provided for @grubWillCreateBackup.
  ///
  /// In it, this message translates to:
  /// **'• Creerà un backup automatico'**
  String get grubWillCreateBackup;

  /// No description provided for @grubWillSave.
  ///
  /// In it, this message translates to:
  /// **'• Salverà le modifiche'**
  String get grubWillSave;

  /// No description provided for @grubWillUpdate.
  ///
  /// In it, this message translates to:
  /// **'• Aggiornerà GRUB'**
  String get grubWillUpdate;

  /// No description provided for @grubWarning.
  ///
  /// In it, this message translates to:
  /// **'ATTENZIONE: Modifiche errate possono impedire l\'avvio del sistema!'**
  String get grubWarning;

  /// No description provided for @saveAndUpdate.
  ///
  /// In it, this message translates to:
  /// **'Salva e Aggiorna'**
  String get saveAndUpdate;

  /// No description provided for @grubSavedSuccess.
  ///
  /// In it, this message translates to:
  /// **'Configurazione GRUB salvata e aggiornata con successo'**
  String get grubSavedSuccess;

  /// No description provided for @grubSaveError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il salvataggio'**
  String get grubSaveError;

  /// No description provided for @reload.
  ///
  /// In it, this message translates to:
  /// **'Ricarica'**
  String get reload;

  /// No description provided for @restoreBackup.
  ///
  /// In it, this message translates to:
  /// **'Ripristina Backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupQuestion.
  ///
  /// In it, this message translates to:
  /// **'Vuoi ripristinare il backup della configurazione GRUB?'**
  String get restoreBackupQuestion;

  /// No description provided for @restore.
  ///
  /// In it, this message translates to:
  /// **'Ripristina'**
  String get restore;

  /// No description provided for @backupRestoredSuccess.
  ///
  /// In it, this message translates to:
  /// **'Backup ripristinato con successo'**
  String get backupRestoredSuccess;

  /// No description provided for @backupRestoreError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il ripristino del backup'**
  String get backupRestoreError;

  /// No description provided for @kernelCannotRemoveActive.
  ///
  /// In it, this message translates to:
  /// **'Non è possibile rimuovere il kernel attualmente in uso'**
  String get kernelCannotRemoveActive;

  /// No description provided for @removeKernel.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi Kernel'**
  String get removeKernel;

  /// No description provided for @removeKernelQuestion.
  ///
  /// In it, this message translates to:
  /// **'Vuoi rimuovere il kernel {version}?'**
  String removeKernelQuestion(String version);

  /// No description provided for @thisOperation.
  ///
  /// In it, this message translates to:
  /// **'Questa operazione:'**
  String get thisOperation;

  /// No description provided for @willRemovePackage.
  ///
  /// In it, this message translates to:
  /// **'• Rimuoverà il pacchetto del kernel'**
  String get willRemovePackage;

  /// No description provided for @willUpdateGrub.
  ///
  /// In it, this message translates to:
  /// **'• Aggiornerà GRUB'**
  String get willUpdateGrub;

  /// No description provided for @kernelWarning.
  ///
  /// In it, this message translates to:
  /// **'ATTENZIONE: Assicurati di avere almeno un kernel funzionante!'**
  String get kernelWarning;

  /// No description provided for @kernelRemovedSuccess.
  ///
  /// In it, this message translates to:
  /// **'Kernel {version} rimosso con successo'**
  String kernelRemovedSuccess(String version);

  /// No description provided for @kernelRemoveError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante la rimozione del kernel'**
  String get kernelRemoveError;

  /// No description provided for @setDefaultKernel.
  ///
  /// In it, this message translates to:
  /// **'Imposta kernel predefinito (GRUB)'**
  String get setDefaultKernel;

  /// No description provided for @setDefaultKernelQuestion.
  ///
  /// In it, this message translates to:
  /// **'Impostare {version} come kernel predefinito al prossimo avvio? Verranno usati comandi GRUB con privilegi di amministratore.'**
  String setDefaultKernelQuestion(String version);

  /// No description provided for @set.
  ///
  /// In it, this message translates to:
  /// **'Imposta'**
  String get set;

  /// No description provided for @kernelSetDefaultSuccess.
  ///
  /// In it, this message translates to:
  /// **'Kernel {version} impostato come predefinito in GRUB'**
  String kernelSetDefaultSuccess(String version);

  /// No description provided for @kernelSetDefaultError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'impostazione del kernel default'**
  String get kernelSetDefaultError;

  /// No description provided for @keepMax.
  ///
  /// In it, this message translates to:
  /// **'Mantieni max:'**
  String get keepMax;

  /// No description provided for @cleanupKernels.
  ///
  /// In it, this message translates to:
  /// **'Pulizia Kernel'**
  String get cleanupKernels;

  /// No description provided for @keepOnlyRecentKernels.
  ///
  /// In it, this message translates to:
  /// **'Vuoi mantenere solo i {count} kernel più recenti?'**
  String keepOnlyRecentKernels(int count);

  /// No description provided for @totalKernels.
  ///
  /// In it, this message translates to:
  /// **'Kernel totali: {count}'**
  String totalKernels(int count);

  /// No description provided for @kernelsToKeep.
  ///
  /// In it, this message translates to:
  /// **'Kernel da mantenere: {count}'**
  String kernelsToKeep(int count);

  /// No description provided for @kernelsToRemove.
  ///
  /// In it, this message translates to:
  /// **'Kernel da rimuovere: {count}'**
  String kernelsToRemove(int count);

  /// No description provided for @cleanupKernelsWarning.
  ///
  /// In it, this message translates to:
  /// **'ATTENZIONE: Verranno rimossi solo i kernel non in uso.'**
  String get cleanupKernelsWarning;

  /// No description provided for @cleanup.
  ///
  /// In it, this message translates to:
  /// **'Pulisci'**
  String get cleanup;

  /// No description provided for @kernelCleanupSuccess.
  ///
  /// In it, this message translates to:
  /// **'Pulizia kernel completata con successo'**
  String get kernelCleanupSuccess;

  /// No description provided for @kernelCleanupError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante la pulizia dei kernel'**
  String get kernelCleanupError;

  /// No description provided for @invalidKernelCount.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un numero valido di kernel da mantenere'**
  String get invalidKernelCount;

  /// No description provided for @noKernelsFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun kernel installato trovato'**
  String get noKernelsFound;

  /// No description provided for @updateGrub.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna GRUB'**
  String get updateGrub;

  /// No description provided for @updateGrubQuestion.
  ///
  /// In it, this message translates to:
  /// **'Vuoi aggiornare GRUB? Questa operazione aggiornerà la configurazione del bootloader.'**
  String get updateGrubQuestion;

  /// No description provided for @grubUpdateSuccess.
  ///
  /// In it, this message translates to:
  /// **'GRUB aggiornato con successo'**
  String get grubUpdateSuccess;

  /// No description provided for @grubUpdateError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'aggiornamento di GRUB'**
  String get grubUpdateError;

  /// No description provided for @rebootSystem.
  ///
  /// In it, this message translates to:
  /// **'Riavvia Sistema'**
  String get rebootSystem;

  /// No description provided for @rebootSystemQuestion.
  ///
  /// In it, this message translates to:
  /// **'Vuoi riavviare il sistema? Tutte le applicazioni aperte verranno chiuse.'**
  String get rebootSystemQuestion;

  /// No description provided for @rebootSystemSuccess.
  ///
  /// In it, this message translates to:
  /// **'Il sistema si sta riavviando...'**
  String get rebootSystemSuccess;

  /// No description provided for @rebootSystemError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il riavvio del sistema'**
  String get rebootSystemError;

  /// No description provided for @package.
  ///
  /// In it, this message translates to:
  /// **'Pacchetto'**
  String get package;

  /// No description provided for @size.
  ///
  /// In it, this message translates to:
  /// **'Dimensione'**
  String get size;

  /// No description provided for @setAsDefault.
  ///
  /// In it, this message translates to:
  /// **'Imposta come predefinito'**
  String get setAsDefault;

  /// No description provided for @refreshDimensions.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna Dimensioni'**
  String get refreshDimensions;

  /// No description provided for @cleanupTempFiles.
  ///
  /// In it, this message translates to:
  /// **'Pulisci File Temporanei'**
  String get cleanupTempFiles;

  /// No description provided for @disableApp.
  ///
  /// In it, this message translates to:
  /// **'Disabilita App'**
  String get disableApp;

  /// No description provided for @onlyDisable.
  ///
  /// In it, this message translates to:
  /// **'Solo Disabilita'**
  String get onlyDisable;

  /// No description provided for @systemApps.
  ///
  /// In it, this message translates to:
  /// **'App di Sistema'**
  String get systemApps;

  /// No description provided for @close.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get close;

  /// No description provided for @updateStartupApps.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna App all\'Avvio'**
  String get updateStartupApps;

  /// No description provided for @saving.
  ///
  /// In it, this message translates to:
  /// **'Salvataggio...'**
  String get saving;

  /// No description provided for @scaleFactor.
  ///
  /// In it, this message translates to:
  /// **'Fattore di scala:'**
  String get scaleFactor;

  /// No description provided for @maximize.
  ///
  /// In it, this message translates to:
  /// **'Massimizzare'**
  String get maximize;

  /// No description provided for @minimize.
  ///
  /// In it, this message translates to:
  /// **'Minimizzare'**
  String get minimize;

  /// No description provided for @positioning.
  ///
  /// In it, this message translates to:
  /// **'Posizionamento:'**
  String get positioning;

  /// No description provided for @left.
  ///
  /// In it, this message translates to:
  /// **'Sinistra'**
  String get left;

  /// No description provided for @right.
  ///
  /// In it, this message translates to:
  /// **'Destra'**
  String get right;

  /// No description provided for @buttonOrder.
  ///
  /// In it, this message translates to:
  /// **'Ordine pulsanti:'**
  String get buttonOrder;

  /// No description provided for @attachedDialogs.
  ///
  /// In it, this message translates to:
  /// **'Finestre di dialogo allegate'**
  String get attachedDialogs;

  /// No description provided for @centerNewWindows.
  ///
  /// In it, this message translates to:
  /// **'Accentra le nuove finestre'**
  String get centerNewWindows;

  /// No description provided for @resizeWithSecondaryClick.
  ///
  /// In it, this message translates to:
  /// **'Ridimensiona con il clic secondario'**
  String get resizeWithSecondaryClick;

  /// No description provided for @raiseOnFocus.
  ///
  /// In it, this message translates to:
  /// **'Sollevare le finestre quando hanno il focus'**
  String get raiseOnFocus;

  /// No description provided for @backgroundImageUpdated.
  ///
  /// In it, this message translates to:
  /// **'Immagine di sfondo aggiornata!'**
  String get backgroundImageUpdated;

  /// No description provided for @backgroundImageError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'aggiornamento dell\'immagine.'**
  String get backgroundImageError;

  /// No description provided for @preferredFonts.
  ///
  /// In it, this message translates to:
  /// **'Caratteri preferiti'**
  String get preferredFonts;

  /// No description provided for @interfaceText.
  ///
  /// In it, this message translates to:
  /// **'Testo dell\'interfaccia'**
  String get interfaceText;

  /// No description provided for @documentText.
  ///
  /// In it, this message translates to:
  /// **'Testo del documento'**
  String get documentText;

  /// No description provided for @fixedWidthText.
  ///
  /// In it, this message translates to:
  /// **'Testo a spaziatura fissa'**
  String get fixedWidthText;

  /// No description provided for @rendering.
  ///
  /// In it, this message translates to:
  /// **'Rendering'**
  String get rendering;

  /// No description provided for @hinting.
  ///
  /// In it, this message translates to:
  /// **'Hinting'**
  String get hinting;

  /// No description provided for @full.
  ///
  /// In it, this message translates to:
  /// **'Pieno'**
  String get full;

  /// No description provided for @medium.
  ///
  /// In it, this message translates to:
  /// **'Medio'**
  String get medium;

  /// No description provided for @light.
  ///
  /// In it, this message translates to:
  /// **'Leggero'**
  String get light;

  /// No description provided for @antialiasing.
  ///
  /// In it, this message translates to:
  /// **'Antialiasing'**
  String get antialiasing;

  /// No description provided for @subpixelLCD.
  ///
  /// In it, this message translates to:
  /// **'Subpixel (per gli schermi LCD)'**
  String get subpixelLCD;

  /// No description provided for @standardGrayscale.
  ///
  /// In it, this message translates to:
  /// **'Standard (scala di grigi)'**
  String get standardGrayscale;

  /// No description provided for @dimensions.
  ///
  /// In it, this message translates to:
  /// **'Dimensioni'**
  String get dimensions;

  /// No description provided for @preview.
  ///
  /// In it, this message translates to:
  /// **'Anteprima:'**
  String get preview;

  /// No description provided for @noImageSelected.
  ///
  /// In it, this message translates to:
  /// **'Nessuna immagine selezionata'**
  String get noImageSelected;

  /// No description provided for @command.
  ///
  /// In it, this message translates to:
  /// **'Comando:'**
  String get command;

  /// No description provided for @comment.
  ///
  /// In it, this message translates to:
  /// **'Commento:'**
  String get comment;

  /// No description provided for @enabledApps.
  ///
  /// In it, this message translates to:
  /// **'App Abilitate'**
  String get enabledApps;

  /// No description provided for @disabledApps.
  ///
  /// In it, this message translates to:
  /// **'App Disabilitate'**
  String get disabledApps;

  /// No description provided for @noStartupAppsFound.
  ///
  /// In it, this message translates to:
  /// **'Nessuna app all\'avvio trovata.'**
  String get noStartupAppsFound;

  /// No description provided for @enabledStatus.
  ///
  /// In it, this message translates to:
  /// **'Abilitata'**
  String get enabledStatus;

  /// No description provided for @disabledStatus.
  ///
  /// In it, this message translates to:
  /// **'Disabilitata'**
  String get disabledStatus;

  /// No description provided for @styles.
  ///
  /// In it, this message translates to:
  /// **'Stili'**
  String get styles;

  /// No description provided for @cursor.
  ///
  /// In it, this message translates to:
  /// **'Cursore'**
  String get cursor;

  /// No description provided for @icons.
  ///
  /// In it, this message translates to:
  /// **'Icone'**
  String get icons;

  /// No description provided for @legacyApps.
  ///
  /// In it, this message translates to:
  /// **'Applicazioni datate'**
  String get legacyApps;

  /// No description provided for @background.
  ///
  /// In it, this message translates to:
  /// **'Sfondo'**
  String get background;

  /// No description provided for @defaultImage.
  ///
  /// In it, this message translates to:
  /// **'Immagine predefinita'**
  String get defaultImage;

  /// No description provided for @darkImage.
  ///
  /// In it, this message translates to:
  /// **'Immagine in Stile Scuro'**
  String get darkImage;

  /// No description provided for @adjustment.
  ///
  /// In it, this message translates to:
  /// **'Regolazione'**
  String get adjustment;

  /// No description provided for @noneOption.
  ///
  /// In it, this message translates to:
  /// **'Nessuno'**
  String get noneOption;

  /// No description provided for @wallpaper.
  ///
  /// In it, this message translates to:
  /// **'Sfondo'**
  String get wallpaper;

  /// No description provided for @centered.
  ///
  /// In it, this message translates to:
  /// **'Centrato'**
  String get centered;

  /// No description provided for @scaled.
  ///
  /// In it, this message translates to:
  /// **'Scalato'**
  String get scaled;

  /// No description provided for @stretched.
  ///
  /// In it, this message translates to:
  /// **'Allungato'**
  String get stretched;

  /// No description provided for @zoom.
  ///
  /// In it, this message translates to:
  /// **'Zoom'**
  String get zoom;

  /// No description provided for @spanned.
  ///
  /// In it, this message translates to:
  /// **'Esteso'**
  String get spanned;

  /// No description provided for @windowBehavior.
  ///
  /// In it, this message translates to:
  /// **'Comportamento Finestre'**
  String get windowBehavior;

  /// No description provided for @titlebarButtons.
  ///
  /// In it, this message translates to:
  /// **'Pulsanti barra del titolo'**
  String get titlebarButtons;

  /// No description provided for @clickActions.
  ///
  /// In it, this message translates to:
  /// **'Fare clic su Azioni'**
  String get clickActions;

  /// No description provided for @windowFocus.
  ///
  /// In it, this message translates to:
  /// **'Focus della finestra'**
  String get windowFocus;

  /// No description provided for @doubleClick.
  ///
  /// In it, this message translates to:
  /// **'Doppio clic'**
  String get doubleClick;

  /// No description provided for @middleClick.
  ///
  /// In it, this message translates to:
  /// **'Clic centrale'**
  String get middleClick;

  /// No description provided for @rightClick.
  ///
  /// In it, this message translates to:
  /// **'Clic secondario'**
  String get rightClick;

  /// No description provided for @toggleMaximize.
  ///
  /// In it, this message translates to:
  /// **'Toggle Maximize'**
  String get toggleMaximize;

  /// No description provided for @toggleMaximizeHorizontal.
  ///
  /// In it, this message translates to:
  /// **'Toggle Maximize Horizontalmente'**
  String get toggleMaximizeHorizontal;

  /// No description provided for @toggleMaximizeVertical.
  ///
  /// In it, this message translates to:
  /// **'Toggle Maximize Verticalmente'**
  String get toggleMaximizeVertical;

  /// No description provided for @toggleShade.
  ///
  /// In it, this message translates to:
  /// **'Toggle Shade'**
  String get toggleShade;

  /// No description provided for @toggleMenu.
  ///
  /// In it, this message translates to:
  /// **'Toggle Menu'**
  String get toggleMenu;

  /// No description provided for @lower.
  ///
  /// In it, this message translates to:
  /// **'Lower'**
  String get lower;

  /// No description provided for @menu.
  ///
  /// In it, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @clickForFocus.
  ///
  /// In it, this message translates to:
  /// **'Fare clic per il focus'**
  String get clickForFocus;

  /// No description provided for @focusOnHover.
  ///
  /// In it, this message translates to:
  /// **'Focus al passaggio'**
  String get focusOnHover;

  /// No description provided for @focusFollowsMouse.
  ///
  /// In it, this message translates to:
  /// **'Il fuoco segue il mouse'**
  String get focusFollowsMouse;

  /// No description provided for @clickForFocusDesc.
  ///
  /// In it, this message translates to:
  /// **'Le finestre avranno il focus quando si fa clic su di loro.'**
  String get clickForFocusDesc;

  /// No description provided for @focusOnHoverDesc.
  ///
  /// In it, this message translates to:
  /// **'La finestra ha il focus quando si passa sopra col puntatore. Le finestre rimangono con il focus quando si passa sulla scrivania.'**
  String get focusOnHoverDesc;

  /// No description provided for @focusFollowsMouseDesc.
  ///
  /// In it, this message translates to:
  /// **'La finestra ha il focus quando si passa sopra col puntatore. Passare sulla scrivania rimuove il focus dalla finestra precedente.'**
  String get focusFollowsMouseDesc;

  /// No description provided for @someProcessesNotTerminated.
  ///
  /// In it, this message translates to:
  /// **'Alcuni processi non sono stati terminati correttamente'**
  String get someProcessesNotTerminated;

  /// No description provided for @errorDisabling.
  ///
  /// In it, this message translates to:
  /// **'Errore durante la disabilitazione'**
  String get errorDisabling;

  /// No description provided for @appReEnabled.
  ///
  /// In it, this message translates to:
  /// **'App {appName} riabilitata'**
  String appReEnabled(String appName);

  /// No description provided for @errorEnabling.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'abilitazione'**
  String get errorEnabling;

  /// No description provided for @removeAppFromStartup.
  ///
  /// In it, this message translates to:
  /// **'Vuoi rimuovere {appName} dall\'avvio?'**
  String removeAppFromStartup(String appName);

  /// No description provided for @appRemoved.
  ///
  /// In it, this message translates to:
  /// **'App {appName} rimossa'**
  String appRemoved(String appName);

  /// No description provided for @errorRemoving.
  ///
  /// In it, this message translates to:
  /// **'Errore durante la rimozione'**
  String get errorRemoving;

  /// No description provided for @terminateProcesses.
  ///
  /// In it, this message translates to:
  /// **'Termina Processi'**
  String get terminateProcesses;

  /// No description provided for @noProcessesRunning.
  ///
  /// In it, this message translates to:
  /// **'Nessun processo in esecuzione per questa app'**
  String get noProcessesRunning;

  /// No description provided for @cache.
  ///
  /// In it, this message translates to:
  /// **'Cache'**
  String get cache;

  /// No description provided for @swap.
  ///
  /// In it, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @filesystem.
  ///
  /// In it, this message translates to:
  /// **'Filesystem'**
  String get filesystem;

  /// No description provided for @temperatureUnit.
  ///
  /// In it, this message translates to:
  /// **'°C'**
  String get temperatureUnit;

  /// No description provided for @removing.
  ///
  /// In it, this message translates to:
  /// **'Rimozione in corso...'**
  String get removing;

  /// No description provided for @versionLabel.
  ///
  /// In it, this message translates to:
  /// **'Versione:'**
  String get versionLabel;

  /// No description provided for @selectBasePath.
  ///
  /// In it, this message translates to:
  /// **'Seleziona percorso base:'**
  String get selectBasePath;

  /// No description provided for @root.
  ///
  /// In it, this message translates to:
  /// **'Root'**
  String get root;

  /// No description provided for @home.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @externalDisks.
  ///
  /// In it, this message translates to:
  /// **'Dischi esterni:'**
  String get externalDisks;

  /// No description provided for @selectPathToAnalyze.
  ///
  /// In it, this message translates to:
  /// **'Seleziona un percorso da analizzare'**
  String get selectPathToAnalyze;

  /// No description provided for @totalSize.
  ///
  /// In it, this message translates to:
  /// **'Dimensione totale'**
  String get totalSize;

  /// No description provided for @files.
  ///
  /// In it, this message translates to:
  /// **'File'**
  String get files;

  /// No description provided for @directories.
  ///
  /// In it, this message translates to:
  /// **'Directory'**
  String get directories;

  /// No description provided for @excluded.
  ///
  /// In it, this message translates to:
  /// **'Esclusa'**
  String get excluded;

  /// No description provided for @exclude.
  ///
  /// In it, this message translates to:
  /// **'Escludi'**
  String get exclude;

  /// No description provided for @include.
  ///
  /// In it, this message translates to:
  /// **'Includi'**
  String get include;

  /// No description provided for @analyzing.
  ///
  /// In it, this message translates to:
  /// **'Analisi in corso...'**
  String get analyzing;

  /// No description provided for @addExcludedFolder.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi Cartella Esclusa'**
  String get addExcludedFolder;

  /// No description provided for @enterFolderPath.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il percorso della cartella da escludere dalla pulizia:'**
  String get enterFolderPath;

  /// No description provided for @folderPath.
  ///
  /// In it, this message translates to:
  /// **'Percorso cartella'**
  String get folderPath;

  /// No description provided for @folderExcluded.
  ///
  /// In it, this message translates to:
  /// **'Cartella aggiunta alle esclusioni'**
  String get folderExcluded;

  /// No description provided for @folderNotFound.
  ///
  /// In it, this message translates to:
  /// **'Cartella non trovata'**
  String get folderNotFound;

  /// No description provided for @add.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi'**
  String get add;

  /// No description provided for @goBack.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get goBack;

  /// No description provided for @goForward.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get goForward;

  /// No description provided for @goToRoot.
  ///
  /// In it, this message translates to:
  /// **'Vai alla radice'**
  String get goToRoot;

  /// No description provided for @moveToTrash.
  ///
  /// In it, this message translates to:
  /// **'Sposta nel cestino'**
  String get moveToTrash;

  /// No description provided for @moveToTrashConfirm.
  ///
  /// In it, this message translates to:
  /// **'Vuoi spostare \"{name}\" nel cestino?'**
  String moveToTrashConfirm(String name);

  /// No description provided for @move.
  ///
  /// In it, this message translates to:
  /// **'Sposta'**
  String get move;

  /// No description provided for @movedToTrash.
  ///
  /// In it, this message translates to:
  /// **'Spostato nel cestino'**
  String get movedToTrash;

  /// No description provided for @errorMovingToTrash.
  ///
  /// In it, this message translates to:
  /// **'Errore durante lo spostamento nel cestino'**
  String get errorMovingToTrash;

  /// No description provided for @deleteFromRootWarning.
  ///
  /// In it, this message translates to:
  /// **'ATTENZIONE: Eliminazione dalla Root'**
  String get deleteFromRootWarning;

  /// No description provided for @deleteFromRootMessage.
  ///
  /// In it, this message translates to:
  /// **'Stai per eliminare \"{name}\" dalla directory root del sistema. Questa operazione richiede privilegi amministratore e può essere irreversibile. Sei sicuro di voler procedere?'**
  String deleteFromRootMessage(String name);

  /// No description provided for @deletePermanently.
  ///
  /// In it, this message translates to:
  /// **'Elimina Definitivamente'**
  String get deletePermanently;

  /// No description provided for @emptyDirectory.
  ///
  /// In it, this message translates to:
  /// **'Directory vuota'**
  String get emptyDirectory;

  /// No description provided for @cannotPreviewFile.
  ///
  /// In it, this message translates to:
  /// **'Impossibile visualizzare l\'anteprima del file'**
  String get cannotPreviewFile;

  /// No description provided for @fileType.
  ///
  /// In it, this message translates to:
  /// **'Tipo file'**
  String get fileType;

  /// No description provided for @unknown.
  ///
  /// In it, this message translates to:
  /// **'Sconosciuto'**
  String get unknown;

  /// No description provided for @directory.
  ///
  /// In it, this message translates to:
  /// **'Directory'**
  String get directory;

  /// No description provided for @file.
  ///
  /// In it, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @rename.
  ///
  /// In it, this message translates to:
  /// **'Rinomina'**
  String get rename;

  /// No description provided for @newName.
  ///
  /// In it, this message translates to:
  /// **'Nuovo nome'**
  String get newName;

  /// No description provided for @details.
  ///
  /// In it, this message translates to:
  /// **'Dettagli'**
  String get details;

  /// No description provided for @renamedSuccessfully.
  ///
  /// In it, this message translates to:
  /// **'Rinominato con successo'**
  String get renamedSuccessfully;

  /// No description provided for @renameError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante la rinomina'**
  String get renameError;

  /// No description provided for @type.
  ///
  /// In it, this message translates to:
  /// **'Tipo'**
  String get type;

  /// No description provided for @permissions.
  ///
  /// In it, this message translates to:
  /// **'Permessi'**
  String get permissions;

  /// No description provided for @owner.
  ///
  /// In it, this message translates to:
  /// **'Proprietario'**
  String get owner;

  /// No description provided for @modified.
  ///
  /// In it, this message translates to:
  /// **'Modificato'**
  String get modified;

  /// No description provided for @path.
  ///
  /// In it, this message translates to:
  /// **'Percorso'**
  String get path;

  /// No description provided for @usedSpace.
  ///
  /// In it, this message translates to:
  /// **'Spazio Occupato'**
  String get usedSpace;

  /// No description provided for @freeSpace.
  ///
  /// In it, this message translates to:
  /// **'Spazio Libero'**
  String get freeSpace;

  /// No description provided for @pages.
  ///
  /// In it, this message translates to:
  /// **'Pagine'**
  String get pages;

  /// No description provided for @title.
  ///
  /// In it, this message translates to:
  /// **'Titolo'**
  String get title;

  /// No description provided for @artist.
  ///
  /// In it, this message translates to:
  /// **'Artista'**
  String get artist;

  /// No description provided for @duration.
  ///
  /// In it, this message translates to:
  /// **'Durata'**
  String get duration;

  /// No description provided for @bitrate.
  ///
  /// In it, this message translates to:
  /// **'Bitrate'**
  String get bitrate;

  /// No description provided for @resolution.
  ///
  /// In it, this message translates to:
  /// **'Risoluzione'**
  String get resolution;

  /// No description provided for @codec.
  ///
  /// In it, this message translates to:
  /// **'Codec'**
  String get codec;

  /// No description provided for @showSystemFiles.
  ///
  /// In it, this message translates to:
  /// **'Mostra file di sistema'**
  String get showSystemFiles;

  /// No description provided for @hideSystemFiles.
  ///
  /// In it, this message translates to:
  /// **'Nascondi file di sistema'**
  String get hideSystemFiles;

  /// No description provided for @appDisabled.
  ///
  /// In it, this message translates to:
  /// **'App {appName} disabilitata'**
  String appDisabled(String appName);

  /// No description provided for @appDisabledAndProcessesTerminated.
  ///
  /// In it, this message translates to:
  /// **'App {appName} disabilitata e processi terminati'**
  String appDisabledAndProcessesTerminated(String appName);

  /// No description provided for @terminateProcessesQuestion.
  ///
  /// In it, this message translates to:
  /// **'Vuoi terminare {count} processo/i di \"{appName}\"?'**
  String terminateProcessesQuestion(int count, String appName);

  /// No description provided for @totalSpaceToFree.
  ///
  /// In it, this message translates to:
  /// **'Spazio totale da liberare:'**
  String get totalSpaceToFree;

  /// No description provided for @foldersWithErrors.
  ///
  /// In it, this message translates to:
  /// **'Cartelle con errori:'**
  String get foldersWithErrors;

  /// No description provided for @andOthers.
  ///
  /// In it, this message translates to:
  /// **'e altre {count}'**
  String andOthers(int count);

  /// No description provided for @recoveryDescription.
  ///
  /// In it, this message translates to:
  /// **'Questa sezione contiene strumenti per ripristinare funzioni alterate del sistema. I comandi sono adattati automaticamente in base alla distribuzione Linux rilevata.'**
  String get recoveryDescription;

  /// No description provided for @recoveryRestartPipewire.
  ///
  /// In it, this message translates to:
  /// **'Riavvia Pipewire'**
  String get recoveryRestartPipewire;

  /// No description provided for @recoveryRestartPipewireDesc.
  ///
  /// In it, this message translates to:
  /// **'Riavvia i servizi Pipewire, Pipewire-Pulse e Wireplumber per risolvere problemi audio.'**
  String get recoveryRestartPipewireDesc;

  /// No description provided for @recoveryRestoreNetwork.
  ///
  /// In it, this message translates to:
  /// **'Ripristina Servizi di Rete'**
  String get recoveryRestoreNetwork;

  /// No description provided for @recoveryRestoreNetworkDesc.
  ///
  /// In it, this message translates to:
  /// **'Riavvia i servizi di rete (NetworkManager, systemd-networkd) per risolvere problemi di connessione.'**
  String get recoveryRestoreNetworkDesc;

  /// No description provided for @recoveryRebuildGrub.
  ///
  /// In it, this message translates to:
  /// **'Ricostruisci GRUB'**
  String get recoveryRebuildGrub;

  /// No description provided for @recoveryRebuildGrubDesc.
  ///
  /// In it, this message translates to:
  /// **'Ricostruisce la configurazione GRUB e aggiorna il bootloader. Viene creato un backup automatico.'**
  String get recoveryRebuildGrubDesc;

  /// No description provided for @recoveryRestoreFlathub.
  ///
  /// In it, this message translates to:
  /// **'Ripristina Flathub'**
  String get recoveryRestoreFlathub;

  /// No description provided for @recoveryRestoreFlathubDesc.
  ///
  /// In it, this message translates to:
  /// **'Ripristina il repository Flathub per Flatpak e aggiorna i metadati delle app.'**
  String get recoveryRestoreFlathubDesc;

  /// No description provided for @recoveryRestoreRepos.
  ///
  /// In it, this message translates to:
  /// **'Ripristina Repository'**
  String get recoveryRestoreRepos;

  /// No description provided for @recoveryRestoreReposDesc.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna e ripristina i repository del package manager (APT, DNF, Pacman) per risolvere problemi di aggiornamento.'**
  String get recoveryRestoreReposDesc;

  /// No description provided for @recoveryPerformUpdates.
  ///
  /// In it, this message translates to:
  /// **'Esegui Aggiornamenti'**
  String get recoveryPerformUpdates;

  /// No description provided for @recoveryPerformUpdatesConfirm.
  ///
  /// In it, this message translates to:
  /// **'Vuoi eseguire gli aggiornamenti disponibili? Questa operazione potrebbe richiedere del tempo.'**
  String get recoveryPerformUpdatesConfirm;

  /// No description provided for @recoveryTabRecovery.
  ///
  /// In it, this message translates to:
  /// **'Recovery'**
  String get recoveryTabRecovery;

  /// No description provided for @recoveryTabSoftwareInstaller.
  ///
  /// In it, this message translates to:
  /// **'Installatore Software di Sistema'**
  String get recoveryTabSoftwareInstaller;

  /// No description provided for @recoverySoftwareInstallerDesc.
  ///
  /// In it, this message translates to:
  /// **'Scarica e installa automaticamente software di sistema essenziale.'**
  String get recoverySoftwareInstallerDesc;

  /// No description provided for @recoveryInstallFfmpeg.
  ///
  /// In it, this message translates to:
  /// **'FFmpeg'**
  String get recoveryInstallFfmpeg;

  /// No description provided for @recoveryInstallFfmpegDesc.
  ///
  /// In it, this message translates to:
  /// **'Framework multimediale per codifica/decodifica audio e video.'**
  String get recoveryInstallFfmpegDesc;

  /// No description provided for @recoveryInstallYtDlp.
  ///
  /// In it, this message translates to:
  /// **'yt-dlp'**
  String get recoveryInstallYtDlp;

  /// No description provided for @recoveryInstallYtDlpDesc.
  ///
  /// In it, this message translates to:
  /// **'Scaricatore video per molti siti.'**
  String get recoveryInstallYtDlpDesc;

  /// No description provided for @recoveryInstallSystemLibs.
  ///
  /// In it, this message translates to:
  /// **'Librerie di sistema'**
  String get recoveryInstallSystemLibs;

  /// No description provided for @recoveryInstallSystemLibsDesc.
  ///
  /// In it, this message translates to:
  /// **'Librerie di sistema essenziali che spesso si possono corrompere.'**
  String get recoveryInstallSystemLibsDesc;

  /// No description provided for @recoveryInstallCodecs.
  ///
  /// In it, this message translates to:
  /// **'Codec video e audio'**
  String get recoveryInstallCodecs;

  /// No description provided for @recoveryInstallCodecsDesc.
  ///
  /// In it, this message translates to:
  /// **'Codec per riprodurre formati video e audio comuni.'**
  String get recoveryInstallCodecsDesc;

  /// No description provided for @recoveryInstallRsync.
  ///
  /// In it, this message translates to:
  /// **'rsync'**
  String get recoveryInstallRsync;

  /// No description provided for @recoveryInstallRsyncDesc.
  ///
  /// In it, this message translates to:
  /// **'Strumento efficiente per sincronizzazione e trasferimento file.'**
  String get recoveryInstallRsyncDesc;

  /// No description provided for @recoveryFixWifiAutoSuspend.
  ///
  /// In it, this message translates to:
  /// **'Fix Auto-Suspend WiFi'**
  String get recoveryFixWifiAutoSuspend;

  /// No description provided for @recoveryFixWifiAutoSuspendDesc.
  ///
  /// In it, this message translates to:
  /// **'Disabilita l\'auto-suspend USB per gli adattatori WiFi e i ricevitori wireless interni per prevenire disconnessioni casuali.'**
  String get recoveryFixWifiAutoSuspendDesc;

  /// No description provided for @install.
  ///
  /// In it, this message translates to:
  /// **'Installa'**
  String get install;

  /// No description provided for @execute.
  ///
  /// In it, this message translates to:
  /// **'Esegui'**
  String get execute;

  /// No description provided for @viewOutput.
  ///
  /// In it, this message translates to:
  /// **'Visualizza Output'**
  String get viewOutput;

  /// No description provided for @infoServices.
  ///
  /// In it, this message translates to:
  /// **'Servizi'**
  String get infoServices;

  /// No description provided for @infoServicesAnalysis.
  ///
  /// In it, this message translates to:
  /// **'Analisi servizi di sistema'**
  String get infoServicesAnalysis;

  /// No description provided for @infoServicesAnalysisDesc.
  ///
  /// In it, this message translates to:
  /// **'Identifica i servizi che rallentano l\'avvio del sistema utilizzando systemd-analyze blame'**
  String get infoServicesAnalysisDesc;

  /// No description provided for @infoServicesManagement.
  ///
  /// In it, this message translates to:
  /// **'Gestione servizi'**
  String get infoServicesManagement;

  /// No description provided for @infoServicesManagementDesc.
  ///
  /// In it, this message translates to:
  /// **'Abilita, disabilita e riavvia servizi di sistema con controllo completo'**
  String get infoServicesManagementDesc;

  /// No description provided for @infoServicesStatus.
  ///
  /// In it, this message translates to:
  /// **'Visualizzazione stato'**
  String get infoServicesStatus;

  /// No description provided for @infoServicesStatusDesc.
  ///
  /// In it, this message translates to:
  /// **'Mostra lo stato di tutti i servizi (attivi, inattivi, falliti)'**
  String get infoServicesStatusDesc;

  /// No description provided for @infoStartupApps.
  ///
  /// In it, this message translates to:
  /// **'App all\'Avvio'**
  String get infoStartupApps;

  /// No description provided for @infoStartupAppsManagement.
  ///
  /// In it, this message translates to:
  /// **'Gestione applicazioni all\'avvio'**
  String get infoStartupAppsManagement;

  /// No description provided for @infoStartupAppsManagementDesc.
  ///
  /// In it, this message translates to:
  /// **'Visualizza e gestisci tutte le applicazioni che si avviano automaticamente'**
  String get infoStartupAppsManagementDesc;

  /// No description provided for @infoStartupAppsProtection.
  ///
  /// In it, this message translates to:
  /// **'Protezione app di sistema'**
  String get infoStartupAppsProtection;

  /// No description provided for @infoStartupAppsProtectionDesc.
  ///
  /// In it, this message translates to:
  /// **'Previene la disabilitazione accidentale di applicazioni critiche del sistema'**
  String get infoStartupAppsProtectionDesc;

  /// No description provided for @infoStartupAppsTermination.
  ///
  /// In it, this message translates to:
  /// **'Terminazione processi'**
  String get infoStartupAppsTermination;

  /// No description provided for @infoStartupAppsTerminationDesc.
  ///
  /// In it, this message translates to:
  /// **'Opzione per terminare i processi di un\'app quando viene disabilitata'**
  String get infoStartupAppsTerminationDesc;

  /// No description provided for @infoCleanup.
  ///
  /// In it, this message translates to:
  /// **'Pulizia Sistema'**
  String get infoCleanup;

  /// No description provided for @infoCleanupTempFiles.
  ///
  /// In it, this message translates to:
  /// **'Ricerca file temporanei'**
  String get infoCleanupTempFiles;

  /// No description provided for @infoCleanupTempFilesDesc.
  ///
  /// In it, this message translates to:
  /// **'Trova automaticamente file temporanei di applicazioni comuni (browser, IDE, sviluppo)'**
  String get infoCleanupTempFilesDesc;

  /// No description provided for @infoCleanupCache.
  ///
  /// In it, this message translates to:
  /// **'Pulizia cache'**
  String get infoCleanupCache;

  /// No description provided for @infoCleanupCacheDesc.
  ///
  /// In it, this message translates to:
  /// **'Elimina cache di sistema e applicazioni per liberare spazio'**
  String get infoCleanupCacheDesc;

  /// No description provided for @infoCleanupTrash.
  ///
  /// In it, this message translates to:
  /// **'Gestione cestino'**
  String get infoCleanupTrash;

  /// No description provided for @infoCleanupTrashDesc.
  ///
  /// In it, this message translates to:
  /// **'Svuota il cestino e pulisce file temporanei in modo sicuro'**
  String get infoCleanupTrashDesc;

  /// No description provided for @infoInstalledApps.
  ///
  /// In it, this message translates to:
  /// **'App Installate'**
  String get infoInstalledApps;

  /// No description provided for @infoInstalledAppsManagement.
  ///
  /// In it, this message translates to:
  /// **'Gestione pacchetti multipli'**
  String get infoInstalledAppsManagement;

  /// No description provided for @infoInstalledAppsManagementDesc.
  ///
  /// In it, this message translates to:
  /// **'Visualizza app installate tramite APT, Snap, Flatpak e GNOME'**
  String get infoInstalledAppsManagementDesc;

  /// No description provided for @infoInstalledAppsDependencies.
  ///
  /// In it, this message translates to:
  /// **'Controllo dipendenze'**
  String get infoInstalledAppsDependencies;

  /// No description provided for @infoInstalledAppsDependenciesDesc.
  ///
  /// In it, this message translates to:
  /// **'Verifica le dipendenze prima della rimozione per evitare problemi'**
  String get infoInstalledAppsDependenciesDesc;

  /// No description provided for @infoInstalledAppsWarnings.
  ///
  /// In it, this message translates to:
  /// **'Avvisi di sicurezza'**
  String get infoInstalledAppsWarnings;

  /// No description provided for @infoInstalledAppsWarningsDesc.
  ///
  /// In it, this message translates to:
  /// **'Avvisa quando un pacchetto è utilizzato da altri software o dal sistema'**
  String get infoInstalledAppsWarningsDesc;

  /// No description provided for @infoMonitor.
  ///
  /// In it, this message translates to:
  /// **'Monitor Sistema'**
  String get infoMonitor;

  /// No description provided for @infoMonitorProcesses.
  ///
  /// In it, this message translates to:
  /// **'Monitoraggio processi'**
  String get infoMonitorProcesses;

  /// No description provided for @infoMonitorProcessesDesc.
  ///
  /// In it, this message translates to:
  /// **'Visualizza tutti i processi attivi con uso CPU, memoria e disco'**
  String get infoMonitorProcessesDesc;

  /// No description provided for @infoMonitorSorting.
  ///
  /// In it, this message translates to:
  /// **'Ordinamento avanzato'**
  String get infoMonitorSorting;

  /// No description provided for @infoMonitorSortingDesc.
  ///
  /// In it, this message translates to:
  /// **'Ordina processi per CPU o memoria in ordine crescente o decrescente'**
  String get infoMonitorSortingDesc;

  /// No description provided for @infoMonitorTermination.
  ///
  /// In it, this message translates to:
  /// **'Terminazione processi'**
  String get infoMonitorTermination;

  /// No description provided for @infoMonitorTerminationDesc.
  ///
  /// In it, this message translates to:
  /// **'Termina processi non rispondenti direttamente dall\'interfaccia'**
  String get infoMonitorTerminationDesc;

  /// No description provided for @infoMonitorSystemInfo.
  ///
  /// In it, this message translates to:
  /// **'Informazioni sistema'**
  String get infoMonitorSystemInfo;

  /// No description provided for @infoMonitorSystemInfoDesc.
  ///
  /// In it, this message translates to:
  /// **'Mostra dettagli su CPU, RAM, dischi e scheda video'**
  String get infoMonitorSystemInfoDesc;

  /// No description provided for @infoAppearance.
  ///
  /// In it, this message translates to:
  /// **'Personalizzazione Aspetto'**
  String get infoAppearance;

  /// No description provided for @infoAppearanceFonts.
  ///
  /// In it, this message translates to:
  /// **'Gestione font'**
  String get infoAppearanceFonts;

  /// No description provided for @infoAppearanceFontsDesc.
  ///
  /// In it, this message translates to:
  /// **'Configura font per interfaccia, documenti e testo monospazio con anteprime'**
  String get infoAppearanceFontsDesc;

  /// No description provided for @infoAppearanceRendering.
  ///
  /// In it, this message translates to:
  /// **'Rendering avanzato'**
  String get infoAppearanceRendering;

  /// No description provided for @infoAppearanceRenderingDesc.
  ///
  /// In it, this message translates to:
  /// **'Controlla hinting, antialiasing e fattore di scala'**
  String get infoAppearanceRenderingDesc;

  /// No description provided for @infoAppearanceThemes.
  ///
  /// In it, this message translates to:
  /// **'Temi e icone'**
  String get infoAppearanceThemes;

  /// No description provided for @infoAppearanceThemesDesc.
  ///
  /// In it, this message translates to:
  /// **'Personalizza temi cursore, icone e applicazioni legacy con anteprime'**
  String get infoAppearanceThemesDesc;

  /// No description provided for @infoAppearanceWallpaper.
  ///
  /// In it, this message translates to:
  /// **'Sfondo desktop'**
  String get infoAppearanceWallpaper;

  /// No description provided for @infoAppearanceWallpaperDesc.
  ///
  /// In it, this message translates to:
  /// **'Imposta immagini di sfondo per tema chiaro e scuro'**
  String get infoAppearanceWallpaperDesc;

  /// No description provided for @infoAppearanceWindows.
  ///
  /// In it, this message translates to:
  /// **'Comportamento finestre'**
  String get infoAppearanceWindows;

  /// No description provided for @infoAppearanceWindowsDesc.
  ///
  /// In it, this message translates to:
  /// **'Configura azioni click, pulsanti barra titolo e focus delle finestre'**
  String get infoAppearanceWindowsDesc;

  /// No description provided for @infoGrub.
  ///
  /// In it, this message translates to:
  /// **'GRUB Editor (Modalità Avanzata)'**
  String get infoGrub;

  /// No description provided for @infoGrubEditor.
  ///
  /// In it, this message translates to:
  /// **'Editor configurazione GRUB'**
  String get infoGrubEditor;

  /// No description provided for @infoGrubEditorDesc.
  ///
  /// In it, this message translates to:
  /// **'Modifica direttamente il file /etc/default/grub con editor integrato'**
  String get infoGrubEditorDesc;

  /// No description provided for @infoGrubBackup.
  ///
  /// In it, this message translates to:
  /// **'Backup automatico'**
  String get infoGrubBackup;

  /// No description provided for @infoGrubBackupDesc.
  ///
  /// In it, this message translates to:
  /// **'Crea backup automatici prima di ogni modifica'**
  String get infoGrubBackupDesc;

  /// No description provided for @infoGrubUpdate.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento GRUB'**
  String get infoGrubUpdate;

  /// No description provided for @infoGrubUpdateDesc.
  ///
  /// In it, this message translates to:
  /// **'Applica le modifiche e aggiorna il bootloader'**
  String get infoGrubUpdateDesc;

  /// No description provided for @infoGrubRestore.
  ///
  /// In it, this message translates to:
  /// **'Ripristino backup'**
  String get infoGrubRestore;

  /// No description provided for @infoGrubRestoreDesc.
  ///
  /// In it, this message translates to:
  /// **'Ripristina facilmente una configurazione precedente'**
  String get infoGrubRestoreDesc;

  /// No description provided for @infoKernel.
  ///
  /// In it, this message translates to:
  /// **'Gestione Kernel (Modalità Avanzata)'**
  String get infoKernel;

  /// No description provided for @infoKernelList.
  ///
  /// In it, this message translates to:
  /// **'Lista kernel installati'**
  String get infoKernelList;

  /// No description provided for @infoKernelListDesc.
  ///
  /// In it, this message translates to:
  /// **'Visualizza tutti i kernel installati con versione e dimensione'**
  String get infoKernelListDesc;

  /// No description provided for @infoKernelRemoval.
  ///
  /// In it, this message translates to:
  /// **'Rimozione kernel'**
  String get infoKernelRemoval;

  /// No description provided for @infoKernelRemovalDesc.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi kernel vecchi in modo sicuro (protegge il kernel corrente)'**
  String get infoKernelRemovalDesc;

  /// No description provided for @infoKernelDefault.
  ///
  /// In it, this message translates to:
  /// **'Impostazione kernel predefinito'**
  String get infoKernelDefault;

  /// No description provided for @infoKernelDefaultDesc.
  ///
  /// In it, this message translates to:
  /// **'Scegli quale kernel avviare di default'**
  String get infoKernelDefaultDesc;

  /// No description provided for @infoKernelCleanup.
  ///
  /// In it, this message translates to:
  /// **'Pulizia automatica'**
  String get infoKernelCleanup;

  /// No description provided for @infoKernelCleanupDesc.
  ///
  /// In it, this message translates to:
  /// **'Mantieni solo un numero specificato di kernel più recenti'**
  String get infoKernelCleanupDesc;

  /// No description provided for @infoSecurity.
  ///
  /// In it, this message translates to:
  /// **'Sicurezza'**
  String get infoSecurity;

  /// No description provided for @infoSecurityPassword.
  ///
  /// In it, this message translates to:
  /// **'Gestione password'**
  String get infoSecurityPassword;

  /// No description provided for @infoSecurityPasswordDesc.
  ///
  /// In it, this message translates to:
  /// **'Salva la password di amministratore in modo sicuro per operazioni sudo'**
  String get infoSecurityPasswordDesc;

  /// No description provided for @infoSecurityWarning.
  ///
  /// In it, this message translates to:
  /// **'Avviso utenti esperti'**
  String get infoSecurityWarning;

  /// No description provided for @infoSecurityWarningDesc.
  ///
  /// In it, this message translates to:
  /// **'Schermata di avviso iniziale per utenti esperti'**
  String get infoSecurityWarningDesc;

  /// No description provided for @infoSecurityMode.
  ///
  /// In it, this message translates to:
  /// **'Modalità Standard/Avanzata'**
  String get infoSecurityMode;

  /// No description provided for @infoSecurityModeDesc.
  ///
  /// In it, this message translates to:
  /// **'Separa funzionalità base da quelle avanzate (GRUB, Kernel)'**
  String get infoSecurityModeDesc;

  /// No description provided for @recoveryCheckUpdatesComplete.
  ///
  /// In it, this message translates to:
  /// **'Ricerca aggiornamenti completata'**
  String get recoveryCheckUpdatesComplete;

  /// Messaggio di errore durante la ricerca degli aggiornamenti
  ///
  /// In it, this message translates to:
  /// **'Errore durante la ricerca degli aggiornamenti: {error}'**
  String recoveryCheckUpdatesError(String error);

  /// No description provided for @diskAnalyzerMainDirectories.
  ///
  /// In it, this message translates to:
  /// **'Directory Principali'**
  String get diskAnalyzerMainDirectories;

  /// No description provided for @diskIndexingNotice.
  ///
  /// In it, this message translates to:
  /// **'Indicizzazione del disco in corso: la prima analisi può richiedere tempo. I dati verranno salvati nella cache per le sessioni successive.'**
  String get diskIndexingNotice;

  /// No description provided for @hardwareSuggestionsTitle.
  ///
  /// In it, this message translates to:
  /// **'Suggerimenti GRUB basati su Hardware'**
  String get hardwareSuggestionsTitle;

  /// No description provided for @hardwareSuggestionsDescription.
  ///
  /// In it, this message translates to:
  /// **'I seguenti suggerimenti sono basati sull\'analisi della tua configurazione hardware:'**
  String get hardwareSuggestionsDescription;

  /// No description provided for @hardwareSuggestionsPriorityHigh.
  ///
  /// In it, this message translates to:
  /// **'Alta'**
  String get hardwareSuggestionsPriorityHigh;

  /// No description provided for @hardwareSuggestionsPriorityMedium.
  ///
  /// In it, this message translates to:
  /// **'Media'**
  String get hardwareSuggestionsPriorityMedium;

  /// No description provided for @hardwareSuggestionsPriorityLow.
  ///
  /// In it, this message translates to:
  /// **'Bassa'**
  String get hardwareSuggestionsPriorityLow;

  /// No description provided for @hardwareSuggestionsApply.
  ///
  /// In it, this message translates to:
  /// **'Applica'**
  String get hardwareSuggestionsApply;

  /// No description provided for @hardwareSuggestionsCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get hardwareSuggestionsCancel;

  /// No description provided for @hardwareSuggestionsAlreadyPresent.
  ///
  /// In it, this message translates to:
  /// **'Già presente'**
  String get hardwareSuggestionsAlreadyPresent;

  /// No description provided for @hardwareSuggestionsCurrentValue.
  ///
  /// In it, this message translates to:
  /// **'Valore corrente: {value}'**
  String hardwareSuggestionsCurrentValue(String value);

  /// No description provided for @hardwareSuggestionsSuggestedValue.
  ///
  /// In it, this message translates to:
  /// **'Suggerito: {value}'**
  String hardwareSuggestionsSuggestedValue(String value);

  /// No description provided for @hardwareSuggestionsAnalyzing.
  ///
  /// In it, this message translates to:
  /// **'Analisi hardware in corso...'**
  String get hardwareSuggestionsAnalyzing;

  /// No description provided for @hardwareSuggestionsNoAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessun suggerimento disponibile per il tuo hardware.'**
  String get hardwareSuggestionsNoAvailable;

  /// No description provided for @hardwareSuggestionsApplied.
  ///
  /// In it, this message translates to:
  /// **'Suggerimento applicato: {parameter}'**
  String hardwareSuggestionsApplied(String parameter);

  /// No description provided for @hardwareSuggestionsApplyError.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'applicazione del suggerimento: {error}'**
  String hardwareSuggestionsApplyError(String error);

  /// No description provided for @hardwareSuggestionsGenerationError.
  ///
  /// In it, this message translates to:
  /// **'Errore nella generazione dei suggerimenti: {error}'**
  String hardwareSuggestionsGenerationError(String error);

  /// No description provided for @grubSuggestionCpuThreadirqs.
  ///
  /// In it, this message translates to:
  /// **'CPU con {count} core: threadirqs può migliorare lo scheduling multi-core'**
  String grubSuggestionCpuThreadirqs(int count);

  /// No description provided for @grubSuggestionCpuMitigationsOff.
  ///
  /// In it, this message translates to:
  /// **'CPU moderna: mitigations=off può migliorare le prestazioni (solo se accetti i compromessi di sicurezza)'**
  String get grubSuggestionCpuMitigationsOff;

  /// No description provided for @grubSuggestionCpuIntelIommu.
  ///
  /// In it, this message translates to:
  /// **'CPU Intel: abilita IOMMU per virtualizzazione e isolamento dispositivi'**
  String get grubSuggestionCpuIntelIommu;

  /// No description provided for @grubSuggestionCpuAmdIommu.
  ///
  /// In it, this message translates to:
  /// **'CPU AMD: abilita IOMMU per virtualizzazione e isolamento dispositivi'**
  String get grubSuggestionCpuAmdIommu;

  /// No description provided for @grubSuggestionRamZswapDisable.
  ///
  /// In it, this message translates to:
  /// **'Sistema con {gb} GB RAM: zswap spesso non è necessario'**
  String grubSuggestionRamZswapDisable(String gb);

  /// No description provided for @grubSuggestionRamZswapEnable.
  ///
  /// In it, this message translates to:
  /// **'Sistema con {gb} GB RAM: zswap può aiutare quando la memoria è sotto pressione'**
  String grubSuggestionRamZswapEnable(String gb);

  /// No description provided for @grubSuggestionGpuNvidiaModeset.
  ///
  /// In it, this message translates to:
  /// **'GPU NVIDIA rilevata: abilita nvidia-drm modeset per migliori prestazioni video'**
  String get grubSuggestionGpuNvidiaModeset;

  /// No description provided for @grubSuggestionGpuNvidiaVideoMemory.
  ///
  /// In it, this message translates to:
  /// **'GPU NVIDIA: preserva le allocazioni di memoria video tra sospensione/ripresa'**
  String get grubSuggestionGpuNvidiaVideoMemory;

  /// No description provided for @grubSuggestionGpuAmdPpfeaturemask.
  ///
  /// In it, this message translates to:
  /// **'GPU AMD: abilita la maschera completa delle funzioni di power management'**
  String get grubSuggestionGpuAmdPpfeaturemask;

  /// No description provided for @grubSuggestionGpuVideoMode.
  ///
  /// In it, this message translates to:
  /// **'Imposta una modalità video fissa per ridurre problemi di schermo all’avvio'**
  String get grubSuggestionGpuVideoMode;

  /// No description provided for @grubSuggestionFirmwareUefiQuietSplash.
  ///
  /// In it, this message translates to:
  /// **'UEFI: quiet splash può migliorare l’esperienza di boot'**
  String get grubSuggestionFirmwareUefiQuietSplash;

  /// No description provided for @grubSuggestionPerfElevatorNone.
  ///
  /// In it, this message translates to:
  /// **'Storage orientato agli SSD: elevator=none può migliorare le prestazioni I/O'**
  String get grubSuggestionPerfElevatorNone;

  /// No description provided for @grubSuggestionPerfVmSwappiness.
  ///
  /// In it, this message translates to:
  /// **'Riduci lo swappiness quando il sistema ha RAM sufficiente'**
  String get grubSuggestionPerfVmSwappiness;

  /// No description provided for @grubSuggestionGpuNvidiaWaylandPageTable.
  ///
  /// In it, this message translates to:
  /// **'NVIDIA: UsePageAttributeTable migliora le prestazioni di rendering su Wayland'**
  String get grubSuggestionGpuNvidiaWaylandPageTable;

  /// No description provided for @grubSuggestionGpuNvidiaWaylandResizableBar.
  ///
  /// In it, this message translates to:
  /// **'NVIDIA: EnableResizableBar aumenta le prestazioni GPU del 10-15% (PCIe ReBAR)'**
  String get grubSuggestionGpuNvidiaWaylandResizableBar;

  /// No description provided for @grubSuggestionGpuNvidiaWaylandGpuFirmware.
  ///
  /// In it, this message translates to:
  /// **'NVIDIA: EnableGpuFirmware=0 migliora stabilità e compatibilità su Wayland'**
  String get grubSuggestionGpuNvidiaWaylandGpuFirmware;

  /// No description provided for @grubSuggestionGpuNvidiaWaylandFbdev.
  ///
  /// In it, this message translates to:
  /// **'NVIDIA: fbdev=1 abilita la console framebuffer su Wayland'**
  String get grubSuggestionGpuNvidiaWaylandFbdev;

  /// No description provided for @settingsPasswordSecurityMessage.
  ///
  /// In it, this message translates to:
  /// **'La password viene salvata in modo sicuro utilizzando il keyring del sistema.'**
  String get settingsPasswordSecurityMessage;

  /// No description provided for @tabSmart.
  ///
  /// In it, this message translates to:
  /// **'SMART'**
  String get tabSmart;

  /// No description provided for @tabShutdownScheduler.
  ///
  /// In it, this message translates to:
  /// **'Spegnimento Automatico'**
  String get tabShutdownScheduler;

  /// No description provided for @shutdownInfoTitle.
  ///
  /// In it, this message translates to:
  /// **'Spegnimento Automatico'**
  String get shutdownInfoTitle;

  /// No description provided for @shutdownInfoDescription.
  ///
  /// In it, this message translates to:
  /// **'Configura lo spegnimento automatico del PC a orari prestabiliti. Utilizza systemd timers per garantire la compatibilità con tutte le distribuzioni Linux moderne.'**
  String get shutdownInfoDescription;

  /// No description provided for @shutdownSystemdRequired.
  ///
  /// In it, this message translates to:
  /// **'systemd Richiesto'**
  String get shutdownSystemdRequired;

  /// No description provided for @shutdownSystemdRequiredDesc.
  ///
  /// In it, this message translates to:
  /// **'Questa funzionalità richiede systemd, disponibile su Fedora, Ubuntu, Arch, Debian e altre distribuzioni Linux moderne.'**
  String get shutdownSystemdRequiredDesc;

  /// No description provided for @shutdownPasswordRequired.
  ///
  /// In it, this message translates to:
  /// **'Password richiesta. Configura la password nelle impostazioni.'**
  String get shutdownPasswordRequired;

  /// No description provided for @shutdownActiveTimers.
  ///
  /// In it, this message translates to:
  /// **'Timer Attivi'**
  String get shutdownActiveTimers;

  /// No description provided for @shutdownCreateTimer.
  ///
  /// In it, this message translates to:
  /// **'Crea Nuovo Timer'**
  String get shutdownCreateTimer;

  /// No description provided for @shutdownScheduleType.
  ///
  /// In it, this message translates to:
  /// **'Tipo di Programmazione'**
  String get shutdownScheduleType;

  /// No description provided for @shutdownScheduleDaily.
  ///
  /// In it, this message translates to:
  /// **'Giornaliera'**
  String get shutdownScheduleDaily;

  /// No description provided for @shutdownScheduleWeekly.
  ///
  /// In it, this message translates to:
  /// **'Settimanale'**
  String get shutdownScheduleWeekly;

  /// No description provided for @shutdownScheduleMonthly.
  ///
  /// In it, this message translates to:
  /// **'Mensile'**
  String get shutdownScheduleMonthly;

  /// No description provided for @shutdownTime.
  ///
  /// In it, this message translates to:
  /// **'Ora'**
  String get shutdownTime;

  /// No description provided for @shutdownSelectTime.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Ora'**
  String get shutdownSelectTime;

  /// No description provided for @shutdownSelectDays.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Giorni'**
  String get shutdownSelectDays;

  /// No description provided for @shutdownSelectDayOfMonth.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Giorno del Mese'**
  String get shutdownSelectDayOfMonth;

  /// No description provided for @shutdownDayOfMonth.
  ///
  /// In it, this message translates to:
  /// **'Giorno del Mese'**
  String get shutdownDayOfMonth;

  /// No description provided for @shutdownDaySunday.
  ///
  /// In it, this message translates to:
  /// **'Domenica'**
  String get shutdownDaySunday;

  /// No description provided for @shutdownDayMonday.
  ///
  /// In it, this message translates to:
  /// **'Lunedì'**
  String get shutdownDayMonday;

  /// No description provided for @shutdownDayTuesday.
  ///
  /// In it, this message translates to:
  /// **'Martedì'**
  String get shutdownDayTuesday;

  /// No description provided for @shutdownDayWednesday.
  ///
  /// In it, this message translates to:
  /// **'Mercoledì'**
  String get shutdownDayWednesday;

  /// No description provided for @shutdownDayThursday.
  ///
  /// In it, this message translates to:
  /// **'Giovedì'**
  String get shutdownDayThursday;

  /// No description provided for @shutdownDayFriday.
  ///
  /// In it, this message translates to:
  /// **'Venerdì'**
  String get shutdownDayFriday;

  /// No description provided for @shutdownDaySaturday.
  ///
  /// In it, this message translates to:
  /// **'Sabato'**
  String get shutdownDaySaturday;

  /// No description provided for @shutdownTimerCreated.
  ///
  /// In it, this message translates to:
  /// **'Timer di spegnimento creato con successo'**
  String get shutdownTimerCreated;

  /// No description provided for @shutdownTimerRemoved.
  ///
  /// In it, this message translates to:
  /// **'Timer di spegnimento rimosso con successo'**
  String get shutdownTimerRemoved;

  /// No description provided for @shutdownRemoveConfirm.
  ///
  /// In it, this message translates to:
  /// **'Vuoi rimuovere questo timer di spegnimento?'**
  String get shutdownRemoveConfirm;

  /// No description provided for @shutdownNextRun.
  ///
  /// In it, this message translates to:
  /// **'Prossima esecuzione'**
  String get shutdownNextRun;

  /// No description provided for @shutdownStatusInactive.
  ///
  /// In it, this message translates to:
  /// **'Inattivo'**
  String get shutdownStatusInactive;

  /// No description provided for @shutdownWeeklyDaysRequired.
  ///
  /// In it, this message translates to:
  /// **'Seleziona almeno un giorno della settimana'**
  String get shutdownWeeklyDaysRequired;

  /// No description provided for @shutdownMonthlyDayRequired.
  ///
  /// In it, this message translates to:
  /// **'Seleziona un giorno del mese'**
  String get shutdownMonthlyDayRequired;

  /// No description provided for @shutdownOpenSettings.
  ///
  /// In it, this message translates to:
  /// **'Apri Impostazioni Spegnimento'**
  String get shutdownOpenSettings;

  /// No description provided for @shutdownEditTimer.
  ///
  /// In it, this message translates to:
  /// **'Modifica Timer'**
  String get shutdownEditTimer;

  /// No description provided for @shutdownTimerDetails.
  ///
  /// In it, this message translates to:
  /// **'Dettagli Timer'**
  String get shutdownTimerDetails;

  /// No description provided for @diskCacheGenerating.
  ///
  /// In it, this message translates to:
  /// **'Lettura e generazione cache in corso... (vale la prima volta)'**
  String get diskCacheGenerating;

  /// No description provided for @licenseActivate.
  ///
  /// In it, this message translates to:
  /// **'Attiva versione avanzata'**
  String get licenseActivate;

  /// No description provided for @licenseActivateButton.
  ///
  /// In it, this message translates to:
  /// **'Attiva'**
  String get licenseActivateButton;

  /// No description provided for @licenseName.
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get licenseName;

  /// No description provided for @licenseSurname.
  ///
  /// In it, this message translates to:
  /// **'Cognome'**
  String get licenseSurname;

  /// No description provided for @licenseEmail.
  ///
  /// In it, this message translates to:
  /// **'Email'**
  String get licenseEmail;

  /// No description provided for @licenseCode.
  ///
  /// In it, this message translates to:
  /// **'Codice licenza'**
  String get licenseCode;

  /// No description provided for @licenseRequired.
  ///
  /// In it, this message translates to:
  /// **'Questo campo è obbligatorio'**
  String get licenseRequired;

  /// No description provided for @licenseActivateSuccess.
  ///
  /// In it, this message translates to:
  /// **'Versione avanzata attivata con successo.'**
  String get licenseActivateSuccess;

  /// No description provided for @licenseActivateError.
  ///
  /// In it, this message translates to:
  /// **'Codice non valido. Verifica nome, cognome e email.'**
  String get licenseActivateError;

  /// No description provided for @licenseActivatePremium.
  ///
  /// In it, this message translates to:
  /// **'Attiva / Premium'**
  String get licenseActivatePremium;

  /// No description provided for @licenseActivateCardTitle.
  ///
  /// In it, this message translates to:
  /// **'Attiva versione avanzata'**
  String get licenseActivateCardTitle;

  /// No description provided for @licenseActivateCardDesc.
  ///
  /// In it, this message translates to:
  /// **'La versione Advanced costa 19,99 €. Inserisci i tuoi dati e il codice licenza ricevuto dopo il pagamento andato a buon fine per sbloccare GRUB, Kernel e Recovery. Senza un pagamento valido l\'app non può essere attivata.'**
  String get licenseActivateCardDesc;

  /// No description provided for @noSmartDisksFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun disco con supporto SMART trovato.'**
  String get noSmartDisksFound;

  /// No description provided for @smartctlNotFound.
  ///
  /// In it, this message translates to:
  /// **'smartctl non trovato'**
  String get smartctlNotFound;

  /// No description provided for @smartctlInstallPrompt.
  ///
  /// In it, this message translates to:
  /// **'smartmontools è necessario per monitorare la salute del disco. Vuoi installarlo?'**
  String get smartctlInstallPrompt;

  /// No description provided for @installing.
  ///
  /// In it, this message translates to:
  /// **'Installazione in corso...'**
  String get installing;

  /// No description provided for @installSmartctl.
  ///
  /// In it, this message translates to:
  /// **'Installa smartmontools'**
  String get installSmartctl;

  /// No description provided for @selectDisk.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Disco'**
  String get selectDisk;

  /// No description provided for @smartHealthPassed.
  ///
  /// In it, this message translates to:
  /// **'Salute: SUPERATA'**
  String get smartHealthPassed;

  /// No description provided for @smartHealthFailed.
  ///
  /// In it, this message translates to:
  /// **'Salute: FALLITA'**
  String get smartHealthFailed;

  /// No description provided for @powerOnHours.
  ///
  /// In it, this message translates to:
  /// **'Ore di Accensione'**
  String get powerOnHours;

  /// No description provided for @powerCycleCount.
  ///
  /// In it, this message translates to:
  /// **'Conteggio Cicli di Accensione'**
  String get powerCycleCount;

  /// No description provided for @diskInformation.
  ///
  /// In it, this message translates to:
  /// **'Informazioni Disco'**
  String get diskInformation;

  /// No description provided for @serialNumber.
  ///
  /// In it, this message translates to:
  /// **'Numero Seriale'**
  String get serialNumber;

  /// No description provided for @firmware.
  ///
  /// In it, this message translates to:
  /// **'Firmware'**
  String get firmware;

  /// No description provided for @interface.
  ///
  /// In it, this message translates to:
  /// **'Interfaccia'**
  String get interface;

  /// No description provided for @smartAvailable.
  ///
  /// In it, this message translates to:
  /// **'SMART Disponibile'**
  String get smartAvailable;

  /// No description provided for @smartEnabled.
  ///
  /// In it, this message translates to:
  /// **'SMART Abilitato'**
  String get smartEnabled;

  /// No description provided for @smartAttributes.
  ///
  /// In it, this message translates to:
  /// **'Attributi SMART'**
  String get smartAttributes;

  /// No description provided for @attributes.
  ///
  /// In it, this message translates to:
  /// **'attributi'**
  String get attributes;

  /// No description provided for @failedAttributes.
  ///
  /// In it, this message translates to:
  /// **'Attributi Falliti'**
  String get failedAttributes;

  /// No description provided for @attributeId.
  ///
  /// In it, this message translates to:
  /// **'ID'**
  String get attributeId;

  /// No description provided for @attributeName.
  ///
  /// In it, this message translates to:
  /// **'Attributo'**
  String get attributeName;

  /// No description provided for @attributeValue.
  ///
  /// In it, this message translates to:
  /// **'Valore'**
  String get attributeValue;

  /// No description provided for @attributeWorst.
  ///
  /// In it, this message translates to:
  /// **'Peggiore'**
  String get attributeWorst;

  /// No description provided for @attributeThreshold.
  ///
  /// In it, this message translates to:
  /// **'Soglia'**
  String get attributeThreshold;

  /// No description provided for @attributeRaw.
  ///
  /// In it, this message translates to:
  /// **'Valore Grezzo'**
  String get attributeRaw;

  /// No description provided for @selfTest.
  ///
  /// In it, this message translates to:
  /// **'Self-Test'**
  String get selfTest;

  /// No description provided for @shortTest.
  ///
  /// In it, this message translates to:
  /// **'Test Breve'**
  String get shortTest;

  /// No description provided for @longTest.
  ///
  /// In it, this message translates to:
  /// **'Test Esteso'**
  String get longTest;

  /// No description provided for @selfTestHint.
  ///
  /// In it, this message translates to:
  /// **'Un self-test verrà accodato sul disco. Controlla i risultati in seguito nella tabella degli attributi.'**
  String get selfTestHint;

  /// No description provided for @selfTestStarted.
  ///
  /// In it, this message translates to:
  /// **'Self-test avviato con successo. Controlla i risultati in seguito.'**
  String get selfTestStarted;

  /// No description provided for @selfTestFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile avviare il self-test'**
  String get selfTestFailed;

  /// No description provided for @attributeFailedWarning.
  ///
  /// In it, this message translates to:
  /// **'Questo attributo ha FALLITO! Il disco potrebbe necessitare di sostituzione.'**
  String get attributeFailedWarning;

  /// No description provided for @smartDataNotAvailable.
  ///
  /// In it, this message translates to:
  /// **'Dati SMART non disponibili per questo disco.'**
  String get smartDataNotAvailable;

  /// No description provided for @smartUsbInfoTitle.
  ///
  /// In it, this message translates to:
  /// **'Unità USB'**
  String get smartUsbInfoTitle;

  /// No description provided for @smartUsbInfoBody.
  ///
  /// In it, this message translates to:
  /// **'I bridge USB-SATA spesso limitano i dati SMART allo stato di salute e temperatura. La tabella completa degli attributi potrebbe non essere disponibile. Se possibile, prova una connessione SATA diretta.'**
  String get smartUsbInfoBody;

  /// No description provided for @smartSudoPasswordRequired.
  ///
  /// In it, this message translates to:
  /// **'Salva prima la tua password sudo nelle Impostazioni.'**
  String get smartSudoPasswordRequired;

  /// No description provided for @smartInstallFailed.
  ///
  /// In it, this message translates to:
  /// **'Installazione fallita.'**
  String get smartInstallFailed;

  /// No description provided for @smartInstallError.
  ///
  /// In it, this message translates to:
  /// **'Errore di installazione: {error}'**
  String smartInstallError(String error);

  /// No description provided for @smartErrNoPassword.
  ///
  /// In it, this message translates to:
  /// **'Password non salvata. Salva la password nelle impostazioni.'**
  String get smartErrNoPassword;

  /// No description provided for @smartErrWrongPassword.
  ///
  /// In it, this message translates to:
  /// **'Password non corretta.'**
  String get smartErrWrongPassword;

  /// No description provided for @smartErrPasswordRequired.
  ///
  /// In it, this message translates to:
  /// **'Password richiesta ma non fornita.'**
  String get smartErrPasswordRequired;

  /// No description provided for @smartErrPasswordTimeout.
  ///
  /// In it, this message translates to:
  /// **'Timeout durante validazione password.'**
  String get smartErrPasswordTimeout;

  /// No description provided for @smartErrPasswordGeneric.
  ///
  /// In it, this message translates to:
  /// **'Errore durante validazione: {error}'**
  String smartErrPasswordGeneric(String error);

  /// No description provided for @smartErrSudo.
  ///
  /// In it, this message translates to:
  /// **'Errore sudo: {error}'**
  String smartErrSudo(String error);

  /// No description provided for @smartErrUnsupportedPm.
  ///
  /// In it, this message translates to:
  /// **'Package manager non supportato.'**
  String get smartErrUnsupportedPm;

  /// No description provided for @smartErrUnexpected.
  ///
  /// In it, this message translates to:
  /// **'Errore imprevisto: {error}'**
  String smartErrUnexpected(String error);

  /// No description provided for @smartErrAptLock.
  ///
  /// In it, this message translates to:
  /// **'Impossibile aggiornare: un altro processo sta usando apt. Riprova tra qualche secondo.'**
  String get smartErrAptLock;

  /// No description provided for @smartErrAptNoRepos.
  ///
  /// In it, this message translates to:
  /// **'Repository non trovati. Controlla la configurazione dei repository.'**
  String get smartErrAptNoRepos;

  /// No description provided for @smartErrAptUpdateFailed.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento cache fallito: {error}'**
  String smartErrAptUpdateFailed(String error);

  /// No description provided for @smartErrDpkgInterrupted.
  ///
  /// In it, this message translates to:
  /// **'dpkg interrotto. Esegui \"sudo dpkg --configure -a\" e riprova.'**
  String get smartErrDpkgInterrupted;

  /// No description provided for @smartErrGpgUnauthenticated.
  ///
  /// In it, this message translates to:
  /// **'Pacchetti non autenticati. Aggiorna le chiavi GPG: \"sudo apt-get update\".'**
  String get smartErrGpgUnauthenticated;

  /// No description provided for @smartErrInstallFailed.
  ///
  /// In it, this message translates to:
  /// **'Installazione fallita: {error}'**
  String smartErrInstallFailed(String error);

  /// No description provided for @smartErrNotFoundAfterInstall.
  ///
  /// In it, this message translates to:
  /// **'Installazione completata ma smartctl non trovato. Riavvia l\'app e riprova.'**
  String get smartErrNotFoundAfterInstall;

  /// No description provided for @servicesGuideTitle.
  ///
  /// In it, this message translates to:
  /// **'Guida ai Servizi Linux'**
  String get servicesGuideTitle;

  /// No description provided for @servicesGuideWhatAre.
  ///
  /// In it, this message translates to:
  /// **'Cosa sono i servizi Linux?'**
  String get servicesGuideWhatAre;

  /// No description provided for @servicesGuideWhatAreBody.
  ///
  /// In it, this message translates to:
  /// **'I servizi (chiamati anche demoni o daemon) sono programmi in background che si avviano automaticamente all\'accensione del sistema. Forniscono funzioni essenziali come la gestione della rete (NetworkManager), la stampa (CUPS), la schedulazione (cron), database server (MySQL, PostgreSQL), server web (Apache, Nginx) e molti altri.\n\nAlcuni servizi sono indispensabili per il corretto funzionamento del sistema, mentre altri sono opzionali e dipendono dall\'uso specifico che si fa della macchina.'**
  String get servicesGuideWhatAreBody;

  /// No description provided for @servicesGuideHowToManage.
  ///
  /// In it, this message translates to:
  /// **'Come vengono gestiti i servizi'**
  String get servicesGuideHowToManage;

  /// No description provided for @servicesGuideHowToManageBody.
  ///
  /// In it, this message translates to:
  /// **'Sulle moderne distribuzioni Linux, i servizi sono gestiti da systemd, il sistema di init. Ogni servizio ha un file unit (.service) che definisce come si avvia, si ferma e si comporta.\n\nIn questa applicazione puoi:\n• Avviare e fermare un servizio immediatamente\n• Abilitare un servizio perché parta automaticamente all\'avvio\n• Disabilitare un servizio perché NON parta all\'avvio\n• Visualizzare lo stato corrente e i log di un servizio\n• Modificare le opzioni del servizio dal menu contestuale'**
  String get servicesGuideHowToManageBody;

  /// No description provided for @servicesGuideHowToDisable.
  ///
  /// In it, this message translates to:
  /// **'Come disabilitare un servizio con questo software'**
  String get servicesGuideHowToDisable;

  /// No description provided for @servicesGuideHowToDisableBody.
  ///
  /// In it, this message translates to:
  /// **'Dalla scheda \"Servizi\", individua il servizio che intendi disabilitare. Premi \"Stop\" per fermarlo immediatamente, oppure \"Disabilita\" per impedirne l\'avvio automatico al prossimo riavvio.\n\nPuoi anche combinare le due azioni: premi \"Stop\" e poi \"Disabilita\" per disattivare completamente un servizio finché non lo riabiliti manualmente.'**
  String get servicesGuideHowToDisableBody;

  /// No description provided for @servicesGuidePrecautions.
  ///
  /// In it, this message translates to:
  /// **'Precauzioni e cautele'**
  String get servicesGuidePrecautions;

  /// No description provided for @servicesGuidePrecautionsBody.
  ///
  /// In it, this message translates to:
  /// **'• NON disabilitare servizi che non conosci: alcuni sono essenziali per il sistema (es. NetworkManager, accounts-daemon, systemd-logind)\n• Disabilitare servizi di rete (NetworkManager, systemd-networkd) interromperà la connessione Internet\n• Disabilitare il display manager (gdm, sddm, lightdm) impedirà l\'avvio dell\'interfaccia grafica\n• Verifica sempre di non aver bisogno di un servizio prima di disabilitarlo\n• Le modifiche sono a livello di sistema: riguardano tutti gli utenti, non solo il tuo account\n• Se commetti un errore, puoi riabilitare il servizio dalla stessa schermata usando \"Abilita\"'**
  String get servicesGuidePrecautionsBody;

  /// No description provided for @servicesGuideDontShowAgain.
  ///
  /// In it, this message translates to:
  /// **'Non mostrare più questa guida'**
  String get servicesGuideDontShowAgain;

  /// No description provided for @servicesGuideGotIt.
  ///
  /// In it, this message translates to:
  /// **'Ho capito!'**
  String get servicesGuideGotIt;

  /// No description provided for @tabRepositories.
  ///
  /// In it, this message translates to:
  /// **'Repository'**
  String get tabRepositories;

  /// No description provided for @repoTitle.
  ///
  /// In it, this message translates to:
  /// **'Repository'**
  String get repoTitle;

  /// No description provided for @repoCount.
  ///
  /// In it, this message translates to:
  /// **'repo'**
  String get repoCount;

  /// No description provided for @repoEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna repository trovata'**
  String get repoEmpty;

  /// No description provided for @repoEnabled.
  ///
  /// In it, this message translates to:
  /// **'{name} abilitata'**
  String repoEnabled(Object name);

  /// No description provided for @repoDisabled.
  ///
  /// In it, this message translates to:
  /// **'{name} disabilitata'**
  String repoDisabled(Object name);

  /// No description provided for @repoRemoved.
  ///
  /// In it, this message translates to:
  /// **'{name} rimossa'**
  String repoRemoved(Object name);

  /// No description provided for @repoError.
  ///
  /// In it, this message translates to:
  /// **'Operazione fallita. Controlla la password sudo.'**
  String get repoError;

  /// No description provided for @repoRemoveTitle.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi Repository'**
  String get repoRemoveTitle;

  /// No description provided for @repoRemoveConfirm.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler rimuovere \"{name}\"?'**
  String repoRemoveConfirm(Object name);

  /// No description provided for @repoEditTitle.
  ///
  /// In it, this message translates to:
  /// **'Modifica Repository'**
  String get repoEditTitle;

  /// No description provided for @repoFilePathLabel.
  ///
  /// In it, this message translates to:
  /// **'File:'**
  String get repoFilePathLabel;

  /// No description provided for @repoContentLabel.
  ///
  /// In it, this message translates to:
  /// **'Contenuto'**
  String get repoContentLabel;

  /// No description provided for @repoUpdated.
  ///
  /// In it, this message translates to:
  /// **'Repository aggiornata'**
  String get repoUpdated;

  /// No description provided for @edit.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get edit;

  /// No description provided for @tabTweaks.
  ///
  /// In it, this message translates to:
  /// **'Tweaks'**
  String get tabTweaks;

  /// No description provided for @tweaksSwap.
  ///
  /// In it, this message translates to:
  /// **'Swap'**
  String get tweaksSwap;

  /// No description provided for @tweaksSwapRecommendations.
  ///
  /// In it, this message translates to:
  /// **'Raccomandazioni Swap'**
  String get tweaksSwapRecommendations;

  /// No description provided for @appCheckForUpdates.
  ///
  /// In it, this message translates to:
  /// **'Cerca aggiornamenti'**
  String get appCheckForUpdates;

  /// No description provided for @kernelUpdateDetectedLiquorix.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento kernel Liquorix disponibile'**
  String get kernelUpdateDetectedLiquorix;

  /// No description provided for @kernelUpdateDetectedXanmod.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento kernel Xanmod disponibile'**
  String get kernelUpdateDetectedXanmod;

  /// No description provided for @tabSystemStatus.
  ///
  /// In it, this message translates to:
  /// **'Stato Sistema'**
  String get tabSystemStatus;

  /// No description provided for @tabSecurity.
  ///
  /// In it, this message translates to:
  /// **'Sicurezza'**
  String get tabSecurity;

  /// No description provided for @tabKernelTweaks.
  ///
  /// In it, this message translates to:
  /// **'Tweaks Kernel'**
  String get tabKernelTweaks;

  /// No description provided for @tabOperationHistory.
  ///
  /// In it, this message translates to:
  /// **'Cronologia'**
  String get tabOperationHistory;

  /// No description provided for @statusRefresh.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get statusRefresh;

  /// No description provided for @statusReadOnlyNote.
  ///
  /// In it, this message translates to:
  /// **'Informazioni di sistema di sola lettura. Non viene modificato nulla.'**
  String get statusReadOnlyNote;

  /// No description provided for @statusTabKernel.
  ///
  /// In it, this message translates to:
  /// **'Kernel'**
  String get statusTabKernel;

  /// No description provided for @statusTabSecurity.
  ///
  /// In it, this message translates to:
  /// **'Sicurezza'**
  String get statusTabSecurity;

  /// No description provided for @statusTabVirtualization.
  ///
  /// In it, this message translates to:
  /// **'Virtualizzazione'**
  String get statusTabVirtualization;

  /// No description provided for @statusTabPrinters.
  ///
  /// In it, this message translates to:
  /// **'Stampanti'**
  String get statusTabPrinters;

  /// No description provided for @statusEnabled.
  ///
  /// In it, this message translates to:
  /// **'Attivo'**
  String get statusEnabled;

  /// No description provided for @statusDisabled.
  ///
  /// In it, this message translates to:
  /// **'Disattivo'**
  String get statusDisabled;

  /// No description provided for @statusNotAvailable.
  ///
  /// In it, this message translates to:
  /// **'Non disponibile'**
  String get statusNotAvailable;

  /// No description provided for @statusNotInstalled.
  ///
  /// In it, this message translates to:
  /// **'Non installato'**
  String get statusNotInstalled;

  /// No description provided for @statusUnknown.
  ///
  /// In it, this message translates to:
  /// **'Sconosciuto'**
  String get statusUnknown;

  /// No description provided for @statusNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuno'**
  String get statusNone;

  /// No description provided for @statusEnforcing.
  ///
  /// In it, this message translates to:
  /// **'Enforcing'**
  String get statusEnforcing;

  /// No description provided for @statusPermissive.
  ///
  /// In it, this message translates to:
  /// **'Permissivo'**
  String get statusPermissive;

  /// No description provided for @statusKernelInfo.
  ///
  /// In it, this message translates to:
  /// **'Informazioni kernel'**
  String get statusKernelInfo;

  /// No description provided for @statusKernelVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione'**
  String get statusKernelVersion;

  /// No description provided for @statusKernelBuild.
  ///
  /// In it, this message translates to:
  /// **'Build'**
  String get statusKernelBuild;

  /// No description provided for @statusCpuCount.
  ///
  /// In it, this message translates to:
  /// **'Numero di CPU'**
  String get statusCpuCount;

  /// No description provided for @statusKernelTuning.
  ///
  /// In it, this message translates to:
  /// **'Ottimizzazione kernel'**
  String get statusKernelTuning;

  /// No description provided for @statusThpMode.
  ///
  /// In it, this message translates to:
  /// **'Transparent Huge Pages'**
  String get statusThpMode;

  /// No description provided for @statusZswap.
  ///
  /// In it, this message translates to:
  /// **'Zswap'**
  String get statusZswap;

  /// No description provided for @statusGovernor.
  ///
  /// In it, this message translates to:
  /// **'Governor CPU'**
  String get statusGovernor;

  /// No description provided for @statusIoScheduler.
  ///
  /// In it, this message translates to:
  /// **'Scheduler I/O'**
  String get statusIoScheduler;

  /// No description provided for @statusMandatoryAccess.
  ///
  /// In it, this message translates to:
  /// **'Controllo accessi obbligatorio'**
  String get statusMandatoryAccess;

  /// No description provided for @statusAppArmor.
  ///
  /// In it, this message translates to:
  /// **'AppArmor'**
  String get statusAppArmor;

  /// No description provided for @statusSelinux.
  ///
  /// In it, this message translates to:
  /// **'SELinux'**
  String get statusSelinux;

  /// No description provided for @statusSecureBoot.
  ///
  /// In it, this message translates to:
  /// **'Secure Boot'**
  String get statusSecureBoot;

  /// No description provided for @statusNetworkSecurity.
  ///
  /// In it, this message translates to:
  /// **'Sicurezza di rete'**
  String get statusNetworkSecurity;

  /// No description provided for @statusFirewall.
  ///
  /// In it, this message translates to:
  /// **'Firewall'**
  String get statusFirewall;

  /// No description provided for @statusFirewallBackend.
  ///
  /// In it, this message translates to:
  /// **'Backend firewall'**
  String get statusFirewallBackend;

  /// No description provided for @statusSshService.
  ///
  /// In it, this message translates to:
  /// **'Servizio SSH'**
  String get statusSshService;

  /// No description provided for @statusRootSsh.
  ///
  /// In it, this message translates to:
  /// **'Login root SSH'**
  String get statusRootSsh;

  /// No description provided for @statusAutoUpdates.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamenti automatici'**
  String get statusAutoUpdates;

  /// No description provided for @statusVirtHost.
  ///
  /// In it, this message translates to:
  /// **'Host di virtualizzazione'**
  String get statusVirtHost;

  /// No description provided for @statusCpuVirt.
  ///
  /// In it, this message translates to:
  /// **'Virtualizzazione CPU'**
  String get statusCpuVirt;

  /// No description provided for @statusKvmModule.
  ///
  /// In it, this message translates to:
  /// **'Modulo KVM'**
  String get statusKvmModule;

  /// No description provided for @statusIommu.
  ///
  /// In it, this message translates to:
  /// **'IOMMU'**
  String get statusIommu;

  /// No description provided for @statusVirtAux.
  ///
  /// In it, this message translates to:
  /// **'Supporto virtualizzazione'**
  String get statusVirtAux;

  /// No description provided for @statusVfio.
  ///
  /// In it, this message translates to:
  /// **'VFIO'**
  String get statusVfio;

  /// No description provided for @statusKsm.
  ///
  /// In it, this message translates to:
  /// **'KSM'**
  String get statusKsm;

  /// No description provided for @statusDocker.
  ///
  /// In it, this message translates to:
  /// **'Docker'**
  String get statusDocker;

  /// No description provided for @statusLibvirt.
  ///
  /// In it, this message translates to:
  /// **'Libvirt'**
  String get statusLibvirt;

  /// No description provided for @statusCups.
  ///
  /// In it, this message translates to:
  /// **'CUPS'**
  String get statusCups;

  /// No description provided for @statusCupsService.
  ///
  /// In it, this message translates to:
  /// **'Servizio CUPS'**
  String get statusCupsService;

  /// No description provided for @statusPrinters.
  ///
  /// In it, this message translates to:
  /// **'Stampanti'**
  String get statusPrinters;

  /// No description provided for @statusPrinterDrivers.
  ///
  /// In it, this message translates to:
  /// **'Driver stampanti'**
  String get statusPrinterDrivers;

  /// No description provided for @securitySubtitle.
  ///
  /// In it, this message translates to:
  /// **'Gestisci i servizi di sicurezza del sistema. Ogni azione viene registrata nella cronologia operazioni e può essere annullata.'**
  String get securitySubtitle;

  /// No description provided for @securityFirewall.
  ///
  /// In it, this message translates to:
  /// **'Firewall'**
  String get securityFirewall;

  /// No description provided for @securityFirewallDesc.
  ///
  /// In it, this message translates to:
  /// **'Blocca le connessioni in entrata non richieste usando UFW o firewalld.'**
  String get securityFirewallDesc;

  /// No description provided for @securityFirewallBackend.
  ///
  /// In it, this message translates to:
  /// **'Attivo ({backend})'**
  String securityFirewallBackend(Object backend);

  /// No description provided for @securitySsh.
  ///
  /// In it, this message translates to:
  /// **'Servizio SSH'**
  String get securitySsh;

  /// No description provided for @securitySshDesc.
  ///
  /// In it, this message translates to:
  /// **'Accesso remoto a shell sulla rete.'**
  String get securitySshDesc;

  /// No description provided for @securityRootSsh.
  ///
  /// In it, this message translates to:
  /// **'Login root SSH'**
  String get securityRootSsh;

  /// No description provided for @securityRootSshDesc.
  ///
  /// In it, this message translates to:
  /// **'Consenti o nega il login root diretto via SSH.'**
  String get securityRootSshDesc;

  /// No description provided for @securityRootAllowed.
  ///
  /// In it, this message translates to:
  /// **'Login root consentito'**
  String get securityRootAllowed;

  /// No description provided for @securityAutoUpdates.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamenti automatici'**
  String get securityAutoUpdates;

  /// No description provided for @securityAutoUpdatesDesc.
  ///
  /// In it, this message translates to:
  /// **'Installa automaticamente in background gli aggiornamenti di sicurezza.'**
  String get securityAutoUpdatesDesc;

  /// No description provided for @kernelTweaksSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Applica le impostazioni del kernel in modo permanente: vengono riapplicate a ogni avvio.'**
  String get kernelTweaksSubtitle;

  /// No description provided for @kernelTweaksPersistNote.
  ///
  /// In it, this message translates to:
  /// **'Nessun tweak persistente attivo. Le impostazioni applicate vengono salvate in un servizio systemd e riapplicate a ogni avvio.'**
  String get kernelTweaksPersistNote;

  /// No description provided for @kernelTweaksPersistActive.
  ///
  /// In it, this message translates to:
  /// **'I tweaks del kernel persistenti sono attivi e riapplicati a ogni avvio.'**
  String get kernelTweaksPersistActive;

  /// No description provided for @kernelTweaksApply.
  ///
  /// In it, this message translates to:
  /// **'Applica'**
  String get kernelTweaksApply;

  /// No description provided for @kernelTweaksReset.
  ///
  /// In it, this message translates to:
  /// **'Ripristina'**
  String get kernelTweaksReset;

  /// No description provided for @kernelTweaksResetTitle.
  ///
  /// In it, this message translates to:
  /// **'Ripristina tweaks del kernel'**
  String get kernelTweaksResetTitle;

  /// No description provided for @kernelTweaksResetConfirm.
  ///
  /// In it, this message translates to:
  /// **'Questa operazione rimuove i tweaks persistenti del kernel e ripristina i valori predefiniti. Continuare?'**
  String get kernelTweaksResetConfirm;

  /// No description provided for @kernelTweaksThp.
  ///
  /// In it, this message translates to:
  /// **'Transparent Huge Pages'**
  String get kernelTweaksThp;

  /// No description provided for @kernelTweaksThpDesc.
  ///
  /// In it, this message translates to:
  /// **'Modalità usata per l\'allocazione delle huge page trasparenti.'**
  String get kernelTweaksThpDesc;

  /// No description provided for @kernelTweaksGovernor.
  ///
  /// In it, this message translates to:
  /// **'Governor CPU'**
  String get kernelTweaksGovernor;

  /// No description provided for @kernelTweaksGovernorDesc.
  ///
  /// In it, this message translates to:
  /// **'Politica di scaling delle frequenze CPU applicata a tutti i core.'**
  String get kernelTweaksGovernorDesc;

  /// No description provided for @kernelTweaksScheduler.
  ///
  /// In it, this message translates to:
  /// **'Scheduler CPU'**
  String get kernelTweaksScheduler;

  /// No description provided for @kernelTweaksSchedulerDesc.
  ///
  /// In it, this message translates to:
  /// **'Esegue i processi figli appena creati prima del processo padre per una maggiore reattività.'**
  String get kernelTweaksSchedulerDesc;

  /// No description provided for @kernelTweaksPerf.
  ///
  /// In it, this message translates to:
  /// **'Performance'**
  String get kernelTweaksPerf;

  /// No description provided for @kernelTweaksOndemand.
  ///
  /// In it, this message translates to:
  /// **'On-demand'**
  String get kernelTweaksOndemand;

  /// No description provided for @kernelTweaksSchedutil.
  ///
  /// In it, this message translates to:
  /// **'Schedutil'**
  String get kernelTweaksSchedutil;

  /// No description provided for @kernelTweaksPowersave.
  ///
  /// In it, this message translates to:
  /// **'Powersave'**
  String get kernelTweaksPowersave;

  /// No description provided for @kernelTweaksAlways.
  ///
  /// In it, this message translates to:
  /// **'Sempre'**
  String get kernelTweaksAlways;

  /// No description provided for @kernelTweaksMadvise.
  ///
  /// In it, this message translates to:
  /// **'Madvise'**
  String get kernelTweaksMadvise;

  /// No description provided for @kernelTweaksNever.
  ///
  /// In it, this message translates to:
  /// **'Mai'**
  String get kernelTweaksNever;

  /// No description provided for @kernelTweaksSchedOn.
  ///
  /// In it, this message translates to:
  /// **'Figli per primi'**
  String get kernelTweaksSchedOn;

  /// No description provided for @kernelTweaksSchedOff.
  ///
  /// In it, this message translates to:
  /// **'Predefinito'**
  String get kernelTweaksSchedOff;

  /// No description provided for @historySubtitle.
  ///
  /// In it, this message translates to:
  /// **'Registro delle operazioni eseguite. Ripristina per annullare un\'azione.'**
  String get historySubtitle;

  /// No description provided for @historyEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna operazione registrata.'**
  String get historyEmpty;

  /// No description provided for @historyRestore.
  ///
  /// In it, this message translates to:
  /// **'Ripristina'**
  String get historyRestore;

  /// No description provided for @historyRestoreTitle.
  ///
  /// In it, this message translates to:
  /// **'Ripristina operazione'**
  String get historyRestoreTitle;

  /// No description provided for @historyRestoreConfirm.
  ///
  /// In it, this message translates to:
  /// **'Verranno annullate le modifiche di questa operazione. Continuare?'**
  String get historyRestoreConfirm;

  /// No description provided for @historyRestored.
  ///
  /// In it, this message translates to:
  /// **'Ripristinata'**
  String get historyRestored;

  /// No description provided for @historyClearAll.
  ///
  /// In it, this message translates to:
  /// **'Svuota cronologia'**
  String get historyClearAll;

  /// No description provided for @historyClearTitle.
  ///
  /// In it, this message translates to:
  /// **'Svuota cronologia'**
  String get historyClearTitle;

  /// No description provided for @historyClearConfirm.
  ///
  /// In it, this message translates to:
  /// **'Rimuove tutte le operazioni registrate dalla cronologia. Non annulla nulla. Continuare?'**
  String get historyClearConfirm;

  /// No description provided for @historyFirewallEnable.
  ///
  /// In it, this message translates to:
  /// **'Firewall attivato'**
  String get historyFirewallEnable;

  /// No description provided for @historyFirewallDisable.
  ///
  /// In it, this message translates to:
  /// **'Firewall disattivato'**
  String get historyFirewallDisable;

  /// No description provided for @historySshEnable.
  ///
  /// In it, this message translates to:
  /// **'Servizio SSH attivato'**
  String get historySshEnable;

  /// No description provided for @historySshDisable.
  ///
  /// In it, this message translates to:
  /// **'Servizio SSH disattivato'**
  String get historySshDisable;

  /// No description provided for @historyRootAllow.
  ///
  /// In it, this message translates to:
  /// **'Login root SSH consentito'**
  String get historyRootAllow;

  /// No description provided for @historyRootDeny.
  ///
  /// In it, this message translates to:
  /// **'Login root SSH negato'**
  String get historyRootDeny;

  /// No description provided for @historyAutoUpdateEnable.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamenti automatici attivati'**
  String get historyAutoUpdateEnable;

  /// No description provided for @historyAutoUpdateDisable.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamenti automatici disattivati'**
  String get historyAutoUpdateDisable;

  /// No description provided for @historyKernelApply.
  ///
  /// In it, this message translates to:
  /// **'Tweaks del kernel applicati'**
  String get historyKernelApply;

  /// No description provided for @historyKernelReset.
  ///
  /// In it, this message translates to:
  /// **'Tweaks del kernel ripristinati'**
  String get historyKernelReset;

  /// No description provided for @kernelTweaksCurrent.
  ///
  /// In it, this message translates to:
  /// **'Attuale'**
  String get kernelTweaksCurrent;

  /// No description provided for @kernelTweaksSavedForBoot.
  ///
  /// In it, this message translates to:
  /// **'Salvato per l\'avvio'**
  String get kernelTweaksSavedForBoot;

  /// No description provided for @tabDeviceManager.
  ///
  /// In it, this message translates to:
  /// **'Gestione Periferiche'**
  String get tabDeviceManager;

  /// No description provided for @deviceManagerTitle.
  ///
  /// In it, this message translates to:
  /// **'Gestione Periferiche'**
  String get deviceManagerTitle;

  /// No description provided for @deviceManagerLoading.
  ///
  /// In it, this message translates to:
  /// **'Rilevamento periferiche in corso...'**
  String get deviceManagerLoading;

  /// No description provided for @deviceManagerEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna periferica trovata'**
  String get deviceManagerEmpty;

  /// No description provided for @deviceManagerRefresh.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get deviceManagerRefresh;

  /// No description provided for @deviceManagerEnable.
  ///
  /// In it, this message translates to:
  /// **'Abilita'**
  String get deviceManagerEnable;

  /// No description provided for @deviceManagerDisable.
  ///
  /// In it, this message translates to:
  /// **'Disabilita'**
  String get deviceManagerDisable;

  /// No description provided for @deviceManagerEnabled.
  ///
  /// In it, this message translates to:
  /// **'Abilitato'**
  String get deviceManagerEnabled;

  /// No description provided for @deviceManagerDisabled.
  ///
  /// In it, this message translates to:
  /// **'Disabilitato'**
  String get deviceManagerDisabled;

  /// No description provided for @deviceManagerToggleSuccess.
  ///
  /// In it, this message translates to:
  /// **'Periferica {action} con successo'**
  String deviceManagerToggleSuccess(Object action);

  /// No description provided for @deviceManagerToggleError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile {action} la periferica'**
  String deviceManagerToggleError(Object action);

  /// No description provided for @deviceManagerCannotDisable.
  ///
  /// In it, this message translates to:
  /// **'Questa periferica non può essere disabilitata'**
  String get deviceManagerCannotDisable;

  /// No description provided for @deviceManagerDetails.
  ///
  /// In it, this message translates to:
  /// **'Dettagli'**
  String get deviceManagerDetails;

  /// No description provided for @deviceManagerDriver.
  ///
  /// In it, this message translates to:
  /// **'Driver'**
  String get deviceManagerDriver;

  /// No description provided for @deviceManagerBus.
  ///
  /// In it, this message translates to:
  /// **'Bus'**
  String get deviceManagerBus;

  /// No description provided for @deviceManagerVendor.
  ///
  /// In it, this message translates to:
  /// **'Produttore'**
  String get deviceManagerVendor;

  /// No description provided for @deviceManagerProduct.
  ///
  /// In it, this message translates to:
  /// **'Prodotto'**
  String get deviceManagerProduct;

  /// No description provided for @deviceManagerConfirmTitle.
  ///
  /// In it, this message translates to:
  /// **'Conferma azione'**
  String get deviceManagerConfirmTitle;

  /// No description provided for @deviceManagerConfirmDisable.
  ///
  /// In it, this message translates to:
  /// **'Disabilitare questa periferica potrebbe causare instabilità del sistema. La modifica persiste al riavvio. Continuare?'**
  String get deviceManagerConfirmDisable;

  /// No description provided for @deviceManagerConfirmEnable.
  ///
  /// In it, this message translates to:
  /// **'Abilitare questa periferica? La modifica persiste al riavvio. Continuare?'**
  String get deviceManagerConfirmEnable;

  /// No description provided for @deviceManagerAllDevices.
  ///
  /// In it, this message translates to:
  /// **'Tutte le periferiche'**
  String get deviceManagerAllDevices;

  /// No description provided for @deviceManagerShowDisabled.
  ///
  /// In it, this message translates to:
  /// **'Mostra disabilitate'**
  String get deviceManagerShowDisabled;

  /// No description provided for @deviceManagerStatus.
  ///
  /// In it, this message translates to:
  /// **'Stato'**
  String get deviceManagerStatus;

  /// No description provided for @deviceManagerProperties.
  ///
  /// In it, this message translates to:
  /// **'Proprietà'**
  String get deviceManagerProperties;

  /// No description provided for @deviceManagerClose.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get deviceManagerClose;

  /// No description provided for @deviceManagerNoSudo.
  ///
  /// In it, this message translates to:
  /// **'Salva prima la password amministratore nelle Impostazioni'**
  String get deviceManagerNoSudo;

  /// No description provided for @deviceManagerPersistent.
  ///
  /// In it, this message translates to:
  /// **'Persiste al riavvio'**
  String get deviceManagerPersistent;

  /// No description provided for @tabDriverManager.
  ///
  /// In it, this message translates to:
  /// **'Driver'**
  String get tabDriverManager;

  /// No description provided for @driverManagerTitle.
  ///
  /// In it, this message translates to:
  /// **'Gestione Driver e Firmware'**
  String get driverManagerTitle;

  /// No description provided for @driverManagerScan.
  ///
  /// In it, this message translates to:
  /// **'Scansiona hardware'**
  String get driverManagerScan;

  /// No description provided for @driverManagerFirmwareUpdates.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamenti Firmware'**
  String get driverManagerFirmwareUpdates;

  /// No description provided for @driverManagerAvailableDrivers.
  ///
  /// In it, this message translates to:
  /// **'Driver disponibili'**
  String get driverManagerAvailableDrivers;

  /// No description provided for @driverManagerInstalledDrivers.
  ///
  /// In it, this message translates to:
  /// **'Driver installati'**
  String get driverManagerInstalledDrivers;

  /// No description provided for @driverManagerAllDriversInstalled.
  ///
  /// In it, this message translates to:
  /// **'Tutti i driver noti sono installati'**
  String get driverManagerAllDriversInstalled;

  /// No description provided for @driverManagerNoDriversInstalled.
  ///
  /// In it, this message translates to:
  /// **'Nessun driver gestito installato'**
  String get driverManagerNoDriversInstalled;

  /// No description provided for @driverManagerCurrentDriver.
  ///
  /// In it, this message translates to:
  /// **'Driver attuale'**
  String get driverManagerCurrentDriver;

  /// No description provided for @driverManagerPackage.
  ///
  /// In it, this message translates to:
  /// **'Pacchetto'**
  String get driverManagerPackage;

  /// No description provided for @driverManagerInstall.
  ///
  /// In it, this message translates to:
  /// **'Installa'**
  String get driverManagerInstall;

  /// No description provided for @driverManagerUpdate.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get driverManagerUpdate;

  /// No description provided for @driverManagerRebootRequired.
  ///
  /// In it, this message translates to:
  /// **'Riavvio necessario dopo l\'aggiornamento'**
  String get driverManagerRebootRequired;

  /// No description provided for @driverManagerLinuxFirmware.
  ///
  /// In it, this message translates to:
  /// **'Firmware Linux (linux-firmware)'**
  String get driverManagerLinuxFirmware;

  /// No description provided for @driverManagerLinuxFirmwareDesc.
  ///
  /// In it, this message translates to:
  /// **'Pacchetto firmware completo per GPU, Wi-Fi, Bluetooth e altri dispositivi'**
  String get driverManagerLinuxFirmwareDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
