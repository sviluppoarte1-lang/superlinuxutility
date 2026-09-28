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

## Tray menu
- `TrayMenuLabels`/`TrayCallbacks` hanno il campo `settings`/`onShowSettings`: la voce "Impostazioni" apre il tab Settings (`HomeScreen._goToSettingsTab()` usa `tabCount - 2`).
- Etichetta traySettings aggiunta in tutti gli `.arb`; rigenerare con `flutter gen-l10n` (template = `app_it.arb`). Attenzione: `gen-l10n` rigenera anche getter precedentemente presenti solo nei `.dart` committati; le stringhe nuove vanno aggiunte a TUTTI i 6 `.arb`.

## Struttura tab HomeScreen (recovery sempre disponibile)
- Tab sempre visibili (standard e advanced): Services, StartupApps, Cleanup, InstalledApps, Monitor, DiskAnalyzer, Smart, **Recovery**, Tweaks, Settings, Info → `_standardTabCount = 11`.
- Tab solo advanced: Grub, Benchmark → `_advancedTabCount = 13`.
- `SecurityScreen` e `RepositoriesScreen` NON hanno più tab propri nella sidebar: sono sub-tab dentro `RecoveryScreen`.

## RecoveryScreen (5 sub-tab)
- TabBar: `recoveryTabRecovery` (operazioni), `tabSecurity`, `tabRepositories`, `recoveryTabSoftwareInstaller`, `tabOperationHistory`.
- Il sub-tab "Verifica Aggiornamenti" (`recoveryCheckUpdates`/`recoveryTabCheckUpdates`) è stato RIMOSSO: gli aggiornamenti si controllano dal tray/dialog (`HomeScreen._showTrayCheckUpdatesDialog` usa `recoveryCheckUpdatesComplete`/`recoveryCheckUpdatesError`/`recoveryPerformUpdates` — tenere queste chiavi l10n).
- Recovery è disponibile anche nella versione standard (gratuita); Grub e Benchmark restano avanzati.

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
