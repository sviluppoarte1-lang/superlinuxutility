<img width="676" height="651" alt="Schermata del 2026-09-19 11-24-35" src="https://github.com/user-attachments/assets/460a7954-acdb-402f-82fb-6c90f32d92ac" />
<img width="383" height="459" alt="Schermata del 2026-09-19 11-24-18" src="https://github.com/user-attachments/assets/eb7b3dd0-b877-4b34-8ea1-b01e4bf5db10" />
<img width="1918" height="1045" alt="Schermata del 2026-09-19 11-24-02" src="https://github.com/user-attachments/assets/f73941ca-8003-4d04-aa1e-7a218ba781d8" />
<img width="1918" height="1045" alt="Schermata del 2026-09-19 11-23-48" src="https://github.com/user-attachments/assets/d82247dc-abd0-4ee8-a589-0aae2929d20f" />
<img width="1918" height="1045" alt="Schermata del 2026-09-19 11-23-40" src="https://github.com/user-attachments/assets/44286671-48a7-4516-bb10-404e66d002a3" />
<img width="1918" height="1045" alt="Schermata del 2026-09-19 11-23-29" src="https://github.com/user-attachments/assets/36260666-dd3c-420b-82cc-c12784c05710" />
<img width="1917" height="1055" alt="Schermata del 2026-09-19 11-23-19" src="https://github.com/user-attachments/assets/efeecbb5-753c-4020-b2e3-88224b7d7c27" />
<img width="278" height="364" alt="Schermata del 2026-09-19 11-23-03" src="https://github.com/user-attachments/assets/03c7abef-0236-4298-8a59-8cab07f01c7b" />

# Super Linux Utility

**Version 2.1.0** — All-in-one Linux system management utility with system tray integration.

---

## Features

### System Tray
- Live CPU/GPU temperature, disk usage, memory usage, and SMART health in the tray menu
- Quick actions: check updates, clean temp files, shutdown timer, clipboard history, battery status
- System submenu for power/session items; colored emoji labels (Cinnamon)
- 5-second refresh interval for live monitoring
- Wayland & X11 support
- Start at login, minimize to tray, close to tray options

### System Monitor
- Real-time CPU usage per-core with color-coded percentage display
- CPU model, cores, threads, current frequency (MHz/GHz)
- Memory usage with detailed breakdown
- Disk usage per partition
- GPU monitoring (NVIDIA, AMD, Intel) with temperature and utilization
- Display server detection (Wayland, X11, XWayland)
- Process manager with grouped-by-name view, search, sort, kill/force kill

### Package & System Updates
- GitHub release check for app self-updates (checks for newer `.deb`)
- Automatic download & install with user confirmation dialog
- Release notes preview before installing
- Package manager support: APT (Debian/Ubuntu), DNF (Fedora), Pacman (Arch), Snap, Flatpak
- Kernel updates detected separately with explicit confirmation required

### Disk Analyzer
- Root filesystem analysis using `du`
- Real-time streaming with progress updates
- Per-directory size visualization with color-coded bars

### SMART Monitoring
- Full S.M.A.R.T. data for ATA, NVMe, and USB drives
- Auto-installs `smartmontools` if missing
- Health assessment, temperature, power-on hours, self-test log
- USB drive support with automatic vendor-specific `-d` type probing
- Per-device cached working variant (persisted across restarts)
- Self-test execution (short/long/conveyance)

### Services Management
- List, start, stop, enable, disable systemd services
- Service status with color indicators
- Filter by running/stopped/enabled/disabled
- Beginner-friendly guide dialog on first launch

### Startup Applications
- Manage user systemd services and autostart `.desktop` files
- Enable/disable startup entries
- Protection against accidental changes

### Cleanup
- Temporary files, system cache, trash cleanup
- APT cache, journal logs, thumbnail cache, browser caches
- Advanced cleanup: pip/cargo/npm/go/gradle/docker caches, journald vacuuming, old kernel removal
- Configurable cleanup scope
- One-click RAM cleaning (page cache, dentries, inodes) with before/after figures
- Optional automatic RAM cleaning at configurable intervals

### Drivers & Firmware
- Hardware detection via `lspci`/`lsusb` with a known-chipset database (NVIDIA, AMD, Realtek, Broadcom, Intel)
- One-click driver installation with per-distro package fallbacks (APT, DNF, Pacman, Zypper)
- Kernel header check before DKMS installs (standard, XanMod, Liquorix, LTS, Zen kernels)
- Firmware updates via `fwupdmgr`, with reboot indicator

### Battery
- Health, cycle count, capacity and charge threshold (20-100%)
- Automatic governor switching; live percentage in the tray

### Clipboard History
- Polls the clipboard every 2s, persisted across restarts
- 1-8h retention with auto-prune (max 500 entries); tray entry included

### Recovery & Repositories
- System recovery operations with an operation history
- Repository manager: view, toggle, edit and restore official distribution repositories (APT, DNF, Pacman), including Ubuntu 24.04+ DEB822 format
- Software installer and security settings

### Kernel Management
- List installed kernels
- Remove old/unused kernels
- Set default kernel
- Cleanup kernel packages

### GRUB Editor
- Edit GRUB configuration
- Add custom kernel parameters (including NVIDIA Wayland optimizations)
- Backup, restore, and update GRUB
- Preset configurations for common scenarios

### Tweaks
- Swap file/zram management: create, resize and remove with automatic priority
- DaVinci Resolve dependency installer
- Kernel tweaks (Advanced): Transparent Huge Pages, CPU governor, scheduler toggle

### Shutdown Timer
- Schedule system shutdown, reboot, or suspend
- Configurable delay with countdown

### Appearance
- Theme switching (Light/Dark/System)
- Accent color selection
- Font size adjustment
- Wallpaper management
- Window behavior settings

### Security
- Admin password management (sudo)
- Warning screen on first launch
- Safe mode options

### Multi-language Support
- English, Italian, French, Spanish, German, Portuguese

---

## Build Types

| Type | Description |
|------|-------------|
| **Standard** (free) | Full feature set, no license required |
| **Advanced** (paid) | All features + license activation |

Build with:
```bash
# Standard (free)
flutter build linux --dart-define=APP_BUILD=standard

# Advanced (paid)
flutter build linux --dart-define=APP_BUILD=advanced

```

---

## Requirements

- Linux desktop (GTK3)
- Flutter SDK 3.10+ (to build from source)
- Runtime: `libayatana-appindicator` (system tray), `smartmontools`, `lscpu`, `mpstat` (optional, falls back to `/proc/stat`)

---

## Installation

### From GitHub Releases (.deb)
1. Download the latest `.deb` from [releases](https://github.com/sviluppoarte1-lang/superlinuxutility/releases)
2. Install with: `sudo dpkg -i super-linux-utility_*.deb`
3. Launch from application menu or run `super_linux_utility`

### AppImage
1. Download the `.AppImage` from [releases](https://github.com/sviluppoarte1-lang/superlinuxutility/releases) (static runtime, no FUSE required)
2. `chmod +x super-linux-utility-*.AppImage && ./super-linux-utility-*.AppImage`

### Arch Linux package
```bash
sudo pacman -U super-linux-utility-*.pkg.tar.zst
```

### Auto-update
The app can check for updates automatically via GitHub releases. When a new version is found:
1. A dialog shows the new version and release notes
2. User confirms download & install
3. The `.deb` is downloaded and installed via `sudo dpkg -i`
4. Restart the app to use the new version

---

## Technical Details

- **Password storage**: Base64-encoded in SharedPreferences (used for sudo operations)
- **SMART USB probing**: Progressive discovery — one vendor variant per tray refresh cycle (5s), or all at once in the SMART screen
- **CPU monitoring**: Reads `/proc/stat` directly (no external dependencies required for basic stats; `mpstat` used if available for per-core data)
- **Memory monitoring**: Reads `/proc/meminfo` directly
- **GPU monitoring**: Uses `nvidia-smi` for NVIDIA, `/sys/class/drm/` for others (30s cache)
- **GLib compatibility**: Ships weak symbol stubs for GLib < 2.78 (MX Linux, Debian 12)

---

## License

GNU General Public License v3.0 — see the app's Info screen for details.

---

## Author

**Marco Di Giangiacomo**

[GitHub Repository](https://github.com/sviluppoarte1-lang/superlinuxutility)
