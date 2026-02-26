class SystemProcess {
  final int pid;
  final String name;
  final String user;
  final double cpuPercent;
  final int memoryBytes;
  final String? command;
  final String state; // R, S, D, Z, etc.
  final int? parentPid;

  SystemProcess({
    required this.pid,
    required this.name,
    required this.user,
    required this.cpuPercent,
    required this.memoryBytes,
    this.command,
    this.state = '',
    this.parentPid,
  });

  String get memoryFormatted {
    if (memoryBytes < 1024) {
      return '$memoryBytes B';
    } else if (memoryBytes < 1024 * 1024) {
      return '${(memoryBytes / 1024).toStringAsFixed(1)} KB';
    } else if (memoryBytes < 1024 * 1024 * 1024) {
      return '${(memoryBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(memoryBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Map<String, dynamic> toJson() => {
        'pid': pid,
        'name': name,
        'user': user,
        'cpuPercent': cpuPercent,
        'memoryBytes': memoryBytes,
        'command': command,
        'state': state,
        'parentPid': parentPid,
      };
}

