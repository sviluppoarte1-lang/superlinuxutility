enum PackageManager {
  apt,
  snap,
  flatpak,
  gnome,
}

class InstalledApp {
  final String name;
  final String? version;
  final String? description;
  final PackageManager packageManager;
  final int? size; // Dimensione in bytes
  final bool isSystemPackage; // Se è un pacchetto di sistema
  List<String> dependencies; // Dipendenze del pacchetto
  List<String> reverseDependencies; // Pacchetti che dipendono da questo

  InstalledApp({
    required this.name,
    this.version,
    this.description,
    required this.packageManager,
    this.size,
    this.isSystemPackage = false,
    List<String>? dependencies,
    List<String>? reverseDependencies,
  })  : dependencies = dependencies ?? [],
        reverseDependencies = reverseDependencies ?? [];

  /// Verifica se il pacchetto può essere rimosso in sicurezza
  bool get canSafelyRemove {
    // Non rimuovere pacchetti di sistema
    if (isSystemPackage) return false;
    // Non rimuovere se altri pacchetti dipendono da questo
    if (reverseDependencies.isNotEmpty) return false;
    return true;
  }

  /// Ottiene un messaggio di avviso se il pacchetto non può essere rimosso in sicurezza
  String? get warningMessage {
    if (isSystemPackage) {
      return 'Questo è un pacchetto di sistema. Rimuoverlo potrebbe compromettere il funzionamento del sistema.';
    }
    if (reverseDependencies.isNotEmpty) {
      return 'Altri ${reverseDependencies.length} pacchetto/i dipendono da questo: ${reverseDependencies.take(3).join(", ")}${reverseDependencies.length > 3 ? "..." : ""}';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'description': description,
        'packageManager': packageManager.toString(),
        'size': size,
        'isSystemPackage': isSystemPackage,
        'dependencies': dependencies,
        'reverseDependencies': reverseDependencies,
      };
}

