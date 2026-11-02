class StartupApp {
  final String name;
  final String command;
  final String? comment;
  final bool isEnabled;
  final String? desktopFile;
  final bool isProtected;

  /// Voce di sistema nascosta (`NoDisplay=true` nel .desktop): è un
  /// semaforo/agente di background, mai lanciato dall'utente. Utile per non
  /// giudicarla con lo storico dei file recenti (non ne compare mai).
  final bool noDisplay;

  StartupApp({
    required this.name,
    required this.command,
    this.comment,
    required this.isEnabled,
    this.desktopFile,
    this.isProtected = false,
    this.noDisplay = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'command': command,
        'comment': comment,
        'isEnabled': isEnabled,
        'desktopFile': desktopFile,
        'isProtected': isProtected,
        'noDisplay': noDisplay,
      };
}

