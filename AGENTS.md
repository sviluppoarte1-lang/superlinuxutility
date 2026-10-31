# Build & Development Context

## Build command
```bash
flutter build linux
```

## GLib 2.78 compat (MX Linux 23 / Debian 12)
- `libflutter_linux_gtk.so` (built against GLib ≥ 2.78) references `g_once_init_enter_pointer` and `g_once_init_leave_pointer`.
- GLib < 2.78 (MX Linux 23 has 2.74) doesn't export these symbols → undefined symbol error.
- Fix: `linux/runner/glib_compat.cpp` provides weak `__attribute__((weak))` stub implementations.
  - On GLib ≥ 2.78: GLib's strong symbols override the weak stubs.
  - On GLib < 2.78: the weak stubs fill in the missing symbols.
- File is C++ (`.cpp`) not C because CMakeLists.txt uses `project(runner LANGUAGES CXX)`.
- Does NOT `#include <glib.h>` (would conflict with GLib 2.78+ header declarations).
- Forward-declares only `g_once_init_enter` and `g_once_init_leave` (both exist in GLib 1.0+).
- Uses `__atomic_load_n` instead of `g_atomic_pointer_get` to avoid GLib header dependency.

## Flatpak display names
- `recovery_service.dart:shortUpdateDisplayName()` extracts human-readable name from reverse domain refs.
- E.g. `app/org.superproductivity/x86_64/stable` → `Superproductivity`.

## CPU core/thread counting
- Use `lscpu` fields `Core(s) per socket × Socket(s)` for physical cores, not `nproc` (which returns logical threads).
- Linux: `system_monitor.dart:225-233`.

## Disk chart
- `disk_analyzer_screen.dart` uses `du -h -d1 -x` with streaming partial results for root filesystem.
- Chart labels render in fixed 64px column + bold text.

## Wayland / NVIDIA / XWayland optimizations

### Display server detection
- `system_detector.dart:_detectDisplayServer()` reads `XDG_SESSION_TYPE`, `WAYLAND_DISPLAY`, `DISPLAY`.
- Returns `DisplayServer.{wayland,x11,xWayland,unknown}`.
- Result used to adapt GPU monitoring commands.

### GPU monitoring on Wayland
- `system_monitor.dart:_getGpuInfo()` caches result for 30s to avoid repeated `nvidia-smi` calls.
- On Wayland: skips `glxinfo` (X11-only), falls back to `/sys/class/drm/` sysfs detection.
- `_tryQuickNvidiaGpuForTray()` also caches for 5s.
- `lspci -d ::0300 -nn` used as lighter weight GPU query (targets VGA class only).

### CPU temperature
- `getCpuTemperature()` caches result for 5s.
- `sensors -u` used instead of full `sensors` (machine-parseable, lighter output).

### Memory monitoring via /proc
- `getMemoryFromFreeForTray()` reads `/proc/meminfo` directly instead of spawning `free -h` + parsing.

### GRUB suggestions for NVIDIA + Wayland
- `grub_suggestions_service.dart` adds 4 new NVIDIA-specific kernel parameter suggestions:
  - `nvidia.NVreg_UsePageAttributeTable=1` — Wayland rendering perf
  - `nvidia.NVreg_EnableResizableBar=1` — PCIe ReBAR (10-15% boost)
  - `nvidia.NVreg_EnableGpuFirmware=0` — Wayland stability
  - `nvidia_drm.fbdev=1` — framebuffer console on Wayland

### Display info in System tab
- `system_monitor_screen.dart:_buildDisplayServerCard()` shows Wayland/X11/XWayland detection + desktop + env vars.

## Repository Manager (multi-distro)
- `repository_manager.dart` centralizza la configurazione dei repository per ogni distribuzione.
- Supporta: Ubuntu, Debian, Linux Mint, Pop!_OS, Zorin, elementary, MX Linux, Fedora, RHEL, CentOS, Arch Linux, Manjaro, EndeavourOS, KDE neon.
- `restoreRepositories()` ripristina i file `.sources`/`.list`/`.repo`/`pacman.conf` con le repository ufficiali.
- `getUpdateCacheCommand()` restituisce il comando per aggiornare la cache del package manager.
- `getRestoreCommands()` produce comandi bash per scrivere i file di repo tramite heredoc.

## Dependency install with repo auto‑restore
- `_installPackages()` in `recovery_service.dart` chiama `RepositoryManager.restoreRepositories()` + aggiornamento cache prima di installare.
- `DependencyCheckService.ensureRepositories()` disponibile per chiamate manuali.
- `checkForUpdates()` in `recovery_service.dart` ripristina i repository prima di controllare aggiornamenti.
- Qualsiasi distribuzione con APT/DNF/Pacman può ora installare pacchetti anche se le repository sono corrotte o mancanti.

## Tray menu rebuild with label caching
- `_refreshMenuStats()` in tray ricostruisce il menu (`setContextMenu()`) solo quando le label effettivamente cambiano.
- Cache: `_prevTempLabel`, `_prevUsageLabel`, `_prevDiskLabel`, `_prevMemoryLabel`, `_prevSmartLabel`.
- `_menuDirty` flag per forzare rebuild iniziale o su cambio labels localizzate.
- Su Cinnamon, evita `setContextMenu` a ogni refresh (5s), riducendo il rischio che l'appindicator nativo perda i callback GObject.

## Smartmontools install feedback
- `_installSmartctl()` in `smart_monitor_screen.dart` ora mostra SnackBar di errore se installazione fallisce.
- Controlla che password sudo sia salvata prima di procedere (SnackBar arancione se manca).

## Cinnamon tray detection
- `SystemDetectionInfo.hasCinnamon`: campo booleano; `_detectDesktopEnvironment()` setta `hasCinnamon = true` quando `XDG_CURRENT_DESKTOP` contiene 'cinnamon'.
- `isSystemTraySupported()` in `dependency_check_service.dart` cerca anche `libcinnamon-appindicator*`.

## Smart monitoring USB detection
- `scanDisks()` in `smart_service.dart` ora include un passaggio `lsblk` per dispositivi USB.
- Molti bridge USB-SATA non vengono enumerati da `smartctl --scan` ma sono visibili via `lsblk -dno NAME,TRAN`.
- Il passaggio aggiuntivo prova `smartctl -d sat` per ogni dispositivo con `TRAN=usb` non trovato da `smartctl --scan`.
- Timeout USB aumentato da 1s a 3s per bridge più lenti (`_runSudoCommand` con `timeout: const Duration(seconds: 3)`).
- Dispositivi trovati da `lsblk` vengono aggiunti alla lista anche se `smartctl --scan` non li vedeva.

## Debian 13 / sudo password handling fixes
- **Root cause su Debian 13**: `ensureSmartctlAvailable()` in `smart_service.dart` catch-all nascondeva l'errore reale (apt lock, repo mancanti, password sbagliata) → sempre "Check your sudo password".
- **Fix 1**: `ensureSmartctlAvailableDetailed()` ritorna `SmartctlInstallResult` con errore specifico (password non corretta, apt lock, repo mancanti, dpkg interrotto).
- **Fix 2**: `validateSudoPassword()` esegue `sudo -v` prima di tentare installazione, ritorna errore specifico se password sbagliata.
- **Fix 3**: `_installViaApt()` esegue `apt-get update -qq` prima di `apt-get install` con gestione errori specifica per Debian 13 (apt lock, repo 404, dpkg interrupted, pacchetti non autenticati).
- **Fix 4**: Password escaping migliorato in `_escapeForBashDoubleQuote()` — gestisce `\n`, `\r`, `'` oltre a `\`, `"`, `$`, `` ` ``.
- **Fix 5**: Stessa correzione escaping in `dependency_check_service.dart` e `recovery_service.dart` (stesso pattern vulnerabile).
- **Fix 6**: `2>&1` aggiunto a tutti i comandi sudo per catturare stderr nel stdout.

## Tray showWindow reliability (Cinnamon/XWayland)
- `showWindow()` in `tray_service.dart` ora usa retry con delay progressivo (150ms, 250ms) per gestire Cinnamon/XWayland dove il window manager potrebbe non aver mappato la finestra quando il callback tray arriva.
- `windowManager.show()` + `windowManager.focus()` + `_appWindow?.show()` eseguiti sia al primo tentativo che al retry.

## Smart disk detection (multi-distro)
- `scanDisks()` in `smart_service.dart` ora usa un approccio a 3 fasi per compatibilità universale:
  1. **lsblk JSON** (`lsblk -dJno`): metodo principale, funziona su tutte le distro Linux, non richiede smartctl --scan.
  2. **smartctl --scan**: integrazione per dispositivi NVMe/RAID visti da smartctl ma non da lsblk.
  3. **`/sys/block/`**: fallback estremo per sistemi minimali.
- `_trySmartctlInfo()` prova smartctl con sudo per ogni dispositivo scoperto, con varianti di tipo device.
- Dischi scoperti da lsblk/sysfs vengono mostrati anche senza info SMART (i dati vengono letti al click).
- Fix Debian 13: `smartctl --scan` spesso restituisce vuoto su Debian 13 — lsblk risolve il problema.
- **Fix USB vs SATA**: `getSmartInfo()` ora usa `disk.interface` (non `deviceType`) per distinguere USB reali da SATA locali. `deviceType='sat'` viene usato sia per bridge USB-SATA che per SATA locale — causava classificazione errata.
- **Two-phase smartctl**: prima prova senza sudo, poi con sudo. Dischi locali spesso funzionano senza sudo; sudo serve solo per permessi restrittivi.
- **Errori localizzati**: `smart_service.dart` NON restituisce più messaggi hardcoded italiani. Restituisce codici errore (`SmartErrors.*`, es. `smartErrAptLock`) con dettaglio dinamico nel formato `codice:dettaglio`. La UI li traduce con `SmartService.localizeError(l10n, code)`; le chiavi sono in tutti gli `.arb` (prefisso `smartErr*`).

## Distro-aware smart strategy
- `_detectStrategy()` legge `/etc/os-release` e mappa la distro in `_SmartStrategy` enum.
- **Ubuntu family** (Ubuntu, Zorin, Mint, Pop, elementary): `smartctl --scan` funziona → scan con smartctl, no-sudo prima poi sudo.
- **Debian family** (Debian, Kali, Deepin, MX, Parrot): `smartctl --scan` rotto → scan con lsblk, sudo prima poi no-sudo.
- **Fedora family** (Fedora, RHEL, CentOS, Rocky): smartctl --scan funziona → come Ubuntu.
- **Arch family** (Arch, Manjaro, CachyOS, EndeavourOS): smartctl --scan funziona → come Ubuntu.
- **Unknown**: prova entrambi gli approcci (lsblk + smartctl --scan).

## Process list filtering
- `getProcesses()` in `system_monitor.dart` filtra i processi transienti di sistema.
- `_isTransientProcess()` esclude: `ps`, `bash`, `sh`, `sudo`, processi kernel (pid < 100), `kworker*`, `ksoftirqd*`, `rcu_*`, `migration*`.
- Evita che il comando `ps` stesso appaia nella lista dei processi.

## Arch Linux / CachyOS / AUR build
- `build_arch.sh`: script per build Arch Linux (standard, advanced, personal).
- `PKGBUILD`: file per AUR (Arch User Repository).
- Supporta: Arch Linux, CachyOS, EndeavourOS, Manjaro, Garuda e derivate.
- Dipendenze: `gtk3`, `glib2`, `libayatana-appindicator` (runtime), `cmake`, `ninja`, `clang`, `pkg-config` (build).
- Pacchetti generati: `.pkg.tar.zst` con struttura standard Arch (`/usr/bin/`, `/usr/share/`, `.PKGINFO`).

## Linux Mint / LMDE repository protection (CRITICAL)
- `repository_manager.dart` gestisce il ripristino repository per Linux Mint (tutte le varianti: Cinnamon, XFCE, MATE, KDE, LMDE).
- **Bug storico**: LMDE7 (VERSION_CODENAME=gigi, DEBIAN_CODENAME=trixie) aveva `_isLmde()` che falliva se `ID_LIKE` non era esattamente `'debian'` → il codice scriveva repository Ubuntu (`archive.ubuntu.com`) con codename `gigi` → sistema rotto.
- **Fix `_isLmde()`**: usa 3 segnali: `ID_LIKE` contiene `'debian'` (non exact match), `PRETTY_NAME` contiene `'lmde'`, `DEBIAN_CODENAME` è presente. **PRIMA** verifica che `ID_LIKE` non contenga `'ubuntu'` → se contiene `'ubuntu'`, è Mint standard e restituisce false subito.
- **Fix `_getBaseCodename()`**: VERSION_ID 7→trixie, 8→forky (Debian 13/14). Default: `trixie` (non `'stable'`). **CRITICO**: usa match ESATTO (`ver == '2'`) non `startsWith('2')` — altrimenti VERSION_ID=`22` (Mint 22) matchava → restituiva `jessie` (Debian 8).
- **Fix `_sanitizeLmdeCodename()`**: converte codename non-Debian in `stable` come fallback sicuro.
- **Fix `areRepositoriesHealthy()`**: controlla se `sources.list` ha righe `deb ` (su Mint non dovrebbe) → restituisce false. Controlla anche file extra in `sources.list.d/` con repo sbagliate (Debian su Mint standard, Ubuntu su LMDE).
- **Fix `checkForUpdates()` e `_installPackages()`**: chiamano `areRepositoriesHealthy()` prima di `restoreRepositories()`, evitando di sovrascrivere repo funzionanti.
- **Fix cleanup**: `_mintRepos()` ora rimuove file extra in `sources.list.d/` con repo sbagliate (residui di versioni precedenti).
- **PROTEZIONE FUTURA**: `_getAptRestoreCommands()` ha commento `// PROTETTO: Linux Mint usa SEMPRE repository proprie. NON generare MAI repository Ubuntu per Mint.` — NON rimuovere questa protezione.
- **Codename mapping LMDE**: `faye`=LMDE6/bookworm, `gigi`=LMDE7/trixie. `VERSION_CODENAME` è il codename Mint, `DEBIAN_CODENAME` è il codename Debian base.

## RAM cleanup (Pulizia RAM)
- `ram_cleanup_service.dart` esegue una pulizia della RAM multi-distro NON invasiva.
- `cleanupRam()` fa SOLO: `sync` + `drop_caches` (echo 1/2/3 → `/proc/sys/vm/drop_caches`, richiede root) + riciclo swap (`swapoff -a && swapon -a`) + `sync` finale.
- **NON tocca MAI** servizi di sistema (non usa più `systemctl`/`detectUnnecessaryServices`/`stopService`) e **NON elimina** file temporanei (`/tmp`, `/var/tmp`, `~/.cache`) — rimozione richiesta dall'utente.
- `RamCleanupResult` contiene solo `success`, `before`, `after`, `stepsDone`, `stepsFailed` (campo `servicesStopped` rimosso).
- Statistiche RAM lette da `/proc/meminfo` (`getRamStats()`) con fallback `free -b`.
- Il messaggio di conferma (`ramCleanupConfirmMessage`) in tutti i `.arb` spiega che non ferma servizi né cancella file temporanei.

## RAM cleanup automatica (Impostazioni)
- `RamCleanupService.prefKeyIntervalMinutes` = 'ram_cleanup_interval_minutes' (0=off, 5, 10, 15, 30 minuti).
- `HomeScreen._startRamCleanupTimer()` avvia un tick ogni minuto; `_onRamCleanupTick()` esegue `cleanupRam()` solo se è passato l'intervallo configurato (`prefKeyLastRunTs`).
- SettingsScreen passa `onRamCleanupPolicyChanged: _startRamCleanupTimer` per riavviare il timer al cambio impostazione.

# Sessione 2026-10-18: documentazione aggiornata + benchmark rimosso dai documenti
- **Manuali utente (6 file in `manual/`)**: allineati a v2.1.0 — versione (v2.0.6→v2.1.0), "12 schede"→"14 schede", elenco edizione Standard con Gestore Driver+Batteria, elenco edizione Avanzata SENZA "Benchmark suite" (tab rimossa), TOC con 5.13/5.14 e senza 6.2, sezione "Controllo Aggiornamenti" sostituita da nota (aggiornamenti dal tray o controllo automatico), nuovo bullet "Riduci a icona nel vassoio/opzionale" in Impostazioni→Barra, sezioni 6.2 Benchmark ELIMINATE, cap. 6 = solo Editor GRUB. I 6 manuali hanno la STESSA struttura (stessi numeri riga): le modifiche si fanno per TUTTI e 6 insieme; contenuti per lingua nel diff del commit.
- `README.md`: sezione Appearance STALE rimossa (accent color + wallpaper non esistono più); aggiunte Disk Analyzer (nascosti, streaming, cache), Global search Ctrl+K + Undo banner, Interface (onboarding, tema/font/lingua, scrollbar, tab batteria nascosta), Security (keyring). Technical Details "Password storage" aggiornato al keyring.
- `CHANGELOG.md`: aggiunta sezione "## Unreleased" (fix tray Fedora, fix build scripts secret, Disk Analyzer, UX, keyring/licenza, rimozione dead code, l10n 55+ stringhe). Il changelog riflette ora lo stato post-2.1.0 non ancora rilasciato.
- Copie tracciate in `deb_package_{standard,advanced}/` (doc/ + flutter_assets/CHANGELOG.md) sincronizzate con README/CHANGELOG root.
- ⚠️ Non usare la parola "Benchmark" nei documenti/per l10n: il tab NON esiste più; keyword 'benchmark' resta solo nelle `_TabSpec.keywords` di Tweaks (porta lì).

# Sessione 2026-10-27: Fedora/dnf5 aggiornamenti + versioni driver reali (tutte le PM)
- **BUG RADICE aggiornamenti Fedora/dnf**: regex "pkg.arch <spazio>" usava `[a-zA-Z0-9]+` DOPO il punto → l'arch `x86_64` (underscore!) non matchava mai → TUTTE le righe DNF `.x86_64` scartate dal check e classificate come "Snap" nel dialog tray. Fix: `[a-zA-Z0-9_]+` in `parseDnfUpdateLines` (recovery_service) e in `_sourceForIndex` (home_screen), più noise-list per dnf5.
- `checkForUpdates` DNF: `LC_ALL=C dnf check-update -q`; rc tracciato con marker `__DNF_RC__:$?` (dnf4/5: rc 100 = aggiornamenti, 0 = nessuno); fallback `dnf list updates -q` se il primo parse dà 0 con rc≠0/100; timeout → mode error (non "none"). `dnfPackageNameFromLine()` pure: strip arch SOLO se arch-valido (x86/noarch/aarch/ppc/s390/riscv), anti-injection charset `[A-Za-z0-9+._-]+`.
- `performUpdates` DNF: `dnf -y upgrade` (dnf5 deprecato `update`) + LC_ALL=C + installazione SELETTIVA: gli item scelti (raw "name.arch …") vengono riconvertiti in nomi via `dnfPackageNameFromLine`; selezione vuota → full upgrade.
- **Driver Manager versioni reali (tutte le PM)**: nuovo `installedPatterns` in `_ChipsetEntry` per 11 chipset; `_installedPackages()` = un solo comando per scan (dpkg-query -W TAB / rpm -qa --qf TAB / pacman -Q) cache statica 2 min; `parseInstalledPackages()` e `matchInstalledPackages()` PURE (pattern regex case-insensitive, invalidi ignorati); DriverInfo ha `installedPackageName` + `version` popolati; status installed = module loaded OR match famiglia OR candidato nel DB. **NVIDIA**: versione display da `nvidia-smi --query-gpu=driver_version` (cache 5 min, cat. Graphics & vendor 10de) — così su Zorin si vede 580.x e NON più il pacchetto candidato statico; candidati apt NVIDIA DINAMICI via `apt-cache search --names-only '^nvidia-driver-[0-9]+$'` ordinati desc (fallback statico esteso a 580/575/570/560/550/535). Screen: mostra "Installato di sistema: name (version)" invece del primo candidato quando è installato.
- **Perf**: `_isPackageInstalled` rimane (firmware/install); il vecchio loop per-candidato (dpkg/rpm per OGNI candidato per OGNI device) è stato sostituito dal DB unico in cache — non reintrodurre N query per candidato.
- RepositoriesService lettura DNF: `enabled=true/false` (dnf5) accettato; `metalink=`/`mirrorlist=` mostrati come URI se baseurl assente; supporto `reposdir=` personalizzato da `/etc/dnf/dnf.conf` (dirs multiple, dedup per path). RepositoryManager resta write-only.
- **CHANGELOG "Unreleased"**: la card "ultima release" di InfoScreen usa `releasedChangelogSections()` (nuovo in changelog_view.dart) che esclude le sezioni che iniziano con "Unreleased"; il dialog completo mostra tutto. Test changelog aggiornato.
- l10n: +1 chiave `driverManagerInstalled` ×6 arb; NELL'ATTRIBUTO @ usa la MAPPA con "description" (una stringa piana fa fallire gen-l10n con "not a properly formatted Map"). Nuovi test `test/dnf_updates_parse_test.dart` (15). Verifica: analyze **177 (== baseline HEAD, 0 errori)**, test **134/134**, build release OK.
- ⚠️ La baseline analyze è ora 177 (non più 164) — issue preesistenti a HEAD; aggiornare riferimenti vecchi.

## Tray menu
- `TrayMenuLabels`/`TrayCallbacks` hanno il campo `settings`/`onShowSettings`: la voce "Impostazioni" apre il tab Settings (`HomeScreen._goToSettingsTab()` usa `tabCount - 2`).
- Etichetta traySettings aggiunta in tutti gli `.arb`; rigenerare con `flutter gen-l10n` (template = `app_it.arb`). Attenzione: `gen-l10n` rigenera anche getter precedentemente presenti solo nei `.dart` committati; le stringhe nuove vanno aggiunte a TUTTI i 6 `.arb`.

## Struttura tab HomeScreen (recovery sempre disponibile)
- Tab standard (14, con batteria): Services, StartupApps, Cleanup, InstalledApps, Monitor, DiskAnalyzer, Smart, DeviceManager, DriverManager, Recovery, Battery, Tweaks, Settings, Info → 13 se la batteria è assente (`BatteryService.hasBatteryDevice()` su sysfs è fatta in `_initializeController`, default true in caso di errore di lettura).
- Tab solo advanced: Grub → `_advancedTabCount` = tab standard + 1 (15 con batteria, 14 senza). Il Benchmark è STATO RIMOSSO (le schermate di benchmark non esistono più; la keyword 'benchmark' nella ricerca porta a Tweaks).
- **Indici NON più fonte di verità**: sidebar e viste sono costruite da `_allTabSpecs` (chiave stabile per tab: 'services','startup','cleanup','installed','monitor','diskAnalyzer','smart','deviceManager','driverManager','recovery','grub'(advancedOnly),'battery'(needsBattery),'tweaks','settings','info') in home_screen; `_goToTabKey(key)` naviga per chiave (fallback 'battery'→'monitor' se assente); callback tray usano chiavi; `_goToSettingsTab` non fa più aritmetica `tabCount-2` (FIX: "Batteria" nel tray andava su Recovery!). `_TabSpec.keywords` (EN) alimenta la ricerca globale.
- `SecurityScreen` e `RepositoriesScreen` NON hanno più tab propri nella sidebar: sono sub-tab dentro `RecoveryScreen`.

## Hardware tab / desktop senza batteria
- Tab Battery nascosto se `BatteryService.hasBatteryDevice()` è false (nuovo metodo pubblico su `_batteryNames()`; su errore di lettura restituisce false→NON nasconde per sbaglio, ritorna lista vuota → ambienti rari: tab visibile iff lista vuota per mancanza reale di BAT*).
- DeviceManager/DriverManager restano SEMPRE (su desktop PCI/USB esistono sempre: non erano veri "tab vuoti"; l'utente proponeva collassarli ma la sostanza era il tab batteria + nullità discovery → risolta con ricerca globale).

## Ricerca globale Ctrl+K (2026-10-18)
- `lib/widgets/global_search_dialog.dart`: dialog con filtro fuzzy (token AND; score label-startsWith > label-contains > keywords); le voci `TabSearchEntry` derivano da `_allTabSpecs` (etichette localizzate + keywords EN); risultato = chiave del tab → `_goToTabKey`.
- Scorciatoie registrate in HomeScreen build (CallbackShortcuts + Focus autofocus): Ctrl+K e Meta+K; anche icona lente in AppBar.
- l10n: `searchHint`, `searchNoResults`.

## Banner operazione annullabile (Undo, 2026-10-18)
- `lib/widgets/undo_snackbar.dart`: `showOperationUndoSnackBar(context, message, ok, record)` — SnackBar col messaggio del risultato; se il record ha `undoCommand` (e non già restored) mostra azione Undo → `OperationHistoryService.restoreOperation(id)` + SnackBar esito. `ScaffoldMessenger` va catturato PRIMA (context della snackbar morta nella chiusura). `showUndoSnackBarForLatest(...)` recupera l'ultimo record con `latestRecord({category, action})` (nuovo metodo in operation_history_service).
- Cablato su Tweaks→kernel tweaks apply (il servizio logga con undoCommand). Reset logga senza undo → nessun banner Undo. `latestRecord({category, action})` è il nuovo metodo in operation_history_service.

## Onboarding stepper (2026-10-18)
- `lib/screens/onboarding_screen.dart` sostituisce LanguageSelectionScreen + WarningScreen (ENTRAMBI rimossi): passo 1 lingua (apply IMMEDIATO al tap: prefs `locale` + `language_selected` scritti subito, così se l'app si chiude al passo 2 riapre localizzati), passo 2 avviso rischi + card "Sistema rilevato" LOCALIZZATA (prima hardcoded italiano: keys `warningSystemCard`, `warningOsLabel`, `warningDesktopLabel`, `warningGrubCommand`).
- main.dart: `_showLanguageSelection || _showWarning` → OnboardingScreen(`initialStep` 0/1, `onComplete` → `_checkInitialStatus()`); `warning_accepted` scritto in `_complete()` (GOTCHA: prima stesura lo aveva perso, test l'ha beccato).
- Fallback EN con `lookupAppLocalizations(const Locale('en'))` se l10n null (solo teorico: passo warn richiede lingua già scelta).
- `onboardingContinue` ("Avanti"/"Next"/...) per il bottone del passo 1.
- `window_close_to_tray.dart`: `firstRun` flag resta `language_selected||warning_accepted||password_configured` (nessun cambio).

## Riduci a icona nel tray (minimize_to_tray, 2026-10-18)
- **Accertato: NON esiste hide-on-blur** (nessun onWindowBlur in lib/; my_application.cc non tocca focus). Il sospetto "si nasconde quando perde il focus" era `onWindowMinimize` → hide quando `close_to_tray` attivo.
- Fix: `TrayService.prefKeyMinimizeToTray = 'minimize_to_tray'` (default **false** = minimize normale, resta nella barra applicazioni); il listener nasconde nel tray SOLO con il pref attivo. Toggle separato in SettingsScreen (`_setMinimizeToTray`) + snackbar on/off (`settingsMinimizeToTrayOn/Off`); `close_to_tray` invariato (default true).
- **Behavior change** per utenti esistenti: finora minimize→tray sempre; ora opt-in (attivabile da Impostazioni).

## RecoveryScreen (4 sub-tab)
- TabBar: `recoveryTabRecovery` (operazioni), `tabRepositories`, `recoveryTabSoftwareInstaller`, `tabOperationHistory` (4 tab; `tabSecurity` non esiste più, SecurityScreen rimossa).
- Il sub-tab "Verifica Aggiornamenti" (`recoveryCheckUpdates`/`recoveryTabCheckUpdates`) è stato RIMOSSO: gli aggiornamenti si controllano dal tray/dialog (`HomeScreen._showTrayCheckUpdatesDialog` usa `recoveryCheckUpdatesComplete`/`recoveryCheckUpdatesError`/`recoveryPerformUpdates` — tenere queste chiavi l10n).
- Recovery è disponibile anche nella versione standard (gratuita); Grub e Benchmark restano avanzati.

## Disk Analyzer: nascosti sempre visibili + velocità (2026-10-18)
- **Nascosti (`.*`) visibili di default**: `_showHiddenFiles` default true + persistito (`disk_analyzer_show_hidden`). Prima il default era false e la preferenza non persisteva al riavvio; le cartelle nascoste (spesso le più grosse: .cache/.local/docker) risultavano invisibili dall'app.
- **Cache master senza filtrare**: nuovo campo `_lastListedItems` (elenco completo da cache/listDirectory, nascosti inclusi) — le dimensioni calcolate in background vanno aggiornate li e `_persistChildSizesToCache` persiste il MASTER: prima, navigando col filtro attivo, la cache veniva riscritta SOLO con le voci visibili e l'occupazione dei nascosti non veniva né aggiornata né recuperata al prossimo avvio. BUG radice: "fa difficoltà a leggere e mostrare tutte le cartelle".
- **Esclusioni rimosse (completezza)**: root chart (`_duStreamingInnerCommand`) e `_tryParseDuLine` NON escludono più `/var/lib/docker`, `/var/lib/containers`, `/var/cache`, `/var/tmp` — sono proprio le cartelle di sistema principali che l'utente vuole vedere (coperte dal passaggio sudo). Restano le esclusioni dei montaggi virtuali/loop (/proc /sys /dev /run /tmp /snap /boot /boot/efi /lost+found /sysroot).
- **Filtro nomi virtuali solo al primo livello**: in `_tryParseDuLine` la black list per NOME ('tmp','proc',...) scatta solo per le figlie DIRETTE della root scansionata (du -d1 emette solo quelle): una 'tmp'/'cache' annidata è reale e resta visibile (prima veniva nascosta ovunque).
- **Velocità, dimensioni via UN SOLO du**: `_calculateSizesInBackground` ora usa `_streamChildSizesFromDu` = un solo `du -b -d1 '<dir>'` (output streaming, righe "size<TAB>path"; parse in `_parseDuSbLine`, flush per-chunk con `_applyChildSize` su entrambe le liste). Prima: in batch che spawnavano fino a 10 processi `du -sb` concorrenti, ciascuno riattraversava l'intero sottoalbero per ogni sottocartella (N passate complete) → sprechi di I/O e lookahead limitato. **GOTCHA du**: `du -sb -d1` è ERRORE ("-s confligge con --max-depth=1") → usare `du -b -d1`; `-b` = apparent-size bytes, coerente con il `du -sb` già usato dal servizio. Fallback legacy `_calculateSizesWithPerDirectoryDu` (vecchi batch) solo se du non produce righe.
- **Velocità, sudo-first**: `_getTopDirectories`: con password già salvata si parte direttamente con sudo (un passaggio completo; il passaggio senza privilegi produceva parziali non vuoti e l'early-return lo dava per buono, saltando le cartelle protette per sempre). Senza password: ordine invariato (utente → sudo con dialog).
- `du -d1` NON mostra i FILE di primo livello (solo directory): le size dei file restano quelle dal listing (corretto, invariato).

## Disk Indexing Engine (Analizzatore Disco)
- `lib/services/disk_indexing_engine.dart`: traccia lo stato di indicizzazione del disco.
- Un disco è "indicizzato" dopo la prima scansione completa (`DiskCacheService.saveDirectorySizes`).
- `isIndexed()`: cache di sessione → flag `fullyIndexed` nel JSON cache → fallback: `directorySizes` non vuoti contano come già indicizzati (compatibilità cache vecchie).
- `markIndexed()`: imposta `fullyIndexed` e persiste nella cache del disco.
- Chiave l10n `diskIndexingNotice` mostra un piccolo banner (icona hourglass) finché il disco selezionato non è indicizzato; `disk_analyzer_screen.dart` chiama `_refreshIndexedState(path)` alla selezione base/disco esterno e `markIndexed` dopo il primo salvataggio della scansione.
- Percorso normalizzato: root → `'/'`, trailing slash rimosso.

## CPU usage optimization (audit)
- `system_monitor.dart:_getCpuInfo()`: cache statica (5 min) per i valori statici (`lscpu`, `nproc`); sui cache-hit rifresca solo i valori dinamici (`/proc/stat`, `mpstat`, cpufreq) senza rispawnare `lscpu`/`nproc`.
- `system_monitor.dart:_getDiskInfo()`: cache statica (3 min) per l'output `df -B1 -T`, evitando il subprocess a ogni refresh.
- `tray_task_manager_dialog.dart`: flag `_isRefreshing` sul timer 5s per evitare chiamate sovrapposte a `getSystemInfo()`.
- `system_monitor_screen.dart`: già ottimizzato (timer 5s con `_isRefreshing` + stop quando la tab non è attiva).

## CHANGELOG & About (docs in deb)
- `CHANGELOG.md` (repo root, inglese): unica fonte delle note di rilascio; versioni da GitHub releases (2.1.0 → 1.8.6). È anche **flutter asset** (`pubspec.yaml` → `assets: - CHANGELOG.md`).
- `lib/widgets/changelog_view.dart`: `parseChangelog()` (sezioni `## `) + `ChangelogView` (rendering `###`, bullet, `**bold**`); `maxSections: 1` per la card inline.
- `lib/screens/info_screen.dart`: card "Changelog" dopo la card License (mostra ultima release + bottone "View full changelog" → dialog scrollabile). Se l'asset non carica, la card resta nascosta.
- l10n: chiavi `infoChangelog` / `infoChangelogShowAll` in tutti i 6 `.arb` + `flutter gen-l10n`.
- `build_deb.sh` (3 blocchi standard/advanced/personal) installa in `/usr/share/doc/$APP_NAME/`: `LICENSE`→`copyright`, `README.md`, `CHANGELOG.md`, e testo completo GPL-3→`LICENSE` se presente in `/usr/share/common-licenses/`.
- **Gotcha test**: `rootBundle.loadString` dentro un `test()` "semplice" fa bloccare il `pumpWidget` del `testWidgets` successivo → caricare gli asset **dentro** il body `testWidgets` (vedi `test/changelog_test.dart`). Font di test quadrato: usare `tester.view.physicalSize` più ampio per non far traboccare le righe dei titoli card.

## Rimozione AI slop (2026-09)
- Rimossi: `combined_patch.patch`, `docs/README_STYLE_EN.md`, `docs/PAGE_FOR_USERS_AND_INSTALL_EN.md`, `.vibe_chat.json`, `SystemTrayManager.dart` (orphan (root), causava errore in `flutter analyze`).
- Rimossa `publish_github/` (copia duplicata e obsoleta del progetto, 222 file): `build_rpm.sh` è stato spostato alla radice, il resto era duplicato/obsoleto.
- `deb_package_personal/` non è più tracciato (come deciso su GitHub); `.gitignore` esclude `*.deb`, `*.AppImage`, `*.pkg.tar.zst`, `Versione Arch Linux/` e `deb_package_personal/`.
- Metainfo (4 file): rimosso commento template screenshot e markdown `**...**` dalla descrizione.
- `appDescription` (6 arb) riscritta senza copy marketing; rimossa l'intestazione duplicata nella card descrizione di About.
- Tenuti: `docs/FLATHUB_*.md`, `docs/CREA_GITHUB_PAGES_VERIFICA.md` (note operative), `manual/` (manuali utente, tracciati), `AGENTS.md`.
- NOTA SICUREZZA: `_kLicenseSecret` (HMAC licenze) è identica in `lib/services/license_service.dart` e `tools/license_key_generator.dart` ed è nel repo pubblico + storico git; la validazione è client-side, quindi la secret è comunque estraibile dal binario. Per prodotto reale: ruotare la secret e valutare validazione server-side.

## Task 2.1: tray no-flash, zram, firmware, cleanup v2 (2026-10)
- **Tray avvio minimizzato**: `linux/runner/my_application.cc` legge la pref `slu_pref_bool("should_start_hidden")` (prima del mapping della finestra); se true + `SUPER_LINUX_UTILITY_MODE=tray`, la finestra non viene mappata (`gtk_widget_show` saltato, `first_frame_cb` early-return) → nessun flash. Fallback: `lib/main.dart:ensureWindowShown()` (mostra dopo 1.5s solo se la finestra non è mai stata visibile), rescue tray-init e `_AlreadyRunningApp.initState` show. `window_close_to_tray.dart` gatea i retry di hide con `firstRun`.
- **Zram persistente**: `ram_cleanup_service.dart` cattura `beforeDevs` prima dello swapoff e rifà swapon dei device mancanti; dopo il cleanup esegue `systemctl restart zramswap` (non `start`: unit è `active (exited)`, start sarebbe no-op). `tweaks_service.dart`: `isZramEnabledAtBoot()` (grep zramswap in unit + /etc/fstab + /etc/modules), `buildEnableZramAtBootCommand()`, `buildInstallZramCommand()`, `getSwapRecommendations(..., bootEnabled)`.
- **Stato firmware linux-firmware**: `driver_manager_service.dart` → `LinuxFirmwareStatus{notInstalled,upToDate,updateAvailable,unknown}` via `parseAptPolicyUpdatable` (puro, testabile) su `apt-cache policy linux-firmware` (usa `Candidate:` vs `Installed:`); install/update con sudo+dpkg. Card a 3 stati in `driver_manager_screen.dart`.
- **Cleanup v2 (7 nuove voci advanced)** in `advanced_cleanup_service.dart`, tutte con gate `sizeBytes > 0`: `pkg-cache` (`/var/cache/apt` + dnf/pacman), `electron-cache` (`_electronCacheNames` in `~/.config/*/`), `opencode-data` (SOLO `log`+`snapshot`, MAI `opencode.db`), `cuda-repo` (`/var`,`/var/lib` prefix `cuda-repo`), `cuda-dup` (default-EXCLUDED in `_loadAdvanced`), `snap-old`, `flatpak-unused`.
- **Gotcha critici**: (1) ogni stringa shell con `$var` che NON è una variabile Dart DEVE essere raw `r'...'` altrimenti Dart la interpola (errori `undefined_identifier`/`missing_identifier`); `'$fail'` in test interpola la funzione `fail` di matcher. (2) Comandi passati a `_runSudo` NON devono contenere apici singoli → awk usa doppio apice `awk "{print \$1}"`. (3) `_dirSize` deve parsare stdout anche con du rc≠0 (dirs mode 700). (4) snap list ha header localizzato (italiano anche con LC_ALL=C) → salta riga 1. (5) flatpak uninstall senza risposta annulla SÌ di default → `printf 'n\n'` obbligatorio nel dry-run; righe TAB-separate con op `r`, 4-5 campi. (6) `activeCudaRoot` ordine: nvcc PATH → shell rc (ultima vince) → `/usr/local/cuda` (su questa macchina readlink→13.1 ma nvcc→13.0!). 
- **l10n**: 13 chiavi ×6 arb (7 `dev*` dopo `devKernelHeaders`, 6 `driverManagerFirmware*` a fine file, la desc esistente va solo virgolata) + `flutter gen-l10n`.
- Verifica: `flutter analyze` 255 info/warning **0 errori**, `flutter test` **59/59**, `flutter build linux --release` OK; parità arb 1012 chiavi ×6, 13 getter ×6 file locale generati.

## Uninstaller rewrite (2026-10)
- `app_manager.dart` riscritto: `removeApp()` restituisce `RemovalResult{success, message, code}` (non più bool) — il successo è **verificato ri-interrogando il PM** (`_execRemoval` pattern: rc=0 da solo NON basta, alcuni comandi escono 0 anche su errore). `code`: `no-password` | `timeout` | `invalid-name` | `no-desktop-file`.
- **Bug fissati**: (1) `${Description}` di dpkg-query è la descrizione LONG multilinea → le righe di continuazione con `;` creavano "app fantasma" che apt non poteva rimuovere; ora formato TAB (`Package\tVersion\tInstalled-Size\t${db:Status-Status}\tDescription`), righe che iniziano con spazio scartate, stato `config-files`/`not-installed` escluso (erano voci "già rimosse" che re-move davano no-op). (2) flatpak: split su whitespace rompeva id per nomi con spazi ("Super Productivity"→"Productivity"); ora `--columns=name,application,version,branch,installation` TAB-separated + `installation` nel model (`user|system|both`, merge in `mergeFlatpakScope`). (3) apt remove senza `DEBIAN_FRONTEND=noninteractive` + `--force-confold` → EOF su prompt dpkg → fallimento silenzioso; lock dpkg → retry 3×2.5s; `LC_ALL=C` su tutti i comandi letti (apt-cache "Reverse Depends:" è localizzato!). (4) app GNOME: usava il display name come nome file .desktop (mai trovato) → ora `desktopFile` = percorso reale; saltati file owned da dpkg (duplicati dell'elenco APT, `dpkg -S` a blocchi di 400) e `NoDisplay`/`Hidden`/`Type!=Application`; `~/.local` prevale su `/usr/share` per basename. (5) fallback `apt list` passava `2>/dev/null` come ARGOMENTO (Process.run non fa redirect) + parsava il codename come versione.
- **Nuovi PM**: enum `pacman` (`pacman -Qi` con LC_ALL=C, blocchi `Key: value`) e `dnf` (`rpm -qa --qf` TAB, ordinato) — list + remove + verify (`pacman -Q`/`rpm -q`). Rimozione pacman solo `-R` (MAI `-Rns`: rompe le dipendenze AUR). `_isSystemPackage` ha ora set esatto (`linux`, `kernel`, `glibc`, `bash`...) oltre alle substring.
- Snap: base/runtime (`_isSnapBase`: core\d*, bare, gnome-\d*, gtk-common-themes, kf\d-core\d+, mesa-\d*) marcati isSystemPackage; notes `-` → null.
- Validazione anti-injection: `isValidAptName/isValidSnapName/isValidFlatpakId/isValidRpmName` PRIMA di ogni comando in shell; nomi/system nei builder via `shq()` (escape `'\''`). Tutti i builder (`buildAptRemoveCommand`, `buildFlatpakUninstallCommand`, `buildDnfRemoveCommand`, ...) sono public e testati con `bash -n`.
- `_run()` con timeout (Process.start + kill, 180s rimozione / 20s verify), password mancante → `_Cmd(-2,'','NO_PASSWORD')` → `code:'no-password'` (UI mostra `passwordSetupDesc`). Errori mostrati in SnackBar come `errorRemoving: <coda stderr 4 righe, max 300 char>` (`AppManager.errorTail`).
- l10n: 4 chiavi ×6 (`installedAppsLoading{count}`, `installedAppsManagedBy{manager}`, `installedAppsSystemWarning`, `installedAppsReverseWarning{count}`) — `warningMessage` hardcoded italiano rimosso dal model, ora `_warningText()` nello screen; `infoInstalledAppsManagementDesc` aggiornata con Pacman/DNF. Stringhe hardcoded della screen sostituite (`appRemoved`, `errorRemoving`, `updatesPreviewTruncated`).
- Rimossi metodi morti: `getAllInstalledApps`, `removeAppWithDependencies`.
- **Test widget gotcha**: in `testWidgets` le Future avviate FUORI da `runAsync` (initState → `_loadApps`) non completano mai (zona fake) → `pumpWidget` va chiamato DENTRO `tester.runAsync()` con delay reale. `find.byType(PopupMenuButton)` fallisce: il widget è `PopupMenuButton<String>` (byType esatto sui type args) → usare `find.byType(ListTile)`.
- Verifica: `flutter analyze` 255 (baseline) 0 errori, `flutter test` **108/108** (48 nuovi in `app_manager_test.dart` + smoke `installed_apps_screen_test.dart`), build release OK, parità arb 1016 chiavi ×6, 4 getter ×6 file locale.

## Scrollbar sempre visibile (Ubuntu/Linux, 2026-10)
- **Problema segnalato**: su Ubuntu nell'app non appare la barra di scorrimento, soprattutto sulle pagine con molte funzioni.
- **Causa**: `MaterialScrollBehavior.buildScrollbar` SU Linux costruisce già lo `Scrollbar` per gli scroll verticali (niente da aggiungere all'albero), ma: (1) il pollice è visibile SOLO durante lo scorrimento e svanisce dopo ~600ms; (2) il colore di riposo di default è `onSurface` al **10% di opacità** (quasi invisibile su bianco) → l'utente non vede nulla.
- **Fix**: `lib/utils/scrollbar_theme.dart` → `buildAppScrollbarTheme(Brightness)` con `thumbVisibility: true` (pollice persistente), `interactive: true` (trascinabile) e `thumbColor` ad alto contrasto per stato (riposo 0.35, hover 0.55, drag 0.75 — usare `withValues(alpha:)`, NON `withOpacity` che è deprecato e aggiungerebbe info all'analyze).
- Cablato in TUTTI i `ThemeData` di `lib/main.dart`: `_StandaloneApp` (light/dark via `copyWith`) + `MyApp` light e dark. `_AlreadyRunningApp` non ha scroll → non serve.
- Il pollice sparisce DA SOLO quando non c'è overflow (controllo interno `RawScrollbar`: `maxScrollExtent - minScrollExtent > tolerance`) → liste corte restano pulite.
- **Scroll orizzontali NON toccati**: `MaterialScrollBehavior` salta `Axis.horizontal` e wrapperebbe anche l'intera TextField monoriga con un pollice permanente — lasciare così.
- Test: `test/scrollbar_theme_test.dart` (4): proprietà tema + widget test con `paints..rect()` che dimostra default=nascosto e tema=pollice dipinto dal primo frame (platform del tema = `TargetPlatform.linux`).
- Verifica: `flutter analyze` 255 (baseline) 0 errori, `flutter test` **112/112**, build release OK.

## Cleanup screen: pagina unica scorrevole con scrollbar (2026-10)
- **Problema segnalato**: nella Pulizia avanzata non c'è scrollbar → l'utente non scorre in basso e non può raggiungere file e pulsanti di pulizia.
- **Causa**: `build()` di `cleanup_screen.dart` aveva una `Column` con sezioni FISSE (testata + card RAM + tile "Pulizia avanzata" + errore) e solo la lista file temporanei in `Expanded`. Con il tile aperto il contenuto fisico superava l'altezza finestra → RenderFlex overflow: il tile veniva ritagliato e TUTTO ciò che stava sotto (lista file, pulsanti) spariva senza nemmeno una scrollbar (non era uno scrollabile).
- **Fix**: `body` è ora UNA sola `ListView` (`padding: EdgeInsets.zero`) con tutti i figli → scorrimento unico + scrollbar globale sempre visibile. Il `ListView.builder` annidato dei file temporanei va rimosso (divieto di ListView dentro ListView): gli item sono costruiti eager con `..._sizes.entries.map((e) => _buildSizeEntry(context, e))`, metodo estratto dal vecchio `itemBuilder` (contenuto invariato). Il loader `if (_isLoading || _isCleaning)` ora è `Padding+Center` dentro la ListView (Center in vincoli non limitati si ridimensiona al figlio).
- **Gotcha test (elementi annidati in ListView)**: la card RAM entra nell'albero dopo il primo frame; inserirla PRIMA del tap nel tile sposta gli indici dei figli → l'elemento `ExpansionTile` viene ricreato per posizione e perde lo stato di espansione (il contenuto sparisce). Nel test: polling `find.byIcon(Icons.speed)` + `pump()` PRIMA di toccare il tile.
- **Gotcha test (stima scroll)**: `maxScrollExtent` dello SliverList è una STIMA finché i figli fuori viewport non vengono costruiti → dopo un drag il massimo si affina e `pixels` può superarlo (errore `closeTo`). Soluzione: un drag reale per provare lo scorrimento, poi `position.jumpTo(maxScrollExtent)` + pump in loop finché `|pixels − max| ≤ 1` (jumpTo è deterministico e ferma anche i ballistic: `tester.drag` con offset grandi produce fling con pixels frazionati).
- Test: `test/cleanup_screen_test.dart` (viewport 1024×674, solo comandi di lettura du/journalctl, `TrayService.runCleanupWhenScreenShown` resta false → nessuna pulizia reale). Copre: nessun overflow col tile espanso, tile dentro la ListView, drag reale, raggiungimento del fondo, scrollbar dipinta (`paints..rect()`).
- Verifica: `flutter analyze` 255 (baseline) 0 errori, `flutter test` **113/113**, build release OK.

## Fedora 44 / AppImage: tray, dnf e universalità (2026-10)

### System tray Fedora: 4 cause radice
- **`isSystemTraySupported()` era "sempre true"**: lo script terminava con `echo $?` (exit code sempre 0) e il check leggeva `result.exitCode`; grep `libayatana_appindicator3` (underscore sbagliato: il soname ha l'hyphen); `ldconfig` non in PATH per le app GUI. Su Fedora le librerie mancanti venivano date per presenti → pulsante "Installa dipendenze" mai mostrato, auto-install all'avvio sempre fallita in silenzio. Fix: legge l'**output** (`'0'`/`'1'`), ldconfig con percorsi assoluti (`/sbin` `/usr/sbin` `/bin`), `find` su `/lib64 /usr/lib64 /lib`, **ramo AppImage** (`$APPDIR`, oppure ricavato da `Platform.resolvedExecutable` → `../lib` accanto alla binaria: funziona anche se APPDIR non è esportato).
- **`_isFedora()` saltava l'init tray su Fedora**: rimosso. Guardia = rilevazione reale delle librerie; **nessuna auto-install all'avvio** (install solo dai pulsanti di Settings).
- **`TrayService.init()` ignorava il bool di `initSystemTray`**: se l'indicatore nativo non nasceva (dlopen fallito) continuava a costruire menu e timer con indicatore nullo → crash storici su Fedora/KDE. Ora: `false` → `_lastError` + `return false` subito; UI mostra SnackBar `settingsTrayInitFailed`.
- **Fedora 44 non ha appindicator gtk3 nei repo ufficiali**: `getSystemTrayInstallCommand()` ritorna `null` per dnf (prima: `dnf install libappindicator-gtk3`, pacchetto inesistente → errore opaco). `installSystemTrayDependencies` ritorna `code`: `ok | unsupported | no-password | wrong-password | locked | error` → Settings traduce via l10n.

### AppImage: cause radice instabilità (`build_appimage.sh`)
- **RUNPATH dei plugin Flutter** (`usr/bin/lib/*.so*`) puntava ancora alla build machine → su Fedora (no libayatana a sistema) il plugin system_tray non si caricava (niente tray, MissingPluginException); su Debian-family il fallback via cache caricava lib host insieme allo stack bundled = ibridazione. Fix: `patchelf --set-rpath '$ORIGIN:$ORIGIN/../../lib'` su **tutti** gli ELF di `usr/bin/lib`, **prima** di linuxdeploy (warn se patchelf assente).
- **Nomi SONAME**: il loop di copia usa `cp -L "$real"` → crea il nome del file reale (es. `libstdc++.so.6.0.33`) e NON lo SONAME (`libstdc++.so.6`) che le NEEDED cercano; linuxdeploy non crea i link mancanti per le librerie blacklisted (tra cui proprio libstdc++) → passaggio `readelf -d SONAME` che crea i symlink mancanti (nessun duplicato: solo se non esiste).
- **Compat dlopen**: `usr/lib/libappindicator3.so.1 → libayatana-appindicator3.so.1` (+ catena `.so.1 → .so.1.0.0` se mancante). Il plugin fa `dlopen("libappindicator3.so.1")` a runtime; su Fedora quel file non esiste → dlopen falliva → init false.
- **`libstdc++.so.6` bundlato** in LIBS_TO_CHECK: libflutter richiede GLIBCXX_3.4.31 → Debian 12/Ubuntu 22.04 stock (3.4.30) non potevano far partire l'AppImage; la copia della build machine è sempre ≥ del bisogno (stesso processo di build).
- **6 lib nella blacklist di linuxdeploy ma NEEDED di lib BUNDLED** aggiunte a LIBS_TO_CHECK: `libz libxcb libexpat libgmp libcom_err libgpg-error` (zlib per cairo/freetype/png/xml2, expat per fontconfig, gmp per gnutls, com_err per krb5/gssapi, xcb per X11, gpg-error per gcrypt) → niente più stack ibrido bundled+host.
- **Verifica scriptabile**: `./verify_appimage.sh [standard|advanced|personal]` → RUNPATH $ORIGIN per exec+plugin+libs, compat e SONAME presenti, ogni NEEDED risolvibile **dentro** l'AppDir (whitelist: solo libc-family/libgcc_s/ld-linux/vDSO), nessun symlink assoluto/broken. Tutte e 3 le varianti: **TUTTO OK, 230 ELF verificati**; contenuto dell'AppImage estratto (`--appimage-extract`) verificato identico.

### Installed Apps dnf (Fedora)
- `_run`: decode → `const Utf8Decoder(allowMalformed: true)`. UN solo byte non-UTF-8 in `%{SUMMARY}` di un pacchetto rpm faceva fallire l'intero decoder → catch → exit -1 → **lista dnf intera buttata** ("app dnf non calcolate").
- `getDnfApps`: `env LC_ALL=C rpm -qa --qf ...` + retry **senza `%{SUMMARY}`** (solo nome+versione) se la lista è vuota/fallita.
- `getGnomeApps`: il filtro owner usava solo `dpkg -S` (assente su Fedora) → TUTTI i `.desktop` di sistema finivano sotto la categoria "GNOME", in duplicati con l'elenco dnf. Ora `_packageOwnedDesktopFiles`: dpkg batch → altrimenti `rpm -qf` / `pacman -Qqo` (1 query per file, 8 worker concorrenti, solo `/usr/share/applications`; `/usr/local` e `~/.local` non sono mai owned da un pacchetto).

### Settings / l10n
- `_setSystemTrayEnabled`: pref salvato **solo a init riuscito**; su errore revert dello switch + SnackBar rosso col motivo; `_installTrayDeps` mappa il `code` → l10n (niente più messaggi tecnici crudi in output).
- 7 nuove chiavi ×6 `.arb` + `flutter gen-l10n`: `settingsTrayInitFailed({error})`, `settingsTrayInstall{Ok,Unsupported,NoPassword,WrongPassword,Locked,Failed({detail})}`.

### Test (113 → 119)
- `test/tray_detection_test.dart`: coerenza `isSystemTraySupported` con verifica indipendente (ldconfig/find) + smoke `getSystemTrayInstallCommand`.
- `test/app_manager_test.dart`: parse fallback 2 campi (description null), righe senza TAB scartate; integrazione `getDnfApps` con fake rpm (`test/fixtures/fakebin/rpm`, marker `FAKE_RPM_FOR_TESTS`, summary con byte `\xff\xfe`) — **skip** se il fake non è in PATH; per esercitarlo: `PATH="$PWD/test/fixtures/fakebin:$PATH" flutter test test/app_manager_test.dart`.
- Verifica: `flutter analyze` 255 (baseline) 0 errori, `flutter test` **119/119**, build release OK, `./build_appimage.sh` exit 0, `./verify_appimage.sh` TUTTO OK ×3.

## Log diagnostico di avvio (main.dart) + diagnosi Fedora (2026-10)

### Stato dei tre fix richiesti (verificati nel codice, già presenti)
- **AppManager fallback DNF**: `getDnfApps()` riprova con `rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\n'` (2 campi, senza `%{SUMMARY}`) se il primo query fallisce o restituisce vuoto — `%{SUMMARY}` può contenere byte non UTF-8 e far crollare il decoder. `parseDnfListOutput` tollera output senza 3° campo.
- **Cache smartctl**: `_smartInfoCacheMap` + `_smartInfoCacheTimestamp` (`smart_service.dart`), TTL **2 minuti**, invalidata da `clearSmartInfoCache()`; evita di rieseguire `smartctl` (specie con sudo) a ogni refresh.
- **Indicizzazione progressiva disco**: `_loadDirectorySizesAsync` passa `onPartial` a `_getTopDirectories` → il grafico si aggiorna man mano che le dimensioni arrivano, senza aspettare la scansione completa; a fine scan salva la cache e `DiskIndexingEngine.markIndexed()`.

### Log di avvio sempre attivo (release incluse)
- `lib/main.dart` → `_diag()`: scrive **sia su stdout (`[SLU] ...`) sia su `/tmp/slu-startup.log`** con `flush: true`. In release AOT `debugPrint` è inaffidabile e le eccezioni native non arrivano a Dart: con file + flush, se l'AppImage muore durante l'avvio l'**ultima riga** del log indica il punto morto.
- Copre: env (`APPDIR`, `XDG_SESSION_TYPE`, `WAYLAND_DISPLAY`, `DISPLAY`, `GDK_BACKEND`, ...), `/etc/os-release`, `singleInstance` (una 2ª istanza apre solo la schermata "già in esecuzione" e sembra "app che non si apre"!), esito `isSystemTraySupported` + `TrayService.init` + `TrayService.lastError`, `startMinimized`, `ensureWindowShown` (fase immediata e al primo frame), auto-restart 90 min, modalità standalone, icona finestra.
- `_installErrorLogging()`: `ui.PlatformDispatcher.instance.onError` + `FlutterError.onError` → eccezioni Dart non gestite finiscono anche su file (in release finirebbero solo su stderr). `onError` ritorna `false` per non alterare il comportamento di default.
- **NON** introdurre `debugPrint` per la diagnosi: va bene solo `print`/`stdout` o scritture dirette su file.
- Il log è monotono (append, rotazione a 256 KB): cancellare `/tmp/slu-startup.log` prima di un test pulito.

### `diag_fedora.sh` (repo root)
- Helper per il test su Fedora/altre distro: raccoglie `/etc/os-release`, env grafica, `ldconfig -p` (lib host), presenza fuse, poi lancia l'AppImage con `G_MESSAGES_DEBUG=all` e `2>&1 | tee` → `/tmp/slu-fedora-diag.log`.
- Uso: `./diag_fedora.sh [appimage]` (default: primo `./*-x86_64.AppImage` della cwd).
- ATTENZIONE: gli errori di GTK avviati **prima** di Dart (es. "Cannot open display", GIO load di moduli, segfault del loader) compaiono SOLO su stderr → far sempre il test da terminale o con questo script, mai solo con doppio clic.

### Ripristino struttura main.dart (gotcha)
- Durante un editing parziale `lib/main.dart` era rimasto spezzato: una `class InitialScreen extends StatefulWidget {` erronea aveva sostituito l'intestazione di `_MyAppState._loadFontSettings`, producendo metodi orfani a livello di biblioteca, una `build` duplicata e un `_lastError` usato fuori dalla classe (non compilava).
- Sintomi in `flutter analyze`: `undefined_identifier` (`_fontFamily`, `_themeMode`, `mounted`), `undefined_function` (`setState`), `extraneous_modifier` (`static` su `_detectSystemTheme`), `expected_executable`.
- Correzione: le `Future`/`void` dei settings (`_loadFontSettings`, `setFont`, `_loadThemeMode`, `_detectSystemTheme` — che resta `static`, `_loadLocale`, `setThemeMode`, `setLocale`) devono stare **dentro** `_MyAppState`, **dopo** il `build` e **prima** della `}` che chiude la classe; `class InitialScreen` resta una sola volta.
- Conteggi utili per i check: `main.dart` ha **5** `Widget build(BuildContext context) {` (`_AlreadyRunningAppState`, `_StandaloneApp`, `_StandaloneScreenState`, `_MyAppState`, `_InitialScreenState`).
- **Mai patch parziale su main.dart**: riscrivere il file per intero (o usare uno script con assert sugli anchor) e verificare con `flutter analyze` (baseline 255 issue, **0 errori**) prima di procedere.

- Verifica di questa sessione: `flutter analyze` **255 (baseline) 0 errori**, `flutter test` **119/119**.

## Crash tray Fedora 44/KDE: diagnosi in corso (2026-10)

### Fatti accertati (log di avvio + test A/B)
- Su **Fedora 44 KDE Plasma (Wayland, `GDK_BACKEND=x11`)** l'AppImage muore **dentro `InitSystemTray`**, prima di `runApp(MyApp)`: l'ultima riga è `method call InitSystemTray`.
- Il plugin `system_tray` (2.0.3) stampa `method call %s` (`g_print` in `system_tray_plugin.cc`) **PRIMA** del dispatch, e `Tray::set_tray_info` stampa `SystemTray::set_system_tray_info ...` **quando arriva a icona/titolo**. Su Fedora quella riga NON compare → il crash è nel blocco `init_tray(const char*)`, cioè:
  `dlopen("libappindicator3.so.1")` → `dlsym` → `app_indicator_new(tray_id, "", 0)` → `app_indicator_set_status(ACTIVE)`.
- **Test A/B**: la stessa AppImage su Zorin 18.1 (GNOME/Wayland) inizializza il tray senza problemi (`tray: init terminato (isInitialized=true)`) → non è un errore di packaging generico.
- Packaging escluso: `verify_appimage.sh` passa (RUNPATH `$ORIGIN` ovunque, whitelist solo libc-family) e la catena `libappindicator3.so.1 → libayatana-appindicator3.so.1 → .so.1.0.0` + `libayatana-indicator3.so.7` + `libayatana-ido3-0.4.so.0` + `libdbusmenu-gtk3.so.4` + `libdbusmenu-glib.so.4` è **tutta bundled** con `RUNPATH $ORIGIN`; `readelf -d` conferma che ogni NEEDED è dentro l'AppDir → niente ibridazione con GLib/GTK host (Fedora ha GLib 2.84, bundled è 2.80).
- Verifica con `LD_DEBUG=libs`: il probe locale carica **la stessa** catena bundled dell'AppDir (testa quindi le librerie che Fedora caricherà).
- **Fedora 44 ha anche il `libappindicator3.so.1` REALE host** (`libappindicator-gtk3-12.10.1-10.fc44` + `libdbusmenu-gtk3-16.04.0`) → c'è un secondo scenario da confrontare (probe A) e un rischio ibridazione se il dlopen finisse su quello host (GLib host 2.84 + bundled 2.80).
- Ibridi GLib tramite i cache GTK **esclusi**: `loaders.cache` contiene solo **nomi relativi** dei loader (PNG/JPEG sono builtin in gdk-pixbuf 2.42 → la decodifica della icona funziona già, e infatti su Fedora il log arriva a "icona finestra impostata"), `immodules.cache` punta a path Debian (`/usr/lib/x86_64-linux-gnu/...`) che su Fedora non esistono → il warning `im-ibus.so` è benigno (niente IM, nessun crash), `usr/lib/gio/modules` è vuoto → GIO non carica moduli host.
- `--appimage-extract` in `/tmp` **fallisce su Fedora** (tmpfs piccolo): estrarre in `$HOME/.cache/slu-appdir` e NON nascondere lo stderr dell'estrazione.

### Strumento: `diag_tray_fedora.sh` (repo root)
- **PROBE A (lib HOST)** e **PROBE B (lib BUNDLED)**: la stessa sequenza nativa del plugin replica due volte **fuori Flutter** con Python `ctypes` (`/tmp/slu_probe.py`): `dlopen("libappindicator3.so.1")` → `dlsym` (elenca simboli mancanti) → `app_indicator_new` → `set_status(ACTIVE)` → `set_icon_full` → `set_label`. PROBE A gira senza `LD_LIBRARY_PATH` (usa il `libappindicator3.so.1` **reale** del sistema: Fedora 44 ha `libappindicator-gtk3`+`libdbusmenu-gtk3` host!), PROBE B con `LD_LIBRARY_PATH=<AppDir>/usr/lib` dopo `--appimage-extract` in `$HOME/.cache/slu-appdir`. Se A crasha e B no (o viceversa) la causa è isolata al 100%.
- Ogni probe gira in un **figlio forkato** e scrive ogni passo su `/tmp/slu-probe-<P>.txt` con flush → si vede **quale** chiamata muore anche se il processo viene ucciso; il padre riporta segnale (11=SIGSEGV, 6=SIGABRT) o exit code (3 = dlopen fallito = lib mancante). Se c'è `gdb` rifà lo stesso probe con `set follow-fork-mode child` + `bt` → backtrace puntuale.
- **Il probe pompà anche il main loop GLib** (`g_main_context_default` + `g_main_context_iteration` non bloccante, 2s + 1.5s): senza loop le callback **async** della registrazione DBus (`g_bus_own_name` → `name_acquired` → `RegisterStatusNotifierItem` verso il watcher di KDE) **non partono mai** — è proprio quel codice il differenziale KDE vs GNOME, quindi un probe senza loop non lo eserciterebbe. `GDK_BACKEND=x11` come nell'AppImage.
- **[3]** avvia l'AppImage reale con `LD_DEBUG=libs LD_DEBUG_OUTPUT=/tmp/slu-lddebug` (`timeout -k 3 25`, `XDG_CACHE_HOME` pulito per il single-instance): registra exit code (139=SIGSEGV, 134=SIGABRT, 137=timeout = non crashato), **quali file vengono realmente caricati** (righe `calling init: ...` → bundled vs host!) e `coredumpctl info/stack` (fallback `journalctl`).
- Output: `/tmp/slu-tray-diag.log` + `/tmp/slu-lddebug.*`.
- **Caveat buffering**: il `printf` di `Tray::set_tray_info` NON fa flush e stdout verso pipe/file è bufferizzato a blocchi → la sua assenza dal log **non** prova che il crash sia prima di esso; il probe copre quindi comunque `set_icon_full`/`set_label` (e dopo la correzione, anche `CreateContextMenu`/`SetContextMenu` via `gtk_menu_new`+`set_menu`).
- **Esito PROBE A su Fedora**: la sequenza nativa con le lib host **completa senza crash** → lo stack appindicator di per sé non è rotto su Fedora/KDE. MA i `Gtk-CRITICAL: gtk_icon_theme_get_for_screen: assertion 'GDK_IS_SCREEN (screen)' failed` mostrano che `app_indicator_new` tocca `GtkIconTheme`: nel probe (senza display) si fermava lì con critiche NULL, **nell'app il codice va oltre** → il probe è stato reso fedele con `gtk_init_check` (display aperto) + `gtk_menu_new`/`app_indicator_set_menu` (export dbusmenu) + pump del loop.
- **AppImage non avviabile exit 126 "Permesso negato"** = bit di esecuzione perso nella copia (era partita la prima volta) → lo script ora fa `chmod +x` in automatico prima di usarlo.
- `coredumpctl stack` NON esiste in quella versione di systemd → solo `coredumpctl info` (che però include già "Stack trace of thread"); lo script filtra su `super_linux_utility` (prima mostrava un coredump di Zoom). `gdb` su Fedora chiede il download debuginfo da debuginfod → in batch va disabilitato con `-ex "set debuginfod enabled off"`.
- **Gotcha**: l'app registra un handler su SIGTERM che rilascia solo il lock **senza uscire** → `timeout` va sempre usato con `-k` (kill forzata), altrimenti il processo resta appeso; e NON pipiare l'output su `tail` (i figli tengono aperta la pipe e il comando non termina mai).
- **Gotcha**: non usare `pkill -f "<pattern>"` con un pattern che compare nella riga di comando del shell corrente: si uccide da solo.

### Root cause confermata + fix (2026-10-18)
- **LOG FEDORA**: i probe A (host) e B (bundled) completano **senza crash**, ma l'AppImage muore SIGSEGV (139). LD_DEBUG: nel processo vengono caricati **ENTRAMBI** gli stack: `calling init: /lib64/libappindicator3.so.1` (HOST, vero libappindicator 12.10.1 Fedora/GLib 2.84) **e** `.../usr/bin/../lib/libayatana-appindicator3.so.1` (bundled, GLib 2.80). Su Zorin l'host `libappindicator3.so.1` è un **symlink allo stesso file ayatana** → dedup by inode → un solo oggetto → nessun crash.
- **Chi carica la lib host**: il plugin `system_tray` 2.0.3 è compilato **linkato** a ayatana (NEEDED `libayatana-appindicator3.so.1`, macro HAVE_AYATANA sulla macchina di build Debian-family) **e** a runtime in `Tray::init_indicator_api()` fa `dlopen("libappindicator3.so.1", RTLD_LAZY)`. Su Fedora quel dlopen non dedup (soname diverso da quello già caricato) e va sul **vero** libappindicator host → due stack appindicator su GLib diversi → SIGSEGV dentro InitSystemTray (l'uso dei simboli via dlsym nel mix). Nel `.cc` la stringa `libappindicator3.so.1` esiste SOLO nel plugin (verificato con grep binario su tutto l'AppDir).
- **FIX (patch plugin, `SLU-AYATANA-FIRST-PATCH`)**: `dlopen("libayatana-appindicator3.so.1", RTLD_LAZY)` **primo** + fallback al vecchio nome. Il nome ayatana dedup SEMPRE contro l'oggetto già caricato dal NEEDED → il dlopen diventa no-op → nessuna lib host nel processo. Applicata in `/home/workstation/.pub-cache/hosted/pub.dev/system_tray-2.0.3/linux/tray.cc` e resa **idempotente e duratura** in `build_appimage.sh` e `build_arch.sh` (funzione `patch_system_tray_plugin`, marker `SLU-AYATANA-FIRST-PATCH`, python3 heredoc, skip se già presente, exit 1 se il pattern non matcha).
- **Verifica del fix via LD_DEBUG** (locale, prima/dopo): `find library=libappindicator3.so.1` 2→0 occorrenze; `find library=libayatana-appindicator3.so.1` solo 1 occorrenza (il NEEDED) — il dlopen successivo non fa più ricerca. Se un giorno serve ri-testare: `XDG_CACHE_HOME=<dir pulita> LD_DEBUG=libs LD_DEBUG_OUTPUT=/tmp/slu-lddebug timeout -k 3 20 ./<AppImage>` poi grep su `/tmp/slu-lddebug.*`.
- Pipeline: `./build_appimage.sh` OK ×3 varianti, `./verify_appimage.sh` TUTTO OK ×3, `flutter analyze` 255 (baseline) 0 errori, `flutter test` 119/119. AppImage ricompilate in repo root (2.1.0).
- **Gotcha re-incontrato**: `pkill -f "AppRun.wrapped"` uccide la shell stessa (il pattern è nella riga di comando corrente) — usare sotto-pattern non self-matching (es. `pkill -f "AppRun.wrapp[e]d"`) o affidarsi a `timeout -k`.

### Rete di sicurezza (futuro, opzionale)
- Ipotesi di rete di sicurezza (da valutare SOLO dopo la causa): il tray non deve MAI far morire l'app — un segfault non è catturabile in Dart, quindi l'unica difesa è un pre-flight in processo figlio (stesso eseguibile con env `SUPER_LINUX_UTILITY_TRAY_PROBE=1` che fa solo l'init tray ed esce) prima di `TrayService.init()`, skippando il tray se il figlio muore.

## Sessione 2026-10-18: hardening security, l10n, timeout sudo, keyring, licenza

### Baseline nuova
- `flutter analyze` **172 issue, 0 errori**; `flutter test` **119/119**; build linux release OK; `./verify_appimage.sh` TUTTO OK ×3 (personal/advanced/standard, 233 ELF).
- Baseline 172 è post-rimozione dead code: eliminati `security_screen.dart`, `security_service.dart`, `appearance_screen.dart`, `appearance_service.dart`, `ocs_theme_installer.dart`, `pling_store_service.dart` + `_showTrayTaskManagerDialog` (0 riferimenti nei test).

### Sidebar highlight (fix radice)
- `HomeScreen` leggeva `selectedIndex = _tabController?.index` nel build SENZA listener → nessun rebuild al cambio tab. Fix: `_onTabIndexChanged()` (setState se `!indexIsChanging`) agganciato a ENTRAMBE le creazioni del `TabController` (`_initializeController` + `_setMode`) + postFrameCallback dopo la prima creazione.

### Info — dedup testi licenza (6 arb)
- `licenseActivateCardDesc` senza frase prezzo + chiusura duplicata; `purchaseLicenseViaPaypal` tiene prezzo + flusso PayPal senza il closing "Senza un pagamento valido...".

### Driver DB
- `8086:2725` = **AX210** (AX211 è CNVio2-only, ID diversi — allineato a device_manager_service).
- Fallback vendor `'10de'` su GPU: se il nome contiene 'audio' → categoria `'Audio (GPU HDMI)'` dentro `_lookupChipset` (prima finiva nel catch GPU generico).

### l10n (+41 chiavi ×6 arb, template `app_it.arb`)
- Tweaks swap card e raccomandazioni: `SwapRecommendation` ha ora `code`+`params` (codici `swapAdjustLow/Mid/High`, `swapOptimal`, `swapCreate`, `zramBoot`, `zramActive`, `zramStart`, `zramInstall`); chiavi `swapAdjust*Title/Desc{ram,current,ideal}`, `swapOptimal*`, `swapCreate*`, `zram*Title/Desc`, `tweaksSystemMemory`, `tweaksSwapTotal/Used/DeviceLabel`, `tweaksSwapNone`, `tweaksZswapLabel`, `tweaksStatusActive/Inactive/Unavailable`, `tweaksRestartRequired` (la schermata localizza via switch su `rec.code`, fallback al testo EN del servizio).
- Home: `homeNewVersionAvailable{version}`, `homeUpdateAction`, `homeRestoringRepositories`, `homeCheckingUpdates`, `homeKernelUpdateTitle`, `homeKernelUpdateBody`.
- Grub: `grubUnsavedBanner`, `grubContentHint`. Update dialog: `updateReleaseNotes`, `updateDownloadAndInstall`, `updateInstalledOk{version}`, `updateDownloading`. Selezione lingua: usa le chiavi ESISTENTI `languageSelectionTitle/Desc` + nuova `languageSelectionSave`.
- **Gotcha**: `_runCheck` in `TrayCheckUpdatesDialog` veniva chiamato da `initState` → `AppLocalizations.of(context)` lì è illegale (dependOnInheritedWidget prima del primo frame). Fix: `addPostFrameCallback` in initState e l10n solo dentro `_runCheck`.
- Le chiavi `languageSelectionTitle/Desc` esistevano già da prima — controllare SEMPRE i .arb prima di aggiungere duplicati.

### Timeout sudo / runProcess (P1)
- **`Process.run` di dart:io NON ha il parametro `timeout`** (errore `undefined_named_parameter`): la via corretta è `lib/utils/process_utils.dart` → `runProcess(exec, args, {runInShell, timeout})` basato su `Process.start` + Timer che invia `process.kill(ProcessSignal.sigkill)` (API kill: SOLO positional `ProcessSignal`, niente `pid:`) e ritorna ProcessResult con exitCode convenzionale **124** su timeout. Fold UTF-8 con `allowMalformed: true`.
- Aggiornati i wrapper sudo di 14 servizi (recovery 180s, cleanup/advanced_cleanup/kernel-install 300s, grub 120s, repo heredoc 120s, swap/zram 180s, probe 20–60s) + fallback `on ProcessException` nel wrapper di recovery (rc 124 senza crash).
- `_pumpStdoutLines` (recovery, flussi streaming `printf|sudo -S`) ha un **watchdog di inattività** (default 6 min, tick 5s): nessun output → SIGKILL e chiusura stream, così apt/flatpak fermi su un lock non bloccano più l'app.
- Siti script-legacy con `.timeout(...)` (es. `isSystemdAvailable` in shutdown_scheduler) ripristinati TALI QUALI: il loro postfix `.timeout` convive con il wrapper.

### Password in keyring (P1) — flutter_secure_storage
- `pubspec.yaml`: `flutter_secure_storage` (risolto **10.3.4**+linux 3.0.3). Il plugin linux NON ha `lib/` (solo nativo, `pluginClass` + method channel) — è normale, NON è cache corrotta.
- `lib/services/password_storage.dart` riscritto: keyring via libsecret → **fallback legacy base64 in prefs** se il backend non risponde (`keyringAvailable()` con probe `containsKey`, sticky in sessione) + **migrazione opportunistica** della vecchia `flutter.admin_password` al primo read nel keyring con rimozione della copia in chiaro; `deletePassword` pulisce ENTRAMBI i backend.
- `libsecret-1>=0.18.4` richiesto in build (presente: dev 0.21.4). Le AppImage bundlano `libflutter_secure_storage_linux_plugin.so` + `libsecret-1.so.0` in-AppDir (verify ×3 OK).
- La password legacy reale dell'host (12 char base64 in `~/.local/share/com.superlinux.utility/shared_preferences.json`) migrerà al primo avvio — nessuna azione richiesta all'utente.

### Secret licenza fuori dal repo (P1)
- `lib/services/license_service.dart`: `const String _kLicenseSecret = String.fromEnvironment('SLU_LICENSE_SECRET');` — il valore hardcodato è RIMOSSO dal repo (era estrabile).
- Sorgente del segreto: file git-ignored `~/.config/slu/license_secret` (HOST di build, creato UNA volta con il valore VECCHIO `SLU-License-2025-Secret-Key-Change-In-Production` → le licenze già vendute restano valide; rotazione futura = cambiare il file). `chmod 600`.
- Tutti e 4 gli script di build (`build_appimage.sh`, `build_arch.sh`, `build_deb.sh`, `build_rpm.sh`) leggono il file (helper `read_license_secret`, override con env `SLU_LICENSE_SECRET_FILE`/`SLU_LICENSE_SECRET`) e iniettano `--dart-define=SLU_LICENSE_SECRET=...` SOLO nei build advanced/standard che lo usano (personal/standard senza licenza non lo ricevono). Se manca: warning + build senza attivazione licenze (verifica fallisce senza crash).
- `tools/license_key_generator.dart` legge lo STESSO file (env ha precedenza) ed esce con errore 2 se assente — generatore e build non possono più divergere.
- **GOTCHA (fix 2026-10-18, commit separato)**: in `build_deb.sh`/`build_arch.sh`/`build_rpm.sh` il blocco `read_license_secret()` era stato finito DENTRO gli heredoc (postrm del .deb, wrapper Arch, wrapper RPM) → con `set -e` "comando non trovato" uccideva il build subito (build_deb alle 3 varianti); in `build_rpm.sh` mancava pure la CHIAMATA (`$LICENSE_SECRET` mai assegnato → build RPM in silenzio SENZA licenza). Fix: helper UNA volta a livello di script (top, prima del primo uso) + chiamata ripristinata in rpm + blocco rimosso dagli heredoc generati (postrm/wrapper). Idempotente: verificato `grep -c "read_license_secret() {"` = 1 per script e definizione PRIMA delle chiamate; `bash -n` su tutti; **build_deb.sh completo eseguito con exit 0** e nessun warning secret.
- Invariante: in ogni build script `read_license_secret` deve stare a LIVELLO SCRIPT mai dentro `cat <<'EOF'`.
- **Documentato**: il segreto resta estrabile dal binario (dart-define è string visibility-only); la rotazione del file invalida i codici vecchi.

### GOTCHA CRITICO — corruzione massa + recupero (da non ripetere)
- Uno script python di refactoring su `Process.run` con parser a bilanciamento-parentesi HA CANCELLATO gli argomenti (sostituendo il nome e saltando fino alla `)` bilanciata) in **76 call-site di 13 servizi** (tutto non committato: HEAD = Release 2.1.0 del 28/09).
- RECUPERO possibile perché esiste una **copia di backup dell'albero a `/mnt/a6c06caa-9d13-4102-9582-a292877cb965/utility/`** (stesso repo, worktree separato, stato 6 ottobre, SENZA il rigurgito odierno): diff backup↔corrotto = esattamente le modifiche della giornata + i buchi. Riparazione: canvas = backup, restore ogni call dal backup + ri-applicazione intenzionale degli upgrade (timeout runProcess). Diff finale ogni file = SOLO le modifiche volute.
- Lezioni: (1) MAI refactoring strutturale con parser testuale fai-da-te su Dart — usare gli strumenti dedicati a file singoli con assert di unicità; (2) tenere una copia snapshot dell'albero fuori dalla repo; (3) `git status --porcelain` regolare: tutto il lavoro di ottobre non era committato; (4) i siti legacy con postfix `.timeout(`: il restore deve prevedere tail NON-`;` (`.timeout(`).
- `pgrep -f AppImage` produce self-match (il pattern sta nella cmdline della shell): usare `pgrep -af "AppIma[g]e"` (idem `pkill`, già noto).

### Altro
- home_screen update-snackbar: `homeNewVersionAvailable(updateInfo...)` con `homeUpdateAction`; dialog kernel localizzato (`homeKernelUpdateTitle/Body`).
- AppImage 2.1.0 ricompilate ×3 con plugin libsecret + tray-patch idempotente; test avvio personal su Zorin OK (tray init, icona, singleInstance).
- AGENTS tab counts corretti (14/15, Recovery = 4 sub-tab).

## Disk Analyzer v2: pulsante nascosti + scansioni infinitesime (2026-10-28)
- **Requisito utente**: "mostrare TUTTE le cartelle di sistema, tutto il contenuto, non deve mai fermarsi" + "pulsante mostra/nascondi file nascosti in tutte le lingue".
- **Pulsante toggle nascosti**: nuovo `IconButton` nella toolbar file-list (icona `visibility`/`visibility_off`, primario quando mostra i nascosti); tooltip = AZIONE (l10n ESISTENTI `showSystemFiles`/`hideSystemFiles` ×6 arb, nessuna chiave nuova). Logica estratta in `_toggleHiddenFiles()` usata DA ENTRAMBE le vie (pulsante + popup menu 'toggle_hidden'): setState + persist pref `disk_analyzer_show_hidden` + `_loadDirectory(skipHistory: true)` (il filtro è applicato al LISTING, serve reload).
- **/tmp tornato visibile**: rimosso 'tmp' da `virtualDirs` dei listing (×2 blocchi in `_loadDirectory`) e rimosso `/tmp` dagliAbsolutePath filters; in `_tryParseDuLine` black-list nomi virtuali ridotta a proc/sys/dev/run (prima: + tmp/snap/lost+found/sysroot) e rimossi i drop su /tmp /snap /boot /boot/efi /lost+found /sysroot — l'utente vuole VEDERLE. `-x` in du (scansione root) esclude comunque fs virtuali/esterni → /run tmpfs, /snap squashfs, /boot/efi separata non compaiono; /tmp e /boot same-fs SÌ.
- **`_duStreamingInnerCommand('/')`**: esclusioni ridotte a --exclude=/proc /sys /dev /run (2>/dev/null resta).
- **`_streamChildSizesFromDu` (dimensioni figlie)**: RIMOSSO `timeout 45` fisso (uccideva scansioni grandi a metà) → inner = `du -b -d1 [-x +esclusioni root] 'dir' 2>/dev/null`. Nuovo watchdog INATTIVITÀ 2 min (Timer 10s: nessun byte → SIGTERM) + tetto totale 45 min + kill se !mounted; `watchdog?.cancel()` nel finally. rootExcludes allineati (solo proc/sys/dev/run).
- **`_getTopDirectories` (grafico root)**: riscritto senza early-return a metà — STADI (record `({bool sudo, Duration max})`): con password salvata [sudo 30min, utente 2min]; senza password [utente 60s, sudo 30min]. `byPath` UNICO accumulato TRA le fasi (righe utente SOVRASCRITTE da sudo = dimensioni più complete); niente più "return al 25s" che buttava la fase sudo.
- **`_drainDuStdoutToMaps`**: watchdog inattività 3 min (Timer 10s, `lastDataAt` aggiornato a ogni chunk; kill su !mounted / cambio chartToken / idle>3min) + `idleWatch.cancel()` nel finally. maxDuration = cap di fase (30 min), non più arresto a 25-90s.
- **Gotcha**: (1) il `idleWatch` assegnato subito prima del try → analyzer dice ricevitore non-nullo → `idleWatch.cancel()` NON `?.` (altrimenti warning `invalid_null_aware` e baseline 178); (2) duplicare `_spawnDuShell` modificando il docstring del metodo successivo è facile — l'edit aveva ri-inserito il metodo intero → `duplicate_definition`; verificare sempre con analyze mirato sul file; (3) `_isInRootDirectory` con '/tmp' in userDirectories è la protezione cancellazioni, NON la visibilità: lasciarlo.
- Verifica: analyze **177 (baseline, 0 errori)**, test **134/134**, build release OK. Nessuna nuova chiave l10n.

## Disk Analyzer v3: "Mostra cartella" + nascosti SEMPRE visibili (2026-10-28)
- **Requisito utente**: (1) voce "Mostra cartella" nel menu contestuale item (bottom sheet Sposta nel cestino/Rinomina/Dettagli) in tutte le lingue; (2) nascosti sempre visibili su Filesystem e Home.
- **`showFolder`**: primo ListTile del bottom sheet (`Icons.folder_open`) → `_openInFileSystem(item)`: per una directory apre la directory STESSA, per un file la cartella che lo contiene. `Process.run('xdg-open', [target])`, fallback `gio open`, fallback SnackBar con NUOVA chiave `showFolderError({path})`. l10n ×6: `showFolder` + `showFolderError` (attributo @ dopo "details", placeholder `path` String). No url_launcher (file:// sarebbe richiesto `canLaunch`; xdg-open diretto più affidabile).
- **Nascosti SEMPRE visibili**: rimosso ENGA il gating `_showHiddenFiles`: campo + `_prefKeyShowHidden` + `_loadShowHiddenFilesPref()` + `_toggleHiddenFiles()` + IconButton toolbar + voce popup 'toggle_hidden' + entrambi i filtri listing (`if (!_showHiddenFiles && name.startsWith('.'))`) rimossi. Toolbar dov'era l'occhio ora ha solo i pulsanti sort (il PopupMenuButton ⋮ della toolbar era SOLO il toggle → eliminato del tutto). Il pulsante aggiunto nella sessione precedente è STATO RIMOSSO su nuova richiesta: non riaggiungerlo.
- **Gotcha**: l10n via json.dump disturbava la formattazione degli altri attributi (@→placeholders su una riga) → floater diff + gen-l10n lento: inserire Testualmente nel .arb (dopo `"details": ...`), poi verificare che `},` non collisione sulla '"renamedSuccess...' `},  "renamed...` (newline mancante, fix python). Remove import `shared_preferences` da disk_analyzer_screen (sarebbe baseline 178).
- Verifica: analyze **177 (baseline, 0 errori)**, test **134/134**, build release OK. l10n: +2 chiavi ×6 (`showFolder`, `showFolderError`).

## Finestre standalone dal tray: niente titlebar, niente sfondo nero (2026-10-29)
- **Sintomo utente** (screenshot): la dialog "Check system updates" aperta dal tray appariva in una finestra con titlebar "Super Linux Utility - Updates" e uno sfondo quasi NERO attorno alla card; la dialog in-app (screenshot 2) è quella corretta, senza contorni.
- **Causa (3 fattori)**: (1) `showDialog` usa `barrierColor` default `Colors.black54` che scuriva TUTTO lo sfondo della finestra standalone; (2) la finestra GTK veniva creata con header bar/decorazioni del WM (`my_application_activate`); (3) lo Scaffold dello standalone aveva il colore scuro del tema, diverso dalla card → cornice nera visibile.
- **Fix C++ (`linux/runner/my_application.cc`)**: in `my_application_activate` se `SUPER_LINUX_UTILITY_MODE` è impostato (standalone: task-manager / check-updates / clipboard) → `gtk_window_set_decorated(window, FALSE)` e NIENTE header bar (il titolo resta via `gtk_window_set_title` per la window list). `bg_hex` = `#2B2930` (M3 dark surfaceContainerHigh) per lo standalone (pre-frame Flutter + CSS di window/flutter_view), `#FFFFFF` altrimenti. NB: `standalone_mode` è una variabile LOCALE di activate (in `should_start_hidden` esiste un'altra `mode`, nessun conflitto).
- **Fix Dart (`lib/main.dart`)**: `_StandaloneApp._standaloneTheme(brightness)` → `scaffoldBackgroundColor` = `colorScheme.surfaceContainerHigh` e `dialogTheme: DialogThemeData(backgroundColor: card, elevation: 0, shadowColor: transparent, surfaceTintColor: transparent)`; `showDialog(... barrierColor: Colors.transparent ...)`. Risultato: la finestra senza decorazioni è UNA card uniforme (dialog = finestra), nessun bordo/ombra/alone.
- **Verifica VISIVA reale** (display disponibile): `GDK_BACKEND=x11 SUPER_LINUX_UTILITY_MODE=<mode> ./build/linux/x64/release/bundle/super_linux_utility` poi `xwininfo -root -tree | grep "Super Linux Utility"` → `import -window <id> out.png` (import di ImageMagick NON funziona sulle finestre Wayland-native: forzare GDK_BACKEND=x11 e catturare l'ID X11). I 3 modi verificati: Updates (560×640), Clipboard (680×600), Processes (900×600) → nessuna titlebar, sfondo uniforme `#2B2930`, solo gli archetti AA dei 4 angoli della dialog (invisibili). `convert img -format %c histogram:info:-` per confermare il colore dominante.
- **Gotcha test manuale**: l'app INSTALLATA dell'utente (`/usr/share/super-linux-utility-personal`) può essere in esecuzione con la stessa window class → `pkill -f "build/linux/x64/release/bundle/super_linux_util[i]ty"` (pattern NON self-matching) per uccidere solo i processi di test. `G_APPLICATION_NON_UNIQUE` è già impostato → più standalone coesistono.
- **Nota**: con tema CHIARO il pre-frame C++ resta `#2B2930` (flash scuro di <1 frame) — prima era bianco; il colore vero arriva al primo frame Flutter. Non introdurre un parser JSON di `theme_mode` in C++ solo per questo.
- Verifica: analyze **177 (baseline, 0 errori)**, test **134/134**, build release OK (C++ ricompilato).

## Finestre standalone: hugging del contenuto via sizer a intrinsechi (2026-10-31)
- **Requisito utente**: le dialog dal tray erano "troppo larghe, troppo spazio inutilizzato" — la finestra va adattata alla card reale.
- **`_StandaloneDialogSizer`** (`lib/main.dart`): avvolge la dialog (tranne la **clipboard**, vedi sotto) e ogni 600ms (max 12 resize) misura la card e chiama `windowManager.setSize(...)` + `center()`.
- **MISURA VIA INTRINSECHI, NON via size di layout**: il primo RenderObject di una `Dialog` è un `Align`/`Center` non-posizionato che si espande a TUTTA la finestra → `findRenderObject().size` darebbe la finestra stessa e il resize non partirebbe (o peggio, loop). Uso `getMaxIntrinsicWidth(infinity)` + `getMaxIntrinsicHeight(w)` che delegano al contenuto reale (testo + padding della dialog compresi) → dimensione "huggata". `_CardMeasurer`/`_RenderCardMeasurer` (SingleChildRenderObjectWidget/RenderShiftedBox, import `package:flutter/rendering.dart`) restano come wrapper con la GlobalKey.
- **CLAMP allo schermo via `PlatformDispatcher`, NON via `View.of(context)`** (BUG riscontrato): `View.of(context)` restituisce la view della finestra STANDALONE → `physicalSize` = dimensione CORRENTE della finestra → il clamp `min(w, screen-80)` restringeva la finestra di 80px a ogni tick (loop fino a 0x0: Updates 368x76 → 288x-4, Processes 80x92). Fix: `ui.PlatformDispatcher.instance.displays[0].size / devicePixelRatio` (display fisica reale, default 1920x1080 se vuoto).
- **Clipboard ESCLUSA dalla sizer**: la `ClipboardHistoryDialog` ha una ListView con figli flessibili → gli intrinsechi ne ignorano l'altezza → restringerebbe la finestra a ~148px. Resta alla dimensione progettata 688x608. NB: la sizer riceve `mode` e salta per `'clipboard'`.
- **Task manager**: `tray_task_manager_dialog.dart` content era `SizedBox(width: MediaQuery.size*0.75, height: *0.7)` → con la finestra ridimensionata dalla sizer creerebbe un feedback loop (card dipende dalla finestra e viceversa). Ora size FISSE 512x420.
- **`insetPadding: EdgeInsets.zero`** nel `dialogTheme` standalone → la card occupa tutta la finestra (niente fascia vuota ai lati); la finestra è poi ridimensionata esattamente sulla card.
- Dimensioni INIZIALI in `main.dart`: task-manager 600x600, clipboard 688x608, check-updates 560x420 (poi aggiustate dalla sizer). Risultati verificati: Updates **528x385**, Processes **560x572**, Clipboard 688x608 (invariata).
- **Verifica visiva**: `GDK_BACKEND=x11 SUPER_LINUX_UTILITY_MODE=<mode> ./build/.../super_linux_utility` + `xwininfo -root -tree | grep "Super Linux Utility - "` → dimensioni finali + `import -window <id> out.png`. Log `[SLU] sizer:` mostra intrinsechi/finestra/target per il debug del resize.
- **Gotcha pkill self-match**: pattern che contengono `SUPER_LINUX_UTILITY_MODE=...` nella riga di comando della shell corrente uccidono la shell stessa (SIGTERM) → usare `MODE=check-update[s]` (con [s]) o pattern non self-matching, in COMANDI SEPARATI dal build.
- Verifica: analyze **177 (baseline, 0 errori)**, test **134/134**, build release OK.
