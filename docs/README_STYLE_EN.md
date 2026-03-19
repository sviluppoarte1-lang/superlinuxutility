# Super Linux Utility

[![License: GPL-3.0-or-later](https://img.shields.io/badge/License-GPL%203.0-or--later-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://github.com/sviluppoarte1-lang/superlinuxutility)
[![Releases](https://img.shields.io/github/v/release/sviluppoarte1-lang/superlinuxutility?include_prereleases&label=Release)](https://github.com/sviluppoarte1-lang/superlinuxutility/releases)

**One app to manage, monitor, and optimize your Linux system.**

Super Linux Utility brings systemd services, startup apps, cleanup, installed packages (APT, Snap, Flatpak), system monitoring, and disk analysis into a single, easy-to-use desktop application. No more hopping between terminal and multiple tools—everything you need is in one place.

---

## ✨ Features

- **Services** — View and manage systemd services, find what slows down boot, enable/disable/restart safely.
- **Startup apps** — See what runs at login; enable or disable entries with protection for system apps.
- **Cleanup** — Remove temp files from browsers, editors, dev tools, and system caches (APT, Snap, Flatpak).
- **Installed apps** — List and manage apps from APT, Snap, Flatpak, and GNOME with dependency checks.
- **Monitor** — Live CPU, RAM, disk, and GPU usage; process list with search and terminate.
- **Disk analyzer** — See where space is used and manage large or old files.
- **Appearance** — Customize fonts and system look (where supported).
- **Advanced edition (paid)** — GRUB editor with backup, kernel management, and system recovery.

**Two editions:** Free **Standard** (all of the above except GRUB/Kernel/Recovery) and paid **Advanced** (full feature set). Unlock Advanced from the app via **Info** or **Activate / Premium**.

---

## 📥 Installation

### .deb (Ubuntu / Debian)

1. Go to [**Releases**](https://github.com/sviluppoarte1-lang/superlinuxutility/releases).
2. Download:
   - **Standard (free):** `super-linux-utility_1.8.6_amd64.deb`
   - **Advanced (paid):** `super-linux-utility-advanced_1.8.6_amd64.deb`
3. Install:
   ```bash
   sudo dpkg -i super-linux-utility_1.8.6_amd64.deb
   sudo apt-get install -f   # if you see dependency errors
   ```
4. Launch **Super Linux Utility** from your application menu.

### Flatpak (when available on Flathub)

```bash
flatpak install flathub io.github.marcodigiangiacomo.SuperLinuxUtility
flatpak run io.github.marcodigiangiacomo.SuperLinuxUtility
```

### From source

```bash
git clone https://github.com/sviluppoarte1-lang/superlinuxutility.git
cd superlinuxutility
flutter pub get
flutter run -d linux
```

Release build: `flutter build linux --release` → binary in `build/linux/x64/release/bundle/`.

---

## 🖥️ Requirements

- Linux with systemd (e.g. Ubuntu 20.04+, Debian, Fedora)
- x86_64 (amd64)
- GTK 3, glib2 (usually already installed)

---

## 🚀 First run

1. Start the app from your menu.
2. Choose language and accept the warning if shown.
3. Optionally set your admin password when first needed (stored securely).
4. Use the tabs: **Services**, **Startup apps**, **Cleanup**, **Installed apps**, **Monitor**, **Disk analyzer**, **Settings**, **Info**.

---

## 📄 Links

- [Releases & downloads](https://github.com/sviluppoarte1-lang/superlinuxutility/releases)
- [Report a bug or request a feature](https://github.com/sviluppoarte1-lang/superlinuxutility/issues)

---

## 📜 License

GPL-3.0-or-later. Author: **Marco Di Giangiacomo**.
