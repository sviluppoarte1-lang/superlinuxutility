# Changelog

## 2.1.0 — 2026-09-19

### New features

- **Driver & Firmware Manager**: new "Drivers" tab. Detects hardware via `lspci`/`lsusb`, identifies known chipsets and offers one-click installation on APT, DNF, Pacman and Zypper distributions.
- **Multi-distro chipset database**: NVIDIA (535+ fallback), AMDGPU, Realtek Wi-Fi (RTL8812AU/8821CE/8822BE), Broadcom, Intel Wi-Fi (AX200/AX211), each with per-distro candidate packages and automatic fallbacks.
- **Kernel compatibility checks**: reads the running kernel (`uname -r`) and verifies header packages before installing DKMS modules (standard, XanMod, Liquorix, LTS, Zen kernels).
- **Firmware handling**: `linux-firmware` with fallbacks to `firmware-linux-free` / `firmware-misc-nonfree` on Debian/Ubuntu; native package on Fedora, Arch and openSUSE.
- **In-kernel Realtek RTL8168 support**: managed by the built-in `r8169` driver, no DKMS build required.
- **Firmware updates via `fwupdmgr`**: checks for updates and applies them, with an indicator when a reboot is required.
- **Battery management**: dedicated tab with health, cycles, capacity, 20-100% charge threshold and automatic governor switching; live percentage in the tray.
- **Clipboard history**: 2s polling service, persisted in SharedPreferences, 1-8h retention with auto-prune (max 500 entries), run as a separate process.
- **Advanced cleanup**: expandable section in Disk Cleanup for pip/cargo/npm/go/gradle/docker caches (with reclaimable size), journald vacuuming and safe removal of old kernels.
- **Reorganized tray menu**: five system items moved to a "System" submenu, new "Clipboard" and "Battery" entries, colored emoji labels for Cinnamon, live CPU/GPU/RAM tooltips.

### Fixes

- **journald limit now applies**: the whole `bash -c` chain is elevated with sudo (previously only `mkdir` ran as root, so writes to `/etc/systemd` failed); the new limit is verified after reload.
- **Battery/GRUB tab order**: navigation and views now both use `insert(9)`, fixing swapped tabs.
- **No window flash during automatic RAM cleanup**: the window is hidden before the tray service is destroyed.
- **Benchmark tab removed**: unused benchmark screens and their localization keys deleted, smaller app footprint.

## 2.0.6 — 2026-08-14

### Fixes

- **RAM cleanup and zram**: `swapoff` no longer kills zram; the cleanup detects zram first and restores it with `systemctl start zramswap` if it was active. Swap reclaim also runs when zram is in use even if swap usage is 0.
- **Repository Manager on Ubuntu 24.04+**: detects `ubuntu.sources` and writes DEB822 format with the correct `Signed-By` keyring path; the old one-line `sources.list` format is still used on older Ubuntu releases.
- **CPU usage calculation**: `iowait` is no longer counted as active time (was inflating usage by 5-15%), `steal` is now counted (important for VMs), `guest`/`guest_nice` are no longer double-counted; same fix applied to per-core values.
- **Tray task manager**: the app no longer lists (and inflates) its own process; the current PID is filtered out of the process list.

### Changes

- Removed the non-functional Security sub-tab from the Recovery screen.

## 2.0.5 — 2026-08-09

### New features

- **RAM cleaning**: one-click cleanup from the Cleanup tab (page cache, dentries, inodes) with memory usage shown before and the amount freed shown after.
- **Automatic RAM cleaning**: configurable interval in Settings (disabled, 15/30/60/120/180 minutes), runs in background at startup, persists across restarts.
- **Kernel tweaks** (Advanced): Transparent Huge Pages (always/madvise/never), CPU governor (performance/ondemand/schedutil/powersave), `child_runs_first` scheduler toggle; applied persistently via a systemd service.

### Improvements

- **System Status consolidated**: the Kernel, Security, Virtualization and Printers tabs were merged into a single scrollable card, as the third tab of the System Monitor (after Processes and System).
- **AppImage without FUSE**: built with the static runtime, runs on Debian 12+, LMDE 7 and any system without `libfuse2`/`libfuse3` (`APPIMAGE_EXTRACT_AND_RUN=1` as fallback).

### Fixes

- Kernel tweaks no longer crash when the sudo password has not been saved.

## 2.0.1 — 2026-07-21

### New sections

- **Benchmark** (Advanced, license required): CPU, GPU, disk and network tests with a composite score and optimization suggestions; network test implements the Ookla Speedtest protocol (download, upload, ping, jitter, DNS).
- **Repositories** (Standard + Advanced): view, toggle, edit and restore official distribution repositories (APT, DNF, Pacman); restores `.sources`, `.list`, `.repo` and `pacman.conf` files and refreshes the package manager cache.
- **Tweaks** (Standard + Advanced): swap management (create, resize, remove swap files/zram with automatic priority) and DaVinci Resolve dependency installer.

### Network benchmark rewrite

- Download and upload values were swapped; now measured in the correct direction.
- Requests are re-launched throughout the test window instead of finishing in the first second (fast connections no longer report near-zero speeds).
- Upload bytes are counted only after the server confirms them, not at local buffer write.
- In-flight bytes are no longer dropped at the end of a chunk; elapsed time uses the configured test length.
- Thread count capped at 16 (was 72), no-cache headers added, Ookla config and server list shared between download and upload; fixed crash paths (`unawaited` misuse and `sublist` range errors).

### Improvements

- **Process tab gauges**: custom CPU/RAM/GPU donut charts in a panel next to the process table, refreshed every 5 seconds.
- **Recovery (Advanced)**: new WiFi auto-suspend fix — udev rule to disable USB autosuspend plus `wifi.powersave = 2` in NetworkManager, applied at runtime and localized in 6 languages.
- "Check for updates" button in the Standard build main window.
- Kernel update detection for Pacman distributions (Arch, Manjaro, EndeavourOS).

## 1.9.2 — 2026-06-01

- Complete feature documentation: tray, system monitor, self-updates, disk analyzer, SMART monitoring, services, startup apps, cleanup, kernel management, GRUB editor, shutdown timer, appearance, security and multi-language support.
- Arch Linux package (`.pkg.tar.zst`) published alongside the `.deb` releases.

## 1.9.0 — 2026-05-14

### Fixes

- **CPU core detection**: physical cores are now read from `lscpu` (cores per socket × sockets); `nproc` is used only for the thread count. Previously logical threads were counted twice (e.g. Ryzen 7 5700G showed 32 threads instead of 8 cores / 16 threads).
- **Disk analyzer chart for the root filesystem**: the base path now runs `du -h -d1 -x` (progressive timeout, streaming partial results) and caches the result; before, the chart was populated only from directory entries and stayed empty.
- **Chart labels**: size labels are rendered in a fixed 64px column, aligned on the same vertical axis; chart text is bold and uniform.

## 1.8.6 — 2026-02-26

- First public release: services, startup apps, cleanup, installed apps, system monitor, disk analyzer, appearance settings and system tray integration.
- Advanced edition: GRUB editor with backup, kernel management and system recovery.
