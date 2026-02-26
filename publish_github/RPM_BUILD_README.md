# Guida alla creazione del pacchetto RPM per Fedora

Questo documento spiega come creare un pacchetto RPM per Super Linux Utility su Fedora.

## Prerequisiti

Prima di eseguire lo script, assicurati di avere installati i seguenti pacchetti:

```bash
sudo dnf install rpm-build rpmdevtools desktop-file-utils
```

## Utilizzo

1. **Esegui lo script di build:**

```bash
./build_rpm.sh
```

Lo script eseguirà automaticamente:
- Pulizia delle build precedenti (`flutter clean`)
- Compilazione dell'applicazione Flutter in modalità release
- Creazione della struttura RPM necessaria
- Generazione del pacchetto RPM

2. **Il pacchetto RPM verrà creato in:**

```
~/rpmbuild/RPMS/x86_64/super-linux-utility-1.8.6-1.fc*.rpm
```

## Installazione del pacchetto

Dopo aver generato il pacchetto RPM, puoi installarlo con:

```bash
sudo dnf install ~/rpmbuild/RPMS/x86_64/super-linux-utility-1.8.6-1.fc*.rpm
```

Oppure, se preferisci usare `rpm` direttamente:

```bash
sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/super-linux-utility-1.8.6-1.fc*.rpm
```

## Verifica del pacchetto

Puoi verificare il contenuto del pacchetto prima dell'installazione:

```bash
rpm -qlp ~/rpmbuild/RPMS/x86_64/super-linux-utility-1.8.6-1.fc*.rpm
```

Per vedere le informazioni del pacchetto:

```bash
rpm -qip ~/rpmbuild/RPMS/x86_64/super-linux-utility-1.8.6-1.fc*.rpm
```

## Disinstallazione

Per rimuovere il pacchetto:

```bash
sudo dnf remove super-linux-utility
```

Oppure:

```bash
sudo rpm -e super-linux-utility
```

## Struttura del pacchetto

Il pacchetto installa i file nelle seguenti posizioni:

- `/usr/share/super-linux-utility/` - File dell'applicazione
- `/usr/bin/super-linux-utility` - Script wrapper eseguibile
- `/usr/share/applications/super-linux-utility.desktop` - File desktop entry
- `/usr/share/pixmaps/super-linux-utility.png` - Icona dell'applicazione

## Personalizzazione

Se vuoi modificare la versione o altre impostazioni, modifica le variabili all'inizio dello script `build_rpm.sh`:

```bash
APP_NAME="super-linux-utility"
APP_VERSION="1.8.6"
APP_RELEASE="1"
```

## Note

- Lo script crea automaticamente la struttura `~/rpmbuild/` se non esiste
- Il file SPEC viene generato automaticamente dallo script
- Lo script include script post-installazione e post-rimozione per aggiornare i database desktop
- Il pacchetto è configurato per architettura x86_64

## Risoluzione problemi

### Errore: "rpmbuild is not installed"
Installa i prerequisiti:
```bash
sudo dnf install rpm-build rpmdevtools
```

### Errore: "Build directory not found"
Assicurati che Flutter sia installato e che la compilazione sia completata con successo.

### Errore durante la creazione del tarball
Verifica che la directory `~/rpmbuild/SOURCES/` sia scrivibile e che ci sia spazio su disco sufficiente.

