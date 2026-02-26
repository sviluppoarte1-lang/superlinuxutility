class SystemdService {
  final String name;
  final String status;
  final Duration? activeTime;
  final Duration? bootTime;
  final bool isEnabled;
  final bool isActive;
  final String? description;
  final bool isSlow; // Indica se il servizio rallenta l'avvio

  SystemdService({
    required this.name,
    required this.status,
    this.activeTime,
    this.bootTime,
    required this.isEnabled,
    required this.isActive,
    this.description,
    this.isSlow = false,
  });

  factory SystemdService.fromString(String line) {
    // Parsing della linea di systemctl list-units
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) {
      throw FormatException('Invalid systemd service line: $line');
    }

    final name = parts[0];
    final status = parts[2];
    final isActive = status == 'active';
    final isEnabled = parts.length > 3 && parts[3] == 'enabled';

    return SystemdService(
      name: name,
      status: status,
      isActive: isActive,
      isEnabled: isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'status': status,
        'activeTime': activeTime?.inMilliseconds,
        'bootTime': bootTime?.inMilliseconds,
        'isEnabled': isEnabled,
        'isActive': isActive,
        'description': description,
        'isSlow': isSlow,
      };
}

