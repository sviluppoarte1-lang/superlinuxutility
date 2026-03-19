# Super Linux Utility

**One app to manage, monitor, and optimize your Linux system.**

Super Linux Utility is a modern, easy-to-use desktop application that puts system management in one place: services, startup apps, cleanup, installed packages, resource monitoring, and disk analysis. No need to jump between terminal and different tools—everything is in a single, clear interface.

---

## Why Super Linux Utility?

- **All-in-one** — Services, startup apps, cleanup, installed apps (APT, Snap, Flatpak), system monitor, and disk analyzer in one window.
- **Safe and clear** — See what’s running, what starts at boot, and what can be cleaned before you change anything.
- **Two editions** — Use the **free Standard** edition for everyday tasks, or unlock the **Advanced** edition for GRUB, kernel, and recovery tools.
- **Built for Linux** — Designed for systemd-based distributions (Ubuntu, Debian, Fedora, etc.) with a native feel.

---

## Features at a glance

| Area | What you can do |
|------|------------------|
| **Services** | View and manage systemd services, spot slow boot services, enable/disable/restart them. |
| **Startup apps** | See what runs at login, enable or disable startup entries, keep system apps protected. |
| **Cleanup** | Find and remove temp files from browsers, editors, dev tools, and system caches (APT, Snap, Flatpak). |
| **Installed apps** | List apps from APT, Snap, Flatpak, and GNOME; check dependencies before removing. |
| **Monitor** | Live view of CPU, RAM, disks, and GPU; process list with search and kill. |
| **Disk analyzer** | See where space is used and manage large or old files. |
| **Appearance** | Adjust fonts, themes, and system look (where supported). |
| **Advanced (paid)** | GRUB editor with backup, kernel management, and system recovery tools. |

---

## Two editions

- **Standard (free)** — Services, startup apps, cleanup, installed apps, monitor, disk analyzer, settings, and info. Ideal for most users.
- **Advanced (paid)** — Everything in Standard plus GRUB editor, kernel management, and system recovery. Unlock via license from the app (Info or “Activate / Premium”).

---

## System requirements

- **OS:** Linux with systemd (e.g. Ubuntu 20.04+, Debian, Fedora, openSUSE).
- **Architecture:** x86_64 (amd64).
- **Dependencies:** GTK 3, glib2, standard desktop libraries (usually already installed).

---

## Installation

Choose one of the options below.

### Option 1: Install from .deb (recommended for Ubuntu / Debian)

1. Open the [Releases](https://github.com/sviluppoarte1-lang/superlinuxutility/releases) page.
2. Download the right package:
   - **Standard (free):** `super-linux-utility_1.8.6_amd64.deb`
   - **Advanced (paid):** `super-linux-utility-advanced_1.8.6_amd64.deb`
3. Install (replace the filename if you chose the other package):

   ```bash
   sudo dpkg -i super-linux-utility_1.8.6_amd64.deb
   ```

   If you see dependency errors:

   ```bash
   sudo apt-get install -f
   ```

4. Start **Super Linux Utility** from your application menu.

---

### Option 2: Install from Flatpak (Flathub)

When the app is available on Flathub:

1. Enable Flathub if you haven’t already: [flathub.org/setup](https://flathub.org/setup).
2. Install:

   ```bash
   flatpak install flathub io.github.marcodigiangiacomo.SuperLinuxUtility
   ```

3. Run:

   ```bash
   flatpak run io.github.marcodigiangiacomo.SuperLinuxUtility
   ```

---

### Option 3: Build from source

If you prefer to compile yourself:

1. Clone the repository:

   ```bash
   git clone https://github.com/sviluppoarte1-lang/superlinuxutility.git
   cd superlinuxutility
   ```

2. Install [Flutter](https://flutter.dev/docs/get-started/install/linux) for Linux.
3. Get dependencies and run:

   ```bash
   flutter pub get
   flutter run -d linux
   ```

   For a release build:

   ```bash
   flutter build linux --release
   ```

   The executable will be in `build/linux/x64/release/bundle/`.

---

## First steps after installation

1. **Launch** Super Linux Utility from your app menu.
2. **Language & theme** — Choose your language and accept the warning if shown (the app can change system settings).
3. **Password (optional)** — When you first use a feature that needs admin rights, you can store your sudo password securely so you don’t have to type it every time.
4. **Explore** — Use the tabs to open Services, Startup apps, Cleanup, Installed apps, Monitor, and Disk analyzer. The **Settings** and **Info** tabs are at the end.
5. **Advanced edition** — If you have a license, open **Info** or click **Activate / Premium** in the app bar to unlock GRUB, Kernel, and Recovery.

---

## Getting help

- **Bugs and ideas:** [Open an issue](https://github.com/sviluppoarte1-lang/superlinuxutility/issues) on GitHub.
- **Releases and downloads:** [Releases](https://github.com/sviluppoarte1-lang/superlinuxutility/releases).
- **Source code:** [GitHub repository](https://github.com/sviluppoarte1-lang/superlinuxutility).

---

## License and credits

- **License:** GPL-3.0-or-later. See the repository or your installation for the full license text.
- **Author:** Marco Di Giangiacomo.

Thank you for using Super Linux Utility. If you find it useful, a star on GitHub is always appreciated.
