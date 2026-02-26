class StartupApp {
  final String name;
  final String command;
  final String? comment;
  final bool isEnabled;
  final String? desktopFile;
  final bool isProtected;

  StartupApp({
    required this.name,
    required this.command,
    this.comment,
    required this.isEnabled,
    this.desktopFile,
    this.isProtected = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'command': command,
        'comment': comment,
        'isEnabled': isEnabled,
        'desktopFile': desktopFile,
        'isProtected': isProtected,
      };
}

