# Super Linux Utility

A full-featured system manager for Linux. Manage systemd services, startup apps, temp cleanup, installed packages (APT, Snap, Flatpak), monitor CPU/RAM/disks, analyze disk usage, and customize appearance. Free standard edition; paid advanced edition adds GRUB editor, kernel management, and recovery tools.

**Project website:** [https://github.com/sviluppoarte1-lang/superlinuxutility](https://github.com/sviluppoarte1-lang/superlinuxutility)

---

## Overview

Super Linux Utility is a complete Flutter application for advanced Linux/Ubuntu system management and optimization. It provides powerful tools to improve performance, manage services and applications, and customize the system. The application is designed for expert users who need fine-grained control over their system.

### Editions

- **Standard (free):** Core features: services, startup apps, cleanup, installed apps, system monitor, disk analyzer, appearance customization.
- **Advanced (paid):** Same as standard plus GRUB editor, kernel management, and system recovery tools. License activation required.
- **Personal/Test:** Full advanced functionality for personal or testing use, without license requirement. Not for distribution.

This software is distributed under the **GPL-3.0 or later** license.

---

## Features

### Systemd services

- Scan and analyze all systemd services on the system.
- Identify services that slow down boot (startup time &gt; 2 seconds).
- View detailed information for each service (status, startup time, description).
- Enable, disable, stop, or restart services.
- List disabled services for easy re-enabling.

### Startup applications

- Scan applications configured to start automatically.
- Search in `~/.config/autostart` and `/etc/xdg/autostart`.
- Enable, disable, or remove startup entries.
- Clear view of enabled vs disabled apps.
- Optional process termination when disabling an app.
- Protection for critical system applications.

### Temporary files and cache cleanup

- Calculate space used by temporary files.
- Automatic detection of common app temp/cache locations:
  - Browsers (Chrome, Firefox, Edge, Opera, Brave)
  - Editors (VS Code, Atom, Sublime Text)
  - Development (npm, pip, cargo, gradle, maven)
  - System (APT cache, Snap, Flatpak)
  - Media (VLC, Spotify)
- Delete temporary files from standard and app-specific folders.
- Trash and cache cleanup.

### Installed applications

- View applications installed via:
  - APT (Debian/Ubuntu packages)
  - Snap
  - Flatpak
  - GNOME (desktop applications)
- Dependency checks before removal.
- Warnings for system packages and shared dependencies.
- Filters by package manager and search.

### System monitor

- **Processes:** Full list of active processes with CPU %, memory, and disk usage; sort by CPU or memory (ascending/descending); terminate processes (normal or force); search.
- **System information:** CPU (model, cores, threads, usage); memory (total, used, free, cache, swap); disks (internal and external with usage); GPU (model, driver, temperature when available).

### Disk analyzer

- Analyze disk usage by directory and file type.
- Visualize space usage; identify large files and folders.
- Cache of scan results for faster navigation.

### Appearance (GNOME)

- Fonts: interface, document, and monospace with previews.
- Rendering: hinting, antialiasing, scale factor.
- Themes: cursor, icons, legacy apps with previews.
- Wallpaper: set backgrounds for light and dark theme.
- Window behavior: click actions, title bar buttons, focus.

### GRUB editor (Advanced)

- Edit `/etc/default/grub` with built-in editor.
- Automatic backups before changes.
- Apply changes and update bootloader.
- Restore from previous backup.

### Kernel management (Advanced)

- List installed kernels with version and size.
- Remove old kernels safely (current kernel protected).
- Set default kernel to boot.
- Automatic cleanup: keep only a chosen number of recent kernels.

### System recovery (Advanced)

- Restore systemd default targets, GRUB, network, Flatpak/Flathub, and package manager repositories.
- One-click restoration for common misconfigurations.

### Security and password

- Store administrator password securely (e.g. system keyring when available).
- Automatic use for commands requiring sudo.
- Dedicated settings screen to manage or clear stored password.

### System tray (Linux)

- Optional system tray icon with quick actions: check updates, cleanup, CPU/GPU temp, disk usage, task manager (processes), shutdown timer, show main window, exit.
- Close to tray and start minimized options when supported.

### Other

- Shutdown timer: schedule automatic shutdown via systemd timers.
- Check for system updates from the tray or UI.
- Multi-language support (e.g. Italian, English, French, Spanish, German, Portuguese).
- Light/dark/system theme.

---

## Requirements

- Ubuntu 20.04+ or other systemd-based Linux distributions.
- Administrator (sudo) privileges for some operations.

### Linux dependencies (when running from build/bundle)

If you run the app from `build/linux/x64/release/bundle` (without using the .deb package), some distributions may lack the library for the **system tray** (notification area icon).

- **Fedora / RHEL** (e.g. error `libayatana-appindicator3.so.1: cannot open shared object file`):
  ```bash
  sudo dnf install libayatana-appindicator-gtk3
  ```
  On **Fedora** (e.g. 42) with KDE/GNOME, the system tray can cause a segmentation fault due to plugin incompatibility with libayatana. The app **automatically disables the tray on Fedora**; it runs without the tray icon and all other features work.
- **Debian / Ubuntu** (if not using the .deb):
  ```bash
  sudo apt install libayatana-appindicator3-1
  ```
- **Arch Linux**:
  ```bash
  sudo pacman -S libayatana-appindicator
  ```

To disable the system tray on any distribution (e.g. to avoid crashes), run with:
`SUPER_LINUX_UTILITY_NO_TRAY=1 ./super_linux_utility`.

After installing the dependency where needed, run `./super_linux_utility` again from the bundle directory.

---

## Installation

### Install the .deb package

Download the appropriate `.deb` from the [Releases](https://github.com/sviluppoarte1-lang/superlinuxutility/releases) page, then:

```bash
sudo dpkg -i super_linux_utility_*.deb
```

If there are missing dependencies:

```bash
sudo apt-get install -f
```

---

## Usage

1. **Initial setup:** Go to the **Settings** tab and save the administrator password if you want to use features that require sudo.
2. **Services:** Use the **Services** tab to find and manage services that slow down boot.
3. **Startup apps:** Use the **Startup Apps** tab to view and manage applications that start automatically.
4. **Cleanup:** Use the **Cleanup** tab to see space used by temp/cache and run cleanup.
5. **Installed apps:** Use the **Installed Apps** tab to view and remove applications.
6. **Monitor:** Use the **Monitor** tab to view running processes and system information (CPU, RAM, disks, GPU).
7. **Disk analyzer:** Use the **Disk Analyzer** tab to inspect disk usage by folder and file type.
8. **Appearance:** Use the **Appearance** tab to customize fonts, themes, and wallpaper (GNOME).
9. **GRUB / Kernel / Recovery:** In the Advanced (or Personal) edition, use the corresponding tabs for boot and kernel management and system recovery.

---

## Security notes

- The password is stored using the available secure mechanism (e.g. system keyring when supported).
- The password is used only when needed for commands that require administrator privileges.
- Use with care: disabling critical services or startup apps, editing GRUB, or removing kernels can affect system stability or bootability. Creating backups is recommended.

---

## License

This project is provided "as is" without warranty. It is distributed under the **GPL-3.0 or later** license. See the [LICENSE](LICENSE) file for details.
