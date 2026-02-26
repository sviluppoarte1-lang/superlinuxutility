class SystemInfo {
  final CpuInfo cpu;
  final MemoryInfo memory;
  final List<DiskInfo> disks;
  final GpuInfo? gpu;

  SystemInfo({
    required this.cpu,
    required this.memory,
    required this.disks,
    this.gpu,
  });
}

class CpuInfo {
  final String model;
  final int cores;
  final int threads;
  final double usagePercent;
  final List<double> coreUsage;

  CpuInfo({
    required this.model,
    required this.cores,
    required this.threads,
    required this.usagePercent,
    this.coreUsage = const [],
  });
}

class MemoryInfo {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final int cachedBytes;
  final int swapTotalBytes;
  final int swapUsedBytes;

  MemoryInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.cachedBytes,
    required this.swapTotalBytes,
    required this.swapUsedBytes,
  });

  double get usagePercent => totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0;
  double get swapUsagePercent => swapTotalBytes > 0 ? (swapUsedBytes / swapTotalBytes) * 100 : 0;

  String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

class DiskInfo {
  final String device;
  final String mountPoint;
  final String fileSystem;
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final bool isExternal;

  DiskInfo({
    required this.device,
    required this.mountPoint,
    required this.fileSystem,
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    this.isExternal = false,
  });

  double get usagePercent => totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0;

  String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

class GpuInfo {
  final String model;
  final String driver;
  final int? memoryTotalBytes;
  final int? memoryUsedBytes;
  final double? usagePercent;
  final double? temperature;

  GpuInfo({
    required this.model,
    required this.driver,
    this.memoryTotalBytes,
    this.memoryUsedBytes,
    this.usagePercent,
    this.temperature,
  });

  double? get memoryUsagePercent {
    if (memoryTotalBytes == null || memoryTotalBytes == 0) return null;
    if (memoryUsedBytes == null) return null;
    return (memoryUsedBytes! / memoryTotalBytes!) * 100;
  }
}

