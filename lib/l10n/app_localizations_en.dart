// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Super Linux Utility';

  @override
  String get appAlreadyRunning => 'The application is already running.';

  @override
  String get trayCheckUpdates => 'Check system updates';

  @override
  String get trayCleanLinuxCache => 'Clear Linux cache';

  @override
  String get trayRemoveTempFiles => 'Remove temporary files';

  @override
  String get trayCleanTempFilesAndCache => 'Clean temporary files and cache';

  @override
  String get trayCleanVram => 'Clear VRAM (GPU reset)';

  @override
  String get trayCpuGpuTemp => 'CPU, GPU temperature';

  @override
  String get trayDiskUsage => 'Disk usage';

  @override
  String get trayMemoryUsage => 'Memory usage';

  @override
  String get traySmartHealth => 'Disk health (SMART)';

  @override
  String get trayShutdownTimer => 'Automatic shutdown';

  @override
  String get trayShowMainWindow => 'Show main window';

  @override
  String get trayCpuGpuUsage => 'CPU, GPU usage';

  @override
  String get trayExit => 'Exit';

  @override
  String get traySettings => 'Settings';

  @override
  String get traySystem => 'System';

  @override
  String get trayClipboard => 'Clipboard';

  @override
  String get clipboardTitle => 'Clipboard history';

  @override
  String get clipboardEmpty =>
      'Nothing copied yet. Copy some text and it will appear here.';

  @override
  String get clipboardEditTitle => 'Edit text';

  @override
  String get clipboardSave => 'Save';

  @override
  String get clipboardCancel => 'Cancel';

  @override
  String get clipboardDelete => 'Delete';

  @override
  String get clipboardDeleteTitle => 'Delete this entry?';

  @override
  String get clipboardDeleteBody =>
      'The entry will be permanently removed from history.';

  @override
  String get clipboardClearAll => 'Clear all';

  @override
  String get clipboardClearAllTitle => 'Clear history?';

  @override
  String get clipboardClearAllBody =>
      'All saved entries will be permanently deleted.';

  @override
  String get clipboardSaveEntryTxt => 'Save as TXT';

  @override
  String get clipboardExportAll => 'Export all as TXT';

  @override
  String clipboardSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get clipboardSaveFailed => 'Save failed.';

  @override
  String get clipboardCopiedBack => 'Text copied to clipboard.';

  @override
  String get clipboardSettingsTitle => 'Clipboard';

  @override
  String get clipboardSettingsDesc =>
      'The app automatically stores texts you copy. Choose how many hours to keep them: expired copies are deleted automatically.';

  @override
  String get clipboardRetentionLabel => 'Keep copies for';

  @override
  String clipboardRetentionHours(int n) {
    return '$n h';
  }

  @override
  String get tabBattery => 'Battery';

  @override
  String get trayBattery => 'Battery';

  @override
  String get trayBatteryHealth => 'Battery health';

  @override
  String get trayChargeLimit => 'Charge limit';

  @override
  String get trayPowerProfile => 'Power profile';

  @override
  String get batteryNoBattery => 'No battery detected';

  @override
  String get batteryNoBatteryDesc =>
      'This feature is only available on notebooks. No battery was found on this system.';

  @override
  String get batteryHealthTitle => 'Battery health';

  @override
  String get batteryCapacityNow => 'Current energy';

  @override
  String get batteryCapacityFull => 'Full capacity';

  @override
  String get batteryCapacityDesign => 'Design capacity';

  @override
  String get batteryHealthPct => 'Health';

  @override
  String get batteryCycles => 'Charge cycles';

  @override
  String get batteryVoltage => 'Voltage';

  @override
  String get batteryPower => 'Power';

  @override
  String get batteryTech => 'Technology';

  @override
  String get batteryStatus => 'Battery';

  @override
  String get batteryAcOnline => 'On AC power';

  @override
  String get batteryAcOffline => 'On battery';

  @override
  String get batteryCharging => 'Charging';

  @override
  String get batteryDischarging => 'Discharging';

  @override
  String get batteryFull => 'Fully charged';

  @override
  String get batteryUnknown => 'Unknown state';

  @override
  String get batteryThresholdsTitle => 'Charge thresholds';

  @override
  String get batteryThresholdsDesc =>
      'Limit the maximum charge (e.g. 80%) to preserve battery lifespan. Requires administrator password. Supported on recent ASUS, ThinkPad, Lenovo and Dell.';

  @override
  String get batteryThresholdsUnsupported =>
      'Charge thresholds not supported on this hardware.';

  @override
  String get batteryEndLimit => 'Maximum charge limit';

  @override
  String get batteryStartLimit => 'Charge start';

  @override
  String get batteryGovernorTitle => 'Automatic governor';

  @override
  String get batteryGovernorDesc =>
      'Switch to powersave when unplugged and to performance when charging. Works while the app is running.';

  @override
  String get batteryGovernorAuto => 'Automatic governor switching';

  @override
  String get batteryGovernorOnAc => 'Governor when charging';

  @override
  String get batteryGovernorOnBattery => 'Governor on battery';

  @override
  String get batteryGovernorCurrent => 'Current governor';

  @override
  String get batteryApplied => 'Setting applied.';

  @override
  String get batteryFailed => 'Operation failed.';

  @override
  String get batteryRefresh => 'Refresh';

  @override
  String get cleanupLinuxCache => 'Clear cache';

  @override
  String get cleanupLinuxCacheDesc =>
      'Clear kernel page cache (drop_caches). Requires administrator password.';

  @override
  String get cleanupLinuxCacheSuccess => 'Linux cache cleared successfully.';

  @override
  String get cleanupLinuxCacheError => 'Error clearing cache.';

  @override
  String get advCleanupTitle => 'Advanced cleanup (logs & dev caches)';

  @override
  String get devPip => 'pip cache';

  @override
  String get devCargo => 'Cargo cache (Rust)';

  @override
  String get devNpm => 'npm cache';

  @override
  String get devGo => 'Go cache';

  @override
  String get devGradle => 'Gradle cache';

  @override
  String get devDocker => 'Unused Docker images';

  @override
  String get devKernelHeaders => 'Old kernels (headers + images)';

  @override
  String get advEmpty => 'No development caches detected.';

  @override
  String get journalTitle => 'System logs (journald)';

  @override
  String get journalCurrentSize => 'Space used';

  @override
  String get journalVacuumTarget => 'Vacuum down to';

  @override
  String get journalVacuumNow => 'Vacuum';

  @override
  String get journalLimitLabel => 'Persistent limit';

  @override
  String get journalLimitApply => 'Apply limit';

  @override
  String get advCleanSelected => 'Clean selected';

  @override
  String get advCleaned => 'Cleanup completed.';

  @override
  String get advFailed => 'Cleanup failed.';

  @override
  String get cleanupVram => 'Clear VRAM';

  @override
  String get cleanupVramConfirmTitle => 'GPU reset';

  @override
  String get cleanupVramConfirmMessage =>
      'I will try to reset the graphics card to free VRAM. It requires an administrator password and may cause a temporary screen interruption. Continue?';

  @override
  String get cleanupVramSuccess => 'VRAM cleared (GPU reset) successfully.';

  @override
  String get cleanupVramError => 'Failed to clear VRAM (GPU reset).';

  @override
  String get ramCleanupTitle => 'RAM Cleanup';

  @override
  String get ramCleanup => 'Clean RAM';

  @override
  String get ramCleanupConfirmTitle => 'Confirm RAM cleanup';

  @override
  String get ramCleanupConfirmMessage =>
      'Deep RAM cleanup will flush kernel caches (drop_caches) and recycle swap to free memory used by inactive data. It does not stop system services and does not delete temporary files. Requires administrator password. Continue?';

  @override
  String get ramCleanupSuccess => 'RAM cleanup completed successfully.';

  @override
  String get ramCleanupError => 'Error during RAM cleanup.';

  @override
  String get ramUsed => 'Used';

  @override
  String get ramAvailable => 'Available';

  @override
  String get ramCache => 'Cache';

  @override
  String get ramSwap => 'Swap';

  @override
  String get ramSwapNone => 'No swap';

  @override
  String get ramFreed => 'Memory freed';

  @override
  String get ramBefore => 'Before';

  @override
  String get ramAfter => 'After';

  @override
  String get ramStepsFailed => 'Failed steps';

  @override
  String get ramCleanupSettingsTitle => 'Automatic RAM cleanup';

  @override
  String get ramCleanupSettingsDesc =>
      'Automatically performs deep RAM cleanup at regular intervals.';

  @override
  String get ramCleanupSettingsInterval => 'RAM cleanup frequency';

  @override
  String get ramCleanupNever => 'Never';

  @override
  String get ramCleanupEvery5Min => 'Every 5 minutes';

  @override
  String get ramCleanupEvery10Min => 'Every 10 minutes';

  @override
  String get ramCleanupEvery15Min => 'Every 15 minutes';

  @override
  String get ramCleanupEvery30Min => 'Every 30 minutes';

  @override
  String ramCleanupAutoEnabled(int minutes) {
    return 'Automatic RAM cleanup enabled (every $minutes minutes).';
  }

  @override
  String get ramCleanupAutoDisabled => 'Automatic RAM cleanup disabled.';

  @override
  String get ramCleanupAutoDone => 'Automatic RAM cleanup completed';

  @override
  String get tabServices => 'Services';

  @override
  String get tabStartupApps => 'Startup Apps';

  @override
  String get tabCleanup => 'Cleanup';

  @override
  String get tabInstalledApps => 'Installed Apps';

  @override
  String get tabMonitor => 'Monitor';

  @override
  String get tabDiskAnalyzer => 'Disk Analyzer';

  @override
  String get tabAppearance => 'GNOME Appearance';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabRecovery => 'System Recovery';

  @override
  String get tabGrub => 'GRUB';

  @override
  String get tabKernel => 'Kernel';

  @override
  String get tabSettings => 'Settings';

  @override
  String get modeStandard => 'Standard';

  @override
  String get modeAdvanced => 'Advanced';

  @override
  String get warningTitle => 'WARNING';

  @override
  String get warningSubtitle => 'Application for Expert Users';

  @override
  String get warningMessage =>
      'This application allows you to modify critical Linux operating system configurations.';

  @override
  String get warningGrub => 'GRUB Modifications';

  @override
  String get warningGrubDesc =>
      'Incorrect modification of the bootloader may prevent the system from booting.';

  @override
  String get warningKernel => 'Kernel Removal';

  @override
  String get warningKernelDesc =>
      'Removing essential kernels may render the system unusable.';

  @override
  String get warningServices => 'Service Management';

  @override
  String get warningServicesDesc =>
      'Disabling critical services may cause system malfunctions.';

  @override
  String get warningCleanup => 'File Cleanup';

  @override
  String get warningCleanupDesc =>
      'Deleting system files may compromise stability.';

  @override
  String get warningBackup =>
      'It is recommended to create a system backup before using this application.';

  @override
  String get warningDontShow => 'Don\'t show this warning again';

  @override
  String get warningAccept => 'I Understand, Proceed';

  @override
  String get passwordSetupTitle => 'Password Configuration';

  @override
  String get passwordSetupDesc =>
      'To use features that require administrator privileges, you need to configure the system password.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter administrator password';

  @override
  String get passwordConfirm => 'Confirm Password';

  @override
  String get passwordConfirmHint => 'Re-enter password';

  @override
  String get passwordSave => 'Save Password';

  @override
  String get passwordSkip => 'Skip for now';

  @override
  String get passwordSaved =>
      'Password saved securely using the system keyring.';

  @override
  String get passwordError => 'Error saving password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordEmpty => 'Enter a password';

  @override
  String get passwordRequired => 'Password Required';

  @override
  String get passwordRequiredMessage =>
      'Administrator password is required to access all directories. The password will be saved securely.';

  @override
  String get settingsPasswordTitle => 'Administrator Password';

  @override
  String get settingsPasswordDesc =>
      'Save the administrator password to use features that require sudo privileges.';

  @override
  String get settingsPasswordSaved =>
      'Password saved. You can change or delete it.';

  @override
  String get settingsPasswordConfigured => 'Password configured';

  @override
  String get settingsPasswordUpdate => 'Update Password';

  @override
  String get settingsPasswordDelete => 'Delete';

  @override
  String get settingsThemeTitle => 'Application Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemDesc => 'Follows system settings';

  @override
  String get settingsInfoTitle => 'Information';

  @override
  String get settingsInfoDesc => 'This application helps you to:';

  @override
  String get settingsInfoItem1 => 'Find systemd services that slow down boot';

  @override
  String get settingsInfoItem2 => 'Manage startup applications';

  @override
  String get settingsInfoItem3 => 'Clean system temporary files';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingSettings => 'Loading system settings';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get themeRestartMessage =>
      'The theme will be applied after restarting the application';

  @override
  String get themeApplied => 'Theme applied successfully';

  @override
  String get settingsFontTitle => 'Font and Text Size';

  @override
  String get settingsFontDesc =>
      'Customize the font and text size used throughout the application.';

  @override
  String get settingsSystemTrayTitle => 'System Tray';

  @override
  String get settingsSystemTrayDesc =>
      'Show app icon in system tray for quick actions. Requires system dependencies (libappindicator).';

  @override
  String get settingsTrayDepsOk => 'Dependencies installed.';

  @override
  String get settingsTrayDepsMissing =>
      'Dependencies missing. Install to enable system tray.';

  @override
  String get settingsSystemTrayEnable => 'Enable system tray';

  @override
  String get settingsTrayInstallDeps => 'Install dependencies';

  @override
  String get settingsCloseToTray => 'Keep in tray when closing';

  @override
  String get settingsCloseToTrayDesc =>
      'When enabled, closing or minimizing the window keeps the app running in the system tray.';

  @override
  String get settingsCloseToTrayOn => 'Close to tray enabled.';

  @override
  String get settingsCloseToTrayOff =>
      'Close to tray disabled. Closing the window will exit the app.';

  @override
  String get settingsTrayEnabled => 'System tray enabled.';

  @override
  String get settingsTrayDisabled =>
      'System tray disabled. Restart the app to apply.';

  @override
  String get settingsStartMinimized => 'Start app minimized to tray';

  @override
  String get settingsStartMinimizedDesc =>
      'When enabled, the app starts without showing the main window, only the system tray icon.';

  @override
  String get settingsStartMinimizedOn =>
      'Start minimized enabled. Next launch will open in tray only.';

  @override
  String get settingsStartMinimizedOff => 'Start minimized disabled.';

  @override
  String get settingsStartAtLogin => 'Start app at system login';

  @override
  String get settingsStartAtLoginDesc =>
      'When enabled, the app starts automatically when you log in.';

  @override
  String get settingsStartAtLoginOn =>
      'Start at login enabled. The app will start when you log in.';

  @override
  String get settingsStartAtLoginOff => 'Start at login disabled.';

  @override
  String get settingsStartAtLoginError =>
      'Could not change start at login setting.';

  @override
  String get settingsAutoUpdateCheckTitle => 'Automatic update check';

  @override
  String get settingsAutoUpdateCheckDesc =>
      'Check for system updates automatically at the chosen interval.';

  @override
  String get settingsAutoUpdateCheckInterval => 'Check for updates';

  @override
  String get settingsAutoUpdateNever => 'Never';

  @override
  String get settingsAutoUpdateEvery15Min => 'Every 15 minutes';

  @override
  String get settingsAutoUpdateEvery30Min => 'Every 30 minutes';

  @override
  String get settingsAutoUpdateEvery1Hour => 'Every 1 hour';

  @override
  String get settingsAutoUpdateEvery6Hours => 'Every 6 hours';

  @override
  String get settingsAutoUpdateEvery12Hours => 'Every 12 hours';

  @override
  String get settingsAutoUpdateEveryDay => 'Every day';

  @override
  String get settingsAutoAppUpdateFromGithubTitle =>
      'Auto-update app from GitHub';

  @override
  String get settingsAutoAppUpdateFromGithubDesc =>
      'When enabled, the app periodically downloads and installs the latest .deb for this edition from GitHub releases. Requires a saved administrator password and only runs when automatic system update checks are enabled above.';

  @override
  String get updateCheckAptNone => 'APT: No updates available';

  @override
  String get updateCheckAptPhasedOnly =>
      'APT: No updates installable right now (phased rollout only)';

  @override
  String updateCheckAptHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APT: $count updates available',
      one: 'APT: $count update available',
    );
    return '$_temp0';
  }

  @override
  String updateCheckAptPhasedExtra(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APT: $count phased updates detected',
      one: 'APT: $count phased update detected',
    );
    return '$_temp0';
  }

  @override
  String updateCheckAptError(String error) {
    return 'APT: Error while checking: $error';
  }

  @override
  String get updateCheckDnfNone => 'DNF: No updates available';

  @override
  String updateCheckDnfHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DNF: $count updates available',
      one: 'DNF: $count update available',
    );
    return '$_temp0';
  }

  @override
  String updateCheckDnfError(String error) {
    return 'DNF: Error while checking: $error';
  }

  @override
  String get updateCheckPacmanNone => 'Pacman: No updates available';

  @override
  String updateCheckPacmanHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pacman: $count updates available',
      one: 'Pacman: $count update available',
    );
    return '$_temp0';
  }

  @override
  String updateCheckPacmanError(String error) {
    return 'Pacman: Error while checking: $error';
  }

  @override
  String get updateCheckSnapNone => 'Snap: No updates available';

  @override
  String updateCheckSnapHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Snap: $count updates available',
      one: 'Snap: $count update available',
    );
    return '$_temp0';
  }

  @override
  String updateCheckSnapError(String error) {
    return 'Snap: Error while checking: $error';
  }

  @override
  String get updateCheckFlatpakNone => 'Flatpak: No updates available';

  @override
  String updateCheckFlatpakHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flatpak: $count updates available',
      one: 'Flatpak: $count update available',
    );
    return '$_temp0';
  }

  @override
  String updateCheckFlatpakError(String error) {
    return 'Flatpak: Error while checking: $error';
  }

  @override
  String updateCheckSummaryPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count packages',
      one: '$count package',
      zero: '0 packages',
    );
    return '$_temp0';
  }

  @override
  String updatesAvailableCount(int count) {
    return '$count updates available';
  }

  @override
  String get updatesAvailableDialogTitle => 'Updates available';

  @override
  String updatesAvailableDialogMessage(int count) {
    return '$count updates are available. Do you want to apply them now?';
  }

  @override
  String get updatesAvailableDetectedListHeading => 'Detected:';

  @override
  String updateLabelPhased(String name) {
    return '$name (phased rollout — not installable yet)';
  }

  @override
  String updatesPreviewTruncated(int count) {
    return '… and $count more';
  }

  @override
  String get updatesAvailablePhasedFooter =>
      'Phased packages cannot be installed yet. \"Apply now\" only applies what your system allows.';

  @override
  String get updatesCheckPreviewHeading => 'Affected items:';

  @override
  String get applyNow => 'Apply now';

  @override
  String get postpone => 'Postpone';

  @override
  String get fontFamily => 'Font Family';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontDefault => 'Default (Roboto)';

  @override
  String get fontRestartMessage =>
      'The font will be applied after restarting the application';

  @override
  String get themeApplyError => 'Error applying theme';

  @override
  String get userThemesExtensionMessage =>
      'For complete Shell themes, install the User Themes extension from extensions.gnome.org';

  @override
  String get themeRequiresOcsUrl =>
      'This theme requires ocs-url to be installed correctly';

  @override
  String get installOcsUrl => 'Install ocs-url';

  @override
  String get ocsUrlNotInstalled =>
      'ocs-url is not installed. Some themes may not work correctly.';

  @override
  String get ocsUrlInstalled => 'ocs-url installed successfully!';

  @override
  String get ocsUrlInstallError =>
      'Error installing ocs-url. Verify that the password is correct and that the package manager is available.';

  @override
  String get installingOcsUrl => 'Installing ocs-url...';

  @override
  String get installingOcsUrlDescription =>
      'This operation is performed automatically on first launch.';

  @override
  String get themeToolsMessage =>
      'To install themes from OpenDesktop.org/Pling.com, install ocs-url or PLing-store. Some themes require these tools to work correctly.';

  @override
  String get refresh => 'Refresh';

  @override
  String get search => 'Search';

  @override
  String get noResults => 'No results found';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get restart => 'Restart';

  @override
  String get enable => 'Enable';

  @override
  String get disable => 'Disable';

  @override
  String get remove => 'Remove';

  @override
  String get kill => 'Kill';

  @override
  String get killForce => 'Force Kill';

  @override
  String get processes => 'Processes';

  @override
  String get system => 'System';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => 'Memory';

  @override
  String get disk => 'Disk';

  @override
  String get gpu => 'GPU';

  @override
  String get usage => 'Usage';

  @override
  String get total => 'Total';

  @override
  String get used => 'Used';

  @override
  String get free => 'Free';

  @override
  String get model => 'Model';

  @override
  String get driver => 'Driver';

  @override
  String get temperature => 'Temperature';

  @override
  String get version => 'Version';

  @override
  String get creator => 'Creator';

  @override
  String get creatorName => 'Marco Di Giangiacomo';

  @override
  String get appDescription =>
      'Super Linux Utility is a desktop application for managing a Linux system: services, startup applications, cleanup, installed packages, resource monitoring and appearance settings.';

  @override
  String get features => 'Features';

  @override
  String get appExpertUsers => 'Application designed for expert Linux users';

  @override
  String get infoProjectWebsite => 'Project website';

  @override
  String get infoChangelog => 'Changelog';

  @override
  String get infoChangelogShowAll => 'View full changelog';

  @override
  String get applicationIdLabel => 'Application ID (desktop)';

  @override
  String get updatesPendingPackagesTitle =>
      'Pending packages (from last check)';

  @override
  String updatesProgressCurrent(String detail) {
    return 'Progress: $detail';
  }

  @override
  String get updatesCommandOutputTitle => 'Command output';

  @override
  String get disclaimerLicenseTitle => 'License & Disclaimer';

  @override
  String get disclaimerGplNotice =>
      'This application is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.';

  @override
  String get disclaimerNoWarranty =>
      'This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.';

  @override
  String get disclaimerCopyright =>
      'Copyright (c) 2024-2025 Marco Di Giangiacomo. All rights reserved under GPL-3.0.';

  @override
  String get payWithPaypal => 'Pay with PayPal';

  @override
  String get purchaseLicenseViaPaypal =>
      'The Advanced version costs 19.99 €. To purchase a license, pay via PayPal. After successful payment you will receive your license code by email. Without valid payment, the application cannot be activated.';

  @override
  String get languageSelectionTitle => 'Language Selection';

  @override
  String get languageSelectionDesc => 'Select the language for the application';

  @override
  String get languageItalian => 'Italian';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'French';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageGerman => 'German';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get settingsLanguageTitle => 'Application Language';

  @override
  String get settingsLanguageDesc => 'Select the interface language';

  @override
  String get languageRestartMessage => 'Language updated';

  @override
  String get servicesSlow => 'Slow Services';

  @override
  String get servicesAll => 'All Services';

  @override
  String get servicesDisabled => 'Disabled';

  @override
  String get analyzeAll => 'Analyze All';

  @override
  String get status => 'Status';

  @override
  String get startupTime => 'Startup time';

  @override
  String get noServicesFound => 'No services found.';

  @override
  String get reEnable => 'Re-enable';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cleanupConfirmTitle => 'Confirm cleanup';

  @override
  String get cleanupConfirmMessage =>
      'Do you want to delete all temporary files? This operation cannot be undone.';

  @override
  String get cleanupSuccess => 'Cleanup completed successfully!';

  @override
  String get cleanupPartialSuccess => 'Cleanup completed with some errors.';

  @override
  String get protectedSystemApp => 'Protected System App';

  @override
  String cannotDisableSystemApp(String appName) {
    return 'Cannot disable \"$appName\" because it is an essential system application.';
  }

  @override
  String get systemAppsRequired =>
      'System apps are required for the proper functioning of the desktop environment and cannot be disabled.';

  @override
  String get checkingDependencies => 'Checking dependencies...';

  @override
  String get warning => '⚠️ Warning';

  @override
  String get packagesDependingOnThis => 'Packages that depend on this:';

  @override
  String get areYouSure => 'Are you sure you want to proceed?';

  @override
  String get confirmRemoval => 'Confirm removal';

  @override
  String removeAppQuestion(String appName) {
    return 'Do you want to remove $appName?';
  }

  @override
  String get searchApp => 'Search app';

  @override
  String get all => 'All';

  @override
  String get searchProcess => 'Search process';

  @override
  String processesSelected(int count) {
    return '$count process selected';
  }

  @override
  String processesSelectedPlural(int count) {
    return '$count processes selected';
  }

  @override
  String get app => 'App';

  @override
  String get cpuPercent => 'CPU %';

  @override
  String get name => 'Name';

  @override
  String get pid => 'PID';

  @override
  String get user => 'User';

  @override
  String get noProcessesFound => 'No processes found.';

  @override
  String get selectAll => 'Select all';

  @override
  String get terminateAll => 'Terminate all';

  @override
  String get terminateAllForce => 'Force terminate all';

  @override
  String get cannotLoadSystemInfo => 'Unable to load system information.';

  @override
  String get cores => 'Cores';

  @override
  String get threads => 'Threads';

  @override
  String get grubInvalidContent => 'GRUB file content is not valid';

  @override
  String get grubConfirmSave => 'Confirm Save';

  @override
  String get grubSaveWarning =>
      'You are about to modify the GRUB configuration. This operation:';

  @override
  String get grubWillCreateBackup => '• Will create an automatic backup';

  @override
  String get grubWillSave => '• Will save the changes';

  @override
  String get grubWillUpdate => '• Will update GRUB';

  @override
  String get grubWarning =>
      'WARNING: Incorrect modifications may prevent the system from booting!';

  @override
  String get saveAndUpdate => 'Save and Update';

  @override
  String get grubSavedSuccess =>
      'GRUB configuration saved and updated successfully';

  @override
  String get grubSaveError => 'Error saving';

  @override
  String get reload => 'Reload';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get restoreBackupQuestion =>
      'Do you want to restore the GRUB configuration backup?';

  @override
  String get restore => 'Restore';

  @override
  String get backupRestoredSuccess => 'Backup restored successfully';

  @override
  String get backupRestoreError => 'Error restoring backup';

  @override
  String get kernelCannotRemoveActive =>
      'Cannot remove the currently active kernel';

  @override
  String get removeKernel => 'Remove Kernel';

  @override
  String removeKernelQuestion(String version) {
    return 'Do you want to remove kernel $version?';
  }

  @override
  String get thisOperation => 'This operation:';

  @override
  String get willRemovePackage => '• Will remove the kernel package';

  @override
  String get willUpdateGrub => '• Will update GRUB';

  @override
  String get kernelWarning =>
      'WARNING: Make sure you have at least one working kernel!';

  @override
  String kernelRemovedSuccess(String version) {
    return 'Kernel $version removed successfully';
  }

  @override
  String get kernelRemoveError => 'Error removing kernel';

  @override
  String get setDefaultKernel => 'Set default kernel (GRUB)';

  @override
  String setDefaultKernelQuestion(String version) {
    return 'Set $version as the default kernel on next boot? GRUB will be updated using administrator commands.';
  }

  @override
  String get set => 'Set';

  @override
  String kernelSetDefaultSuccess(String version) {
    return 'Kernel $version set as default';
  }

  @override
  String get kernelSetDefaultError => 'Error setting default kernel';

  @override
  String get keepMax => 'Keep max:';

  @override
  String get cleanupKernels => 'Kernel Cleanup';

  @override
  String keepOnlyRecentKernels(int count) {
    return 'Do you want to keep only the $count most recent kernels?';
  }

  @override
  String totalKernels(int count) {
    return 'Total kernels: $count';
  }

  @override
  String kernelsToKeep(int count) {
    return 'Kernels to keep: $count';
  }

  @override
  String kernelsToRemove(int count) {
    return 'Kernels to remove: $count';
  }

  @override
  String get cleanupKernelsWarning =>
      'WARNING: Only unused kernels will be removed.';

  @override
  String get cleanup => 'Cleanup';

  @override
  String get kernelCleanupSuccess => 'Kernel cleanup completed successfully';

  @override
  String get kernelCleanupError => 'Error during kernel cleanup';

  @override
  String get invalidKernelCount => 'Enter a valid number of kernels to keep';

  @override
  String get noKernelsFound => 'No installed kernels found';

  @override
  String get updateGrub => 'Update GRUB';

  @override
  String get updateGrubQuestion =>
      'Do you want to update GRUB? This operation will update the bootloader configuration.';

  @override
  String get grubUpdateSuccess => 'GRUB updated successfully';

  @override
  String get grubUpdateError => 'Error updating GRUB';

  @override
  String get rebootSystem => 'Reboot System';

  @override
  String get rebootSystemQuestion =>
      'Do you want to reboot the system? All open applications will be closed.';

  @override
  String get rebootSystemSuccess => 'The system is rebooting...';

  @override
  String get rebootSystemError => 'Error rebooting the system';

  @override
  String get package => 'Package';

  @override
  String get size => 'Size';

  @override
  String get setAsDefault => 'Set as default boot';

  @override
  String get refreshDimensions => 'Refresh Dimensions';

  @override
  String get cleanupTempFiles => 'Clean Temporary Files';

  @override
  String get disableApp => 'Disable App';

  @override
  String get onlyDisable => 'Only Disable';

  @override
  String get systemApps => 'System Apps';

  @override
  String get close => 'Close';

  @override
  String get updateStartupApps => 'Update Startup Apps';

  @override
  String get saving => 'Saving...';

  @override
  String get scaleFactor => 'Scale factor:';

  @override
  String get maximize => 'Maximize';

  @override
  String get minimize => 'Minimize';

  @override
  String get positioning => 'Positioning:';

  @override
  String get left => 'Left';

  @override
  String get right => 'Right';

  @override
  String get buttonOrder => 'Button order:';

  @override
  String get attachedDialogs => 'Attached dialogs';

  @override
  String get centerNewWindows => 'Center new windows';

  @override
  String get resizeWithSecondaryClick => 'Resize with secondary click';

  @override
  String get raiseOnFocus => 'Raise windows when they have focus';

  @override
  String get backgroundImageUpdated => 'Background image updated!';

  @override
  String get backgroundImageError => 'Error updating image.';

  @override
  String get preferredFonts => 'Preferred Fonts';

  @override
  String get interfaceText => 'Interface Text';

  @override
  String get documentText => 'Document Text';

  @override
  String get fixedWidthText => 'Fixed-width Text';

  @override
  String get rendering => 'Rendering';

  @override
  String get hinting => 'Hinting';

  @override
  String get full => 'Full';

  @override
  String get medium => 'Medium';

  @override
  String get light => 'Light';

  @override
  String get antialiasing => 'Antialiasing';

  @override
  String get subpixelLCD => 'Subpixel (for LCD screens)';

  @override
  String get standardGrayscale => 'Standard (grayscale)';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get preview => 'Preview:';

  @override
  String get noImageSelected => 'No image selected';

  @override
  String get command => 'Command:';

  @override
  String get comment => 'Comment:';

  @override
  String get enabledApps => 'Enabled Apps';

  @override
  String get disabledApps => 'Disabled Apps';

  @override
  String get noStartupAppsFound => 'No startup apps found.';

  @override
  String get enabledStatus => 'Enabled';

  @override
  String get disabledStatus => 'Disabled';

  @override
  String get styles => 'Styles';

  @override
  String get cursor => 'Cursor';

  @override
  String get icons => 'Icons';

  @override
  String get legacyApps => 'Legacy Applications';

  @override
  String get background => 'Background';

  @override
  String get defaultImage => 'Default Image';

  @override
  String get darkImage => 'Dark Style Image';

  @override
  String get adjustment => 'Adjustment';

  @override
  String get noneOption => 'None';

  @override
  String get wallpaper => 'Wallpaper';

  @override
  String get centered => 'Centered';

  @override
  String get scaled => 'Scaled';

  @override
  String get stretched => 'Stretched';

  @override
  String get zoom => 'Zoom';

  @override
  String get spanned => 'Spanned';

  @override
  String get windowBehavior => 'Window Behavior';

  @override
  String get titlebarButtons => 'Titlebar Buttons';

  @override
  String get clickActions => 'Click Actions';

  @override
  String get windowFocus => 'Window Focus';

  @override
  String get doubleClick => 'Double Click';

  @override
  String get middleClick => 'Middle Click';

  @override
  String get rightClick => 'Right Click';

  @override
  String get toggleMaximize => 'Toggle Maximize';

  @override
  String get toggleMaximizeHorizontal => 'Toggle Maximize Horizontally';

  @override
  String get toggleMaximizeVertical => 'Toggle Maximize Vertically';

  @override
  String get toggleShade => 'Toggle Shade';

  @override
  String get toggleMenu => 'Toggle Menu';

  @override
  String get lower => 'Lower';

  @override
  String get menu => 'Menu';

  @override
  String get clickForFocus => 'Click for focus';

  @override
  String get focusOnHover => 'Focus on hover';

  @override
  String get focusFollowsMouse => 'Focus follows mouse';

  @override
  String get clickForFocusDesc =>
      'Windows will have focus when you click on them.';

  @override
  String get focusOnHoverDesc =>
      'The window has focus when you hover over it. Windows keep focus when hovering over the desktop.';

  @override
  String get focusFollowsMouseDesc =>
      'The window has focus when you hover over it. Hovering over the desktop removes focus from the previous window.';

  @override
  String get someProcessesNotTerminated =>
      'Some processes were not terminated correctly';

  @override
  String get errorDisabling => 'Error disabling';

  @override
  String appReEnabled(String appName) {
    return 'App $appName re-enabled';
  }

  @override
  String get errorEnabling => 'Error enabling';

  @override
  String removeAppFromStartup(String appName) {
    return 'Do you want to remove $appName from startup?';
  }

  @override
  String appRemoved(String appName) {
    return 'App $appName removed';
  }

  @override
  String get errorRemoving => 'Error removing';

  @override
  String get terminateProcesses => 'Terminate Processes';

  @override
  String get noProcessesRunning => 'No processes running for this app';

  @override
  String get cache => 'Cache';

  @override
  String get swap => 'Swap';

  @override
  String get filesystem => 'Filesystem';

  @override
  String get temperatureUnit => '°C';

  @override
  String get removing => 'Removing...';

  @override
  String get versionLabel => 'Version:';

  @override
  String get selectBasePath => 'Select base path:';

  @override
  String get root => 'Root';

  @override
  String get home => 'Home';

  @override
  String get externalDisks => 'External disks:';

  @override
  String get selectPathToAnalyze => 'Select a path to analyze';

  @override
  String get totalSize => 'Total size';

  @override
  String get files => 'Files';

  @override
  String get directories => 'Directories';

  @override
  String get excluded => 'Excluded';

  @override
  String get exclude => 'Exclude';

  @override
  String get include => 'Include';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get addExcludedFolder => 'Add Excluded Folder';

  @override
  String get enterFolderPath =>
      'Enter the path of the folder to exclude from cleanup:';

  @override
  String get folderPath => 'Folder path';

  @override
  String get folderExcluded => 'Folder added to exclusions';

  @override
  String get folderNotFound => 'Folder not found';

  @override
  String get add => 'Add';

  @override
  String get goBack => 'Back';

  @override
  String get goForward => 'Forward';

  @override
  String get goToRoot => 'Go to root';

  @override
  String get moveToTrash => 'Move to trash';

  @override
  String moveToTrashConfirm(String name) {
    return 'Do you want to move \"$name\" to trash?';
  }

  @override
  String get move => 'Move';

  @override
  String get movedToTrash => 'Moved to trash';

  @override
  String get errorMovingToTrash => 'Error moving to trash';

  @override
  String get deleteFromRootWarning => 'WARNING: Deleting from Root';

  @override
  String deleteFromRootMessage(String name) {
    return 'You are about to delete \"$name\" from the system root directory. This operation requires administrator privileges and may be irreversible. Are you sure you want to proceed?';
  }

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get emptyDirectory => 'Empty directory';

  @override
  String get cannotPreviewFile => 'Cannot preview file';

  @override
  String get fileType => 'File type';

  @override
  String get unknown => 'Unknown';

  @override
  String get directory => 'Directory';

  @override
  String get file => 'File';

  @override
  String get rename => 'Rename';

  @override
  String get newName => 'New name';

  @override
  String get details => 'Details';

  @override
  String get renamedSuccessfully => 'Renamed successfully';

  @override
  String get renameError => 'Error renaming';

  @override
  String get type => 'Type';

  @override
  String get permissions => 'Permissions';

  @override
  String get owner => 'Owner';

  @override
  String get modified => 'Modified';

  @override
  String get path => 'Path';

  @override
  String get usedSpace => 'Used Space';

  @override
  String get freeSpace => 'Free Space';

  @override
  String get pages => 'Pages';

  @override
  String get title => 'Title';

  @override
  String get artist => 'Artist';

  @override
  String get duration => 'Duration';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get resolution => 'Resolution';

  @override
  String get codec => 'Codec';

  @override
  String get showSystemFiles => 'Show system files';

  @override
  String get hideSystemFiles => 'Hide system files';

  @override
  String appDisabled(String appName) {
    return 'App $appName disabled';
  }

  @override
  String appDisabledAndProcessesTerminated(String appName) {
    return 'App $appName disabled and processes terminated';
  }

  @override
  String terminateProcessesQuestion(int count, String appName) {
    return 'Do you want to terminate $count process/es of \"$appName\"?';
  }

  @override
  String get totalSpaceToFree => 'Total space to free:';

  @override
  String get foldersWithErrors => 'Folders with errors:';

  @override
  String andOthers(int count) {
    return 'and $count others';
  }

  @override
  String get recoveryDescription =>
      'This section contains tools to restore altered system functions. Commands are automatically adapted based on the detected Linux distribution.';

  @override
  String get recoveryRestartPipewire => 'Restart Pipewire';

  @override
  String get recoveryRestartPipewireDesc =>
      'Restarts Pipewire, Pipewire-Pulse and Wireplumber services to fix audio issues.';

  @override
  String get recoveryRestoreNetwork => 'Restore Network Services';

  @override
  String get recoveryRestoreNetworkDesc =>
      'Restarts network services (NetworkManager, systemd-networkd) to fix connection issues.';

  @override
  String get recoveryRebuildGrub => 'Rebuild GRUB';

  @override
  String get recoveryRebuildGrubDesc =>
      'Rebuilds GRUB configuration and updates the bootloader. An automatic backup is created.';

  @override
  String get recoveryRestoreFlathub => 'Restore Flathub';

  @override
  String get recoveryRestoreFlathubDesc =>
      'Restores the Flathub repository for Flatpak and updates app metadata.';

  @override
  String get recoveryRestoreRepos => 'Restore Repositories';

  @override
  String get recoveryRestoreReposDesc =>
      'Updates and restores package manager repositories (APT, DNF, Pacman) to fix update issues.';

  @override
  String get recoveryPerformUpdates => 'Perform Updates';

  @override
  String get recoveryPerformUpdatesConfirm =>
      'Do you want to perform the available updates? This operation may take some time.';

  @override
  String get recoveryTabRecovery => 'Recovery';

  @override
  String get recoveryTabSoftwareInstaller => 'System Software Installer';

  @override
  String get recoverySoftwareInstallerDesc =>
      'Download and install essential system software automatically.';

  @override
  String get recoveryInstallFfmpeg => 'FFmpeg';

  @override
  String get recoveryInstallFfmpegDesc =>
      'Multimedia framework for encoding/decoding audio and video.';

  @override
  String get recoveryInstallYtDlp => 'yt-dlp';

  @override
  String get recoveryInstallYtDlpDesc =>
      'Video downloader supporting many sites.';

  @override
  String get recoveryInstallSystemLibs => 'System libraries';

  @override
  String get recoveryInstallSystemLibsDesc =>
      'Essential system libraries that are often required and can get corrupted.';

  @override
  String get recoveryInstallCodecs => 'Video and audio codecs';

  @override
  String get recoveryInstallCodecsDesc =>
      'Codecs for playing common video and audio formats.';

  @override
  String get recoveryInstallRsync => 'rsync';

  @override
  String get recoveryInstallRsyncDesc =>
      'Efficient file sync and transfer tool.';

  @override
  String get recoveryFixWifiAutoSuspend => 'Fix WiFi Auto-Suspend';

  @override
  String get recoveryFixWifiAutoSuspendDesc =>
      'Disables USB auto-suspend for WiFi adapters and internal wireless receivers to prevent random disconnections.';

  @override
  String get install => 'Install';

  @override
  String get execute => 'Execute';

  @override
  String get viewOutput => 'View Output';

  @override
  String get infoServices => 'Services';

  @override
  String get infoServicesAnalysis => 'System services analysis';

  @override
  String get infoServicesAnalysisDesc =>
      'Identifies services that slow down system startup using systemd-analyze blame';

  @override
  String get infoServicesManagement => 'Service management';

  @override
  String get infoServicesManagementDesc =>
      'Enable, disable and restart system services with full control';

  @override
  String get infoServicesStatus => 'Status display';

  @override
  String get infoServicesStatusDesc =>
      'Shows the status of all services (active, inactive, failed)';

  @override
  String get infoStartupApps => 'Startup Apps';

  @override
  String get infoStartupAppsManagement => 'Startup application management';

  @override
  String get infoStartupAppsManagementDesc =>
      'View and manage all applications that start automatically';

  @override
  String get infoStartupAppsProtection => 'System app protection';

  @override
  String get infoStartupAppsProtectionDesc =>
      'Prevents accidental disabling of critical system applications';

  @override
  String get infoStartupAppsTermination => 'Process termination';

  @override
  String get infoStartupAppsTerminationDesc =>
      'Option to terminate app processes when disabled';

  @override
  String get infoCleanup => 'System Cleanup';

  @override
  String get infoCleanupTempFiles => 'Temporary file search';

  @override
  String get infoCleanupTempFilesDesc =>
      'Automatically finds temporary files from common applications (browser, IDE, development)';

  @override
  String get infoCleanupCache => 'Cache cleanup';

  @override
  String get infoCleanupCacheDesc =>
      'Deletes system and application cache to free up space';

  @override
  String get infoCleanupTrash => 'Trash management';

  @override
  String get infoCleanupTrashDesc =>
      'Empties trash and safely cleans temporary files';

  @override
  String get infoInstalledApps => 'Installed Apps';

  @override
  String get infoInstalledAppsManagement => 'Multiple package management';

  @override
  String get infoInstalledAppsManagementDesc =>
      'View apps installed via APT, Snap, Flatpak and GNOME';

  @override
  String get infoInstalledAppsDependencies => 'Dependency check';

  @override
  String get infoInstalledAppsDependenciesDesc =>
      'Checks dependencies before removal to avoid problems';

  @override
  String get infoInstalledAppsWarnings => 'Security warnings';

  @override
  String get infoInstalledAppsWarningsDesc =>
      'Warns when a package is used by other software or the system';

  @override
  String get infoMonitor => 'System Monitor';

  @override
  String get infoMonitorProcesses => 'Process monitoring';

  @override
  String get infoMonitorProcessesDesc =>
      'View all active processes with CPU, memory and disk usage';

  @override
  String get infoMonitorSorting => 'Advanced sorting';

  @override
  String get infoMonitorSortingDesc =>
      'Sort processes by CPU or memory in ascending or descending order';

  @override
  String get infoMonitorTermination => 'Process termination';

  @override
  String get infoMonitorTerminationDesc =>
      'Terminate unresponsive processes directly from the interface';

  @override
  String get infoMonitorSystemInfo => 'System information';

  @override
  String get infoMonitorSystemInfoDesc =>
      'Shows details about CPU, RAM, disks and graphics card';

  @override
  String get infoAppearance => 'Appearance Customization';

  @override
  String get infoAppearanceFonts => 'Font management';

  @override
  String get infoAppearanceFontsDesc =>
      'Configure fonts for interface, documents and monospace text with previews';

  @override
  String get infoAppearanceRendering => 'Advanced rendering';

  @override
  String get infoAppearanceRenderingDesc =>
      'Controls hinting, antialiasing and scale factor';

  @override
  String get infoAppearanceThemes => 'Themes and icons';

  @override
  String get infoAppearanceThemesDesc =>
      'Customize cursor themes, icons and legacy applications with previews';

  @override
  String get infoAppearanceWallpaper => 'Desktop background';

  @override
  String get infoAppearanceWallpaperDesc =>
      'Set background images for light and dark theme';

  @override
  String get infoAppearanceWindows => 'Window behavior';

  @override
  String get infoAppearanceWindowsDesc =>
      'Configure click actions, title bar buttons and window focus';

  @override
  String get infoGrub => 'GRUB Editor (Advanced Mode)';

  @override
  String get infoGrubEditor => 'GRUB configuration editor';

  @override
  String get infoGrubEditorDesc =>
      'Directly edit the /etc/default/grub file with integrated editor';

  @override
  String get infoGrubBackup => 'Automatic backup';

  @override
  String get infoGrubBackupDesc =>
      'Creates automatic backups before each modification';

  @override
  String get infoGrubUpdate => 'GRUB update';

  @override
  String get infoGrubUpdateDesc => 'Applies changes and updates the bootloader';

  @override
  String get infoGrubRestore => 'Backup restore';

  @override
  String get infoGrubRestoreDesc => 'Easily restore a previous configuration';

  @override
  String get infoKernel => 'Kernel Management (Advanced Mode)';

  @override
  String get infoKernelList => 'Installed kernel list';

  @override
  String get infoKernelListDesc =>
      'View all installed kernels with version and size';

  @override
  String get infoKernelRemoval => 'Kernel removal';

  @override
  String get infoKernelRemovalDesc =>
      'Safely remove old kernels (protects current kernel)';

  @override
  String get infoKernelDefault => 'Default kernel setting';

  @override
  String get infoKernelDefaultDesc => 'Choose which kernel to boot by default';

  @override
  String get infoKernelCleanup => 'Automatic cleanup';

  @override
  String get infoKernelCleanupDesc =>
      'Keep only a specified number of most recent kernels';

  @override
  String get infoSecurity => 'Security';

  @override
  String get infoSecurityPassword => 'Password management';

  @override
  String get infoSecurityPasswordDesc =>
      'Safely save administrator password for sudo operations';

  @override
  String get infoSecurityWarning => 'Expert users warning';

  @override
  String get infoSecurityWarningDesc =>
      'Initial warning screen for expert users';

  @override
  String get infoSecurityMode => 'Standard/Advanced Mode';

  @override
  String get infoSecurityModeDesc =>
      'Separates basic features from advanced ones (GRUB, Kernel)';

  @override
  String get recoveryCheckUpdatesComplete => 'Update search completed';

  @override
  String recoveryCheckUpdatesError(String error) {
    return 'Error during update search: $error';
  }

  @override
  String get diskAnalyzerMainDirectories => 'Main Directories';

  @override
  String get diskIndexingNotice =>
      'Disk indexing in progress: the first analysis may take some time. Data will be cached for future sessions.';

  @override
  String get hardwareSuggestionsTitle => 'GRUB Suggestions based on Hardware';

  @override
  String get hardwareSuggestionsDescription =>
      'The following suggestions are based on the analysis of your hardware configuration:';

  @override
  String get hardwareSuggestionsPriorityHigh => 'High';

  @override
  String get hardwareSuggestionsPriorityMedium => 'Medium';

  @override
  String get hardwareSuggestionsPriorityLow => 'Low';

  @override
  String get hardwareSuggestionsApply => 'Apply';

  @override
  String get hardwareSuggestionsCancel => 'Cancel';

  @override
  String get hardwareSuggestionsAlreadyPresent => 'Already present';

  @override
  String hardwareSuggestionsCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String hardwareSuggestionsSuggestedValue(String value) {
    return 'Suggested: $value';
  }

  @override
  String get hardwareSuggestionsAnalyzing => 'Analyzing hardware...';

  @override
  String get hardwareSuggestionsNoAvailable =>
      'No hardware suggestions available.';

  @override
  String hardwareSuggestionsApplied(String parameter) {
    return 'Suggestion applied: $parameter';
  }

  @override
  String hardwareSuggestionsApplyError(String error) {
    return 'Error applying suggestion: $error';
  }

  @override
  String hardwareSuggestionsGenerationError(String error) {
    return 'Error generating suggestions: $error';
  }

  @override
  String grubSuggestionCpuThreadirqs(int count) {
    return 'CPU with $count cores: adding threadirqs can improve multi-core scheduling';
  }

  @override
  String get grubSuggestionCpuMitigationsOff =>
      'Modern CPU: mitigations=off may improve performance (only if you accept the security trade-offs)';

  @override
  String get grubSuggestionCpuIntelIommu =>
      'Intel CPU: enable IOMMU for virtualization and device isolation';

  @override
  String get grubSuggestionCpuAmdIommu =>
      'AMD CPU: enable IOMMU for virtualization and device isolation';

  @override
  String grubSuggestionRamZswapDisable(String gb) {
    return 'System with $gb GB RAM: zswap is often unnecessary';
  }

  @override
  String grubSuggestionRamZswapEnable(String gb) {
    return 'System with $gb GB RAM: zswap may help when memory is tight';
  }

  @override
  String get grubSuggestionGpuNvidiaModeset =>
      'NVIDIA GPU detected: enable nvidia-drm modeset for better display performance';

  @override
  String get grubSuggestionGpuNvidiaVideoMemory =>
      'NVIDIA GPU: preserve video memory allocations across suspend/resume';

  @override
  String get grubSuggestionGpuAmdPpfeaturemask =>
      'AMD GPU: enable the full power-management feature mask';

  @override
  String get grubSuggestionGpuVideoMode =>
      'Set a fixed video mode to reduce early-boot display issues';

  @override
  String get grubSuggestionFirmwareUefiQuietSplash =>
      'UEFI: quiet splash can improve the boot experience';

  @override
  String get grubSuggestionPerfElevatorNone =>
      'SSD-focused storage: elevator=none can improve I/O performance';

  @override
  String get grubSuggestionPerfVmSwappiness =>
      'Lower swappiness when the system has enough RAM';

  @override
  String get grubSuggestionGpuNvidiaWaylandPageTable =>
      'NVIDIA: UsePageAttributeTable improves Wayland rendering performance';

  @override
  String get grubSuggestionGpuNvidiaWaylandResizableBar =>
      'NVIDIA: EnableResizableBar boosts GPU performance 10-15% (PCIe ReBAR)';

  @override
  String get grubSuggestionGpuNvidiaWaylandGpuFirmware =>
      'NVIDIA: EnableGpuFirmware=0 improves Wayland stability and compatibility';

  @override
  String get grubSuggestionGpuNvidiaWaylandFbdev =>
      'NVIDIA: fbdev=1 enables framebuffer console on Wayland';

  @override
  String get settingsPasswordSecurityMessage =>
      'The password is saved securely using the system keyring.';

  @override
  String get tabSmart => 'SMART';

  @override
  String get tabShutdownScheduler => 'Automatic Shutdown';

  @override
  String get shutdownInfoTitle => 'Automatic Shutdown';

  @override
  String get shutdownInfoDescription =>
      'Configure automatic PC shutdown at scheduled times. Uses systemd timers to ensure compatibility with all modern Linux distributions.';

  @override
  String get shutdownSystemdRequired => 'systemd Required';

  @override
  String get shutdownSystemdRequiredDesc =>
      'This feature requires systemd, available on Fedora, Ubuntu, Arch, Debian and other modern Linux distributions.';

  @override
  String get shutdownPasswordRequired =>
      'Password required. Configure the password in settings.';

  @override
  String get shutdownActiveTimers => 'Active Timers';

  @override
  String get shutdownCreateTimer => 'Create New Timer';

  @override
  String get shutdownScheduleType => 'Schedule Type';

  @override
  String get shutdownScheduleDaily => 'Daily';

  @override
  String get shutdownScheduleWeekly => 'Weekly';

  @override
  String get shutdownScheduleMonthly => 'Monthly';

  @override
  String get shutdownTime => 'Time';

  @override
  String get shutdownSelectTime => 'Select Time';

  @override
  String get shutdownSelectDays => 'Select Days';

  @override
  String get shutdownSelectDayOfMonth => 'Select Day of Month';

  @override
  String get shutdownDayOfMonth => 'Day of Month';

  @override
  String get shutdownDaySunday => 'Sunday';

  @override
  String get shutdownDayMonday => 'Monday';

  @override
  String get shutdownDayTuesday => 'Tuesday';

  @override
  String get shutdownDayWednesday => 'Wednesday';

  @override
  String get shutdownDayThursday => 'Thursday';

  @override
  String get shutdownDayFriday => 'Friday';

  @override
  String get shutdownDaySaturday => 'Saturday';

  @override
  String get shutdownTimerCreated => 'Shutdown timer created successfully';

  @override
  String get shutdownTimerRemoved => 'Shutdown timer removed successfully';

  @override
  String get shutdownRemoveConfirm =>
      'Do you want to remove this shutdown timer?';

  @override
  String get shutdownNextRun => 'Next run';

  @override
  String get shutdownStatusInactive => 'Inactive';

  @override
  String get shutdownWeeklyDaysRequired =>
      'Select at least one day of the week';

  @override
  String get shutdownMonthlyDayRequired => 'Select a day of the month';

  @override
  String get shutdownOpenSettings => 'Open Shutdown Settings';

  @override
  String get shutdownEditTimer => 'Edit Timer';

  @override
  String get shutdownTimerDetails => 'Timer Details';

  @override
  String get diskCacheGenerating =>
      'Reading and generating cache in progress... (first time only)';

  @override
  String get licenseActivate => 'Activate Advanced Version';

  @override
  String get licenseActivateButton => 'Activate';

  @override
  String get licenseName => 'First name';

  @override
  String get licenseSurname => 'Last name';

  @override
  String get licenseEmail => 'Email';

  @override
  String get licenseCode => 'License code';

  @override
  String get licenseRequired => 'This field is required';

  @override
  String get licenseActivateSuccess =>
      'Advanced version activated successfully.';

  @override
  String get licenseActivateError =>
      'Invalid code. Check name, surname and email.';

  @override
  String get licenseActivatePremium => 'Activate / Premium';

  @override
  String get licenseActivateCardTitle => 'Activate Advanced Version';

  @override
  String get licenseActivateCardDesc =>
      'The Advanced version costs 19.99 €. Enter your details and the license code you received after successful payment to unlock GRUB, Kernel and Recovery tools. Without valid payment, the application cannot be activated.';

  @override
  String get noSmartDisksFound => 'No disks with SMART support found.';

  @override
  String get smartctlNotFound => 'smartctl not found';

  @override
  String get smartctlInstallPrompt =>
      'smartmontools is required to monitor disk health. Do you want to install it?';

  @override
  String get installing => 'Installing...';

  @override
  String get installSmartctl => 'Install smartmontools';

  @override
  String get selectDisk => 'Select Disk';

  @override
  String get smartHealthPassed => 'Health: PASSED';

  @override
  String get smartHealthFailed => 'Health: FAILED';

  @override
  String get powerOnHours => 'Power-on Hours';

  @override
  String get powerCycleCount => 'Power Cycle Count';

  @override
  String get diskInformation => 'Disk Information';

  @override
  String get serialNumber => 'Serial Number';

  @override
  String get firmware => 'Firmware';

  @override
  String get interface => 'Interface';

  @override
  String get smartAvailable => 'SMART Available';

  @override
  String get smartEnabled => 'SMART Enabled';

  @override
  String get smartAttributes => 'SMART Attributes';

  @override
  String get attributes => 'attributes';

  @override
  String get failedAttributes => 'Failed Attributes';

  @override
  String get attributeId => 'ID';

  @override
  String get attributeName => 'Attribute';

  @override
  String get attributeValue => 'Value';

  @override
  String get attributeWorst => 'Worst';

  @override
  String get attributeThreshold => 'Threshold';

  @override
  String get attributeRaw => 'Raw Value';

  @override
  String get selfTest => 'Self-Test';

  @override
  String get shortTest => 'Short Test';

  @override
  String get longTest => 'Extended Test';

  @override
  String get selfTestHint =>
      'A self-test will be queued on the disk. Check the results later using the attribute table.';

  @override
  String get selfTestStarted =>
      'Self-test started successfully. Check results later.';

  @override
  String get selfTestFailed => 'Failed to start self-test';

  @override
  String get attributeFailedWarning =>
      'This attribute has FAILED! The disk may need replacement.';

  @override
  String get smartDataNotAvailable => 'SMART data not available for this disk.';

  @override
  String get smartUsbInfoTitle => 'USB Drive';

  @override
  String get smartUsbInfoBody =>
      'USB-to-SATA bridges often limit SMART data to health status and temperature. Full attribute table may not be available. If available, try a direct SATA connection.';

  @override
  String get smartSudoPasswordRequired =>
      'Save your sudo password in Settings first.';

  @override
  String get smartInstallFailed => 'Installation failed.';

  @override
  String smartInstallError(String error) {
    return 'Installation error: $error';
  }

  @override
  String get smartErrNoPassword =>
      'Password not saved. Save your password in Settings.';

  @override
  String get smartErrWrongPassword => 'Incorrect password.';

  @override
  String get smartErrPasswordRequired => 'Password required but not provided.';

  @override
  String get smartErrPasswordTimeout => 'Timeout while validating password.';

  @override
  String smartErrPasswordGeneric(String error) {
    return 'Validation error: $error';
  }

  @override
  String smartErrSudo(String error) {
    return 'sudo error: $error';
  }

  @override
  String get smartErrUnsupportedPm => 'Unsupported package manager.';

  @override
  String smartErrUnexpected(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get smartErrAptLock =>
      'Unable to update: another process is using apt. Try again in a few seconds.';

  @override
  String get smartErrAptNoRepos =>
      'Repositories not found. Check your repository configuration.';

  @override
  String smartErrAptUpdateFailed(String error) {
    return 'Cache update failed: $error';
  }

  @override
  String get smartErrDpkgInterrupted =>
      'dpkg was interrupted. Run \"sudo dpkg --configure -a\" and try again.';

  @override
  String get smartErrGpgUnauthenticated =>
      'Unauthenticated packages. Update GPG keys: \"sudo apt-get update\".';

  @override
  String smartErrInstallFailed(String error) {
    return 'Installation failed: $error';
  }

  @override
  String get smartErrNotFoundAfterInstall =>
      'Installation completed but smartctl was not found. Restart the app and try again.';

  @override
  String get servicesGuideTitle => 'Linux Services Guide';

  @override
  String get servicesGuideWhatAre => 'What are Linux Services?';

  @override
  String get servicesGuideWhatAreBody =>
      'Services (also called daemons) are background programs that start automatically when the system boots. They provide essential functions such as network management (NetworkManager), printing (CUPS), scheduling (cron), database servers (MySQL, PostgreSQL), web servers (Apache, Nginx), and many others.\n\nSome services are essential for the system to work correctly, while others are optional and depend on the specific use of the machine.';

  @override
  String get servicesGuideHowToManage => 'How services are managed';

  @override
  String get servicesGuideHowToManageBody =>
      'On modern Linux distributions, services are managed by systemd, the init system. Each service has a unit file (.service) that defines how it starts, stops, and behaves.\n\nIn this application you can:\n• Start and stop a service immediately\n• Enable a service so it starts automatically at boot\n• Disable a service so it does NOT start at boot\n• View the current status and logs of a service';

  @override
  String get servicesGuideHowToDisable =>
      'How to disable a service with this software';

  @override
  String get servicesGuideHowToDisableBody =>
      'From the \"Services\" tab, find the service you want to disable. Tap \"Stop\" to stop it immediately, or tap \"Disable\" to prevent it from starting automatically on the next boot.\n\nYou can also combine the two: tap \"Stop\" and then \"Disable\" to completely deactivate a service until you manually re-enable it.';

  @override
  String get servicesGuidePrecautions => 'Precautions and cautions';

  @override
  String get servicesGuidePrecautionsBody =>
      '• Do NOT disable services you don\'t know: some are essential for the system (e.g. NetworkManager, accounts-daemon, systemd-logind)\n• Disabling network services (NetworkManager, systemd-networkd) will cut off Internet access\n• Disabling display managers (gdm, sddm, lightdm) will prevent the graphical interface from starting\n• Always verify that you don\'t need a service before disabling it\n• The changes are system-wide: they affect all users, not just your account\n• If you make a mistake, you can re-enable the service from the same screen using \"Enable\"';

  @override
  String get servicesGuideDontShowAgain => 'Don\'t show this guide again';

  @override
  String get servicesGuideGotIt => 'Got it!';

  @override
  String get tabRepositories => 'Repositories';

  @override
  String get repoTitle => 'Repositories';

  @override
  String get repoCount => 'repos';

  @override
  String get repoEmpty => 'No repositories found';

  @override
  String repoEnabled(Object name) {
    return '$name enabled';
  }

  @override
  String repoDisabled(Object name) {
    return '$name disabled';
  }

  @override
  String repoRemoved(Object name) {
    return '$name removed';
  }

  @override
  String get repoError => 'Operation failed. Check your sudo password.';

  @override
  String get repoRemoveTitle => 'Remove Repository';

  @override
  String repoRemoveConfirm(Object name) {
    return 'Are you sure you want to remove \"$name\"?';
  }

  @override
  String get repoEditTitle => 'Edit Repository';

  @override
  String get repoFilePathLabel => 'File:';

  @override
  String get repoContentLabel => 'Content';

  @override
  String get repoUpdated => 'Repository updated';

  @override
  String get edit => 'Edit';

  @override
  String get tabTweaks => 'Tweaks';

  @override
  String get tweaksSwap => 'Swap';

  @override
  String get tweaksSwapRecommendations => 'Swap Recommendations';

  @override
  String get appCheckForUpdates => 'Check for updates';

  @override
  String get kernelUpdateDetectedLiquorix => 'Liquorix kernel update available';

  @override
  String get kernelUpdateDetectedXanmod => 'Xanmod kernel update available';

  @override
  String get tabSystemStatus => 'System Status';

  @override
  String get tabSecurity => 'Security';

  @override
  String get tabKernelTweaks => 'Kernel Tweaks';

  @override
  String get tabOperationHistory => 'History';

  @override
  String get statusRefresh => 'Refresh';

  @override
  String get statusReadOnlyNote =>
      'Read-only system information. Nothing is modified.';

  @override
  String get statusTabKernel => 'Kernel';

  @override
  String get statusTabSecurity => 'Security';

  @override
  String get statusTabVirtualization => 'Virtualization';

  @override
  String get statusTabPrinters => 'Printers';

  @override
  String get statusEnabled => 'Enabled';

  @override
  String get statusDisabled => 'Disabled';

  @override
  String get statusNotAvailable => 'Not available';

  @override
  String get statusNotInstalled => 'Not installed';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get statusNone => 'None';

  @override
  String get statusEnforcing => 'Enforcing';

  @override
  String get statusPermissive => 'Permissive';

  @override
  String get statusKernelInfo => 'Kernel information';

  @override
  String get statusKernelVersion => 'Version';

  @override
  String get statusKernelBuild => 'Build';

  @override
  String get statusCpuCount => 'CPU count';

  @override
  String get statusKernelTuning => 'Kernel tuning';

  @override
  String get statusThpMode => 'Transparent Huge Pages';

  @override
  String get statusZswap => 'Zswap';

  @override
  String get statusGovernor => 'CPU governor';

  @override
  String get statusIoScheduler => 'I/O scheduler';

  @override
  String get statusMandatoryAccess => 'Mandatory access control';

  @override
  String get statusAppArmor => 'AppArmor';

  @override
  String get statusSelinux => 'SELinux';

  @override
  String get statusSecureBoot => 'Secure Boot';

  @override
  String get statusNetworkSecurity => 'Network security';

  @override
  String get statusFirewall => 'Firewall';

  @override
  String get statusFirewallBackend => 'Firewall backend';

  @override
  String get statusSshService => 'SSH service';

  @override
  String get statusRootSsh => 'Root SSH login';

  @override
  String get statusAutoUpdates => 'Automatic updates';

  @override
  String get statusVirtHost => 'Virtualization host';

  @override
  String get statusCpuVirt => 'CPU virtualization';

  @override
  String get statusKvmModule => 'KVM module';

  @override
  String get statusIommu => 'IOMMU';

  @override
  String get statusVirtAux => 'Virtualization support';

  @override
  String get statusVfio => 'VFIO';

  @override
  String get statusKsm => 'KSM';

  @override
  String get statusDocker => 'Docker';

  @override
  String get statusLibvirt => 'Libvirt';

  @override
  String get statusCups => 'CUPS';

  @override
  String get statusCupsService => 'CUPS service';

  @override
  String get statusPrinters => 'Printers';

  @override
  String get statusPrinterDrivers => 'Printer drivers';

  @override
  String get securitySubtitle =>
      'Manage system security services. Every action is recorded in the operation history and can be undone.';

  @override
  String get securityFirewall => 'Firewall';

  @override
  String get securityFirewallDesc =>
      'Blocks unsolicited incoming connections using UFW or firewalld.';

  @override
  String securityFirewallBackend(Object backend) {
    return 'Active ($backend)';
  }

  @override
  String get securitySsh => 'SSH service';

  @override
  String get securitySshDesc => 'Remote shell access over the network.';

  @override
  String get securityRootSsh => 'Root SSH login';

  @override
  String get securityRootSshDesc => 'Allow or deny direct root login over SSH.';

  @override
  String get securityRootAllowed => 'Root login allowed';

  @override
  String get securityAutoUpdates => 'Automatic updates';

  @override
  String get securityAutoUpdatesDesc =>
      'Install security updates automatically in the background.';

  @override
  String get kernelTweaksSubtitle =>
      'Apply kernel settings persistently: they are reapplied at every boot.';

  @override
  String get kernelTweaksPersistNote =>
      'No persistent tweaks active yet. Applied settings are saved to a systemd service and reapplied at every boot.';

  @override
  String get kernelTweaksPersistActive =>
      'Persistent kernel tweaks are active and reapplied at every boot.';

  @override
  String get kernelTweaksApply => 'Apply';

  @override
  String get kernelTweaksReset => 'Reset';

  @override
  String get kernelTweaksResetTitle => 'Reset kernel tweaks';

  @override
  String get kernelTweaksResetConfirm =>
      'This removes the persistent kernel tweaks and restores the default values. Continue?';

  @override
  String get kernelTweaksThp => 'Transparent Huge Pages';

  @override
  String get kernelTweaksThpDesc =>
      'Mode used for transparent huge page allocation.';

  @override
  String get kernelTweaksGovernor => 'CPU governor';

  @override
  String get kernelTweaksGovernorDesc =>
      'CPU frequency scaling policy applied to all cores.';

  @override
  String get kernelTweaksScheduler => 'CPU scheduler';

  @override
  String get kernelTweaksSchedulerDesc =>
      'Run newly forked child processes before the parent for better responsiveness.';

  @override
  String get kernelTweaksPerf => 'Performance';

  @override
  String get kernelTweaksOndemand => 'On-demand';

  @override
  String get kernelTweaksSchedutil => 'Schedutil';

  @override
  String get kernelTweaksPowersave => 'Powersave';

  @override
  String get kernelTweaksAlways => 'Always';

  @override
  String get kernelTweaksMadvise => 'Madvise';

  @override
  String get kernelTweaksNever => 'Never';

  @override
  String get kernelTweaksSchedOn => 'Child first';

  @override
  String get kernelTweaksSchedOff => 'Default';

  @override
  String get historySubtitle =>
      'Record of performed operations. Restore to undo an action.';

  @override
  String get historyEmpty => 'No operations recorded yet.';

  @override
  String get historyRestore => 'Restore';

  @override
  String get historyRestoreTitle => 'Restore operation';

  @override
  String get historyRestoreConfirm =>
      'This will revert the changes of this operation. Continue?';

  @override
  String get historyRestored => 'Restored';

  @override
  String get historyClearAll => 'Clear history';

  @override
  String get historyClearTitle => 'Clear history';

  @override
  String get historyClearConfirm =>
      'Remove all recorded operations from the history. Nothing is undone. Continue?';

  @override
  String get historyFirewallEnable => 'Firewall enabled';

  @override
  String get historyFirewallDisable => 'Firewall disabled';

  @override
  String get historySshEnable => 'SSH service enabled';

  @override
  String get historySshDisable => 'SSH service disabled';

  @override
  String get historyRootAllow => 'Root SSH login allowed';

  @override
  String get historyRootDeny => 'Root SSH login denied';

  @override
  String get historyAutoUpdateEnable => 'Automatic updates enabled';

  @override
  String get historyAutoUpdateDisable => 'Automatic updates disabled';

  @override
  String get historyKernelApply => 'Kernel tweaks applied';

  @override
  String get historyKernelReset => 'Kernel tweaks reset';

  @override
  String get kernelTweaksCurrent => 'Current';

  @override
  String get kernelTweaksSavedForBoot => 'Saved for boot';

  @override
  String get tabDeviceManager => 'Device Manager';

  @override
  String get deviceManagerTitle => 'Device Manager';

  @override
  String get deviceManagerLoading => 'Detecting devices...';

  @override
  String get deviceManagerEmpty => 'No devices found';

  @override
  String get deviceManagerRefresh => 'Refresh';

  @override
  String get deviceManagerEnable => 'Enable';

  @override
  String get deviceManagerDisable => 'Disable';

  @override
  String get deviceManagerEnabled => 'Enabled';

  @override
  String get deviceManagerDisabled => 'Disabled';

  @override
  String deviceManagerToggleSuccess(Object action) {
    return 'Device $action successfully';
  }

  @override
  String deviceManagerToggleError(Object action) {
    return 'Failed to $action device';
  }

  @override
  String get deviceManagerCannotDisable => 'This device cannot be disabled';

  @override
  String get deviceManagerDetails => 'Details';

  @override
  String get deviceManagerDriver => 'Driver';

  @override
  String get deviceManagerBus => 'Bus';

  @override
  String get deviceManagerVendor => 'Vendor';

  @override
  String get deviceManagerProduct => 'Product';

  @override
  String get deviceManagerConfirmTitle => 'Confirm action';

  @override
  String get deviceManagerConfirmDisable =>
      'Disabling this device may cause system instability. The change will persist across reboots. Continue?';

  @override
  String get deviceManagerConfirmEnable =>
      'Enable this device? The change will persist across reboots. Continue?';

  @override
  String get deviceManagerAllDevices => 'All devices';

  @override
  String get deviceManagerShowDisabled => 'Show disabled';

  @override
  String get deviceManagerStatus => 'Status';

  @override
  String get deviceManagerProperties => 'Properties';

  @override
  String get deviceManagerClose => 'Close';

  @override
  String get deviceManagerNoSudo =>
      'Save administrator password in Settings first';

  @override
  String get deviceManagerPersistent => 'Persists on reboot';

  @override
  String get tabDriverManager => 'Drivers';

  @override
  String get driverManagerTitle => 'Driver & Firmware Manager';

  @override
  String get driverManagerScan => 'Scan hardware';

  @override
  String get driverManagerFirmwareUpdates => 'Firmware Updates';

  @override
  String get driverManagerAvailableDrivers => 'Available drivers';

  @override
  String get driverManagerInstalledDrivers => 'Installed drivers';

  @override
  String get driverManagerAllDriversInstalled =>
      'All known drivers are installed';

  @override
  String get driverManagerNoDriversInstalled => 'No managed drivers installed';

  @override
  String get driverManagerCurrentDriver => 'Current driver';

  @override
  String get driverManagerPackage => 'Package';

  @override
  String get driverManagerInstall => 'Install';

  @override
  String get driverManagerUpdate => 'Update';

  @override
  String get driverManagerRebootRequired => 'Reboot required after update';

  @override
  String get driverManagerLinuxFirmware => 'Linux Firmware (linux-firmware)';

  @override
  String get driverManagerLinuxFirmwareDesc =>
      'Complete firmware package for GPU, Wi-Fi, Bluetooth and other devices';
}
