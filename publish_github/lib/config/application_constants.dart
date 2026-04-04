/// Identificativi desktop / DBus / GTK (allineato a `APPLICATION_ID` in `linux/CMakeLists.txt`).
abstract final class ApplicationConstants {
  ApplicationConstants._();

  /// ID applicazione Linux (Flutter runner / .desktop StartupWMClass).
  static const String applicationId = 'com.superlinux.utility';

  /// Nome file .desktop consigliato per installazioni che seguono l’ID reverse-DNS.
  static const String desktopFileBaseName = 'com.superlinux.utility.desktop';

  /// Nome binario Linux (`BINARY_NAME` in `linux/CMakeLists.txt`), usato per validare il lock single-instance.
  static const String linuxExecutableName = 'super_linux_utility';
}
