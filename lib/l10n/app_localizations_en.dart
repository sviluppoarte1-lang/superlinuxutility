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
  String get trayShutdownTimer => 'Automatic shutdown';

  @override
  String get trayShowMainWindow => 'Show main window';

  @override
  String get trayCpuGpuUsage => 'CPU, GPU usage';

  @override
  String get trayExit => 'Exit';

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
      'Super Linux Utility is a complete application for advanced Linux system management. It offers powerful tools to optimize performance, manage services, applications and customize the system appearance.';

  @override
  String get features => 'Features';

  @override
  String get appExpertUsers => 'Application designed for expert Linux users';

  @override
  String get infoProjectWebsite => 'Project website';

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
  String get languageRestartMessage =>
      'The language will be applied when the application restarts';

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
  String get setDefaultKernel => 'Set Default Kernel';

  @override
  String setDefaultKernelQuestion(String version) {
    return 'Do you want to set $version as the default kernel?';
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
  String get setAsDefault => 'Set as Default';

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
  String get recoveryCheckUpdates => 'Check for Updates';

  @override
  String get recoveryCheckUpdatesDesc =>
      'Checks for available updates for all installed package managers (APT, DNF, Pacman, Snap, Flatpak).';

  @override
  String get recoveryPerformUpdates => 'Perform Updates';

  @override
  String get recoveryPerformUpdatesConfirm =>
      'Do you want to perform the available updates? This operation may take some time.';

  @override
  String get recoveryTabRecovery => 'Recovery';

  @override
  String get recoveryTabCheckUpdates => 'Check for Updates';

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
  String get settingsPasswordSecurityMessage =>
      'The password is saved securely using the system keyring.';

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
}
