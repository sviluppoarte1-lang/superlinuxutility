# Super Linux Utility v2.0.6
# Vollständiges Benutzerhandbuch — Deutsch

---

## Inhaltsverzeichnis

1. [Einführung](#1-einführung)
2. [Systemanforderungen](#2-systemanforderungen)
3. [Installation](#3-installation)
4. [Erster Start](#4-erster-start)
5. [Standardmodus — Alle Funktionen](#5-standardmodus)
   - 5.1 Dienste
   - 5.2 Autostart-Apps
   - 5.3 Bereinigung
   - 5.4 Installierte Apps
   - 5.5 Systemüberwachung
   - 5.6 Festplattenanalysator
   - 5.7 SMART-Festplattengesundheit
   - 5.8 Geräteverwaltung
   - 5.9 Wiederherstellung
   - 5.10 Optimierungen
   - 5.11 Einstellungen
   - 5.12 Info
6. [Erweiterter Modus — Zusätzliche Funktionen](#6-erweiterter-modus)
   - 6.1 GRUB-Editor
   - 6.2 Benchmark
7. [Systemabschlussleiste](#7-systemabschlussleiste)
8. [Automatische Updates](#8-automatische-updates)
9. [Fehlerbehebung](#9-fehlerbehebung)
10. [Häufig gestellte Fragen](#10-häufig-gestellte-fragen)
11. [Glossar](#11-glossar)

---

## 1. Einführung

**Super Linux Utility** ist eine umfassende Systemverwaltungsanwendung für Linux. Sie bietet eine moderne grafische Oberfläche zur Verwaltung von Diensten, Autostart-Apps, Bereinigung von temporären Dateien, Überwachung der Systemleistung, Analyse von Festplatten, Verwaltung von Hardwaregeräten und vielem mehr.

Die Anwendung ist in zwei Versionen verfügbar:

- **Standard (Kostenlos):** Alle grundlegenden Systemverwaltungswerkzeuge — Dienste, Autostart-Apps, Bereinigung, installierte Apps, Überwachung, Festplattenanalysator, SMART-Gesundheit, Geräteverwaltung, Wiederherstellung, Optimierungen und Einstellungen.
- **Erweitert (Kostenpflichtig):** Alles aus der Standard-Version, plus GRUB-Editor und Benchmark-Suite.

**Unterstützte Distributionen:** Ubuntu, Debian, Linux Mint, LMDE, Pop!_OS, Zorin, elementary, MX Linux, Fedora, RHEL, CentOS, Arch Linux, Manjaro, EndeavourOS, CachyOS, KDE neon.

**Unterstützte Desktop-Umgebungen:** GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt.

---

## 2. Systemanforderungen

- **Betriebssystem:** Linux (64-Bit)
- **Festplattenspeicher:** ~200 MB installiert
- **RAM:** 512 MB Minimum, 2 GB empfohlen
- **Abhängigkeiten:** GTK3, GLib 2.0+
- **Optional:** `libappindicator` für die Systemabschlussleiste, `smartmontools` für SMART-Festplattengesundheit

---

## 3. Installation

### AppImage (Empfohlen)
```bash
chmod +x super-linux-utility-2.0.6-x86_64.AppImage
./super-linux-utility-2.0.6-x86_64.AppImage
```

### Debian/Ubuntu (.deb)
```bash
sudo dpkg -i super-linux-utility_2.0.6_amd64.deb
sudo apt-get install -f
```

### Aus Quellcode
```bash
git clone https://github.com/sviluppoarte1-lang/superlinuxutility.git
cd superlinuxutility
flutter build linux
```

---

## 4. Beim ersten Start

Wenn Sie Super Linux Utility zum ersten Mal öffnen, erscheinen nacheinander drei Einrichtungsbildschirme:

### 4.1 Sprachauswahl
Wählen Sie Ihre bevorzugte Sprache aus: Italienisch, Englisch, Französisch, Spanisch, Deutsch, Portugiesisch. Die ausgewählte Sprache wird für alle Schaltflächen, Menüs, Meldungen und Beschreibungen in der gesamten Anwendung übernommen.

### 4.2 Warnbildschirm
Ein Haftungsausschluss erinnert Sie daran, dass diese Anwendung kritische Systemkonfigurationen ändern kann (GRUB-Bootloader, Kernel, Dienste). Es wird dringend empfohlen, vor der Verwendung erweiterter Funktionen eine Systemsicherung zu erstellen. Aktivieren Sie „Diese Warnung nicht mehr anzeigen", um sie beim nächsten Start zu überspringen.

### 4.3 Passworteinrichtung
Um Funktionen zu verwenden, die das System ändern (Bereinigung, Dienstverwaltung, GRUB-Bearbeitung usw.), benötigt die Anwendung Ihr Administrator-(sudo-)Passwort. Das Passwort wird sicher mit dem Systemschlüsselbund gespeichert. Sie können diesen Schritt überspringen und ihn später in den Einstellungen konfigurieren.

> **Tipp für Einsteiger:** Wenn Sie sich nicht sicher sind, ob Sie Ihr Passwort eingeben sollen, können Sie es überspringen. Die meisten schreibgeschützten Funktionen (Überwachung, Festplattenanalysator, SMART) funktionieren ohne Passwort.

---

## 5. Standardmodus — Alle Funktionen

Der Standardmodus bietet 12 Registerkarten, die über die linke Seitenleiste zugänglich sind. Jede Registerkarte enthält spezifische Werkzeuge.

---

### 5.1 Dienste

**Zweck:** Ansehen und Verwalten von systemd-Diensten, die auf Ihrem System laufen.

**Registerkarten:**
- **Langsame Dienste:** Listet Dienste auf, die mehr als 2 Sekunden zum Starten benötigen (erkannt über `systemd-analyze blame`). Dies hilft zu identifizieren, was Ihren Start verlangsamt.
- **Alle Dienste:** Vollständige Liste aller systemd-Dienste mit ihrem Status (aktiv, inaktiv, fehlgeschlagen). Tippen Sie auf „Alle analysieren", um die vollständige Liste zu laden.
- **Deaktiviert:** Zeigt alle derzeit deaktivierten Dienste.

**Aktionen pro Dienst (Dreipunkte-Menü antippen):**
- **Deaktivieren:** Verhindert, dass der Dienst beim Systemstart gestartet wird.
- **Reaktivieren:** Erlaubt es dem Dienst, beim Systemstart erneut zu starten.
- **Stoppen:** Stoppt einen laufenden Dienst sofort.

> **Warnung für Einsteiger:** Deaktivieren Sie keine Dienste, die Sie nicht erkennen. Einige Dienste sind für den ordnungsgemäßen Betrieb Ihres Systems unerlässlich (z. B. NetworkManager, PulseAudio, systemd-resolved). Im Zweifelsfall lassen Sie den Dienst aktiviert.

> **Tipp für Experten:** Verwenden Sie die Registerkarten „Langsame Dienste", um die Startzeit zu optimieren. Dienste wie `snapd`, `plymouth` oder `fwupd` können oft sicher deaktiviert werden, wenn Sie sie nicht benötigen.

**Erfordert Passwort:** Ja (für Deaktivieren/Aktivieren/Stoppen)

---

### 5.2 Autostart-Apps

**Zweck:** Verwalten von Anwendungen, die automatisch beim Anmelden gestartet werden.

Die Liste zeigt alle Autostart-Einträge, unterteilt in die Bereiche **Aktiviert** und **Deaktiviert**. Jeder Eintrag zeigt den Anwendungsnamen, den Befehl und an, ob es sich um eine System- oder Benutzeranwendung handelt.

**Aktionen pro App (Dreipunkte-Menü antippen):**
- **Deaktivieren:** Verhindert, dass die App beim Anmelden gestartet wird. Wenn die App gerade läuft, werden Sie gefragt, ob auch deren Prozesse beendet werden sollen.
- **Reaktivieren:** Reaktiviert eine deaktivierte Autostart-App.
- **Prozesse beenden:** Beendet alle laufenden Prozesse dieser App.
- **Entfernen:** Löscht den Autostart-Eintrag dauerhaft.

**Systemapp-Schutz:** Einige Apps (wie GNOME Shell, NetworkManager, KDE Plasma-Komponenten) sind als geschützt markiert und können nicht deaktiviert werden. Dies verhindert unbeabsichtigte Beschädigungen Ihrer Desktop-Umgebung.

> **Tipp für Einsteiger:** Wenn Sie bemerken, dass Ihr Computer langsam startet, überprüfen Sie die Registerkarte Autostart-Apps. Das Deaktivieren unnötiger Apps (z. B. Cloud-Speicher-Clients oder Chat-Apps, die Sie beim Start nicht verwenden) kann die Anmeldezeit erheblich verkürzen.

> **Tipp für Experten:** Die Anwendung erstellt Benutzer-Level-Überschreibungen für System-Autostart-Einträge in `/etc/xdg/autostart/`, anstatt Systemdateien zu ändern. Dies ist sicher und umkehrbar.

**Erfordert Passwort:** Nein

---

### 5.3 Bereinigung

**Zweck:** Festplattenspeicher freigeben, indem temporäre Dateien, Caches und der Linux-Seitencache gelöscht werden.

**Schaltflächenreihe:**
- **Größen aktualisieren:** Berechnet die Größe aller erkannten Temp-/Cache-Ordner neu.
- **Temporäre Dateien bereinigen (orangefarbene Schaltfläche):** Löscht temporäre Dateien aus allen aufgeführten Ordnern. Vor dem Löschen erscheint ein Bestätigungsdialog. Sie können bestimmte Ordner ausschließen, indem Sie das Umschaltsymbol neben jedem Ordner antippen.

**Linux-Seitencache:**
- **Cache leeren-Schaltfläche:** Gibt den Kernel-Seitencache frei, indem `sync && echo 1 > /proc/sys/vm/drop_caches` ausgeführt wird. Dies ist sicher und löscht keine Benutzerdaten — es löscht nur zwischengespeicherte Dateilesevorgänge aus dem RAM.

**RAM bereinigen:**
- Zeigt die aktuelle RAM-Auslastung (belegt / Gesamt / Prozent).
- **RAM bereinigen-Schaltfläche:** Leert Seitencache, dentries und inodes durch Ausführen von `sync && echo 3 > /proc/sys/vm/drop_caches`. Dies gibt mehr Speicher frei als das grundlegende Cache-Leeren. Zeigt an, wie viel Speicher nach dem Vorgang freigegeben wurde.

**Automatische RAM-Bereinigung:**
- Konfigurieren Sie in **Einstellungen > RAM-Bereinigung**, um RAM automatisch in Intervallen zu leeren: Nie, 5 Min., 10 Min., 15 Min. oder 30 Min.
- Läuft im Hintergrund im konfigurierten Intervall.

**Ausgeschlossenen Ordner hinzufügen:** Fügen Sie benutzerdefinierte Ordner hinzu, die von der Bereinigung ausgeschlossen werden sollen. Nützlich zum Erhalten von Cache-Verzeichnissen bestimmter Anwendungen.

> **Tipp für Einsteiger:** Verwenden Sie regelmäßig „Temporäre Dateien bereinigen", um Festplattenspeicher freizugeben. Die Schaltflächen „Cache leeren" und „RAM bereinigen" sind sicher — sie löschen keine persönlichen Dateien.

> **Tipp für Experten:** Der RAM-Bereiniger verwendet `echo 3` (löscht Seitencache + dentries + inodes), was aggressiver ist als `echo 1` (nur Seitencache). Verwenden Sie ihn, wenn Sie schnell Speicher zurückgewinnen müssen, z. B. vor dem Start einer speicherintensiven Anwendung.

**Erfordert Passwort:** Ja (für Cache- und RAM-Bereinigung)

---

### 5.4 Installierte Apps

**Zweck:** Ansehen und Deinstallieren von Anwendungen aus allen Paketmanagern.

**Unterstützte Paketmanager:**
- **APT** (Debian/Ubuntu/Mint)
- **Snap** (Universelle Linux-Pakete)
- **Flatpak** (Sandboxierte Anwendungen)
- **GNOME** (Desktop-Anwendungen über .desktop-Dateien)

**Funktionen:**
- **Suche:** Filtern Sie Apps nach Name oder Beschreibung.
- **Filterchips:** Umschalten zwischen Alle, APT, Snap, Flatpak, GNOME-Ansichten.
- **Deinstallation pro App:** Tippen Sie auf das Dreipunkte-Menü und wählen Sie „Entfernen". Die Anwendung prüft zuerst auf Abhängigkeiten — wenn andere Pakete von dem Paket abhängen, das Sie entfernen möchten, zeigt ein Warnungsdialog die Liste.

> **Warnung für Einsteiger:** Seien Sie vorsichtig beim Deinstallieren von Systempaketen. Wenn Sie sich unsicher sind, suchen Sie zuerst online nach dem Paketnamen.

> **Tipp für Experten:** Die Abhängigkeitsprüfung verwendet `apt-cache depends` und `apt-cache rdepends --installed`, um sowohl Vorwärts- als auch Rückwärts-Abhängigkeiten anzuzeigen.

**Erfordert Passwort:** Ja (für Paketentfernung)

---

### 5.5 Systemüberwachung

**Zweck:** Echtzeitüberwachung von Prozessen, CPU, RAM, Festplatte und GPU.

Dieser Bildschirm hat drei Unterregisterkarten:

#### Prozesse-Registerkarte
- Zeigt alle laufenden Prozesse, gruppiert nach Anwendungsname.
- **Spalten:** App-Name, CPU%, Speicher — tippen Sie auf eine Spaltenüberschrift zum Sortieren.
- **CPU/RAM/GPU-Anzeigen** auf der rechten Seite zeigen die Echtzeitauslastung.
- **Aktionen pro Gruppe:** Alle auswählen, Alle beenden, Alle erzwingend beenden.
- **Mehrfachauswahl:** Mehrere Prozessgruppen auswählen und dann alle auf einmal beenden.
- Aktualisiert sich automatisch alle 5 Sekunden.

#### System-Registerkarte
Zeigt Hardwareinformationen in Kartenformat:
- **CPU:** Modell, Kerne, Threads, Auslastungsbalken, Taktfrequenz.
- **Speicher:** Gesamt, belegt, frei, zwischengespeichert, Swap-Auslastung.
- **Festplatte:** Gerätenamen pro Festplatte, Dateisystem, Auslastungsbalken.
- **GPU:** Modell, Treiber, Auslastungsprozent, Speicher, Temperatur (falls verfügbar).
- **Anzeigeserver:** Wayland/X11/XWayland-Erkennung, Desktop-Umgebung, wichtige Umgebungsvariablen.

#### Status-Registerkarte
Schreibgeschütztes Systemstatus-Dashboard mit vier Bereichen:
- **Kernel:** Version, Build-Informationen, THP-Modus, zswap, Governor, E/A-Scheduler.
- **Sicherheit:** AppArmor, SELinux, Secure Boot, Firewall-Status, SSH-Status, Auto-Updates.
- **Virtualisierung:** CPU-Virtualisierungsunterstützung, KVM, IOMMU, VFIO, KSM, Docker, libvirt.
- **Drucker:** CUPS-Dienststatus, installierte Drucker, Druckertreiber.

> **Tipp für Einsteiger:** Die Prozesse-Registerkarte hilft Ihnen zu finden, welche App zu viel CPU oder Speicher verwendet. Tippen Sie auf eine Prozessgruppe, um einzelne Prozesse zu sehen.

> **Tipp für Experten:** Die Status-Registerkarte bietet einen schnellen Sicherheits- und Virtualisierungsaudit. Überprüfen Sie Firewall-, SSH- und Secure Boot-Status auf einen Blick.

**Erfordert Passwort:** Nein

---

### 5.6 Festplattenanalysator

**Zweck:** Durchsuchen Sie Ihr Dateisystem, visualisieren Sie Festplattenauslastung und verwalten Sie Dateien.

**Navigation:**
- **Home / Dateisystem / Externe Festplatten:** Schnellauswahl von Basispfaden.
- **Zurück / Weiter:** Durch den Verlauf navigieren.
- **Sortieren:** Nach Größe (aufsteigend/absteigend) oder alphabetisch.
- **Mehr-Menü:** Sichtbarkeit von versteckten/Systemdateien umschalten.

**Funktionen:**
- **Kreisdiagramm:** Visualisiert die Größenverteilung der Verzeichnisse.
- **Hinweis zum ersten Scan:** Wenn eine Festplatte zum ersten Mal analysiert wird, erscheint ein informativer Hinweis, der darauf hinweist, dass die Indizierung läuft und die erste Analyse einige Zeit dauern kann.
- **Datei/Verzeichnis-Aktionen:**
  - **In Papierkorb verschieben:** Sicheres Löschen in den Papierkorb (mit Bestätigung).
  - **Umbenennen:** Dateien oder Verzeichnisse umbenennen.
  - **Details anzeigen:** Pfad, Größe, Typ, Berechtigungen, Besitzer, Änderungsdatum anzeigen.

> **Warnung:** Das Löschen von Dateien aus dem Root-Dateisystem (`/`) erfordert Administratorrechte und ist unumkehrbar. Seien Sie sehr vorsichtig.

> **Tipp für Einsteiger:** Beginnen Sie mit der Analyse Ihres Home-Verzeichnisses, um große Ordner zu finden, die Speicherplatz belegen (z. B. `~/.cache`, `~/.local/share/Trash`).

**Erfordert Passwort:** Ja (für das Löschen aus Root-Pfaden)

---

### 5.7 SMART-Festplattengesundheit

**Zweck:** Überwachung der Gesundheit von Festplatten und SSDs mithilfe von S.M.A.R.T.-Daten.

**Funktionen:**
- **Festplattenauswahl:** Wählen Sie im Dropdown-Menü aus, welche Festplatte überprüft werden soll.
- **Gesundheitsstatus:** Zeigt BESTANDEN oder FEHLGESCHLAGEN mit Temperatur und Betriebsstunden.
- **USB-Erkennung:** Identifiziert USB-verbundene Laufwerke und warnt, dass USB-zu-SATA-Brücken SMART-Daten einschränken können.
- **Attribute-Tabelle:** Zeigt alle SMART-Attribute (ID, Name, Wert, Schlechtester, Schwellenwert, Rohwert). Fehlgeschlagene Attribute werden rot hervorgehoben.
- **Selbsttests:**
  - **Kurztest:** Schneller Scan (~2 Minuten).
  - **Erweiterter Test:** Gründlicher Scan (kann je nach Festplattengesinde mehrere Stunden dauern).
  Die Ergebnisse erscheinen in der Attributtabelle nach Abschluss des Tests.

**Wenn smartctl nicht installiert ist:** Die Anwendung bietet an, `smartmontools` automatisch zu installieren.

> **Tipp für Einsteiger:** Überprüfen Sie monatlich den Zustand Ihrer Festplatte. Ein „FEHLGESCHLAGEN"-Status oder rot markierte Attribute deuten darauf hin, dass die Festplatte möglicherweise bald ausgetauscht werden muss.

> **Tipp für Experten:** Die Anwendung unterstützt Multi-Distro-Scanning (lsblk + smartctl --scan + /sys/block/-Fallback). USB-SATA-Brücken werden mit `smartctl -d sat` getestet.

**Erfordert Passwort:** Ja (für die Installation von smartctl und das Ausführen von Selbsttests)

---

### 5.8 Geräteverwaltung

**Zweck:** Hardwaregeräte anzeigen, aktivieren und deaktivieren — ähnlich der Windows-Geräteverwaltung.

**Funktionen:**
- **Gerätebaum:** Alle Hardwaregeräte (PCI, USB, Block, Netzwerk) gruppiert nach Kategorie: Grafikkarten, Netzwerkkarten, Sound/Video, USB-Controller, Speicher, Prozessor, Eingabegeräte, Multimedia.
- **Suchleiste:** Geräte nach Name oder Beschreibung filtern.
- **Deaktivierte anzeigen-Filter:** Umschalten, um nur deaktivierte Geräte anzuzeigen.

**Aktionen pro Gerät (antippen zum Erweitern, dann Dreipunkte-Menü):**
- **Aktivieren/Deaktivieren:** Gerätestatus umschalten mit Bestätigungsdialog. Erfordert sudo-Passwort.
- **Eigenschaften-Bereich:** Zeigt detaillierte Informationen — Status, Bus-Typ, Hersteller, Treiber, Hersteller/Geräte-IDs.

**Geräteschutz:** Kritische Geräte (Host-Bridge, PCI-Bridge, ISA-Bridge, IOMMU, SMBus, Prozessor) können nicht deaktiviert werden, um Systeminstabilität zu verhindern.

**Beständigkeit:** Deaktivierte Geräte werden in `/etc/slu_disabled_devices.conf` gespeichert und ein systemd-Dienst wird erstellt, um die Deaktivierung bei jedem Systemstart erneut anzuwenden. Dies stellt sicher, dass Ihre Einstellungen Neustarts überdauern.

> **Warnung für Einsteiger:** Deaktivieren Sie keine Geräte, die Sie nicht erkennen. Das Deaktivieren einer Netzwerkkarte trennt Sie vom Internet. Das Deaktivieren einer Grafikkarte kann Ihren Desktop zum Absturz bringen.

> **Tipp für Experten:** Der Beständigkeitsmechanismus verwendet sysfs (`echo 0 > enable` für PCI, `echo 0 > authorized` für USB, `ip link set X down` für Netzwerk) mit einem systemd-Dienst.

**Erfordert Passwort:** Ja (für Aktivieren/Deaktivieren)

---

### 5.9 Wiederherstellung

**Zweck:** Veränderte Systemfunktionen wiederherstellen, nach Updates suchen und Software installieren.

#### Wiederherstellungsvorgänge
| Vorgang | Beschreibung |
|---------|-------------|
| **Pipewire neu starten** | Startet PipeWire, PipeWire-Pulse und Wireplumber neu, um Audio-Probleme zu beheben. |
| **Netzwerk wiederherstellen** | Startet NetworkManager oder systemd-networkd neu, um Verbindungsprobleme zu beheben. |
| **GRUB neu aufbauen** | Führt `update-grub` aus, um die Bootloader-Konfiguration neu zu generieren. |
| **Flathub wiederherstellen** | Fügt die Flathub-Remote für Flatpak erneut hinzu. |
| **Repositorys wiederherstellen** | Aktualisiert und stellt Paket-Repositorys für Ihre Distribution wieder her. |
| **WiFi-Automatic-Suspend deaktivieren** | Deaktiviert USB-Automatic-Suspend für WLAN-Adapter, um zufällige Trennungen zu verhindern. |

Jeder Vorgang zeigt eine Schaltfläche „Ausgabe ansehen" an, um die Befehlsausgabe zu überprüfen.

#### Updates prüfen-Registerkarte
- **Nach Updates suchen:** Führt den entsprechenden Paketmanager-Update-Befehl aus (`apt update`, `dnf check-update`, `pacman -Sy`).
- Die Ergebnisse zeigen verfügbare Updates pro Paketmanager (APT, DNF, Pacman, Snap, Flatpak).
- **Updates anwenden:** Lädt alle verfügbaren Updates herunter und installiert sie mit Echtzeitfortschritt.

#### Software-Installer-Registerkarte
Ein-Klick-Installer für wichtige Software:
- **FFmpeg:** Multimedia-Framework zum Kodieren/Dekodieren von Audio und Video.
- **yt-dlp:** Video-Downloader, der viele Websites unterstützt.
- **Systembibliotheken:** Wichtige Systembibliotheken, die möglicherweise fehlen.
- **Codecs:** Video- und Audio-Codecs für gängige Formate.
- **rsync:** Effizientes Dateisynchronisations- und Übertragungswerkzeug.

**Erfordert Passwort:** Ja

---

### 5.10 Optimierungen

**Zweck:** Systemleistungs-Optimierung für Swap und DaVinci Resolve.

#### Swap-Registerkarte
- Zeigt aktuelle Swap-Informationen: RAM-Größe, Swap Gesamt/Belegt, Swappiness-Wert, Swap-Gerät.
- Bietet Empfehlungen basierend auf Ihrer Konfiguration:
  - Eine Swap-Datei erstellen, falls keine vorhanden ist.
  - Swappiness-Wert anpassen.
  - zram aktivieren oder deaktivieren.
- Jede Empfehlung hat eine „Ausführen"-Schaltfläche, die die vorgeschlagene Änderung anwendet.

#### DaVinci Resolve-Registerkarte
- Wendet gängige Linux-Korrekturen für Blackmagic DaVinci Resolve an:
  - CUDA-Bibliothekspfade korrigieren.
  - Korrekte GPU-Berechtigungen setzen.
  - Fehlende Abhängigkeiten installieren.
- Jede Korrektur zeigt an, ob ein Neustart erforderlich ist und ob sie bereits angewendet wurde.

> **Tipp für Einsteiger:** Wenn Sie DaVinci Resolve unter Linux verwenden und GPU-Probleme haben, gehen Sie zu dieser Registerkarte und wenden Sie alle Korrekturen an.

> **Tipp für Experten:** Die Swap-Empfehlungen analysieren Ihre `/proc/meminfo`- und Swap-Konfiguration, um die am besten geeigneten Vorschläge zu bieten.

**Erfordert Passwort:** Ja

---

### 5.11 Einstellungen

Konfigurieren Sie anwendungsweite Einstellungen:

#### Passwort
- Speichern, aktualisieren oder löschen Sie Ihr Administrator-Passwort.
- Das Passwort wird mit dem Systemschlüsselbund gespeichert (base64-kodiert in SharedPreferences).

#### Sprache
- Wählen Sie aus 6 Sprachen: Italienisch, Englisch, Französisch, Spanisch, Deutsch, Portugiesisch.
- Änderungen werden wirksam, nachdem Sie die Anwendung neu gestartet haben.

#### Design
- **Hell / Dunkel / System:** Wählen Sie das Farbschema der Anwendung.
- „System" folgt der Design-Einstellung Ihrer Desktop-Umgebung.

#### Schriftart
- **Schriftfamilie:** Wählen Sie aus verfügbaren Systemschriften.
- **Schriftgröße:** Schieberegler von 10sp bis 24sp.

#### Systemabschlussleiste (nur Linux)
- **Systemabschlussleiste aktivieren:** App-Symbol in der Systemabschlussleiste anzeigen/ausblenden.
- **Beim Schließen in Abschlussleiste:** Hält die Anwendung am Laufen, wenn Sie das Fenster schließen.
- **Minimiert starten:** Startet die Anwendung minimiert in der Abschlussleiste.
- **Beim Anmelden starten:** Startet die Anwendung automatisch beim Anmelden (verwendet XDG-Autostart).
- **Abhängigkeiten installieren:** Installiert `libayatana-appindicator`, falls fehlend.

#### Automatische Update-Prüfung
- Legen Sie fest, wie oft die Anwendung nach Systemupdates sucht (Nie, 15 Min., 30 Min., 1 Std., 6 Std., 12 Std., täglich).
- **Auto-Update von GitHub:** Lädt automatisch die neueste `.deb` von GitHub-Releases herunter und installiert sie.

#### RAM-Bereinigung
- Legen Sie ein automatisches Intervall für das Leeren des Linux-Seitencache und RAM fest: **Nie**, **5 Minuten**, **10 Minuten**, **15 Minuten**, **30 Minuten**.
- Läuft im Hintergrund im konfigurierten Intervall.

#### Herunterfahren-Planer
- Öffnet den Bildschirm für den automatischen Herunterfahr-Timer (siehe Abschnitt 7).

---

### 5.12 Info

**Zweck:** Info-Bildschirm mit App-Informationen.

- App-Version, Ersteller und Beschreibung.
- Funktionsliste, organisiert nach Kategorie.
- Lizenz und Haftungsausschluss (GPL).
- **Lizenz aktivieren-Schaltfläche** (nur Erweiterte Version): Geben Sie Ihren Lizenzschlüssel ein, um erweiterte Funktionen freizuschalten.
- **PayPal-Schaltfläche** (nur Erweiterte Version): Kaufen Sie eine Lizenz für 19,99 EUR.
- Link zur Projektwebsite.

---

## 6. Erweiterter Modus — Zusätzliche Funktionen

Der erweiterte Modus schaltet 2 zusätzliche Registerkarten frei und erweitert den vorhandenen Optimierungs-Bildschirm. Erfordert einen gekauften Lizenzschlüssel (oder eine Persönliche/Test-Version).

Zum Wechseln zwischen Standard- und Erweitertem Modus verwenden Sie die Modus-Schaltflächen im oberen rechten Bereich der Seitenleiste.

---

### 6.1 GRUB-Editor

**Zweck:** Die GRUB-Bootloader-Konfiguration sicher bearbeiten.

**Funktionen:**
- **Texteditor:** Bearbeiten Sie `/etc/default/grub` direkt in einem eingebauten Texteditor.
- **Speichern und Aktualisieren:** Speichert die Konfiguration, erstellt ein automatisches Backup und führt `update-grub` aus (oder das Äquivalent für Ihre Distribution).
- **Hardware-Vorschläge:** Analysiert Ihre Hardware und schlägt Kernel-Parameter vor:
  - NVIDIA modeset, iommu, threadirqs, zswap, elevator usw.
  - Jeder Vorschlag hat eine Prioritätsmarkierung (hoch/mittel/niedrig).
  - Tippen Sie auf „Anwenden", um den Vorschlag in den Editor einzufügen.
- **Backup wiederherstellen:** Setzt auf das letzte Backup zurück, wenn etwas schiefgeht.
- **Ungespeicherte Änderungen-Indikator:** Ein orangefarbener Banner erscheint, wenn Sie ungespeicherte Änderungen haben.

**GRUB-Neuaufbau-Befehle nach Distribution:**
- Debian/Ubuntu: `update-grub`
- Fedora: `grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
- Arch: `grub-mkconfig -o /boot/grub/grub.cfg`

> **Warnung:** Falsche GRUB-Änderungen können verhindern, dass Ihr System startet. Erstellen Sie immer ein Backup. Wenn Ihr System nicht startet, verwenden Sie einen Live-USB, um `/etc/default/grub` aus dem Backup wiederherzustellen.

**Erfordert Passwort:** Ja

---

### 6.2 Benchmark

**Zweck:** Die Hardwareleistung Ihres Systems messen.

Vier Benchmark-Kategorien:

| Benchmark | Was es misst |
|-----------|-------------|
| **CPU** | Mehrkern- und Einzelkern-Verarbeitungsleistung. Ergebnisse verglichen mit Referenz-Intel-, AMD- und Apple-Chips. |
| **GPU** | Grafikleistung mit `glmark2`. Ergebnisse verglichen mit Referenz-NVIDIA- und AMD-GPUs. |
| **Festplatte** | Sequentielle Schreib-/Lesegeschwindigkeit. Ergebnisse verglichen mit NVMe-, SSD- und HDD-Referenzen. |
| **Netzwerk** | Internetgeschwindigkeitstest. Ergebnisse verglichen mit Referenz-Netzwerkgeschwindigkeiten. |

Jeder Benchmark zeigt:
- Ihren Wert.
- Die am nächsten passende Referenzhardware.
- Eine Bewertung (Ausgezeichnet, Gut, Durchschnitt, Unterdurchschnitt, Schlecht).

> **Tipp:** Führen Sie Benchmarks nach Systemänderungen durch (neuer Kernel, neue Treiber), um zu sehen, ob sich die Leistung verbessert hat.

**Erfordert Passwort:** Nein

---

## 7. Systemabschlussleiste

Wenn in den Einstellungen aktiviert, platziert Super Linux Utility ein Symbol in der Systemabschlussleiste (Benachrichtigungsbereich). Klicken Sie mit der rechten Maustaste auf das Symbol, um darauf zuzugreifen:

| Menüpunkt | Aktion |
|-----------|--------|
| **Hauptfenster anzeigen** | Bringt das Anwendungsfenster in den Vordergrund. |
| **Updates prüfen** | Öffnet den Update-Prüfungsdialog. |
| **Temporäre Dateien und Cache bereinigen** | Wechselt zur Bereinigungs-Registerkarte. |
| **CPU-, GPU-Temperatur** | Wechselt zur Überwachungs-Registerkarte. |
| **Festplattenauslastung** | Wechselt zur Festplattenanalysator-Registerkarte. |
| **Speicherauslastung** | Zeigt die aktuelle RAM-Auslastung. |
| **Festplattengesundheit (SMART)** | Wechselt zur SMART-Registerkarte. |
| **Automatisches Herunterfahren** | Öffnet den Herunterfahr-Timer-Dialog. |
| **CPU-, GPU-Auslastung** | Öffnet einen Task-Manager-Dialog. |
| **Beenden** | Schließt die Anwendung. |

Das Symbol in der Abschlussleiste zeigt Echtzeit-CPU/GPU-Temperatur und Speicherauslastung an.

---

## 8. Automatische Updates

### System-Update-Prüfung
Konfigurierbar in Einstellungen > Automatische Update-Prüfung. Wenn aktiviert, prüft die Anwendung regelmäßig auf Updates bei allen installierten Paketmanagern (APT, DNF, Pacman, Snap, Flatpak). Update-Benachrichtigungen erscheinen als Dialoge mit Häkchen pro Paket.

### App-Selbst-Update
Wenn in den Einstellungen > Auto-Update von GitHub aktiviert, prüft die Anwendung GitHub-Releases auf neuere `.deb`-Pakete, die zu Ihrer Version (Standard/Erweitert) passen. Lädt automatisch herunter und installiert sie mit `sudo dpkg -i`.

---

## 9. Fehlerbehebung

### „Passwort nicht gespeichert" Fehler
Gehen Sie zu Einstellungen > Passwort und geben Sie Ihr sudo-Passwort erneut ein. Das Passwort wird im Systemschlüsselbund gespeichert.

### SMART-Registerkarte zeigt keine Festplatten
Installieren Sie `smartmontools`: Die Anwendung bietet an, dies automatisch zu tun. Wenn Sie einen USB-SATA-Adapter verwenden, sind SMART-Daten möglicherweise eingeschränkt.

### GRUB-Änderungen nicht angewendet (Erweiterter Modus)
Stellen Sie sicher, dass Sie „Speichern und Aktualisieren" getippt haben (nicht nur „Speichern"). Die Anwendung muss `update-grub` mit Administratorrechten ausführen.

### Symbol in der Systemabschlussleiste nicht sichtbar
Installieren Sie die erforderliche Abhängigkeit: `sudo apt install libayatana-appindicator-3-dev`. Starten Sie dann die Anwendung neu.

### AppImage startet nicht
Das AppImage verwendet eine statische Laufzeitumgebung und sollte ohne FUSE funktionieren. Wenn es dennoch fehlschlägt:
```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./super-linux-utility-*.AppImage
```

### Geräteverwaltung kann Gerät nicht deaktivieren
Einige Geräte sind geschützt, da das Deaktivieren das System zum Absturz bringen würde. Die Anwendung zeigt eine Meldung, wenn ein Gerät nicht deaktiviert werden kann.

---

## 10. Häufig gestellte Fragen

**F: Ist es sicher, diese Anwendung zu verwenden?**
A: Funktionen des Standardmodus sind für alle Benutzer sicher. Der Erweiterte Modus ändert GRUB — erstellen Sie immer ein Backup, bevor Sie GRUB-Funktionen verwenden.

**F: Sendet die Anwendung irgendwohin Daten?**
A: Nein. Die Anwendung erhebt oder übermittelt keine Benutzerdaten. Die einzigen Netzwerkoperationen sind die Update-Prüfung (von GitHub oder Ihrem Paketmanager).

**F: Kann ich die Anwendung unter Fedora/Arch verwenden?**
A: Ja. Die Anwendung erkennt Ihre Distribution automatisch und passt alle Befehle entsprechend an (APT, DNF, Pacman).

**F: Was passiert, wenn ich einen kritischen Dienst deaktiviere?**
A: Die Anwendung schützt wichtige Desktop-Umgebungs-Dienste (GNOME, KDE usw.) vor dem Deaktivieren. Seien Sie jedoch immer vorsichtig mit unbekannten Diensten.

**F: Wie stelle ich GRUB wieder her, wenn das System nicht startet?**
A: Booten Sie von einem Live-USB, mounten Sie Ihre Root-Partition und kopieren Sie `/etc/default/grub.backup` zurück nach `/etc/default/grub`. Führen Sie dann `sudo update-grub` aus.

**F: Kann ich jedes Hardwaregerät deaktivieren?**
A: Die Geräteverwaltung schützt kritische Systemgeräte (CPU, Bridges, IOMMU) vor dem Deaktivieren. Sie können sicher nicht-essentielle Peripheriegeräte wie USB-Geräte oder sekundäre Netzwerkkarten deaktivieren.

---

## 11. Glossar

| Begriff | Definition |
|---------|-----------|
| **APT** | Advanced Package Tool — Paketmanager für Debian/Ubuntu. |
| **Geräteverwaltung** | Werkzeug zum Anzeigen, Aktivieren und Deaktivieren von Hardwaregeräten. |
| **DNF** | Dandified YUM — Paketmanager für Fedora/RHEL. |
| **Flatpak** | Sandboxiertes Anwendungspaketierungsformat für Linux. |
| **GRUB** | Grand Unified Bootloader — das Programm, das Linux beim Start lädt. |
| **Kernel** | Der Kern des Linux-Betriebssystems. |
| **PCI** | Peripheral Component Interconnect — Standardbus für interne Geräte. |
| **Pacman** | Paketmanager für Arch Linux und Ableger. |
| **PipeWire** | Moderner Linux-Audio/Video-Server. |
| **SMART** | Self-Monitoring, Analysis and Reporting Technology — Festplattengesundheitssystem. |
| **Snap** | Universelles Linux-Paketformat von Canonical. |
| **systemd** | Init-System und Dienstmanager für Linux. |
| **systemctl** | Kommandozeilenwerkzeug zum Verwalten von systemd-Diensten. |
| **Swap** | Festplattenspeicher, der als virtueller RAM verwendet wird, wenn der physische RAM voll ist. |
| **sysfs** | Virtuelles Dateisystem, das Kernel-Gerätedaten bereitstellt (`/sys/`). |
| **USB** | Universal Serial Bus — Standard für externe Geräte. |
| **Wayland** | Modernes Anzeigeserver-Protokoll, das X11 ersetzt. |
| **X11** | Traditionelles Anzeigeserver-Protokoll für Linux. |
| **zram** | Komprimiertes, RAM-basiertes Swap-Gerät. |

---

*Super Linux Utility v2.0.6 — Benutzerhandbuch*
*Erstellt von Marco Di Giangiacomo*
*Lizenz: GPL v3*
