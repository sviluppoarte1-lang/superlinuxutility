# Super Linux Utility v2.0.6
# Manuale Utente Completo — Italiano

---

## Indice

1. [Introduzione](#1-introduzione)
2. [Requisiti di Sistema](#2-requisiti-di-sistema)
3. [Installazione](#3-installazione)
4. [Primo Avvio](#4-primo-avvio)
5. [Modalità Standard — Tutte le Funzionalità](#5-modalità-standard)
   - 5.1 Servizi
   - 5.2 App di Avvio
   - 5.3 Pulizia
   - 5.4 App Installate
   - 5.5 Monitor di Sistema
   - 5.6 Analizzatore Dischi
   - 5.7 Salute Dischi SMART
   - 5.8 Gestore Dispositivi
   - 5.9 Ripristino
   - 5.10 Ottimizzazioni
   - 5.11 Impostazioni
   - 5.12 Info
6. [Modalità Avanzata — Funzionalità Aggiuntive](#6-modalità-avanzata)
   - 6.1 Editor GRUB
   - 6.2 Benchmark
7. [Barra di Sistema](#7-barra-di-sistema)
8. [Aggiornamenti Automatici](#8-aggiornamenti-automatici)
9. [Risoluzione Problemi](#9-risoluzione-problemi)
10. [Domande Frequenti](#10-faq)
11. [Glossario](#11-glossario)

---

## 1. Introduzione

**Super Linux Utility** è un'applicazione completa di gestione del sistema per Linux. Fornisce un'interfaccia grafica moderna per gestire servizi, applicazioni di avvio, pulire file temporanei, monitorare le prestazioni del sistema, analizzare i dischi, gestire i dispositivi hardware e molto altro.

L'app è disponibile in due edizioni:

- **Standard (Gratuita):** Tutti gli strumenti essenziali di gestione del sistema — servizi, app di avvio, pulizia, app installate, monitor, analizzatore dischi, salute SMART, gestore dispositivi, ripristino, ottimizzazioni e impostazioni.
- **Avanzata (A pagamento):** Tutto ciò che è incluso nella Standard, più l'editor GRUB e la suite Benchmark.

**Distribuzioni supportate:** Ubuntu, Debian, Linux Mint, LMDE, Pop!_OS, Zorin, elementary, MX Linux, Fedora, RHEL, CentOS, Arch Linux, Manjaro, EndeavourOS, CachyOS, KDE neon.

**Ambienti desktop supportati:** GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt.

---

## 2. Requisiti di Sistema

- **SO:** Linux (64-bit)
- **Spazio su disco:** ~200 MB installati
- **RAM:** 512 MB minimi, 2 GB raccomandati
- **Dipendenze:** GTK3, GLib 2.0+
- **Opzionale:** `libappindicator` per la barra di sistema, `smartmontools` per la salute dischi SMART

---

## 3. Installazione

### AppImage (Raccomandato)
```bash
chmod +x super-linux-utility-2.0.6-x86_64.AppImage
./super-linux-utility-2.0.6-x86_64.AppImage
```

### Debian/Ubuntu (.deb)
```bash
sudo dpkg -i super-linux-utility_2.0.6_amd64.deb
sudo apt-get install -f
```

### Dai sorgenti
```bash
git clone https://github.com/sviluppoarte1-lang/superlinuxutility.git
cd superlinuxutility
flutter build linux
```

---

## 4. Primo Avvio

Quando apri Super Linux Utility per la prima volta, vengono visualizzate tre schermate di configurazione in sequenza:

### 4.1 Selezione della Lingua
Scegli la lingua preferita tra: Italiano, Inglese, Francese, Spagnolo, Tedesco, Portoghese. La lingua selezionata si applica a tutti i pulsanti, i menu, i messaggi e le descrizioni in tutta l'app.

### 4.2 Schermata di Avviso
Un avviso di esclusione della responsabilità ti ricorda che questa app può modificare configurazioni critiche del sistema (bootloader GRUB, kernel, servizi). Si consiglia vivamente di creare un backup del sistema prima di utilizzare le funzionalità avanzate. Seleziona "Non mostrare più questo avviso" per saltarlo agli avvii successivi.

### 4.3 Configurazione della Password
Per utilizzare le funzionalità che modificano il sistema (pulizia, gestione servizi, modifica GRUB, ecc.), l'app ha bisogno della password di amministratore (sudo). La password viene archiviata in modo sicuro utilizzando il portachiavi del sistema. Puoi saltare questo passaggio e configurarla in seguito nelle Impostazioni.

> **Suggerimento per i principianti:** Se non sei sicuro se inserire la password, puoi saltarla. La maggior parte delle funzionalità di sola lettura (monitor, analizzatore dischi, SMART) funzionano senza password.

---

## 5. Modalità Standard — Tutte le Funzionalità

La modalità standard fornisce 12 schede accessibili dalla barra laterale sinistra. Ogni scheda contiene strumenti specifici.

---

### 5.1 Servizi

**Scopo:** Visualizzare e gestire i servizi systemd in esecuzione sul sistema.

**Schede:**
- **Servizi Lenti:** Elenca i servizi che impiegano più di 2 secondi per avviarsi (rilevati tramite `systemd-analyze blame`). Questo aiuta a identificare cosa rallenta l'avvio del sistema.
- **Tutti i Servizi:** Elenco completo di tutti i servizi systemd con il loro stato (attivo, inattivo, fallito). Tocca "Analizza Tutti" per caricare l'elenco completo.
- **Disabilitati:** Mostra tutti i servizi attualmente disabilitati.

**Azioni per servizio (tocca il menu a tre puntini):**
- **Disabilita:** Impedisce l'avvio del servizio all'avvio del sistema.
- **Riabilita:** Consente al servizio di avviarsi nuovamente all'avvio del sistema.
- **Ferma:** Ferma immediatamente un servizio in esecuzione.

> **Avviso per i principianti:** Non disabilitare servizi che non riconosci. Alcuni servizi sono essenziali per il corretto funzionamento del sistema (ad esempio, NetworkManager, PulseAudio, systemd-resolved). In caso di dubbio, lascia il servizio abilitato.

> **Suggerimento per gli esperti:** Usa la scheda "Servizi Lenti" per ottimizzare il tempo di avvio. Servizi come `snapd`, `plymouth` o `fwupd` possono spesso essere disabilitati in sicurezza se non ne hai bisogno.

**Richiede password:** Sì (per le operazioni di disabilita/abilita/ferma)

---

### 5.2 App di Avvio

**Scopo:** Gestire le applicazioni che si avviano automaticamente all'accesso.

L'elenco mostra tutte le voci di avvio automatico divise in sezioni **Abilitate** e **Disabilitate**. Ogni voce visualizza il nome dell'applicazione, il comando e se si tratta di un'app di sistema o utente.

**Azioni per app (tocca il menu a tre puntini):**
- **Disabilita:** Impedisce l'avvio dell'app all'accesso. Se l'app è attualmente in esecuzione, ti viene chiesto se terminare anche i suoi processi.
- **Riabilita:** Riabilita un'app di avvio disabilitata.
- **Termina Processi:** Termina tutti i processi in esecuzione di quell'app.
- **Rimuovi:** Elimina permanentemente la voce di avvio automatico.

**Protezione app di sistema:** Alcune app (come GNOME Shell, NetworkManager, i componenti di KDE Plasma) sono contrassegnate come protette e non possono essere disabilitate. Questo previene danni accidentali all'ambiente desktop.

> **Suggerimento per i principianti:** Se noti che il tuo computer è lento ad avviarsi, controlla la scheda App di Avvio. Disabilitare le app non necessarie (come i client di archiviaione cloud o le app di chat che non usi all'avvio) può velocizzare significativamente l'accesso.

> **Suggerimento per gli esperti:** L'app crea override a livello utente per le voci di avvio automatico di sistema in `/etc/xdg/autostart/` invece di modificare i file di sistema. Questo è sicuro e reversibile.

**Richiede password:** No

---

### 5.3 Pulizia

**Scopo:** Liberare spazio su disco rimuovendo file temporanei, cache e cancellando la cache delle pagine Linux.

**Riga di pulsanti:**
- **Aggiorna Dimensioni:** Ricalcola la dimensione di tutte le cartelle temporanee/cache rilevate.
- **Pulisci File Temporanei (pulsante arancione):** Elimina i file temporanei da tutte le cartelle elencate. Viene visualizzato un dialogo di conferma prima dell'eliminazione. Puoi escludere cartelle specifiche toccando l'icona di attivazione accanto a ogni cartella.

**Cache delle Pagine Linux:**
- **Pulsante Cancella Cache:** Libera la cache delle pagine del kernel eseguendo `sync && echo 1 > /proc/sys/vm/drop_caches`. Questo è sicuro e non elimina alcun dato utente — cancella solo le letture di file memorizzate nella cache dalla RAM.

**Pulisci RAM:**
- Mostra l'utilizzo attuale della RAM (usata / totale / percentuale).
- **Pulsante Pulisci RAM:** Cancella la cache delle pagine, i dentry e gli inode eseguendo `sync && echo 3 > /proc/sys/vm/drop_caches`. Questo libera più memoria della pulizia della cache base. Mostra quanta memoria è stata liberata dopo l'operazione.

**Pulizia Automatica della RAM:**
- Configura in **Impostazioni > Pulizia RAM** per cancellare automaticamente la RAM a intervalli: Mai, 5 min, 10 min, 15 min o 30 min.
- Funziona in background all'intervallo configurato.

**Aggiungi Cartella Esclusa:** Aggiungi cartelle personalizzate da escludere dalla pulizia. Utile per preservare le cartelle cache di applicazioni specifiche.

> **Suggerimento per i principianti:** Usa regolarmente "Pulisci File Temporanei" per liberare spazio su disco. I pulsanti "Cancella Cache" e "Pulisci RAM" sono sicuri — non eliminano alcun file personale.

> **Suggerimento per gli esperti:** Il pulitore RAM usa `echo 3` (rimuove cache pagine + dentry + inode), che è più aggressivo di `echo 1` (solo cache pagine). Usalo quando devi recuperare rapidamente memoria, ad esempio prima di avviare un'applicazione che richiede molta memoria.

**Richiede password:** Sì (per la pulizia della cache e della RAM)

---

### 5.4 App Installate

**Scopo:** Visualizzare e disinstallare applicazioni da tutti i gestori di pacchetti.

**Gestori di pacchetti supportati:**
- **APT** (Debian/Ubuntu/Mint)
- **Snap** (Pacchetti universali Linux)
- **Flatpak** (Applicazioni sandboxed)
- **GNOME** (Applicazioni desktop tramite file .desktop)

**Funzionalità:**
- **Cerca:** Filtra le app per nome o descrizione.
- **Chip di filtro:** Passa tra le viste Tutti, APT, Snap, Flatpak, GNOME.
- **Disinstallazione per app:** Tocca il menu a tre puntini e seleziona "Rimuovi". L'app controlla prima le dipendenze — se altri pacchetti dipendono da quello che vuoi rimuovere, un dialogo di avviso mostra l'elenco.

> **Avviso per i principianti:** Fai attenzione quando disinstalli pacchetti di sistema. Se non sei sicuro, cerca prima il nome del pacchetto online.

> **Suggerimento per gli esperti:** Il controllo delle dipendenze usa `apt-cache depends` e `apt-cache rdepends --installed` per mostrare sia le dipendenze dirette che inverse.

**Richiede password:** Sì (per la rimozione dei pacchetti)

---

### 5.5 Monitor di Sistema

**Scopo:** Monitoraggio in tempo reale di processi, CPU, RAM, disco e GPU.

Questa schermata ha tre sottoschede:

#### Scheda Processi
- Visualizza tutti i processi in esecuzione raggruppati per nome applicazione.
- **Colonne:** Nome App, CPU%, Memoria — tocca un'intestazione di colonna per ordinare.
- **Indicatori CPU/RAM/GPU** sul lato destro mostrano l'utilizzo in tempo reale.
- **Azioni per gruppo:** Seleziona tutti, Termina tutti, Forza termina tutti.
- **Modalità multi-selezione:** Seleziona più gruppi di processi, poi terminali tutti insieme.
- Aggiornamento automatico ogni 5 secondi.

#### Scheda Sistema
Mostra le informazioni hardware in formato scheda:
- **CPU:** Modello, core, thread, barra di utilizzo, velocità di clock.
- **Memoria:** Totale, usata, libera, cache, utilizzo swap.
- **Disco:** Nome dispositivo per disco, file system, barra di utilizzo.
- **GPU:** Modello, driver, percentuale di utilizzo, memoria, temperatura (se disponibile).
- **Server Display:** Rilevamento Wayland/X11/XWayland, ambiente desktop, variabili d'ambiente chiave.

#### Scheda Stato
Pannello di stato del sistema in sola lettura con quattro sezioni:
- **Kernel:** Versione, informazioni di compilazione, modalità THP, zswap, governatore, scheduler I/O.
- **Sicurezza:** AppArmor, SELinux, Secure Boot, stato del firewall, stato SSH, aggiornamenti automatici.
- **Virtualizzazione:** Supporto virtualizzazione CPU, KVM, IOMMU, VFIO, KSM, Docker, libvirt.
- **Stampanti:** Stato del servizio CUPS, stampanti installate, driver di stampa.

> **Suggerimento per i principianti:** La scheda Processi ti aiuta a trovare quale app sta utilizzando troppa CPU o memoria. Tocca su un gruppo di processi per vedere i processi singoli.

> **Suggerimento per gli esperti:** La scheda Stato fornisce un rapido audit di sicurezza e virtualizzazione. Controlla lo stato del firewall, SSH e Secure Boot a colpo d'occhio.

**Richiede password:** No

---

### 5.6 Analizzatore Dischi

**Scopo:** Sfogliare il file system, visualizzare l'utilizzo del disco e gestire i file.

**Navigazione:**
- **Home / File System / Dischi esterni:** Selezione rapida dei percorsi base.
- **Indietro / Avanti:** Naviga attraverso la cronologia.
- **Ordina:** Per dimensione (crescente/decrescente) o alfabeticamente.
- **Menu Altro:** Mostra/nascondi file nascosti/di sistema.

**Funzionalità:**
- **Grafico a torta:** Visualizza la distribuzione delle dimensioni delle directory.
- **Avviso prima scansione:** Quando un disco viene analizzato per la prima volta, compare un avviso informativo che ti informa che l'indicizzazione è in corso e la prima analisi potrebbe richiedere del tempo.
- **Azioni su file/directory:**
  - **Sposta nel Cestino:** Eliminazione sicura nel cestino (con conferma).
  - **Rinomina:** Rinomina file o directory.
  - **Mostra Dettagli:** Visualizza percorso, dimensione, tipo, permessi, proprietario, data di modifica.

> **Avviso:** L'eliminazione di file dal file system radice (`/`) richiede privilegi di amministratore ed è irreversibile. Fai molta attenzione.

> **Suggerimento per i principianti:** Inizia analizzando la tua directory home per trovare cartelle grandi che occupano spazio (ad esempio, `~/.cache`, `~/.local/share/Trash`).

**Richiede password:** Sì (per l'eliminazione da percorsi root)

---

### 5.7 Salute Dischi SMART

**Scopo:** Monitorare la salute dei dischi rigidi e degli SSD utilizzando i dati S.M.A.R.T.

**Funzionalità:**
- **Selettore disco:** Scegli quale disco ispezionare dal menu a tendina.
- **Stato salute:** Mostra PASSATO o FALLITO con temperatura e ore di accensione.
- **Rilevamento USB:** Identifica i dischi collegati via USB e avvisa che i bridge USB-SATA possono limitare i dati SMART.
- **Tabella attributi:** Visualizza tutti gli attributi SMART (ID, nome, valore, peggiore, soglia, grezzo). Gli attributi falliti sono evidenziati in rosso.
- **Self-test:**
  - **Test Breve:** Scansione rapida (~2 minuti).
  - **Test Esteso:** Scansione approfondita (può richiedere ore a seconda della dimensione del disco).
  I risultati appaiono nella tabella degli attributi al completamento del test.

**Se smartctl non è installato:** L'app offre di installare automaticamente `smartmontools`.

> **Suggerimento per i principianti:** Controlla la salute del tuo disco mensilmente. Uno stato "FALLITO" o attributi evidenziati in rosso indicano che il disco potrebbe necessitare di sostituzione a breve.

> **Suggerimento per gli esperti:** L'app supporta la scansione multi-distribuzione (lsblk + smartctl --scan + fallback /sys/block/). I bridge USB-SATA vengono testati con `smartctl -d sat`.

**Richiede password:** Sì (per l'installazione di smartctl e l'esecuzione dei self-test)

---

### 5.8 Gestore Dispositivi

**Scopo:** Visualizzare, abilitare e disabilitare dispositivi hardware — simile al Gestore Dispositivi di Windows.

**Funzionalità:**
- **Albero dispositivi:** Tutti i dispositivi hardware (PCI, USB, blocco, rete) raggruppati per categoria: Adattatori di visualizzazione, Adattatori di rete, Audio/video, Controller USB, Archiviazione, Processore, Dispositivi di input, Multimedia.
- **Barra di ricerca:** Filtra i dispositivi per nome o descrizione.
- **Filtro mostra disabilitati:** Mostra/nascondi solo i dispositivi disabilitati.

**Azioni per dispositivo (tocca per espandere, poi menu a tre puntini):**
- **Abilita/Disabilita:** Attiva/disattiva lo stato del dispositivo con dialogo di conferma. Richiede la password sudo.
- **Pannello proprietà:** Mostra informazioni dettagliate — stato, tipo bus, fornitore, driver, ID fornitore/dispositivo.

**Protezione dispositivi:** I dispositivi critici (Host bridge, PCI bridge, ISA bridge, IOMMU, SMBus, Processore) non possono essere disabilitati per prevenire instabilità del sistema.

**Persistenza:** I dispositivi disabilitati vengono salvati in `/etc/slu_disabled_devices.conf` e viene creato un servizio systemd per riapplicare la disabilità ad ogni avvio. Questo garantisce che le impostazioni sopravvivano ai riavvii.

> **Avviso per i principianti:** Non disabilitare dispositivi che non riconosci. Disabilitare un adattatore di rete ti disconnetterà da Internet. Disabilitare un adattatore di visualizzazione potrebbe causare il crash del desktop.

> **Suggerimento per gli esperti:** Il meccanismo di persistenza usa sysfs (`echo 0 > enable` per PCI, `echo 0 > authorized` per USB, `ip link set X down` per la rete) con un servizio systemd.

**Richiede password:** Sì (per le operazioni di abilita/disabilita)

---

### 5.9 Ripristino

**Scopo:** Ripristinare funzioni di sistema alterate, controllare gli aggiornamenti e installare software.

#### Operazioni di Ripristino
| Operazione | Descrizione |
|-----------|------------|
| **Riavvia Pipewire** | Riavvia PipeWire, PipeWire-Pulse e Wireplumber per risolvere problemi audio. |
| **Ripristina Rete** | Riavvia NetworkManager o systemd-networkd per risolvere problemi di connessione. |
| **Ricostruisci GRUB** | Esegue `update-grub` per rigenerare la configurazione del bootloader. |
| **Ripristina Flathub** | Riaggiunge il remote Flathub per Flatpak. |
| **Ripristina Repository** | Aggiorna e ripristina i repository di pacchetti per la tua distribuzione. |
| **Correggi Auto-Sospensione WiFi** | Disabilita l'auto-sospensione USB per gli adattatori WiFi per prevenire disconnessioni casuali. |

Ogni operazione mostra un pulsante "Visualizza Output" per ispezionare l'output del comando.

#### Scheda Controllo Aggiornamenti
- **Controlla Aggiornamenti:** Esegue il comando appropriato di aggiornamento del gestore di pacchetti (`apt update`, `dnf check-update`, `pacman -Sy`).
- I risultati mostrano gli aggiornamenti disponibili per gestore di pacchetti (APT, DNF, Pacman, Snap, Flatpak).
- **Applica Aggiornamenti:** Scarica e installa tutti gli aggiornamenti disponibili con progresso in tempo reale.

#### Scheda Installatore Software
Installer a click per software essenziale:
- **FFmpeg:** Framework multimediale per la codifica/decodifica di audio e video.
- **yt-dlp:** Scaricatore video che supporta molti siti web.
- **Librerie di Sistema:** Librerie di sistema essenziali che potrebbero mancare.
- **Codec:** Codec audio e video per formati comuni.
- **rsync:** Strumento efficiente di sincronizzazione e trasferimento file.

**Richiede password:** Sì

---

### 5.10 Ottimizzazioni

**Scopo:** Ottimizzazione delle prestazioni del sistema per swap e DaVinci Resolve.

#### Scheda Swap
- Mostra le informazioni attuali dello swap: dimensione RAM, swap totale/usato, valore di swappiness, dispositivo swap.
- Fornisce raccomandazioni basate sulla tua configurazione:
  - Crea un file di swap se non ne esiste uno.
  - Regola il valore di swappiness.
  - Abilita o disabilita zram.
- Ogni raccomandazione ha un pulsante "Esegui" che applica la modifica suggerita.

#### Scheda DaVinci Resolve
- Applica le correzioni comuni Linux per Blackmagic DaVinci Resolve:
  - Correggi i percorsi delle librerie CUDA.
  - Imposta i permessi corretti della GPU.
  - Installa le dipendenze mancanti.
- Ogni correzione mostra se richiede un riavvio e se è stata applicata.

> **Suggerimento per i principianti:** Se usi DaVinci Resolve su Linux e riscontri problemi con la GPU, vai a questa scheda e applica tutte le correzioni.

> **Suggerimento per gli esperti:** Le raccomandazioni sul swap analizzano il tuo `/proc/meminfo` e la configurazione dello swap per fornire i suggerimenti più appropriati.

**Richiede password:** Sì

---

### 5.11 Impostazioni

Configura le preferenze dell'app:

#### Password
- Salva, aggiorna o elimina la password di amministratore.
- La password viene archiviata utilizzando il portachiavi del sistema (codificata in base64 nelle SharedPreferences).

#### Lingua
- Seleziona tra 6 lingue: Italiano, Inglese, Francese, Spagnolo, Tedesco, Portoghese.
- Le modifiche hanno effetto dopo il riavvio dell'app.

#### Tema
- **Chiaro / Scuro / Sistema:** Scegli lo schema colori dell'app.
- "Sistema" segue l'impostazione del tema dell'ambiente desktop.

#### Font
- **Famiglia Font:** Seleziona tra i font di sistema disponibili.
- **Dimensione Font:** Scorrimento da 10sp a 24sp.

#### Barra di Sistema (solo Linux)
- **Abilita Barra di Sistema:** Mostra/nascondi l'icona dell'app nella barra di sistema.
- **Chiudi nella Barra:** Mantieni l'app in esecuzione nella barra quando chiudi la finestra.
- **Avvia Minimizzato:** Avvia l'app minimizzato nella barra.
- **Avvia all'Accesso:** Avvio automatico dell'app all'accesso (usa l'avvio automatico XDG).
- **Installa Dipendenze:** Installa `libayatana-appindicator` se mancante.

#### Controllo Aggiornamento Automatico
- Imposta la frequenza con cui l'app controlla gli aggiornamenti di sistema (Mai, 15 min, 30 min, 1 ora, 6 ore, 12 ore, giornaliero).
- **Aggiornamento automatico da GitHub:** Scarica e installa automaticamente l'ultimo `.deb` dai rilasci GitHub.

#### Pulizia RAM
- Imposta un intervallo automatico per cancellare la cache delle pagine Linux e la RAM: **Mai**, **5 minuti**, **10 minuti**, **15 minuti**, **30 minuti**.
- Funziona in background all'intervallo configurato.

#### Programmatore di Spegnimento
- Apre la schermata del timer di spegnimento automatico (vedi Sezione 7).

---

### 5.12 Info

**Scopo:** Schermata informazioni sull'app.

- Versione dell'app, creatore e descrizione.
- Elenco delle funzionalità organizzato per categoria.
- Licenza e avviso (GPL).
- **Pulsante Attivazione Licenza** (solo build Avanzata): Inserisci la chiave di licenza per sbloccare le funzionalità avanzate.
- **Pulsante PayPal** (solo build Avanzata): Acquista una licenza per 19,99 EUR.
- Link al sito web del progetto.

---

## 6. Modalità Avanzata — Funzionalità Aggiuntive

La modalità avanzata sblocca 2 schede aggiuntive ed estende la schermata Ottimizzazioni esistente. Richiede una chiave di licenza acquistata (o build Personale/Test).

Per passare tra la modalità Standard e Avanzata, usa i pulsanti di modalità nell'area in alto a destra della barra laterale.

---

### 6.1 Editor GRUB

**Scopo:** Modificare in sicurezza la configurazione del bootloader GRUB.

**Funzionalità:**
- **Editor di testo:** Modifica direttamente `/etc/default/grub` in un editor di testo integrato.
- **Salva e Aggiorna:** Salva la configurazione, crea un backup automatico ed esegue `update-grub` (o l'equivalente per la tua distribuzione).
- **Suggerimenti Hardware:** Analizza il tuo hardware e suggerisce parametri del kernel:
  - NVIDIA modeset, iommu, threadirqs, zswap, elevator, ecc.
  - Ogni suggerimento ha un badge di priorità (alta/media/bassa).
  - Tocca "Applica" per inserire il suggerimento nell'editor.
- **Ripristina Backup:** Ripristina l'ultimo backup in caso di problemi.
- **Indicatore modifiche non salvate:** Una barra arancione appare quando hai modifiche non salvate.

**Comandi di ricostruzione GRUB per distribuzione:**
- Debian/Ubuntu: `update-grub`
- Fedora: `grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
- Arch: `grub-mkconfig -o /boot/grub/grub.cfg`

> **Avviso:** Modifiche GRUB errate possono impedire l'avvio del sistema. Mantieni sempre un backup. Se il sistema non si avvia, usa una USB live per ripristinare `/etc/default/grub` dal backup.

**Richiede password:** Sì

---

### 6.2 Benchmark

**Scopo:** Misurare le prestazioni hardware del tuo sistema.

Quattro categorie di benchmark:

| Benchmark | Cosa misura |
|-----------|-------------|
| **CPU** | Potenza di elaborazione multi-core e single-core. Risultati confrontati con chip di riferimento Intel, AMD e Apple. |
| **GPU** | Prestazioni grafiche usando `glmark2`. Risultati confrontati con GPU di riferimento NVIDIA e AMD. |
| **Disco** | Velocità di lettura/scrittura sequenziale. Risultati confrontati con riferimenti NVMe, SSD e HDD. |
| **Rete** | Test della velocità di Internet. Risultati confrontati con velocità di rete di riferimento. |

Ogni benchmark mostra:
- Il tuo punteggio.
- L'hardware di riferimento più vicino.
- Una valutazione (Eccellente, Buono, Medio, Sotto la media, Scarso).

> **Suggerimento:** Esegui i benchmark dopo le modifiche del sistema (nuovo kernel, nuovi driver) per vedere se le prestazioni sono migliorate.

**Richiede password:** No

---

## 7. Barra di Sistema

Quando abilitata nelle Impostazioni, Super Linux Utility inserisce un'icona nella barra di sistema (area di notifica). Fai clic destro sull'icona per accedere:

| Voce Menu | Azione |
|-----------|--------|
| **Mostra finestra principale** | Porta la finestra dell'app in primo piano. |
| **Controlla aggiornamenti** | Apre il dialogo di controllo aggiornamenti. |
| **Pulisci file temporanei e cache** | Naviga alla scheda Pulizia. |
| **Temperatura CPU, GPU** | Naviga alla scheda Monitor. |
| **Utilizzo disco** | Naviga alla scheda Analizzatore Dischi. |
| **Utilizzo memoria** | Mostra l'utilizzo attuale della RAM. |
| **Salute dischi (SMART)** | Naviga alla scheda SMART. |
| **Spegnimento automatico** | Apre il dialogo del timer di spegnimento. |
| **Utilizzo CPU, GPU** | Apre un dialogo del gestore attività. |
| **Esci** | Chiude l'app.**

Il tooltip dell'icona della barra mostra la temperatura CPU/GPU e l'utilizzo della memoria in tempo reale.

---

## 8. Aggiornamenti Automatici

### Controllo Aggiornamenti di Sistema
Configurabile in Impostazioni > Controllo Aggiornamento Automatico. Quando abilitato, l'app controlla periodicamente gli aggiornamenti in tutti i gestori di pacchetti installati (APT, DNF, Pacman, Snap, Flatpak). Le notifiche di aggiornamento appaiono come dialoghi con caselle di controllo per ogni pacchetto.

### Auto-Aggiornamento App
Quando abilitato in Impostazioni > Aggiornamento automatico da GitHub, l'app controlla i rilasci GitHub per pacchetti `.deb` più recenti corrispondenti alla tua edizione (Standard/Avanzata). Scarica e installa automaticamente usando `sudo dpkg -i`.

---

## 9. Risoluzione Problemi

### Errore "Password non salvata"
Vai a Impostazioni > Password e reinserisci la password sudo. La password è archiviata nel portachiavi del sistema.

### La scheda SMART non mostra dischi
Installa `smartmontools`: l'app offrirà di farlo automaticamente. Se stai usando un adattatore USB-SATA, i dati SMART potrebbero essere limitati.

### Le modifiche GRUB non sono state applicate (modalità Avanzata)
Assicurati di aver toccato "Salva e Aggiorna" (non solo "Salva"). L'app deve eseguire `update-grub` con privilegi di amministratore.

### L'icona della barra di sistema non è visibile
Installa la dipendenza richiesta: `sudo apt install libayatana-appindicator-3-dev`. Poi riavvia l'app.

### L'AppImage non si avvia
L'AppImage usa un runtime statico e dovrebbe funzionare senza FUSE. Se ancora non funziona:
```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./super-linux-utility-*.AppImage
```

### Il Gestore Dispositivi non può disabilitare un dispositivo
Alcuni dispositivi sono protetti perché la loro disabilitazione causerebbe il crash del sistema. L'app mostra un messaggio quando un dispositivo non può essere disabilitato.

---

## 10. FAQ

**D: È sicuro usare questa app?**
R: Le funzionalità della modalità Standard sono sicure per tutti gli utenti. La modalità Avanzata modifica GRUB — crea sempre un backup prima di usare le funzionalità GRUB.

**D: L'app invia dati da qualche parte?**
R: No. L'app non raccoglie né trasmette alcun dato utente. Le uniche operazioni di rete sono il controllo degli aggiornamenti (da GitHub o dal tuo gestore di pacchetti).

**D: Posso usare l'app su Fedora/Arch?**
R: Sì. L'app rileva automaticamente la tua distribuzione e adatta tutti i comandi di conseguenza (APT, DNF, Pacman).

**D: Cosa succede se disabilito un servizio critico?**
R: L'app protegge i servizi essenziali dell'ambiente desktop (GNOME, KDE, ecc.) dalla disabilitazione. Tuttavia, sii sempre cauto con servizi sconosciuti.

**D: Come ripristino GRUB se il sistema non si avvia?**
R: Avvia da una USB live, monta la partizione root e copia `/etc/default/grub.backup` di nuovo in `/etc/default/grub`. Poi esegui `sudo update-grub`.

**D: Posso disabilitare qualsiasi dispositivo hardware?**
R: Il Gestore Dispositivi protegge i dispositivi di sistema critici (CPU, bridge, IOMMU) dalla disabilitazione. Puoi disabilitare in sicurezza periferiche non essenziali come dispositivi USB o adattatori di rete secondari.

---

## 11. Glossario

| Termine | Definizione |
|---------|-------------|
| **APT** | Advanced Package Tool — gestore di pacchetti Debian/Ubuntu. |
| **Gestore Dispositivi** | Strumento per visualizzare, abilitare e disabilitare dispositivi hardware. |
| **DNF** | Dandified YUM — gestore di pacchetti Fedora/RHEL. |
| **Flatpak** | Formato di pacchettizzazione applicazioni sandboxed per Linux. |
| **GRUB** | Grand Unified Bootloader — il programma che carica Linux all'avvio. |
| **Kernel** | Il nucleo del sistema operativo Linux. |
| **PCI** | Peripheral Component Interconnect — bus standard per dispositivi interni. |
| **Pacman** | Gestore di pacchetti per Arch Linux e derivati. |
| **PipeWire** | Server audio/video moderno per Linux. |
| **SMART** | Self-Monitoring, Analysis and Reporting Technology — sistema di salute dei dischi rigidi. |
| **Snap** | Formato universale di pacchetti Linux di Canonical. |
| **systemd** | Sistema di init e gestore servizi per Linux. |
| **systemctl** | Strumento da riga di comando per gestire i servizi systemd. |
| **Swap** | Spazio su disco usato come RAM virtuale quando la RAM fisica è piena. |
| **sysfs** | File system virtuale che espone i dati dei dispositivi del kernel (`/sys/`). |
| **USB** | Universal Serial Bus — standard per dispositivi esterni. |
| **Wayland** | Protocollo moderno del server display che sostituisce X11. |
| **X11** | Protocollo tradizionale del server display per Linux. |
| **zram** | Dispositivo di swap basato su RAM compressa. |

---

*Super Linux Utility v2.0.6 — Manuale Utente*
*Creato da Marco Di Giangiacomo*
*Licenza: GPL v3*
