import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

/// Soft memory hygiene for long-running sessions (Flutter image cache grows unbounded by default).
///
/// Does not replace fixing real leaks; it evicts decoded images so RSS can drop after GC.
abstract final class AppMemoryMaintenance {
  AppMemoryMaintenance._();

  /// [HomeScreen] sets this so hiding to tray can leave heavy tabs (disk analyzer, monitor, …)
  /// and let [TabBarView] dispose their state.
  static void Function()? onMainWindowHiddenToTray;

  /// Schedules a trim after the current frame (safe for the raster pipeline).
  static void requestTrim() {
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _trimNow();
    });
  }

  /// When the main window goes to the system tray: optional tab reset (callback) then
  /// aggressive image cache eviction on the next frame.
  static void notifyMainWindowHiddenToTray() {
    try {
      onMainWindowHiddenToTray?.call();
    } catch (_) {}
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _trimNowAggressive();
    });
  }

  static void _trimNow() {
    try {
      final cache = PaintingBinding.instance.imageCache;
      cache.clear();
      cache.clearLiveImages();
    } catch (_) {}
  }

  static void _trimNowAggressive() {
    try {
      final cache = PaintingBinding.instance.imageCache;
      final maxCount = cache.maximumSize;
      final maxBytes = cache.maximumSizeBytes;
      cache.clear();
      cache.clearLiveImages();
      cache.maximumSize = 1;
      cache.maximumSizeBytes = 1;
      cache.clear();
      cache.clearLiveImages();
      cache.maximumSize = maxCount;
      cache.maximumSizeBytes = maxBytes;
    } catch (_) {}
  }
}
