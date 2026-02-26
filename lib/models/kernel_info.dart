class KernelInfo {
  final String version;
  final String packageName;
  final bool isInstalled;
  final bool isActive; // Kernel attualmente in uso
  final bool isDefault; // Kernel di default per il prossimo avvio
  final String? description;
  final int? size; // Dimensione in bytes

  KernelInfo({
    required this.version,
    required this.packageName,
    required this.isInstalled,
    this.isActive = false,
    this.isDefault = false,
    this.description,
    this.size,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'packageName': packageName,
        'isInstalled': isInstalled,
        'isActive': isActive,
        'isDefault': isDefault,
        'description': description,
        'size': size,
      };
}

