# Super Linux Utility

Applicazione Flutter completa per la gestione e ottimizzazione del sistema Linux/Ubuntu.

## Funzionalità

### 🔍 Scansione Servizi Systemd
- Analizza tutti i servizi systemd del sistema
- Identifica i servizi che rallentano l'avvio (tempo > 2 secondi)
- Mostra informazioni dettagliate su ogni servizio (stato, tempo di avvio, descrizione)
- Permette di disabilitare, fermare o riabilitare servizi
- Visualizza servizi disabilitati per ripristinarli facilmente

### 📱 Gestione Applicazioni all'Avvio
- Scansiona le applicazioni configurate per avviarsi automaticamente
- Cerca in `~/.config/autostart` e `/etc/xdg/autostart`
- Permette di abilitare, disabilitare o rimuovere applicazioni all'avvio
- Visualizza chiaramente app abilitate e disabilitate

### 🧹 Pulizia File Temporanei
- Calcola lo spazio occupato dai file temporanei
- Ricerca automatica di file temporanei di app comuni:
  - Browser (Chrome, Firefox, Edge, Opera, Brave)
  - Editor (VS Code, Atom, Sublime Text)
  - Sviluppo (npm, pip, cargo, gradle, maven)
  - Sistema (APT cache, Snap, Flatpak)
  - Multimediali (VLC, Spotify)
- Elimina file temporanei da cartelle standard e app specifiche

### 📦 Gestione App Installate
- Visualizza tutte le app installate da:
  - APT (pacchetti Debian/Ubuntu)
  - Snap
  - Flatpak
  - GNOME (applicazioni desktop)
- Controllo intelligente delle dipendenze prima della rimozione
- Avvisi di sicurezza per pacchetti di sistema e dipendenze
- Filtri per package manager e ricerca

### 📊 Monitor di Sistema
- **Processi**: Lista completa di tutti i processi attivi
  - Percentuale CPU e uso memoria per ogni processo
  - Ordinamento per CPU o memoria (crescente/decrescente)
  - Possibilità di terminare processi (normale o forzato)
  - Ricerca processi
- **Informazioni Sistema**:
  - CPU: modello, core, threads, uso percentuale
  - Memoria: totale, usata, libera, cache, swap
  - Dischi: tutti i dischi interni ed esterni con uso
  - GPU: informazioni scheda video (se disponibile)

### 🔐 Gestione Password
- Salvataggio sicuro della password di amministratore
- Utilizzo automatico per comandi che richiedono privilegi sudo
- Gestione tramite interfaccia dedicata

## Requisiti

- Ubuntu 20.04+ (o altre distribuzioni Linux basate su systemd)
- Flutter SDK
- Privilegi sudo per alcune operazioni

## Dipendenze Linux (avvio dalla build/bundle)

Se avvii l’app dalla cartella `build/linux/x64/release/bundle` (senza usare il .deb), su alcune distro può mancare la libreria per la **system tray** (icona in area di notifica).

- **Fedora / RHEL** (errore `libayatana-appindicator3.so.1: cannot open shared object file`):
  ```bash
  sudo dnf install libayatana-appindicator-gtk3
  ```
  Su **Fedora** (es. 42) con KDE/GNOME la system tray può causare un *segmentation fault* per incompatibilità del plugin con libayatana. L’app **disabilita automaticamente la tray su Fedora**: parte senza icona in system tray, tutto il resto funziona.
- **Debian / Ubuntu** (se non usi il .deb):
  ```bash
  sudo apt install libayatana-appindicator3-1
  ```
- **Arch Linux**:
  ```bash
  sudo pacman -S libayatana-appindicator
  ```

Per disabilitare la system tray su qualsiasi distro (es. per evitare crash): avvia con  
`SUPER_LINUX_UTILITY_NO_TRAY=1 ./super_linux_utility`.

Dopo aver installato la dipendenza (ove serve), riesegui `./super_linux_utility` dalla cartella `bundle`.

## Installazione

### 1. Installa le dipendenze Flutter

```bash
flutter pub get
```

### 2. Esegui l'applicazione

```bash
flutter run -d linux
```

### 3. Compila per la distribuzione

```bash
flutter build linux --release
```

### 4. Genera il pacchetto .deb

```bash
./build_deb.sh
```

Il file `.deb` sarà creato nella directory principale: `super_linux_utility_1.0.0_amd64.deb`

### 5. Installa il pacchetto .deb

```bash
sudo dpkg -i super_linux_utility_1.0.0_amd64.deb
```

Se ci sono dipendenze mancanti:

```bash
sudo apt-get install -f
```

## Utilizzo

1. **Configurazione iniziale**: Vai alla tab "Impostazioni" e salva la password di amministratore
2. **Analizza servizi**: Vai alla tab "Servizi" per trovare i servizi che rallentano l'avvio
3. **Gestisci app all'avvio**: Vai alla tab "App Avvio" per vedere e gestire le applicazioni che si avviano automaticamente
4. **Pulisci file temporanei**: Vai alla tab "Pulizia" per vedere lo spazio occupato e pulire i file temporanei
5. **Gestisci app installate**: Vai alla tab "App Installate" per visualizzare e rimuovere applicazioni
6. **Monitora sistema**: Vai alla tab "Monitor" per vedere processi attivi e informazioni di sistema

## Sicurezza

La password viene salvata utilizzando `shared_preferences` con codifica base64. Questo è un metodo funzionale ma meno sicuro rispetto all'utilizzo del keyring del sistema.

**Per maggiore sicurezza (opzionale):**
Se vuoi utilizzare il keyring del sistema Linux (più sicuro), puoi:
1. Installare `libsecret-1-dev`: `sudo apt-get install -y libsecret-1-dev`
2. Aggiungere `flutter_secure_storage: ^9.2.2` al `pubspec.yaml`
3. Modificare `lib/services/password_storage.dart` per utilizzare `FlutterSecureStorage`

La password viene utilizzata solo quando necessario per eseguire comandi con privilegi amministratore.

## Note

- Alcune operazioni richiedono privilegi amministratore
- Fai attenzione quando disabiliti servizi o applicazioni all'avvio, alcuni potrebbero essere necessari per il corretto funzionamento del sistema
- La pulizia dei file temporanei è permanente e non può essere annullata
- Il monitor di sistema si aggiorna automaticamente ogni 3 secondi

## Licenza

Questo progetto è fornito "così com'è" senza garanzie.
