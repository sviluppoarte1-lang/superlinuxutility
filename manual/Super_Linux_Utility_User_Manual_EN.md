# Super Linux Utility v2.0.6
# Complete User Manual — English

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [System Requirements](#2-system-requirements)
3. [Installation](#3-installation)
4. [First Launch](#4-first-launch)
5. [Standard Mode — All Features](#5-standard-mode)
   - 5.1 Services
   - 5.2 Startup Apps
   - 5.3 Cleanup
   - 5.4 Installed Apps
   - 5.5 System Monitor
   - 5.6 Disk Analyzer
   - 5.7 SMART Disk Health
   - 5.8 Device Manager
   - 5.9 Recovery
   - 5.10 Tweaks
   - 5.11 Settings
   - 5.12 Info
6. [Advanced Mode — Additional Features](#6-advanced-mode)
   - 6.1 GRUB Editor
   - 6.2 Benchmark
7. [System Tray](#7-system-tray)
8. [Automatic Updates](#8-automatic-updates)
9. [Troubleshooting](#9-troubleshooting)
10. [Frequently Asked Questions](#10-faq)
11. [Glossary](#11-glossary)

---

## 1. Introduction

**Super Linux Utility** is a comprehensive system management application for Linux. It provides a modern graphical interface to manage services, startup applications, clean temporary files, monitor system performance, analyze disks, manage hardware devices, and much more.

The app comes in two editions:

- **Standard (Free):** All essential system management tools — services, startup apps, cleanup, installed apps, monitor, disk analyzer, SMART health, device manager, recovery, tweaks, and settings.
- **Advanced (Paid):** Everything in Standard, plus GRUB editor and Benchmark suite.

**Supported distributions:** Ubuntu, Debian, Linux Mint, LMDE, Pop!_OS, Zorin, elementary, MX Linux, Fedora, RHEL, CentOS, Arch Linux, Manjaro, EndeavourOS, CachyOS, KDE neon.

**Supported desktop environments:** GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt.

---

## 2. System Requirements

- **OS:** Linux (64-bit)
- **Disk space:** ~200 MB installed
- **RAM:** 512 MB minimum, 2 GB recommended
- **Dependencies:** GTK3, GLib 2.0+
- **Optional:** `libappindicator` for system tray, `smartmontools` for SMART disk health

---

## 3. Installation

### AppImage (Recommended)
```bash
chmod +x super-linux-utility-2.0.6-x86_64.AppImage
./super-linux-utility-2.0.6-x86_64.AppImage
```

### Debian/Ubuntu (.deb)
```bash
sudo dpkg -i super-linux-utility_2.0.6_amd64.deb
sudo apt-get install -f
```

### From source
```bash
git clone https://github.com/sviluppoarte1-lang/superlinuxutility.git
cd superlinuxutility
flutter build linux
```

---

## 4. First Launch

When you open Super Linux Utility for the first time, three setup screens appear in sequence:

### 4.1 Language Selection
Choose your preferred language from: Italian, English, French, Spanish, German, Portuguese. The selected language applies to all buttons, menus, messages, and descriptions throughout the app.

### 4.2 Warning Screen
A disclaimer reminds you that this app can modify critical system configurations (GRUB bootloader, kernel, services). It is strongly recommended to create a system backup before using advanced features. Check "Don't show this warning again" to skip it on future launches.

### 4.3 Password Setup
To use features that modify the system (cleanup, service management, GRUB editing, etc.), the app needs your administrator (sudo) password. The password is stored securely using the system keyring. You can skip this step and configure it later in Settings.

> **Tip for beginners:** If you are not sure whether to enter your password, you can skip it. Most read-only features (monitor, disk analyzer, SMART) work without a password.

---

## 5. Standard Mode — All Features

Standard mode provides 12 tabs accessible from the left sidebar. Each tab contains specific tools.

---

### 5.1 Services

**Purpose:** View and manage systemd services that run on your system.

**Tabs:**
- **Slow Services:** Lists services that take more than 2 seconds to start (detected via `systemd-analyze blame`). This helps identify what slows down your boot.
- **All Services:** Full list of all systemd services with their status (active, inactive, failed). Tap "Analyze All" to load the complete list.
- **Disabled:** Shows all services that are currently disabled.

**Actions per service (tap the three-dot menu):**
- **Disable:** Prevents the service from starting at boot.
- **Re-enable:** Allows the service to start at boot again.
- **Stop:** Immediately stops a running service.

> **Warning for beginners:** Do not disable services you do not recognize. Some services are essential for your system to function correctly (e.g., NetworkManager, PulseAudio, systemd-resolved). When in doubt, leave the service enabled.

> **Tip for experts:** Use the "Slow Services" tab to optimize boot time. Services like `snapd`, `plymouth`, or `fwupd` can often be safely disabled if you do not need them.

**Requires password:** Yes (for disable/enable/stop operations)

---

### 5.2 Startup Apps

**Purpose:** Manage applications that start automatically when you log in.

The list shows all autostart entries split into **Enabled** and **Disabled** sections. Each entry displays the application name, command, and whether it is a system or user app.

**Actions per app (tap the three-dot menu):**
- **Disable:** Prevents the app from starting at login. If the app is currently running, you are asked whether to also terminate its processes.
- **Re-enable:** Re-enables a disabled startup app.
- **Terminate Processes:** Kills all running processes of that app.
- **Remove:** Permanently deletes the autostart entry.

**System app protection:** Some apps (like GNOME Shell, NetworkManager, KDE Plasma components) are marked as protected and cannot be disabled. This prevents accidental damage to your desktop environment.

> **Tip for beginners:** If you notice your computer is slow to start, check the Startup Apps tab. Disabling unnecessary apps (like cloud storage clients or chat apps you do not use at boot) can significantly speed up login.

> **Tip for experts:** The app creates user-level overrides for system autostart entries in `/etc/xdg/autostart/` instead of modifying system files. This is safe and reversible.

**Requires password:** No

---

### 5.3 Cleanup

**Purpose:** Free disk space by removing temporary files, caches, and clearing the Linux page cache.

**Button row:**
- **Refresh Dimensions:** Recalculates the size of all detected temp/cache folders.
- **Clean Temp Files (orange button):** Deletes temporary files from all listed folders. A confirmation dialog appears before deletion. You can exclude specific folders by tapping the toggle icon next to each folder.

**Linux Page Cache:**
- **Clear Cache button:** Frees the kernel page cache by running `sync && echo 1 > /proc/sys/vm/drop_caches`. This is safe and does not delete any user data — it only clears cached file reads from RAM.

**Clean RAM:**
- Shows current RAM usage (used / total / percentage).
- **Clean RAM button:** Clears page cache, dentries, and inodes by running `sync && echo 3 > /proc/sys/vm/drop_caches`. This frees more memory than the basic cache clear. Shows how much memory was freed after the operation.

**Automatic RAM Cleanup:**
- Configure in **Settings > RAM Cleanup** to automatically clear RAM at intervals: Never, 5 min, 10 min, 15 min, or 30 min.
- Runs in the background at the configured interval.

**Add Excluded Folder:** Add custom folders to exclude from cleanup. Useful for preserving cache directories of specific applications.

> **Tip for beginners:** Use "Clean Temp Files" regularly to free disk space. The "Clear Cache" and "Clean RAM" buttons are safe — they do not delete any personal files.

> **Tip for experts:** The RAM cleaner uses `echo 3` (drops page cache + dentries + inodes), which is more aggressive than `echo 1` (page cache only). Use it when you need to reclaim memory quickly, for example before starting a memory-intensive application.

**Requires password:** Yes (for cache and RAM cleaning)

---

### 5.4 Installed Apps

**Purpose:** View and uninstall applications from all package managers.

**Supported package managers:**
- **APT** (Debian/Ubuntu/Mint)
- **Snap** (Universal Linux packages)
- **Flatpak** (Sandboxed applications)
- **GNOME** (Desktop applications via .desktop files)

**Features:**
- **Search:** Filter apps by name or description.
- **Filter chips:** Toggle between All, APT, Snap, Flatpak, GNOME views.
- **Per-app uninstall:** Tap the three-dot menu and select "Remove". The app checks for dependencies first — if other packages depend on the one you want to remove, a warning dialog shows you the list.

> **Warning for beginners:** Be careful when uninstalling system packages. If you are unsure, search online for the package name first.

> **Tip for experts:** The dependency check uses `apt-cache depends` and `apt-cache rdepends --installed` to show both forward and reverse dependencies.

**Requires password:** Yes (for package removal)

---

### 5.5 System Monitor

**Purpose:** Real-time monitoring of processes, CPU, RAM, disk, and GPU.

This screen has three sub-tabs:

#### Processes Tab
- Displays all running processes grouped by application name.
- **Columns:** App Name, CPU%, Memory — tap a column header to sort.
- **CPU/RAM/GPU gauges** on the right side show real-time usage.
- **Per-group actions:** Select all, Terminate all, Force terminate all.
- **Multi-select mode:** Check multiple process groups, then kill them all at once.
- Auto-refreshes every 5 seconds.

#### System Tab
Shows hardware information in card format:
- **CPU:** Model, cores, threads, usage bar, clock speed.
- **Memory:** Total, used, free, cached, swap usage.
- **Disk:** Per-disk device name, filesystem, usage bar.
- **GPU:** Model, driver, usage percentage, memory, temperature (if available).
- **Display Server:** Wayland/X11/XWayland detection, desktop environment, key environment variables.

#### Status Tab
Read-only system status dashboard with four sections:
- **Kernel:** Version, build info, THP mode, zswap, governor, I/O scheduler.
- **Security:** AppArmor, SELinux, Secure Boot, firewall status, SSH status, auto-updates.
- **Virtualization:** CPU virtualization support, KVM, IOMMU, VFIO, KSM, Docker, libvirt.
- **Printers:** CUPS service status, installed printers, print drivers.

> **Tip for beginners:** The Processes tab helps you find which app is using too much CPU or memory. Tap on a process group to see individual processes.

> **Tip for experts:** The Status tab provides a quick security and virtualization audit. Check firewall, SSH, and Secure Boot status at a glance.

**Requires password:** No

---

### 5.6 Disk Analyzer

**Purpose:** Browse your filesystem, visualize disk usage, and manage files.

**Navigation:**
- **Home / Filesystem / External disks:** Quick-select base paths.
- **Back / Forward:** Navigate through history.
- **Sort:** By size (ascending/descending) or alphabetically.
- **More menu:** Toggle visibility of hidden/system files.

**Features:**
- **Pie chart:** Visualizes directory size distribution.
- **First-scan notice:** When a disk is analyzed for the first time, an informational notice appears informing you that indexing is in progress and the first analysis may take some time.
- **File/directory actions:**
  - **Move to Trash:** Safe deletion to trash (with confirmation).
  - **Rename:** Rename files or directories.
  - **Show Details:** View path, size, type, permissions, owner, modification date.

> **Warning:** Deleting files from the root filesystem (`/`) requires administrator privileges and is irreversible. Be very careful.

> **Tip for beginners:** Start by analyzing your home directory to find large folders taking up space (e.g., `~/.cache`, `~/.local/share/Trash`).

**Requires password:** Yes (for deleting from root paths)

---

### 5.7 SMART Disk Health

**Purpose:** Monitor hard drive and SSD health using S.M.A.R.T. data.

**Features:**
- **Disk selector:** Choose which disk to inspect from the dropdown.
- **Health status:** Shows PASSED or FAILED with temperature and power-on hours.
- **USB detection:** Identifies USB-connected drives and warns that USB-to-SATA bridges may limit SMART data.
- **Attributes table:** Displays all SMART attributes (ID, name, value, worst, threshold, raw). Failed attributes are highlighted in red.
- **Self-tests:**
  - **Short Test:** Quick scan (~2 minutes).
  - **Extended Test:** Thorough scan (can take hours depending on disk size).
  Results appear in the attributes table after the test completes.

**If smartctl is not installed:** The app offers to install `smartmontools` automatically.

> **Tip for beginners:** Check your disk health monthly. A "FAILED" status or attributes marked in red indicate the disk may need replacement soon.

> **Tip for experts:** The app supports multi-distro scanning (lsblk + smartctl --scan + /sys/block/ fallback). USB-SATA bridges are tested with `smartctl -d sat`.

**Requires password:** Yes (for installing smartctl and running self-tests)

---

### 5.8 Device Manager

**Purpose:** View, enable, and disable hardware devices — similar to the Windows Device Manager.

**Features:**
- **Device tree:** All hardware devices (PCI, USB, block, network) grouped by category: Display adapters, Network adapters, Sound/video, USB controllers, Storage, Processor, Input devices, Multimedia.
- **Search bar:** Filter devices by name or description.
- **Show disabled filter:** Toggle to show only disabled devices.

**Actions per device (tap to expand, then three-dot menu):**
- **Enable/Disable:** Toggle device state with confirmation dialog. Requires sudo password.
- **Properties panel:** Shows detailed information — status, bus type, vendor, driver, vendor/device IDs.

**Device protection:** Critical devices (Host bridge, PCI bridge, ISA bridge, IOMMU, SMBus, Processor) cannot be disabled to prevent system instability.

**Persistence:** Disabled devices are saved to `/etc/slu_disabled_devices.conf` and a systemd service is created to re-apply the disable at every boot. This ensures your settings survive reboots.

> **Warning for beginners:** Do not disable devices you do not recognize. Disabling a network adapter will disconnect you from the internet. Disabling a display adapter may crash your desktop.

> **Tip for experts:** The persistence mechanism uses sysfs (`echo 0 > enable` for PCI, `echo 0 > authorized` for USB, `ip link set X down` for network) with a systemd service.

**Requires password:** Yes (for enable/disable operations)

---

### 5.9 Recovery

**Purpose:** Restore altered system functions, check for updates, and install software.

#### Recovery Operations
| Operation | Description |
|-----------|------------|
| **Restart Pipewire** | Restarts PipeWire, PipeWire-Pulse, and Wireplumber to fix audio issues. |
| **Restore Network** | Restarts NetworkManager or systemd-networkd to fix connection problems. |
| **Rebuild GRUB** | Runs `update-grub` to regenerate the bootloader configuration. |
| **Restore Flathub** | Re-adds the Flathub remote for Flatpak. |
| **Restore Repositories** | Updates and restores package repositories for your distro. |
| **Fix WiFi Auto-Suspend** | Disables USB auto-suspend for WiFi adapters to prevent random disconnections. |

Each operation shows a "View Output" button to inspect the command output.

#### Check Updates Tab
- **Check for Updates:** Runs the appropriate package manager update command (`apt update`, `dnf check-update`, `pacman -Sy`).
- Results show available updates per package manager (APT, DNF, Pacman, Snap, Flatpak).
- **Apply Updates:** Downloads and installs all available updates with real-time progress.

#### Software Installer Tab
One-click installers for essential software:
- **FFmpeg:** Multimedia framework for encoding/decoding audio and video.
- **yt-dlp:** Video downloader supporting many websites.
- **System Libraries:** Essential system libraries that may be missing.
- **Codecs:** Video and audio codecs for common formats.
- **rsync:** Efficient file synchronization and transfer tool.

**Requires password:** Yes

---

### 5.10 Tweaks

**Purpose:** System performance tuning for swap and DaVinci Resolve.

#### Swap Tab
- Shows current swap information: RAM size, swap total/used, swappiness value, swap device.
- Provides recommendations based on your configuration:
  - Create a swap file if none exists.
  - Adjust swappiness value.
  - Enable or disable zram.
- Each recommendation has an "Execute" button that applies the suggested change.

#### DaVinci Resolve Tab
- Applies common Linux fixes for Blackmagic DaVinci Resolve:
  - Fix CUDA library paths.
  - Set correct GPU permissions.
  - Install missing dependencies.
- Each fix shows whether it requires a restart and whether it has been applied.

> **Tip for beginners:** If you use DaVinci Resolve on Linux and experience GPU issues, go to this tab and apply all fixes.

> **Tip for experts:** The swap recommendations analyze your `/proc/meminfo` and swap configuration to provide the most appropriate suggestions.

**Requires password:** Yes

---

### 5.11 Settings

Configure app-wide preferences:

#### Password
- Save, update, or delete your administrator password.
- The password is stored using the system keyring (base64-encoded in SharedPreferences).

#### Language
- Select from 6 languages: Italian, English, French, Spanish, German, Portuguese.
- Changes take effect after restarting the app.

#### Theme
- **Light / Dark / System:** Choose the app's color scheme.
- "System" follows your desktop environment's theme setting.

#### Font
- **Font Family:** Select from available system fonts.
- **Font Size:** Slider from 10sp to 24sp.

#### System Tray (Linux only)
- **Enable System Tray:** Show/hide the app icon in the system tray.
- **Close to Tray:** Keep the app running in the tray when you close the window.
- **Start Minimized:** Launch the app minimized to the tray.
- **Start at Login:** Auto-start the app when you log in (uses XDG autostart).
- **Install Dependencies:** Installs `libayatana-appindicator` if missing.

#### Automatic Update Check
- Set how often the app checks for system updates (Never, 15 min, 30 min, 1 hr, 6 hr, 12 hr, daily).
- **Auto-update from GitHub:** Automatically download and install the latest `.deb` from GitHub releases.

#### RAM Cleanup
- Set an automatic interval for clearing the Linux page cache and RAM: **Never**, **5 minutes**, **10 minutes**, **15 minutes**, **30 minutes**.
- Runs in the background at the configured interval.

#### Shutdown Scheduler
- Opens the automatic shutdown timer screen (see Section 7).

---

### 5.12 Info

**Purpose:** About screen with app information.

- App version, creator, and description.
- Feature list organized by category.
- License and disclaimer (GPL).
- **License Activate button** (Advanced build only): Enter your license key to unlock advanced features.
- **PayPal button** (Advanced build only): Purchase a license for 19.99 EUR.
- Project website link.

---

## 6. Advanced Mode — Additional Features

Advanced mode unlocks 2 additional tabs and extends the existing Tweaks screen. Requires a purchased license key (or Personal/Test build).

To switch between Standard and Advanced mode, use the mode buttons in the top-right area of the sidebar.

---

### 6.1 GRUB Editor

**Purpose:** Edit the GRUB bootloader configuration safely.

**Features:**
- **Text editor:** Directly edit `/etc/default/grub` in a built-in text editor.
- **Save and Update:** Saves the configuration, creates an automatic backup, and runs `update-grub` (or equivalent for your distro).
- **Hardware Suggestions:** Analyzes your hardware and suggests kernel parameters:
  - NVIDIA modeset, iommu, threadirqs, zswap, elevator, etc.
  - Each suggestion has a priority badge (high/medium/low).
  - Tap "Apply" to insert the suggestion into the editor.
- **Restore Backup:** Reverts to the last backup if something goes wrong.
- **Unsaved changes indicator:** An orange banner appears when you have unsaved modifications.

**GRUB rebuild commands by distro:**
- Debian/Ubuntu: `update-grub`
- Fedora: `grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
- Arch: `grub-mkconfig -o /boot/grub/grub.cfg`

> **Warning:** Incorrect GRUB modifications can prevent your system from booting. Always keep a backup. If your system fails to boot, use a live USB to restore `/etc/default/grub` from the backup.

**Requires password:** Yes

---

### 6.2 Benchmark

**Purpose:** Measure your system's hardware performance.

Four benchmark categories:

| Benchmark | What it measures |
|-----------|-----------------|
| **CPU** | Multi-core and single-core processing power. Results compared against reference Intel, AMD, and Apple chips. |
| **GPU** | Graphics performance using `glmark2`. Results compared against reference NVIDIA and AMD GPUs. |
| **Disk** | Sequential read/write speed. Results compared against NVMe, SSD, and HDD references. |
| **Network** | Internet speed test. Results compared against reference network speeds. |

Each benchmark shows:
- Your score.
- The closest matching reference hardware.
- A rating (Excellent, Good, Average, Below Average, Poor).

> **Tip:** Run benchmarks after system changes (new kernel, new drivers) to see if performance improved.

**Requires password:** No

---

## 7. System Tray

When enabled in Settings, Super Linux Utility places an icon in the system tray (notification area). Right-click the icon to access:

| Menu Item | Action |
|-----------|--------|
| **Show main window** | Brings the app window to the foreground. |
| **Check updates** | Opens the update check dialog. |
| **Clean temp files and cache** | Navigates to the Cleanup tab. |
| **CPU, GPU temperature** | Navigates to the Monitor tab. |
| **Disk usage** | Navigates to the Disk Analyzer tab. |
| **Memory usage** | Shows current RAM usage. |
| **Disk health (SMART)** | Navigates to the SMART tab. |
| **Automatic shutdown** | Opens the shutdown timer dialog. |
| **CPU, GPU usage** | Opens a task manager dialog. |
| **Exit** | Closes the app. |

The tray icon tooltip shows real-time CPU/GPU temperature and memory usage.

---

## 8. Automatic Updates

### System Update Check
Configurable in Settings > Automatic Update Check. When enabled, the app periodically checks for updates across all installed package managers (APT, DNF, Pacman, Snap, Flatpak). Update notifications appear as dialogs with per-package checkboxes.

### App Self-Update
When enabled in Settings > Auto-update from GitHub, the app checks GitHub releases for newer `.deb` packages matching your edition (Standard/Advanced). Downloads and installs automatically using `sudo dpkg -i`.

---

## 9. Troubleshooting

### "Password not saved" error
Go to Settings > Password and re-enter your sudo password. The password is stored in the system keyring.

### SMART tab shows no disks
Install `smartmontools`: the app will offer to do this automatically. If using a USB-SATA adapter, SMART data may be limited.

### GRUB changes not applied (Advanced mode)
Ensure you tapped "Save and Update" (not just "Save"). The app must run `update-grub` with administrator privileges.

### System tray icon not visible
Install the required dependency: `sudo apt install libayatana-appindicator-3-dev`. Then restart the app.

### AppImage does not start
The AppImage uses a static runtime and should work without FUSE. If it still fails:
```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./super-linux-utility-*.AppImage
```

### Device Manager cannot disable a device
Some devices are protected because disabling them would crash the system. The app shows a message when a device cannot be disabled.

---

## 10. FAQ

**Q: Is it safe to use this app?**
A: Standard mode features are safe for all users. Advanced mode modifies GRUB — always create a backup before using GRUB features.

**Q: Does the app send data anywhere?**
A: No. The app does not collect or transmit any user data. The only network operations are checking for updates (from GitHub or your package manager).

**Q: Can I use the app on Fedora/Arch?**
A: Yes. The app auto-detects your distribution and adapts all commands accordingly (APT, DNF, Pacman).

**Q: What happens if I disable a critical service?**
A: The app protects essential desktop environment services (GNOME, KDE, etc.) from being disabled. However, always be cautious with unknown services.

**Q: How do I restore GRUB if the system does not boot?**
A: Boot from a live USB, mount your root partition, and copy `/etc/default/grub.backup` back to `/etc/default/grub`. Then run `sudo update-grub`.

**Q: Can I disable any hardware device?**
A: The Device Manager protects critical system devices (CPU, bridges, IOMMU) from being disabled. You can safely disable non-essential peripherals like USB devices or secondary network adapters.

---

## 11. Glossary

| Term | Definition |
|------|-----------|
| **APT** | Advanced Package Tool — Debian/Ubuntu package manager. |
| **Device Manager** | Tool to view, enable, and disable hardware devices. |
| **DNF** | Dandified YUM — Fedora/RHEL package manager. |
| **Flatpak** | Sandboxed application packaging format for Linux. |
| **GRUB** | Grand Unified Bootloader — the program that loads Linux at startup. |
| **Kernel** | The core of the Linux operating system. |
| **PCI** | Peripheral Component Interconnect — standard bus for internal devices. |
| **Pacman** | Package manager for Arch Linux and derivatives. |
| **PipeWire** | Modern Linux audio/video server. |
| **SMART** | Self-Monitoring, Analysis and Reporting Technology — hard drive health system. |
| **Snap** | Universal Linux package format by Canonical. |
| **systemd** | Init system and service manager for Linux. |
| **systemctl** | Command-line tool to manage systemd services. |
| **Swap** | Disk space used as virtual RAM when physical RAM is full. |
| **sysfs** | Virtual filesystem exposing kernel device data (`/sys/`). |
| **USB** | Universal Serial Bus — standard for external devices. |
| **Wayland** | Modern display server protocol replacing X11. |
| **X11** | Traditional display server protocol for Linux. |
| **zram** | Compressed RAM-based swap device. |

---

*Super Linux Utility v2.0.6 — User Manual*
*Created by Marco Di Giangiacomo*
*License: GPL v3*
