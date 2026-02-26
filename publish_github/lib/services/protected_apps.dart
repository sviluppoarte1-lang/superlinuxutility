/// Servizio per gestire le app di sistema protette che non possono essere disabilitate
class ProtectedApps {
  /// Lista di app protette per Ubuntu, Debian e Linux Mint
  /// Queste app sono essenziali per il funzionamento del sistema o del desktop environment
  /// e non dovrebbero essere disabilitate
  static final Set<String> _protectedAppNames = {
    // KDE Plasma - Calendar e Reminders
    'Calindori Reminder Client',
    'Calendar Reminders',
    'KDE Plasma Workspace',
    'Plasma Desktop',
    'Plasma Workspace',
    
    // GNOME Desktop
    'GNOME Shell',
    'GNOME Settings Daemon',
    'GNOME Keyring',
    'GNOME Shell Extensions',
    'GNOME Software',
    'GNOME Initial Setup',
    
    // Desktop Environment Core
    'Desktop Environment',
    'Session Manager',
    'Window Manager',
    'Display Manager',
    
    // System Services (come app all'avvio)
    'Network Manager',
    'Bluetooth Manager',
    'Audio System',
    'Print Manager',
    'Update Manager',
    'Package Manager',
    
    // XDG Autostart System Apps
    'XDG Autostart',
    'Desktop Integration',
  };

  /// Lista di comandi protetti (eseguibili)
  static final Set<String> _protectedCommands = {
    // KDE Plasma
    'calindac',
    'kalendarac',
    'plasma-desktop',
    'plasma-workspace',
    'kwin',
    'ksmserver',
    'startkde',
    
    // GNOME
    'gnome-shell',
    'gnome-settings-daemon',
    'gnome-keyring-daemon',
    'gnome-session',
    'gnome-session-binary',
    
    // Desktop Environment
    'dbus-daemon',
    'dbus-launch',
    'systemd',
    'systemd-user',
    
    // System Managers
    'NetworkManager',
    'bluetoothd',
    'pulseaudio',
    'cupsd',
    'gdm',
    'lightdm',
    'sddm',
    
    // XDG
    'xdg-desktop-portal',
    'xdg-desktop-portal-gtk',
    'xdg-desktop-portal-kde',
  };

  /// Lista di percorsi protetti (file .desktop in /etc/xdg/autostart)
  static final Set<String> _protectedPaths = {
    '/etc/xdg/autostart',
  };

  /// Verifica se un'app è protetta basandosi su nome, comando o percorso
  static bool isProtected({
    required String name,
    required String command,
    String? desktopFile,
  }) {
    // Controlla se il nome è protetto
    if (_protectedAppNames.any((protected) => 
        name.toLowerCase().contains(protected.toLowerCase()))) {
      return true;
    }

    // Controlla se il comando è protetto
    final commandLower = command.toLowerCase();
    if (_protectedCommands.any((protected) => 
        commandLower.contains(protected.toLowerCase()))) {
      return true;
    }

    // Controlla se il percorso è protetto (app di sistema in /etc/xdg/autostart)
    if (desktopFile != null && 
        _protectedPaths.any((path) => desktopFile.startsWith(path))) {
      // Verifica anche se è un'app KDE/Plasma o GNOME essenziale
      if (_isSystemDesktopApp(name, command, desktopFile)) {
        return true;
      }
    }

    return false;
  }

  /// Verifica se è un'app desktop di sistema essenziale
  static bool _isSystemDesktopApp(String name, String command, String desktopFile) {
    // App KDE/Plasma essenziali
    if (name.toLowerCase().contains('calendar') ||
        name.toLowerCase().contains('reminder') ||
        name.toLowerCase().contains('calindori') ||
        command.contains('calindac') ||
        command.contains('kalendarac')) {
      return true;
    }

    // App GNOME essenziali
    if (name.toLowerCase().contains('gnome') ||
        command.contains('gnome-')) {
      return true;
    }

    // App di sistema comuni
    final systemKeywords = [
      'session',
      'desktop',
      'workspace',
      'keyring',
      'settings',
      'manager',
      'daemon',
    ];

    final nameLower = name.toLowerCase();
    final commandLower = command.toLowerCase();
    
    // Se contiene più di una parola chiave di sistema, è probabilmente protetta
    int matches = 0;
    for (final keyword in systemKeywords) {
      if (nameLower.contains(keyword) || commandLower.contains(keyword)) {
        matches++;
      }
    }

    // Se ha 2 o più keyword di sistema, è probabilmente un'app protetta
    return matches >= 2;
  }

  /// Ottiene un messaggio di avviso personalizzato per un'app protetta
  static String getWarningMessage(String appName) {
    if (appName.toLowerCase().contains('calendar') ||
        appName.toLowerCase().contains('reminder') ||
        appName.toLowerCase().contains('calindori')) {
      return 'Questa applicazione è parte integrante del desktop environment KDE Plasma e gestisce i promemoria del calendario. Disabilitarla potrebbe causare malfunzionamenti nel sistema di notifiche e promemoria.';
    }

    if (appName.toLowerCase().contains('gnome')) {
      return 'Questa applicazione è parte integrante del desktop environment GNOME. Disabilitarla potrebbe causare malfunzionamenti gravi nel sistema.';
    }

    if (appName.toLowerCase().contains('plasma') ||
        appName.toLowerCase().contains('kde')) {
      return 'Questa applicazione è parte integrante del desktop environment KDE Plasma. Disabilitarla potrebbe causare malfunzionamenti gravi nel sistema.';
    }

    return 'Questa applicazione è essenziale per il funzionamento del sistema o del desktop environment. Disabilitarla potrebbe causare instabilità o impedire il corretto funzionamento di alcune funzionalità del sistema.';
  }
}

