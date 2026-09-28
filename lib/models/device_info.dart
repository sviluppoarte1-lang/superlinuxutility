/// Dispositivo hardware rilevato dal sistema.
class DeviceInfo {
  final String id; // PCI slot, USB bus:dev, sysfs path, etc.
  final String name;
  final String category;
  final String? vendor;
  final String? vendorId;
  final String? deviceId;
  final String? driver;
  final bool enabled;
  final bool canDisable; // root bridges, CPU etc. non si possono disabilitare
  final String? bus; // pci, usb, platform, etc.
  final String? details; // info aggiuntive

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.category,
    this.vendor,
    this.vendorId,
    this.deviceId,
    this.driver,
    this.enabled = true,
    this.canDisable = true,
    this.bus,
    this.details,
  });

  DeviceInfo copyWith({bool? enabled}) => DeviceInfo(
    id: id,
    name: name,
    category: category,
    vendor: vendor,
    vendorId: vendorId,
    deviceId: deviceId,
    driver: driver,
    enabled: enabled ?? this.enabled,
    canDisable: canDisable,
    bus: bus,
    details: details,
  );
}

/// Categoria di dispositivi (simile a Gestione Periferiche Windows XP).
class DeviceCategory {
  final String name;
  final String icon;
  final List<DeviceInfo> devices;

  const DeviceCategory({
    required this.name,
    required this.icon,
    required this.devices,
  });

  bool get allDisabled => devices.every((d) => !d.enabled);
  bool get allEnabled => devices.every((d) => d.enabled);
}
