# Installazione Icone Super Linux Utility

Questo documento spiega come installare le icone dell'applicazione Super Linux Utility per renderle visibili in tutti i Desktop Environment (GNOME, KDE, XFCE, ecc.).

## Icone Generate

L'applicazione include un'icona 3D moderna che rappresenta un ingranaggio con una chiave inglese sovrapposta, in stile blu con effetti di profondità e ombre.

### Formati Disponibili

- **SVG**: `linux/runner/assets/icon.svg` - Versione vettoriale scalabile
- **PNG**: Versioni rasterizzate in tutte le dimensioni standard:
  - 16x16, 24x24, 32x32, 48x48, 64x64, 128x128, 256x256, 512x512 pixel

## Installazione Automatica

### Durante l'installazione del pacchetto .deb

Le icone vengono installate automaticamente quando installi il pacchetto `.deb` dell'applicazione. Lo script `postinst` si occupa di:

1. Installare le icone in `/usr/share/icons/hicolor/` (standard XDG)
2. Installare le icone in `/usr/share/pixmaps/` (legacy)
3. Aggiornare le cache delle icone per GNOME e KDE

### Installazione Manuale

Se hai compilato l'applicazione manualmente o vuoi reinstallare le icone:

```bash
sudo ./install_icons.sh
```

Questo script installerà le icone in tutte le directory appropriate e aggiornerà le cache.

## Installazione Manuale Dettagliata

### 1. Installa nelle directory hicolor (standard XDG)

Le directory hicolor sono lo standard XDG e funzionano con tutti i Desktop Environment:

```bash
# Crea le directory se non esistono
sudo mkdir -p /usr/share/icons/hicolor/{16x16,24x24,32x32,48x48,64x64,128x128,256x256,512x512,scalable}/apps

# Copia le icone PNG
sudo cp linux/runner/assets/icon_16.png /usr/share/icons/hicolor/16x16/apps/super-linux-utility.png
sudo cp linux/runner/assets/icon_24.png /usr/share/icons/hicolor/24x24/apps/super-linux-utility.png
sudo cp linux/runner/assets/icon_32.png /usr/share/icons/hicolor/32x32/apps/super-linux-utility.png
sudo cp linux/runner/assets/icon_48.png /usr/share/icons/hicolor/48x48/apps/super-linux-utility.png
sudo cp linux/runner/assets/icon_64.png /usr/share/icons/hicolor/64x64/apps/super-linux-utility.png
sudo cp linux/runner/assets/icon_128.png /usr/share/icons/hicolor/128x128/apps/super-linux-utility.png
sudo cp linux/runner/assets/icon_256.png /usr/share/icons/hicolor/256x256/apps/super-linux-utility.png
sudo cp linux/runner/assets/icon_512.png /usr/share/icons/hicolor/512x512/apps/super-linux-utility.png

# Copia l'icona SVG scalabile
sudo cp linux/runner/assets/icon.svg /usr/share/icons/hicolor/scalable/apps/super-linux-utility.svg
```

### 2. Installa in pixmaps (legacy, per compatibilità)

```bash
sudo cp linux/runner/assets/icon_48.png /usr/share/pixmaps/super-linux-utility.png
sudo cp linux/runner/assets/icon.svg /usr/share/pixmaps/super-linux-utility.svg
```

### 3. Aggiorna le cache delle icone

#### Per GNOME e GTK-based DE:
```bash
sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor
```

#### Per KDE Plasma:
```bash
# KDE 4
kbuildsycoca4

# KDE 5
kbuildsycoca5

# KDE 6 (Plasma 6)
kbuildsycoca6
```

#### Per XFCE:
```bash
xfce4-panel --restart
```

### 4. Aggiorna il database delle applicazioni desktop

```bash
sudo update-desktop-database /usr/share/applications
```

## Verifica Installazione

Dopo l'installazione, verifica che le icone siano visibili:

1. **GNOME**: Cerca "Super Linux Utility" nel menu delle applicazioni
2. **KDE**: Cerca "Super Linux Utility" nel menu K
3. **XFCE**: Cerca "Super Linux Utility" nel menu applicazioni

Se l'icona non appare, prova a:
- Riavviare il desktop environment
- Eseguire nuovamente gli script di aggiornamento cache
- Verificare che il file `.desktop` punti correttamente all'icona

## Struttura Directory

Le icone vengono installate in:

```
/usr/share/icons/hicolor/
├── 16x16/apps/super-linux-utility.png
├── 24x24/apps/super-linux-utility.png
├── 32x32/apps/super-linux-utility.png
├── 48x48/apps/super-linux-utility.png
├── 64x64/apps/super-linux-utility.png
├── 128x128/apps/super-linux-utility.png
├── 256x256/apps/super-linux-utility.png
├── 512x512/apps/super-linux-utility.png
└── scalable/apps/super-linux-utility.svg

/usr/share/pixmaps/
├── super-linux-utility.png
└── super-linux-utility.svg
```

## Rimozione Icone

Per rimuovere le icone installate:

```bash
# Rimuovi dalle directory hicolor
sudo rm -rf /usr/share/icons/hicolor/*/apps/super-linux-utility.png
sudo rm -rf /usr/share/icons/hicolor/scalable/apps/super-linux-utility.svg

# Rimuovi da pixmaps
sudo rm /usr/share/pixmaps/super-linux-utility.png
sudo rm /usr/share/pixmaps/super-linux-utility.svg

# Aggiorna le cache
sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor
```

## Supporto Desktop Environment

Le icone sono compatibili con:
- ✅ GNOME (e derivate: Ubuntu, Fedora GNOME, etc.)
- ✅ KDE Plasma (4, 5, 6)
- ✅ XFCE
- ✅ MATE
- ✅ Cinnamon
- ✅ LXDE/LXQt
- ✅ Altri DE compatibili con XDG Icon Theme Specification

## Note Tecniche

- Le icone seguono lo standard [XDG Icon Theme Specification](https://specifications.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html)
- L'icona SVG è vettoriale e si scala perfettamente a qualsiasi dimensione
- Le icone PNG sono ottimizzate per ogni dimensione specifica
- L'icona utilizza effetti 3D con gradienti, ombre e profondità per un aspetto moderno

