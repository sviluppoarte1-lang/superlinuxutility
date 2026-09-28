class SmartDisk {
  final String device;
  final String model;
  final String? serial;
  final String? firmware;
  final String interface;
  final String? deviceType;

  const SmartDisk({
    required this.device,
    required this.model,
    this.serial,
    this.firmware,
    this.interface = 'Unknown',
    this.deviceType,
  });

  String get smartctlArgs {
    if (deviceType == null || deviceType == 'scsi') return '"$device"';
    return '-d $deviceType "$device"';
  }

  String get displayInterface {
    if (interface == 'sat' || interface == 'usb') return 'USB (SAT)';
    if (interface == 'nvme') return 'NVMe';
    if (interface == 'scsi') return 'SATA';
    return interface;
  }
}

class SmartAttribute {
  final int id;
  final String name;
  final int value;
  final int worst;
  final int threshold;
  final String rawValue;
  final bool failed;
  final bool isCritical;

  const SmartAttribute({
    required this.id,
    required this.name,
    required this.value,
    required this.worst,
    required this.threshold,
    required this.rawValue,
    this.failed = false,
    this.isCritical = false,
  });
}

class SmartOverallHealth {
  final String device;
  final String model;
  final bool passed;
  final String? rawStatus;

  const SmartOverallHealth({
    required this.device,
    required this.model,
    required this.passed,
    this.rawStatus,
  });
}

class SmartInfo {
  final SmartDisk disk;
  final bool smartAvailable;
  final bool smartEnabled;
  final bool overallHealthPassed;
  final int? temperature;
  final int? powerOnHours;
  final int? powerCycleCount;
  final List<SmartAttribute> attributes;
  final String? rawJson;

  const SmartInfo({
    required this.disk,
    required this.smartAvailable,
    required this.smartEnabled,
    required this.overallHealthPassed,
    this.temperature,
    this.powerOnHours,
    this.powerCycleCount,
    this.attributes = const [],
    this.rawJson,
  });
}
