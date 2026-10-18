enum PackageManager {
  apt,
  snap,
  flatpak,
  gnome,
  pacman,
  dnf,
}

class InstalledApp {
  final String name;
  final String? version;
  final String? description;
  final PackageManager packageManager;
  final int? size; // Dimensione in bytes
  final bool isSystemPackage; // Se è un pacchetto di sistema
  final String? desktopFile; // Solo gnome: percorso completo del file .desktop
  final String? installation; // Solo flatpak: 'user' | 'system' | 'both'
  List<String> dependencies; // Dipendenze del pacchetto
  List<String> reverseDependencies; // Pacchetti che dipendono da questo

  InstalledApp({
    required this.name,
    this.version,
    this.description,
    required this.packageManager,
    this.size,
    this.isSystemPackage = false,
    this.desktopFile,
    this.installation,
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'description': description,
        'packageManager': packageManager.toString(),
        'size': size,
        'isSystemPackage': isSystemPackage,
        'desktopFile': desktopFile,
        'installation': installation,
        'dependencies': dependencies,
        'reverseDependencies': reverseDependencies,
      };
}
