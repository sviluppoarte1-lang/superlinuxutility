// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Super Linux Utility';

  @override
  String get appAlreadyRunning => 'La aplicación ya está en ejecución.';

  @override
  String get trayCheckUpdates => 'Comprobar actualizaciones del sistema';

  @override
  String get trayCleanLinuxCache => 'Limpiar caché de Linux';

  @override
  String get trayRemoveTempFiles => 'Eliminar archivos temporales';

  @override
  String get trayCleanTempFilesAndCache =>
      'Limpiar archivos temporales y caché';

  @override
  String get trayCleanVram => 'Limpiar VRAM (reinicio GPU)';

  @override
  String get trayCpuGpuTemp => 'Temperatura CPU, GPU';

  @override
  String get trayDiskUsage => 'Uso del disco';

  @override
  String get trayMemoryUsage => 'Uso de memoria RAM';

  @override
  String get traySmartHealth => 'Salud del disco (SMART)';

  @override
  String get trayShutdownTimer => 'Apagado automático';

  @override
  String get trayShowMainWindow => 'Mostrar ventana principal';

  @override
  String get trayCpuGpuUsage => 'Uso CPU, GPU';

  @override
  String get trayExit => 'Salir';

  @override
  String get traySettings => 'Configuración';

  @override
  String get traySystem => 'Sistema';

  @override
  String get trayClipboard => 'Portapapeles';

  @override
  String get clipboardTitle => 'Historial del portapapeles';

  @override
  String get clipboardEmpty =>
      'Nada copiado todavía. Copia texto y aparecerá aquí.';

  @override
  String get clipboardEditTitle => 'Editar texto';

  @override
  String get clipboardSave => 'Guardar';

  @override
  String get clipboardCancel => 'Cancelar';

  @override
  String get clipboardDelete => 'Eliminar';

  @override
  String get clipboardDeleteTitle => '¿Eliminar esta entrada?';

  @override
  String get clipboardDeleteBody =>
      'La entrada se eliminará permanentemente del historial.';

  @override
  String get clipboardClearAll => 'Borrar todo';

  @override
  String get clipboardClearAllTitle => '¿Borrar el historial?';

  @override
  String get clipboardClearAllBody =>
      'Todas las entradas guardadas se eliminarán permanentemente.';

  @override
  String get clipboardSaveEntryTxt => 'Guardar como TXT';

  @override
  String get clipboardExportAll => 'Exportar todo como TXT';

  @override
  String clipboardSavedTo(String path) {
    return 'Guardado en $path';
  }

  @override
  String get clipboardSaveFailed => 'Error al guardar.';

  @override
  String get clipboardCopiedBack => 'Texto copiado al portapapeles.';

  @override
  String get clipboardSettingsTitle => 'Portapapeles';

  @override
  String get clipboardSettingsDesc =>
      'La aplicación guarda automáticamente los textos que copias. Elige durante cuántas horas conservarlos: las copias caducadas se eliminan solas.';

  @override
  String get clipboardRetentionLabel => 'Conservar las copias durante';

  @override
  String clipboardRetentionHours(int n) {
    return '$n h';
  }

  @override
  String get tabBattery => 'Batería';

  @override
  String get trayBattery => 'Batería';

  @override
  String get trayBatteryHealth => 'Salud batería';

  @override
  String get trayChargeLimit => 'Límite de carga';

  @override
  String get trayPowerProfile => 'Perfil energía';

  @override
  String get batteryNoBattery => 'Batería no detectada';

  @override
  String get batteryNoBatteryDesc =>
      'Esta función solo está disponible en portátiles. No se encontró batería en este sistema.';

  @override
  String get batteryHealthTitle => 'Salud de la batería';

  @override
  String get batteryCapacityNow => 'Energía actual';

  @override
  String get batteryCapacityFull => 'Capacidad residual';

  @override
  String get batteryCapacityDesign => 'Capacidad nominal';

  @override
  String get batteryHealthPct => 'Salud';

  @override
  String get batteryCycles => 'Ciclos de carga';

  @override
  String get batteryVoltage => 'Voltaje';

  @override
  String get batteryPower => 'Potencia';

  @override
  String get batteryTech => 'Tecnología';

  @override
  String get batteryStatus => 'Batería';

  @override
  String get batteryAcOnline => 'Con corriente';

  @override
  String get batteryAcOffline => 'Con batería';

  @override
  String get batteryCharging => 'Cargando';

  @override
  String get batteryDischarging => 'Descargando';

  @override
  String get batteryFull => 'Carga completa';

  @override
  String get batteryUnknown => 'Estado desconocido';

  @override
  String get batteryThresholdsTitle => 'Umbrales de carga';

  @override
  String get batteryThresholdsDesc =>
      'Limita la carga máxima (ej. 80 %) para preservar la batería. Requiere contraseña de administrador. Compatible con ASUS, ThinkPad, Lenovo y Dell recientes.';

  @override
  String get batteryThresholdsUnsupported =>
      'Umbrales de carga no compatibles con este hardware.';

  @override
  String get batteryEndLimit => 'Límite máximo de carga';

  @override
  String get batteryStartLimit => 'Inicio de carga';

  @override
  String get batteryGovernorTitle => 'Gobernador automático';

  @override
  String get batteryGovernorDesc =>
      'Cambia a powersave al desconectar y a performance al cargar. Funciona mientras la aplicación está en ejecución.';

  @override
  String get batteryGovernorAuto => 'Cambio automático de gobernador';

  @override
  String get batteryGovernorOnAc => 'Gobernador en carga';

  @override
  String get batteryGovernorOnBattery => 'Gobernador con batería';

  @override
  String get batteryGovernorCurrent => 'Gobernador actual';

  @override
  String get batteryApplied => 'Ajuste aplicado.';

  @override
  String get batteryFailed => 'Operación fallida.';

  @override
  String get batteryRefresh => 'Actualizar';

  @override
  String get cleanupLinuxCache => 'Limpiar caché';

  @override
  String get cleanupLinuxCacheDesc =>
      'Vaciar la caché de páginas del kernel (drop_caches). Requiere contraseña de administrador.';

  @override
  String get cleanupLinuxCacheSuccess =>
      'Caché de Linux limpiada correctamente.';

  @override
  String get cleanupLinuxCacheError => 'Error al limpiar la caché.';

  @override
  String get advCleanupTitle => 'Limpieza avanzada (logs y cachés dev)';

  @override
  String get devPip => 'Caché pip';

  @override
  String get devCargo => 'Caché Cargo (Rust)';

  @override
  String get devNpm => 'Caché npm';

  @override
  String get devGo => 'Caché Go';

  @override
  String get devGradle => 'Caché Gradle';

  @override
  String get devDocker => 'Imágenes Docker sin usar';

  @override
  String get devKernelHeaders => 'Kernels antiguos (headers + imágenes)';

  @override
  String get advEmpty => 'No se detectaron cachés de desarrollo.';

  @override
  String get journalTitle => 'Registros del sistema (journald)';

  @override
  String get journalCurrentSize => 'Espacio usado';

  @override
  String get journalVacuumTarget => 'Reducir a';

  @override
  String get journalVacuumNow => 'Limpiar';

  @override
  String get journalLimitLabel => 'Límite permanente';

  @override
  String get journalLimitApply => 'Aplicar';

  @override
  String get advCleanSelected => 'Limpiar selección';

  @override
  String get advCleaned => 'Limpieza completada.';

  @override
  String get advFailed => 'Error en la limpieza.';

  @override
  String get cleanupVram => 'Limpiar VRAM';

  @override
  String get cleanupVramConfirmTitle => 'Reinicio de la GPU';

  @override
  String get cleanupVramConfirmMessage =>
      'Voy a intentar reiniciar la tarjeta gráfica para liberar la VRAM. Requiere contraseña de administrador y puede causar una interrupción temporal de la pantalla. ¿Continuar?';

  @override
  String get cleanupVramSuccess =>
      'VRAM limpiada (reinicio de la GPU) correctamente.';

  @override
  String get cleanupVramError =>
      'No se pudo limpiar la VRAM (reinicio de la GPU fallido).';

  @override
  String get ramCleanupTitle => 'Limpieza de RAM';

  @override
  String get ramCleanup => 'Limpiar RAM';

  @override
  String get ramCleanupConfirmTitle => 'Confirmar limpieza de RAM';

  @override
  String get ramCleanupConfirmMessage =>
      'La limpieza profunda de la RAM vaciará las cachés del kernel (drop_caches) y reciclará el swap para liberar la memoria usada por datos inactivos. No detiene servicios del sistema ni elimina archivos temporales. Requiere contraseña de administrador. ¿Continuar?';

  @override
  String get ramCleanupSuccess => 'Limpieza de RAM completada con éxito.';

  @override
  String get ramCleanupError => 'Error durante la limpieza de la RAM.';

  @override
  String get ramUsed => 'Usada';

  @override
  String get ramAvailable => 'Disponible';

  @override
  String get ramCache => 'Caché';

  @override
  String get ramSwap => 'Swap';

  @override
  String get ramSwapNone => 'Sin swap';

  @override
  String get ramFreed => 'Memoria liberada';

  @override
  String get ramBefore => 'Antes';

  @override
  String get ramAfter => 'Después';

  @override
  String get ramStepsFailed => 'Pasos fallidos';

  @override
  String get ramCleanupSettingsTitle => 'Limpieza automática de RAM';

  @override
  String get ramCleanupSettingsDesc =>
      'Realiza automáticamente la limpieza profunda de la RAM a intervalos regulares.';

  @override
  String get ramCleanupSettingsInterval => 'Frecuencia de limpieza de RAM';

  @override
  String get ramCleanupNever => 'Nunca';

  @override
  String get ramCleanupEvery5Min => 'Cada 5 minutos';

  @override
  String get ramCleanupEvery10Min => 'Cada 10 minutos';

  @override
  String get ramCleanupEvery15Min => 'Cada 15 minutos';

  @override
  String get ramCleanupEvery30Min => 'Cada 30 minutos';

  @override
  String ramCleanupAutoEnabled(int minutes) {
    return 'Limpieza automática de RAM activada (cada $minutes minutos).';
  }

  @override
  String get ramCleanupAutoDisabled =>
      'Limpieza automática de RAM desactivada.';

  @override
  String get ramCleanupAutoDone => 'Limpieza automática de RAM completada';

  @override
  String get tabServices => 'Servicios';

  @override
  String get tabStartupApps => 'Aplicaciones de Inicio';

  @override
  String get tabCleanup => 'Limpieza';

  @override
  String get tabInstalledApps => 'Aplicaciones Instaladas';

  @override
  String get tabMonitor => 'Monitor';

  @override
  String get tabDiskAnalyzer => 'Analizador de Disco';

  @override
  String get tabAppearance => 'Apariencia GNOME';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabRecovery => 'Recuperación del Sistema';

  @override
  String get tabGrub => 'GRUB';

  @override
  String get tabKernel => 'Kernel';

  @override
  String get tabSettings => 'Configuración';

  @override
  String get modeStandard => 'Estándar';

  @override
  String get modeAdvanced => 'Avanzado';

  @override
  String get warningTitle => 'ADVERTENCIA';

  @override
  String get warningSubtitle => 'Aplicación para Usuarios Expertos';

  @override
  String get warningMessage =>
      'Esta aplicación permite modificar configuraciones críticas del sistema operativo Linux.';

  @override
  String get warningGrub => 'Modificaciones GRUB';

  @override
  String get warningGrubDesc =>
      'La modificación incorrecta del gestor de arranque puede impedir que el sistema arranque.';

  @override
  String get warningKernel => 'Eliminación de Kernel';

  @override
  String get warningKernelDesc =>
      'Eliminar kernels esenciales puede hacer que el sistema sea inutilizable.';

  @override
  String get warningServices => 'Gestión de Servicios';

  @override
  String get warningServicesDesc =>
      'Desactivar servicios críticos puede causar fallos del sistema.';

  @override
  String get warningCleanup => 'Limpieza de Archivos';

  @override
  String get warningCleanupDesc =>
      'Eliminar archivos del sistema puede comprometer la estabilidad.';

  @override
  String get warningBackup =>
      'Se recomienda crear una copia de seguridad del sistema antes de usar esta aplicación.';

  @override
  String get warningDontShow => 'No mostrar esta advertencia de nuevo';

  @override
  String get warningAccept => 'Entendido, Continuar';

  @override
  String get passwordSetupTitle => 'Configuración de Contraseña';

  @override
  String get passwordSetupDesc =>
      'Para usar funciones que requieren privilegios de administrador, debe configurar la contraseña del sistema.';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => 'Ingrese la contraseña de administrador';

  @override
  String get passwordConfirm => 'Confirmar Contraseña';

  @override
  String get passwordConfirmHint => 'Re-ingrese la contraseña';

  @override
  String get passwordSave => 'Guardar Contraseña';

  @override
  String get passwordSkip => 'Omitir por ahora';

  @override
  String get passwordSaved =>
      'Contraseña guardada de forma segura usando el llavero del sistema.';

  @override
  String get passwordError => 'Error al guardar';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden';

  @override
  String get passwordEmpty => 'Ingrese una contraseña';

  @override
  String get passwordRequired => 'Contraseña Requerida';

  @override
  String get passwordRequiredMessage =>
      'Se requiere la contraseña de administrador para acceder a todos los directorios. La contraseña se guardará de forma segura.';

  @override
  String get settingsPasswordTitle => 'Contraseña de Administrador';

  @override
  String get settingsPasswordDesc =>
      'Guarde la contraseña de administrador para usar funciones que requieren privilegios sudo.';

  @override
  String get settingsPasswordSaved =>
      'Contraseña guardada. Puede cambiarla o eliminarla.';

  @override
  String get settingsPasswordConfigured => 'Contraseña configurada';

  @override
  String get settingsPasswordUpdate => 'Actualizar Contraseña';

  @override
  String get settingsPasswordDelete => 'Eliminar';

  @override
  String get settingsThemeTitle => 'Tema de la Aplicación';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeSystemDesc => 'Sigue la configuración del sistema';

  @override
  String get settingsInfoTitle => 'Información';

  @override
  String get settingsInfoDesc => 'Esta aplicación le ayuda a:';

  @override
  String get settingsInfoItem1 =>
      'Encontrar servicios systemd que ralentizan el arranque';

  @override
  String get settingsInfoItem2 => 'Gestionar aplicaciones de inicio';

  @override
  String get settingsInfoItem3 => 'Limpiar archivos temporales del sistema';

  @override
  String get loading => 'Cargando...';

  @override
  String get loadingSettings => 'Cargando configuración del sistema';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get themeRestartMessage =>
      'El tema se aplicará después de reiniciar la aplicación';

  @override
  String get themeApplied => 'Tema aplicado con éxito';

  @override
  String get settingsFontTitle => 'Fuente y Tamaño de Texto';

  @override
  String get settingsFontDesc =>
      'Personaliza la fuente y el tamaño del texto utilizado en toda la aplicación.';

  @override
  String get settingsSystemTrayTitle => 'Bandeja del sistema';

  @override
  String get settingsSystemTrayDesc =>
      'Mostrar el icono de la app en la bandeja del sistema para acciones rápidas. Requiere dependencias del sistema (libappindicator).';

  @override
  String get settingsTrayDepsOk => 'Dependencias instaladas.';

  @override
  String get settingsTrayDepsMissing =>
      'Faltan dependencias. Instálalas para habilitar la bandeja del sistema.';

  @override
  String get settingsSystemTrayEnable => 'Habilitar bandeja del sistema';

  @override
  String get settingsTrayInstallDeps => 'Instalar dependencias';

  @override
  String get settingsCloseToTray => 'Mantener en bandeja al cerrar';

  @override
  String get settingsCloseToTrayDesc =>
      'Si está activo, al cerrar o minimizar la ventana la app sigue en la bandeja del sistema.';

  @override
  String get settingsCloseToTrayOn => 'Cerrar a bandeja activado.';

  @override
  String get settingsCloseToTrayOff =>
      'Cerrar a bandeja desactivado. Cerrar la ventana saldrá de la app.';

  @override
  String get settingsTrayEnabled => 'Bandeja del sistema habilitada.';

  @override
  String get settingsTrayDisabled =>
      'Bandeja del sistema deshabilitada. Reinicia la app para aplicar.';

  @override
  String get settingsStartMinimized =>
      'Iniciar la app minimizada en la bandeja';

  @override
  String get settingsStartMinimizedDesc =>
      'Si está activo, la app inicia sin mostrar la ventana principal, solo el icono en la bandeja.';

  @override
  String get settingsStartMinimizedOn =>
      'Inicio minimizado activado. El próximo inicio abrirá solo en bandeja.';

  @override
  String get settingsStartMinimizedOff => 'Inicio minimizado desactivado.';

  @override
  String get settingsStartAtLogin => 'Iniciar la app al arrancar el sistema';

  @override
  String get settingsStartAtLoginDesc =>
      'Si está activo, la app inicia automáticamente al iniciar sesión.';

  @override
  String get settingsStartAtLoginOn =>
      'Inicio al arranque activado. La app se iniciará al iniciar sesión.';

  @override
  String get settingsStartAtLoginOff => 'Inicio al arranque desactivado.';

  @override
  String get settingsStartAtLoginError =>
      'No se pudo cambiar el inicio al arranque.';

  @override
  String get settingsAutoUpdateCheckTitle =>
      'Comprobación automática de actualizaciones';

  @override
  String get settingsAutoUpdateCheckDesc =>
      'Comprobar actualizaciones del sistema automáticamente con la frecuencia elegida.';

  @override
  String get settingsAutoUpdateCheckInterval => 'Comprobar actualizaciones';

  @override
  String get settingsAutoUpdateNever => 'Nunca';

  @override
  String get settingsAutoUpdateEvery15Min => 'Cada 15 minutos';

  @override
  String get settingsAutoUpdateEvery30Min => 'Cada 30 minutos';

  @override
  String get settingsAutoUpdateEvery1Hour => 'Cada hora';

  @override
  String get settingsAutoUpdateEvery6Hours => 'Cada 6 horas';

  @override
  String get settingsAutoUpdateEvery12Hours => 'Cada 12 horas';

  @override
  String get settingsAutoUpdateEveryDay => 'Cada día';

  @override
  String get settingsAutoAppUpdateFromGithubTitle =>
      'Actualizar la app automáticamente desde GitHub';

  @override
  String get settingsAutoAppUpdateFromGithubDesc =>
      'Si está activo, la app descarga e instala periódicamente el último .deb de esta edición desde las releases de GitHub. Requiere la contraseña de administrador guardada y que la verificación automática de arriba esté activa.';

  @override
  String get updateCheckAptNone => 'APT: No hay actualizaciones disponibles';

  @override
  String get updateCheckAptPhasedOnly =>
      'APT: No hay actualizaciones instalables ahora (solo despliegue por fases)';

  @override
  String updateCheckAptHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APT: $count actualizaciones disponibles',
      one: 'APT: $count actualización disponible',
    );
    return '$_temp0';
  }

  @override
  String updateCheckAptPhasedExtra(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APT: $count actualizaciones por fases detectadas',
      one: 'APT: $count actualización por fases detectada',
    );
    return '$_temp0';
  }

  @override
  String updateCheckAptError(String error) {
    return 'APT: Error al comprobar: $error';
  }

  @override
  String get updateCheckDnfNone => 'DNF: No hay actualizaciones disponibles';

  @override
  String updateCheckDnfHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DNF: $count actualizaciones disponibles',
      one: 'DNF: $count actualización disponible',
    );
    return '$_temp0';
  }

  @override
  String updateCheckDnfError(String error) {
    return 'DNF: Error al comprobar: $error';
  }

  @override
  String get updateCheckPacmanNone =>
      'Pacman: No hay actualizaciones disponibles';

  @override
  String updateCheckPacmanHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pacman: $count actualizaciones disponibles',
      one: 'Pacman: $count actualización disponible',
    );
    return '$_temp0';
  }

  @override
  String updateCheckPacmanError(String error) {
    return 'Pacman: Error al comprobar: $error';
  }

  @override
  String get updateCheckSnapNone => 'Snap: No hay actualizaciones disponibles';

  @override
  String updateCheckSnapHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Snap: $count actualizaciones disponibles',
      one: 'Snap: $count actualización disponible',
    );
    return '$_temp0';
  }

  @override
  String updateCheckSnapError(String error) {
    return 'Snap: Error al comprobar: $error';
  }

  @override
  String get updateCheckFlatpakNone =>
      'Flatpak: No hay actualizaciones disponibles';

  @override
  String updateCheckFlatpakHasUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flatpak: $count actualizaciones disponibles',
      one: 'Flatpak: $count actualización disponible',
    );
    return '$_temp0';
  }

  @override
  String updateCheckFlatpakError(String error) {
    return 'Flatpak: Error al comprobar: $error';
  }

  @override
  String updateCheckSummaryPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paquetes',
      one: '$count paquete',
      zero: '0 paquetes',
    );
    return '$_temp0';
  }

  @override
  String updatesAvailableCount(int count) {
    return '$count actualizaciones disponibles';
  }

  @override
  String get updatesAvailableDialogTitle => 'Actualizaciones disponibles';

  @override
  String updatesAvailableDialogMessage(int count) {
    return '$count actualizaciones disponibles. ¿Desea aplicarlas ahora?';
  }

  @override
  String get updatesAvailableDetectedListHeading => 'Detectados:';

  @override
  String updateLabelPhased(String name) {
    return '$name (despliegue gradual — aún no instalable)';
  }

  @override
  String updatesPreviewTruncated(int count) {
    return '… y $count más';
  }

  @override
  String get updatesAvailablePhasedFooter =>
      'Los paquetes en despliegue gradual no se pueden instalar aún. \"Aplicar ahora\" solo aplica lo que el sistema permite.';

  @override
  String get updatesCheckPreviewHeading => 'Elementos afectados:';

  @override
  String get applyNow => 'Aplicar ahora';

  @override
  String get postpone => 'Más tarde';

  @override
  String get fontFamily => 'Familia de Fuente';

  @override
  String get fontSize => 'Tamaño de Fuente';

  @override
  String get fontDefault => 'Predeterminado (Roboto)';

  @override
  String get fontRestartMessage =>
      'La fuente se aplicará después de reiniciar la aplicación';

  @override
  String get themeApplyError => 'Error al aplicar el tema';

  @override
  String get userThemesExtensionMessage =>
      'Para temas Shell completos, instala la extensión User Themes desde extensions.gnome.org';

  @override
  String get themeRequiresOcsUrl =>
      'Este tema requiere ocs-url para ser instalado correctamente';

  @override
  String get installOcsUrl => 'Instalar ocs-url';

  @override
  String get ocsUrlNotInstalled =>
      'ocs-url no está instalado. Algunos temas pueden no funcionar correctamente.';

  @override
  String get ocsUrlInstalled => '¡ocs-url instalado con éxito!';

  @override
  String get ocsUrlInstallError =>
      'Error al instalar ocs-url. Verifique que la contraseña sea correcta y que el gestor de paquetes esté disponible.';

  @override
  String get installingOcsUrl => 'Instalando ocs-url...';

  @override
  String get installingOcsUrlDescription =>
      'Esta operación se realiza automáticamente en el primer inicio.';

  @override
  String get themeToolsMessage =>
      'Para instalar temas desde OpenDesktop.org/Pling.com, instale ocs-url o PLing-store. Algunos temas requieren estas herramientas para funcionar correctamente.';

  @override
  String get refresh => 'Actualizar';

  @override
  String get search => 'Buscar';

  @override
  String get noResults => 'No se encontraron resultados';

  @override
  String get enabled => 'Habilitado';

  @override
  String get disabled => 'Deshabilitado';

  @override
  String get active => 'Activo';

  @override
  String get inactive => 'Inactivo';

  @override
  String get start => 'Iniciar';

  @override
  String get stop => 'Detener';

  @override
  String get restart => 'Reiniciar';

  @override
  String get enable => 'Habilitar';

  @override
  String get disable => 'Deshabilitar';

  @override
  String get remove => 'Eliminar';

  @override
  String get kill => 'Terminar';

  @override
  String get killForce => 'Forzar Terminación';

  @override
  String get processes => 'Procesos';

  @override
  String get system => 'Sistema';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => 'Memoria';

  @override
  String get disk => 'Disco';

  @override
  String get gpu => 'Tarjeta Gráfica';

  @override
  String get usage => 'Uso';

  @override
  String get total => 'Total';

  @override
  String get used => 'Usado';

  @override
  String get free => 'Libre';

  @override
  String get model => 'Modelo';

  @override
  String get driver => 'Controlador';

  @override
  String get temperature => 'Temperatura';

  @override
  String get version => 'Versión';

  @override
  String get creator => 'Creador';

  @override
  String get creatorName => 'Marco Di Giangiacomo';

  @override
  String get appDescription =>
      'Super Linux Utility es una aplicación de escritorio para gestionar un sistema Linux: servicios, aplicaciones de inicio, limpieza, paquetes instalados, monitorización de recursos y ajustes de apariencia.';

  @override
  String get features => 'Características';

  @override
  String get appExpertUsers =>
      'Aplicación diseñada para usuarios expertos de Linux';

  @override
  String get infoProjectWebsite => 'Sitio web del proyecto';

  @override
  String get infoChangelog => 'Registro de cambios';

  @override
  String get infoChangelogShowAll => 'Ver registro completo';

  @override
  String get applicationIdLabel => 'ID de la aplicación (escritorio)';

  @override
  String get updatesPendingPackagesTitle =>
      'Paquetes pendientes (última comprobación)';

  @override
  String updatesProgressCurrent(String detail) {
    return 'Progreso: $detail';
  }

  @override
  String get updatesCommandOutputTitle => 'Salida del comando';

  @override
  String get disclaimerLicenseTitle => 'Licencia y Aviso Legal';

  @override
  String get disclaimerGplNotice =>
      'Esta aplicación es software libre; puede redistribuirla y/o modificarla bajo los términos de la GNU General Public License publicada por la Free Software Foundation, versión 3 de la Licencia o (a su elección) posterior.';

  @override
  String get disclaimerNoWarranty =>
      'Este programa se distribuye con la esperanza de que sea útil, pero SIN NINGUNA GARANTÍA; ni siquiera la garantía implícita de COMERCIABILIDAD o IDONEIDAD PARA UN PROPÓSITO PARTICULAR. Consulte la GNU General Public License para más detalles.';

  @override
  String get disclaimerCopyright =>
      'Copyright (c) 2024-2025 Marco Di Giangiacomo. Todos los derechos reservados bajo GPL-3.0.';

  @override
  String get payWithPaypal => 'Pagar con PayPal';

  @override
  String get purchaseLicenseViaPaypal =>
      'La versión Advanced cuesta 19,99 €. Para comprar una licencia, pague por PayPal. Tras el pago correcto recibirá su código de licencia por correo electrónico. Sin un pago válido, la aplicación no puede activarse.';

  @override
  String get languageSelectionTitle => 'Selección de Idioma';

  @override
  String get languageSelectionDesc => 'Seleccione el idioma de la aplicación';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageGerman => 'Alemán';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get settingsLanguageTitle => 'Idioma de la Aplicación';

  @override
  String get settingsLanguageDesc => 'Seleccione el idioma de la interfaz';

  @override
  String get languageRestartMessage => 'Idioma actualizado';

  @override
  String get servicesSlow => 'Servicios Lentos';

  @override
  String get servicesAll => 'Todos los Servicios';

  @override
  String get servicesDisabled => 'Deshabilitados';

  @override
  String get analyzeAll => 'Analizar Todo';

  @override
  String get status => 'Estado';

  @override
  String get startupTime => 'Tiempo de inicio';

  @override
  String get noServicesFound => 'No se encontraron servicios.';

  @override
  String get reEnable => 'Rehabilitar';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get cleanupConfirmTitle => 'Confirmar limpieza';

  @override
  String get cleanupConfirmMessage =>
      '¿Desea eliminar todos los archivos temporales? Esta operación no se puede deshacer.';

  @override
  String get cleanupSuccess => '¡Limpieza completada con éxito!';

  @override
  String get cleanupPartialSuccess =>
      'Limpieza completada con algunos errores.';

  @override
  String get protectedSystemApp => 'Aplicación de Sistema Protegida';

  @override
  String cannotDisableSystemApp(String appName) {
    return 'No se puede deshabilitar \"$appName\" porque es una aplicación de sistema esencial.';
  }

  @override
  String get systemAppsRequired =>
      'Las aplicaciones del sistema son necesarias para el correcto funcionamiento del entorno de escritorio y no pueden ser deshabilitadas.';

  @override
  String get checkingDependencies => 'Verificando dependencias...';

  @override
  String get warning => '⚠️ Advertencia';

  @override
  String get packagesDependingOnThis => 'Paquetes que dependen de esto:';

  @override
  String get areYouSure => '¿Está seguro de que desea continuar?';

  @override
  String get confirmRemoval => 'Confirmar eliminación';

  @override
  String removeAppQuestion(String appName) {
    return '¿Desea eliminar $appName?';
  }

  @override
  String get searchApp => 'Buscar aplicación';

  @override
  String get all => 'Todos';

  @override
  String get searchProcess => 'Buscar proceso';

  @override
  String processesSelected(int count) {
    return '$count proceso seleccionado';
  }

  @override
  String processesSelectedPlural(int count) {
    return '$count procesos seleccionados';
  }

  @override
  String get app => 'App';

  @override
  String get cpuPercent => 'CPU %';

  @override
  String get name => 'Nombre';

  @override
  String get pid => 'PID';

  @override
  String get user => 'Usuario';

  @override
  String get noProcessesFound => 'No se encontraron procesos.';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get terminateAll => 'Terminar todo';

  @override
  String get terminateAllForce => 'Forzar terminación de todo';

  @override
  String get cannotLoadSystemInfo =>
      'No se pueden cargar las información del sistema.';

  @override
  String get cores => 'Núcleos';

  @override
  String get threads => 'Hilos';

  @override
  String get grubInvalidContent => 'El contenido del archivo GRUB no es válido';

  @override
  String get grubConfirmSave => 'Confirmar guardado';

  @override
  String get grubSaveWarning =>
      'Está a punto de modificar la configuración de GRUB. Esta operación:';

  @override
  String get grubWillCreateBackup =>
      '• Creará una copia de seguridad automática';

  @override
  String get grubWillSave => '• Guardará los cambios';

  @override
  String get grubWillUpdate => '• Actualizará GRUB';

  @override
  String get grubWarning =>
      'ADVERTENCIA: ¡Las modificaciones incorrectas pueden impedir que el sistema arranque!';

  @override
  String get saveAndUpdate => 'Guardar y actualizar';

  @override
  String get grubSavedSuccess =>
      'Configuración de GRUB guardada y actualizada con éxito';

  @override
  String get grubSaveError => 'Error al guardar';

  @override
  String get reload => 'Recargar';

  @override
  String get restoreBackup => 'Restaurar copia de seguridad';

  @override
  String get restoreBackupQuestion =>
      '¿Desea restaurar la copia de seguridad de la configuración de GRUB?';

  @override
  String get restore => 'Restaurar';

  @override
  String get backupRestoredSuccess => 'Copia de seguridad restaurada con éxito';

  @override
  String get backupRestoreError => 'Error al restaurar la copia de seguridad';

  @override
  String get kernelCannotRemoveActive =>
      'No se puede eliminar el kernel actualmente activo';

  @override
  String get removeKernel => 'Eliminar kernel';

  @override
  String removeKernelQuestion(String version) {
    return '¿Desea eliminar el kernel $version?';
  }

  @override
  String get thisOperation => 'Esta operación:';

  @override
  String get willRemovePackage => '• Eliminará el paquete del kernel';

  @override
  String get willUpdateGrub => '• Actualizará GRUB';

  @override
  String get kernelWarning =>
      'ADVERTENCIA: ¡Asegúrese de tener al menos un kernel funcional!';

  @override
  String kernelRemovedSuccess(String version) {
    return 'Kernel $version eliminado con éxito';
  }

  @override
  String get kernelRemoveError => 'Error al eliminar el kernel';

  @override
  String get setDefaultKernel => 'Establecer kernel predeterminado';

  @override
  String setDefaultKernelQuestion(String version) {
    return '¿Desea establecer $version como kernel predeterminado?';
  }

  @override
  String get set => 'Establecer';

  @override
  String kernelSetDefaultSuccess(String version) {
    return 'Kernel $version establecido como predeterminado';
  }

  @override
  String get kernelSetDefaultError =>
      'Error al establecer el kernel predeterminado';

  @override
  String get keepMax => 'Mantener máx:';

  @override
  String get cleanupKernels => 'Limpieza de kernel';

  @override
  String keepOnlyRecentKernels(int count) {
    return '¿Desea mantener solo los $count kernels más recientes?';
  }

  @override
  String totalKernels(int count) {
    return 'Kernels totales: $count';
  }

  @override
  String kernelsToKeep(int count) {
    return 'Kernels a mantener: $count';
  }

  @override
  String kernelsToRemove(int count) {
    return 'Kernels a eliminar: $count';
  }

  @override
  String get cleanupKernelsWarning =>
      'ADVERTENCIA: Solo se eliminarán los kernels no utilizados.';

  @override
  String get cleanup => 'Limpiar';

  @override
  String get kernelCleanupSuccess => 'Limpieza de kernel completada con éxito';

  @override
  String get kernelCleanupError => 'Error durante la limpieza del kernel';

  @override
  String get invalidKernelCount =>
      'Ingrese un número válido de kernels a mantener';

  @override
  String get noKernelsFound => 'No se encontraron kernels instalados';

  @override
  String get updateGrub => 'Actualizar GRUB';

  @override
  String get updateGrubQuestion =>
      '¿Desea actualizar GRUB? Esta operación actualizará la configuración del gestor de arranque.';

  @override
  String get grubUpdateSuccess => 'GRUB actualizado con éxito';

  @override
  String get grubUpdateError => 'Error al actualizar GRUB';

  @override
  String get rebootSystem => 'Reiniciar Sistema';

  @override
  String get rebootSystemQuestion =>
      '¿Desea reiniciar el sistema? Todas las aplicaciones abiertas se cerrarán.';

  @override
  String get rebootSystemSuccess => 'El sistema se está reiniciando...';

  @override
  String get rebootSystemError => 'Error al reiniciar el sistema';

  @override
  String get package => 'Paquete';

  @override
  String get size => 'Tamaño';

  @override
  String get setAsDefault => 'Establecer como predeterminado';

  @override
  String get refreshDimensions => 'Actualizar dimensiones';

  @override
  String get cleanupTempFiles => 'Limpiar archivos temporales';

  @override
  String get disableApp => 'Deshabilitar aplicación';

  @override
  String get onlyDisable => 'Solo deshabilitar';

  @override
  String get systemApps => 'Aplicaciones del sistema';

  @override
  String get close => 'Cerrar';

  @override
  String get updateStartupApps => 'Actualizar aplicaciones de inicio';

  @override
  String get saving => 'Guardando...';

  @override
  String get scaleFactor => 'Factor de escala:';

  @override
  String get maximize => 'Maximizar';

  @override
  String get minimize => 'Minimizar';

  @override
  String get positioning => 'Posicionamiento:';

  @override
  String get left => 'Izquierda';

  @override
  String get right => 'Derecha';

  @override
  String get buttonOrder => 'Orden de botones:';

  @override
  String get attachedDialogs => 'Diálogos adjuntos';

  @override
  String get centerNewWindows => 'Centrar nuevas ventanas';

  @override
  String get resizeWithSecondaryClick => 'Redimensionar con clic secundario';

  @override
  String get raiseOnFocus => 'Elevar ventanas cuando tienen el foco';

  @override
  String get backgroundImageUpdated => '¡Imagen de fondo actualizada!';

  @override
  String get backgroundImageError => 'Error al actualizar la imagen.';

  @override
  String get preferredFonts => 'Fuentes Preferidas';

  @override
  String get interfaceText => 'Texto de la Interfaz';

  @override
  String get documentText => 'Texto del Documento';

  @override
  String get fixedWidthText => 'Texto de Ancho Fijo';

  @override
  String get rendering => 'Renderizado';

  @override
  String get hinting => 'Hinting';

  @override
  String get full => 'Completo';

  @override
  String get medium => 'Medio';

  @override
  String get light => 'Ligero';

  @override
  String get antialiasing => 'Suavizado';

  @override
  String get subpixelLCD => 'Subpíxel (para pantallas LCD)';

  @override
  String get standardGrayscale => 'Estándar (escala de grises)';

  @override
  String get dimensions => 'Dimensiones';

  @override
  String get preview => 'Vista previa:';

  @override
  String get noImageSelected => 'Ninguna imagen seleccionada';

  @override
  String get command => 'Comando:';

  @override
  String get comment => 'Comentario:';

  @override
  String get enabledApps => 'Aplicaciones Habilitadas';

  @override
  String get disabledApps => 'Aplicaciones Deshabilitadas';

  @override
  String get noStartupAppsFound => 'No se encontraron aplicaciones de inicio.';

  @override
  String get enabledStatus => 'Habilitada';

  @override
  String get disabledStatus => 'Deshabilitada';

  @override
  String get styles => 'Estilos';

  @override
  String get cursor => 'Cursor';

  @override
  String get icons => 'Iconos';

  @override
  String get legacyApps => 'Aplicaciones Antiguas';

  @override
  String get background => 'Fondo';

  @override
  String get defaultImage => 'Imagen Predeterminada';

  @override
  String get darkImage => 'Imagen de Estilo Oscuro';

  @override
  String get adjustment => 'Ajuste';

  @override
  String get noneOption => 'Ninguno';

  @override
  String get wallpaper => 'Fondo de Pantalla';

  @override
  String get centered => 'Centrado';

  @override
  String get scaled => 'Escalado';

  @override
  String get stretched => 'Estirado';

  @override
  String get zoom => 'Zoom';

  @override
  String get spanned => 'Extendido';

  @override
  String get windowBehavior => 'Comportamiento de Ventanas';

  @override
  String get titlebarButtons => 'Botones de la Barra de Título';

  @override
  String get clickActions => 'Acciones de Clic';

  @override
  String get windowFocus => 'Enfoque de Ventana';

  @override
  String get doubleClick => 'Doble Clic';

  @override
  String get middleClick => 'Clic Central';

  @override
  String get rightClick => 'Clic Derecho';

  @override
  String get toggleMaximize => 'Alternar Maximizar';

  @override
  String get toggleMaximizeHorizontal => 'Alternar Maximizar Horizontalmente';

  @override
  String get toggleMaximizeVertical => 'Alternar Maximizar Verticalmente';

  @override
  String get toggleShade => 'Alternar Sombra';

  @override
  String get toggleMenu => 'Alternar Menú';

  @override
  String get lower => 'Reducir';

  @override
  String get menu => 'Menú';

  @override
  String get clickForFocus => 'Clic para el enfoque';

  @override
  String get focusOnHover => 'Enfoque al pasar';

  @override
  String get focusFollowsMouse => 'El enfoque sigue el mouse';

  @override
  String get clickForFocusDesc =>
      'Las ventanas tendrán el enfoque cuando haga clic en ellas.';

  @override
  String get focusOnHoverDesc =>
      'La ventana tiene el enfoque cuando pasa el mouse sobre ella. Las ventanas mantienen el enfoque al pasar sobre el escritorio.';

  @override
  String get focusFollowsMouseDesc =>
      'La ventana tiene el enfoque cuando pasa el mouse sobre ella. Pasar sobre el escritorio elimina el enfoque de la ventana anterior.';

  @override
  String get someProcessesNotTerminated =>
      'Algunos procesos no se terminaron correctamente';

  @override
  String get errorDisabling => 'Error al deshabilitar';

  @override
  String appReEnabled(String appName) {
    return 'Aplicación $appName rehabilitada';
  }

  @override
  String get errorEnabling => 'Error al habilitar';

  @override
  String removeAppFromStartup(String appName) {
    return '¿Desea eliminar $appName del inicio?';
  }

  @override
  String appRemoved(String appName) {
    return 'Aplicación $appName eliminada';
  }

  @override
  String get errorRemoving => 'Error al eliminar';

  @override
  String get terminateProcesses => 'Terminar Procesos';

  @override
  String get noProcessesRunning =>
      'No hay procesos en ejecución para esta aplicación';

  @override
  String get cache => 'Caché';

  @override
  String get swap => 'Swap';

  @override
  String get filesystem => 'Sistema de archivos';

  @override
  String get temperatureUnit => '°C';

  @override
  String get removing => 'Eliminando...';

  @override
  String get versionLabel => 'Versión:';

  @override
  String get selectBasePath => 'Seleccionar ruta base:';

  @override
  String get root => 'Raíz';

  @override
  String get home => 'Inicio';

  @override
  String get externalDisks => 'Discos externos:';

  @override
  String get selectPathToAnalyze => 'Seleccionar una ruta para analizar';

  @override
  String get totalSize => 'Tamaño total';

  @override
  String get files => 'Archivos';

  @override
  String get directories => 'Directorios';

  @override
  String get excluded => 'Excluida';

  @override
  String get exclude => 'Excluir';

  @override
  String get include => 'Incluir';

  @override
  String get analyzing => 'Analizando...';

  @override
  String get addExcludedFolder => 'Agregar Carpeta Excluida';

  @override
  String get enterFolderPath =>
      'Ingrese la ruta de la carpeta a excluir de la limpieza:';

  @override
  String get folderPath => 'Ruta de carpeta';

  @override
  String get folderExcluded => 'Carpeta agregada a exclusiones';

  @override
  String get folderNotFound => 'Carpeta no encontrada';

  @override
  String get add => 'Agregar';

  @override
  String get goBack => 'Atrás';

  @override
  String get goForward => 'Adelante';

  @override
  String get goToRoot => 'Ir a la raíz';

  @override
  String get moveToTrash => 'Mover a la papelera';

  @override
  String moveToTrashConfirm(String name) {
    return '¿Desea mover \"$name\" a la papelera?';
  }

  @override
  String get move => 'Mover';

  @override
  String get movedToTrash => 'Movido a la papelera';

  @override
  String get errorMovingToTrash => 'Error al mover a la papelera';

  @override
  String get deleteFromRootWarning => 'ADVERTENCIA: Eliminar desde Root';

  @override
  String deleteFromRootMessage(String name) {
    return 'Está a punto de eliminar \"$name\" del directorio raíz del sistema. Esta operación requiere privilegios de administrador y puede ser irreversible. ¿Está seguro de que desea continuar?';
  }

  @override
  String get deletePermanently => 'Eliminar Permanentemente';

  @override
  String get emptyDirectory => 'Directorio vacío';

  @override
  String get cannotPreviewFile => 'No se puede previsualizar el archivo';

  @override
  String get fileType => 'Tipo de archivo';

  @override
  String get unknown => 'Desconocido';

  @override
  String get directory => 'Directorio';

  @override
  String get file => 'Archivo';

  @override
  String get rename => 'Renombrar';

  @override
  String get newName => 'Nuevo nombre';

  @override
  String get details => 'Detalles';

  @override
  String get renamedSuccessfully => 'Renombrado exitosamente';

  @override
  String get renameError => 'Error al renombrar';

  @override
  String get type => 'Tipo';

  @override
  String get permissions => 'Permisos';

  @override
  String get owner => 'Propietario';

  @override
  String get modified => 'Modificado';

  @override
  String get path => 'Ruta';

  @override
  String get usedSpace => 'Espacio Usado';

  @override
  String get freeSpace => 'Espacio Libre';

  @override
  String get pages => 'Páginas';

  @override
  String get title => 'Título';

  @override
  String get artist => 'Artista';

  @override
  String get duration => 'Duración';

  @override
  String get bitrate => 'Tasa de Bits';

  @override
  String get resolution => 'Resolución';

  @override
  String get codec => 'Códec';

  @override
  String get showSystemFiles => 'Mostrar archivos del sistema';

  @override
  String get hideSystemFiles => 'Ocultar archivos del sistema';

  @override
  String appDisabled(String appName) {
    return 'Aplicación $appName deshabilitada';
  }

  @override
  String appDisabledAndProcessesTerminated(String appName) {
    return 'Aplicación $appName deshabilitada y procesos terminados';
  }

  @override
  String terminateProcessesQuestion(int count, String appName) {
    return '¿Desea terminar $count proceso/s de \"$appName\"?';
  }

  @override
  String get totalSpaceToFree => 'Espacio total a liberar:';

  @override
  String get foldersWithErrors => 'Carpetas con errores:';

  @override
  String andOthers(int count) {
    return 'y $count más';
  }

  @override
  String get recoveryDescription =>
      'Esta sección contiene herramientas para restaurar funciones del sistema alteradas. Los comandos se adaptan automáticamente según la distribución Linux detectada.';

  @override
  String get recoveryRestartPipewire => 'Reiniciar Pipewire';

  @override
  String get recoveryRestartPipewireDesc =>
      'Reinicia los servicios Pipewire, Pipewire-Pulse y Wireplumber para solucionar problemas de audio.';

  @override
  String get recoveryRestoreNetwork => 'Restaurar Servicios de Red';

  @override
  String get recoveryRestoreNetworkDesc =>
      'Reinicia los servicios de red (NetworkManager, systemd-networkd) para solucionar problemas de conexión.';

  @override
  String get recoveryRebuildGrub => 'Reconstruir GRUB';

  @override
  String get recoveryRebuildGrubDesc =>
      'Reconstruye la configuración de GRUB y actualiza el gestor de arranque. Se crea una copia de seguridad automática.';

  @override
  String get recoveryRestoreFlathub => 'Restaurar Flathub';

  @override
  String get recoveryRestoreFlathubDesc =>
      'Restaura el repositorio Flathub para Flatpak y actualiza los metadatos de las aplicaciones.';

  @override
  String get recoveryRestoreRepos => 'Restaurar Repositorios';

  @override
  String get recoveryRestoreReposDesc =>
      'Actualiza y restaura los repositorios del gestor de paquetes (APT, DNF, Pacman) para solucionar problemas de actualización.';

  @override
  String get recoveryPerformUpdates => 'Realizar Actualizaciones';

  @override
  String get recoveryPerformUpdatesConfirm =>
      '¿Desea realizar las actualizaciones disponibles? Esta operación puede tardar algún tiempo.';

  @override
  String get recoveryTabRecovery => 'Recovery';

  @override
  String get recoveryTabSoftwareInstaller =>
      'Instalador de software del sistema';

  @override
  String get recoverySoftwareInstallerDesc =>
      'Descarga e instala automáticamente software esencial del sistema.';

  @override
  String get recoveryInstallFfmpeg => 'FFmpeg';

  @override
  String get recoveryInstallFfmpegDesc =>
      'Framework multimedia para codificación/decodificación de audio y video.';

  @override
  String get recoveryInstallYtDlp => 'yt-dlp';

  @override
  String get recoveryInstallYtDlpDesc =>
      'Descargador de video para muchos sitios.';

  @override
  String get recoveryInstallSystemLibs => 'Bibliotecas del sistema';

  @override
  String get recoveryInstallSystemLibsDesc =>
      'Bibliotecas esenciales que a menudo se pueden corromper.';

  @override
  String get recoveryInstallCodecs => 'Códecs de video y audio';

  @override
  String get recoveryInstallCodecsDesc =>
      'Códecs para formatos de video y audio comunes.';

  @override
  String get recoveryInstallRsync => 'rsync';

  @override
  String get recoveryInstallRsyncDesc =>
      'Herramienta eficiente para sincronización y transferencia de archivos.';

  @override
  String get recoveryFixWifiAutoSuspend => 'Corregir Auto-Suspend WiFi';

  @override
  String get recoveryFixWifiAutoSuspendDesc =>
      'Deshabilita la suspensión automática USB para adaptadores WiFi y receptores inalámbricos internos para evitar desconexiones aleatorias.';

  @override
  String get install => 'Instalar';

  @override
  String get execute => 'Ejecutar';

  @override
  String get viewOutput => 'Ver Salida';

  @override
  String get infoServices => 'Servicios';

  @override
  String get infoServicesAnalysis => 'Análisis de servicios del sistema';

  @override
  String get infoServicesAnalysisDesc =>
      'Identifica los servicios que ralentizan el inicio del sistema usando systemd-analyze blame';

  @override
  String get infoServicesManagement => 'Gestión de servicios';

  @override
  String get infoServicesManagementDesc =>
      'Habilita, deshabilita y reinicia servicios del sistema con control completo';

  @override
  String get infoServicesStatus => 'Visualización de estado';

  @override
  String get infoServicesStatusDesc =>
      'Muestra el estado de todos los servicios (activos, inactivos, fallidos)';

  @override
  String get infoStartupApps => 'Apps al Inicio';

  @override
  String get infoStartupAppsManagement => 'Gestión de aplicaciones al inicio';

  @override
  String get infoStartupAppsManagementDesc =>
      'Ver y gestionar todas las aplicaciones que se inician automáticamente';

  @override
  String get infoStartupAppsProtection => 'Protección de apps del sistema';

  @override
  String get infoStartupAppsProtectionDesc =>
      'Previene la desactivación accidental de aplicaciones críticas del sistema';

  @override
  String get infoStartupAppsTermination => 'Terminación de procesos';

  @override
  String get infoStartupAppsTerminationDesc =>
      'Opción para terminar los procesos de una app cuando se desactiva';

  @override
  String get infoCleanup => 'Limpieza del Sistema';

  @override
  String get infoCleanupTempFiles => 'Búsqueda de archivos temporales';

  @override
  String get infoCleanupTempFilesDesc =>
      'Encuentra automáticamente archivos temporales de aplicaciones comunes (navegador, IDE, desarrollo)';

  @override
  String get infoCleanupCache => 'Limpieza de caché';

  @override
  String get infoCleanupCacheDesc =>
      'Elimina caché del sistema y aplicaciones para liberar espacio';

  @override
  String get infoCleanupTrash => 'Gestión de papelera';

  @override
  String get infoCleanupTrashDesc =>
      'Vacía la papelera y limpia archivos temporales de forma segura';

  @override
  String get infoInstalledApps => 'Apps Instaladas';

  @override
  String get infoInstalledAppsManagement => 'Gestión de múltiples paquetes';

  @override
  String get infoInstalledAppsManagementDesc =>
      'Ver apps instaladas a través de APT, Snap, Flatpak y GNOME';

  @override
  String get infoInstalledAppsDependencies => 'Verificación de dependencias';

  @override
  String get infoInstalledAppsDependenciesDesc =>
      'Verifica las dependencias antes de la eliminación para evitar problemas';

  @override
  String get infoInstalledAppsWarnings => 'Advertencias de seguridad';

  @override
  String get infoInstalledAppsWarningsDesc =>
      'Advierte cuando un paquete es utilizado por otro software o el sistema';

  @override
  String get infoMonitor => 'Monitor del Sistema';

  @override
  String get infoMonitorProcesses => 'Monitoreo de procesos';

  @override
  String get infoMonitorProcessesDesc =>
      'Ver todos los procesos activos con uso de CPU, memoria y disco';

  @override
  String get infoMonitorSorting => 'Ordenamiento avanzado';

  @override
  String get infoMonitorSortingDesc =>
      'Ordena procesos por CPU o memoria en orden ascendente o descendente';

  @override
  String get infoMonitorTermination => 'Terminación de procesos';

  @override
  String get infoMonitorTerminationDesc =>
      'Termina procesos que no responden directamente desde la interfaz';

  @override
  String get infoMonitorSystemInfo => 'Información del sistema';

  @override
  String get infoMonitorSystemInfoDesc =>
      'Muestra detalles sobre CPU, RAM, discos y tarjeta gráfica';

  @override
  String get infoAppearance => 'Personalización de Apariencia';

  @override
  String get infoAppearanceFonts => 'Gestión de fuentes';

  @override
  String get infoAppearanceFontsDesc =>
      'Configura fuentes para interfaz, documentos y texto monoespaciado con vistas previas';

  @override
  String get infoAppearanceRendering => 'Renderizado avanzado';

  @override
  String get infoAppearanceRenderingDesc =>
      'Controla hinting, antialiasing y factor de escala';

  @override
  String get infoAppearanceThemes => 'Temas e iconos';

  @override
  String get infoAppearanceThemesDesc =>
      'Personaliza temas de cursor, iconos y aplicaciones heredadas con vistas previas';

  @override
  String get infoAppearanceWallpaper => 'Fondo de escritorio';

  @override
  String get infoAppearanceWallpaperDesc =>
      'Establece imágenes de fondo para tema claro y oscuro';

  @override
  String get infoAppearanceWindows => 'Comportamiento de ventanas';

  @override
  String get infoAppearanceWindowsDesc =>
      'Configura acciones de clic, botones de barra de título y foco de ventanas';

  @override
  String get infoGrub => 'Editor GRUB (Modo Avanzado)';

  @override
  String get infoGrubEditor => 'Editor de configuración GRUB';

  @override
  String get infoGrubEditorDesc =>
      'Edita directamente el archivo /etc/default/grub con editor integrado';

  @override
  String get infoGrubBackup => 'Respaldo automático';

  @override
  String get infoGrubBackupDesc =>
      'Crea respaldos automáticos antes de cada modificación';

  @override
  String get infoGrubUpdate => 'Actualización de GRUB';

  @override
  String get infoGrubUpdateDesc =>
      'Aplica los cambios y actualiza el gestor de arranque';

  @override
  String get infoGrubRestore => 'Restauración de respaldo';

  @override
  String get infoGrubRestoreDesc =>
      'Restaura fácilmente una configuración anterior';

  @override
  String get infoKernel => 'Gestión de Kernel (Modo Avanzado)';

  @override
  String get infoKernelList => 'Lista de kernels instalados';

  @override
  String get infoKernelListDesc =>
      'Ver todos los kernels instalados con versión y tamaño';

  @override
  String get infoKernelRemoval => 'Eliminación de kernel';

  @override
  String get infoKernelRemovalDesc =>
      'Elimina kernels antiguos de forma segura (protege el kernel actual)';

  @override
  String get infoKernelDefault => 'Configuración de kernel predeterminado';

  @override
  String get infoKernelDefaultDesc => 'Elige qué kernel iniciar por defecto';

  @override
  String get infoKernelCleanup => 'Limpieza automática';

  @override
  String get infoKernelCleanupDesc =>
      'Mantiene solo un número específico de kernels más recientes';

  @override
  String get infoSecurity => 'Seguridad';

  @override
  String get infoSecurityPassword => 'Gestión de contraseñas';

  @override
  String get infoSecurityPasswordDesc =>
      'Guarda la contraseña de administrador de forma segura para operaciones sudo';

  @override
  String get infoSecurityWarning => 'Advertencia para usuarios expertos';

  @override
  String get infoSecurityWarningDesc =>
      'Pantalla de advertencia inicial para usuarios expertos';

  @override
  String get infoSecurityMode => 'Modo Estándar/Avanzado';

  @override
  String get infoSecurityModeDesc =>
      'Separa funcionalidades básicas de las avanzadas (GRUB, Kernel)';

  @override
  String get recoveryCheckUpdatesComplete =>
      'Búsqueda de actualizaciones completada';

  @override
  String recoveryCheckUpdatesError(String error) {
    return 'Error durante la búsqueda de actualizaciones: $error';
  }

  @override
  String get diskAnalyzerMainDirectories => 'Directorios Principales';

  @override
  String get diskIndexingNotice =>
      'Indexación del disco en curso: el primer análisis puede tardar. Los datos se guardarán en la caché para futuras sesiones.';

  @override
  String get hardwareSuggestionsTitle => 'Sugerencias GRUB basadas en Hardware';

  @override
  String get hardwareSuggestionsDescription =>
      'Las siguientes sugerencias se basan en el análisis de tu configuración de hardware:';

  @override
  String get hardwareSuggestionsPriorityHigh => 'Alta';

  @override
  String get hardwareSuggestionsPriorityMedium => 'Media';

  @override
  String get hardwareSuggestionsPriorityLow => 'Baja';

  @override
  String get hardwareSuggestionsApply => 'Aplicar';

  @override
  String get hardwareSuggestionsCancel => 'Cancelar';

  @override
  String get hardwareSuggestionsAlreadyPresent => 'Ya presente';

  @override
  String hardwareSuggestionsCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String hardwareSuggestionsSuggestedValue(String value) {
    return 'Sugerido: $value';
  }

  @override
  String get hardwareSuggestionsAnalyzing => 'Analizando el hardware...';

  @override
  String get hardwareSuggestionsNoAvailable =>
      'No hay sugerencias de hardware disponibles.';

  @override
  String hardwareSuggestionsApplied(String parameter) {
    return 'Sugerencia aplicada: $parameter';
  }

  @override
  String hardwareSuggestionsApplyError(String error) {
    return 'Error al aplicar la sugerencia: $error';
  }

  @override
  String hardwareSuggestionsGenerationError(String error) {
    return 'Error al generar las sugerencias: $error';
  }

  @override
  String grubSuggestionCpuThreadirqs(int count) {
    return 'CPU con $count núcleos: añadir threadirqs puede mejorar la planificación multi-núcleo';
  }

  @override
  String get grubSuggestionCpuMitigationsOff =>
      'CPU moderna: mitigations=off puede mejorar el rendimiento (solo si aceptas el compromiso de seguridad)';

  @override
  String get grubSuggestionCpuIntelIommu =>
      'CPU Intel: habilita IOMMU para virtualización y aislamiento de dispositivos';

  @override
  String get grubSuggestionCpuAmdIommu =>
      'CPU AMD: habilita IOMMU para virtualización y aislamiento de dispositivos';

  @override
  String grubSuggestionRamZswapDisable(String gb) {
    return 'Sistema con $gb GB RAM: zswap suele ser innecesario';
  }

  @override
  String grubSuggestionRamZswapEnable(String gb) {
    return 'Sistema con $gb GB RAM: zswap puede ayudar cuando la memoria está ajustada';
  }

  @override
  String get grubSuggestionGpuNvidiaModeset =>
      'GPU NVIDIA detectada: habilita nvidia-drm modeset para mejor rendimiento gráfico';

  @override
  String get grubSuggestionGpuNvidiaVideoMemory =>
      'GPU NVIDIA: conservar asignaciones de memoria de vídeo entre suspensión/reanudación';

  @override
  String get grubSuggestionGpuAmdPpfeaturemask =>
      'GPU AMD: habilitar la máscara completa de gestión de energía';

  @override
  String get grubSuggestionGpuVideoMode =>
      'Fijar un modo de vídeo para reducir problemas de pantalla al arrancar';

  @override
  String get grubSuggestionFirmwareUefiQuietSplash =>
      'UEFI: quiet splash puede mejorar la experiencia de arranque';

  @override
  String get grubSuggestionPerfElevatorNone =>
      'Almacenamiento centrado en SSD: elevator=none puede mejorar el rendimiento de E/S';

  @override
  String get grubSuggestionPerfVmSwappiness =>
      'Reducir swappiness cuando hay RAM suficiente';

  @override
  String get grubSuggestionGpuNvidiaWaylandPageTable =>
      'NVIDIA: UsePageAttributeTable mejora el rendimiento de renderizado en Wayland';

  @override
  String get grubSuggestionGpuNvidiaWaylandResizableBar =>
      'NVIDIA: EnableResizableBar aumenta el rendimiento de la GPU un 10-15% (PCIe ReBAR)';

  @override
  String get grubSuggestionGpuNvidiaWaylandGpuFirmware =>
      'NVIDIA: EnableGpuFirmware=0 mejora la estabilidad y compatibilidad en Wayland';

  @override
  String get grubSuggestionGpuNvidiaWaylandFbdev =>
      'NVIDIA: fbdev=1 habilita la consola de framebuffer en Wayland';

  @override
  String get settingsPasswordSecurityMessage =>
      'La contraseña se guarda de forma segura utilizando el keyring del sistema.';

  @override
  String get tabSmart => 'SMART';

  @override
  String get tabShutdownScheduler => 'Apagado Automático';

  @override
  String get shutdownInfoTitle => 'Apagado Automático';

  @override
  String get shutdownInfoDescription =>
      'Configura el apagado automático del PC a horas programadas. Utiliza temporizadores systemd para garantizar la compatibilidad con todas las distribuciones Linux modernas.';

  @override
  String get shutdownSystemdRequired => 'systemd Requerido';

  @override
  String get shutdownSystemdRequiredDesc =>
      'Esta función requiere systemd, disponible en Fedora, Ubuntu, Arch, Debian y otras distribuciones Linux modernas.';

  @override
  String get shutdownPasswordRequired =>
      'Contraseña requerida. Configura la contraseña en la configuración.';

  @override
  String get shutdownActiveTimers => 'Temporizadores Activos';

  @override
  String get shutdownCreateTimer => 'Crear Nuevo Temporizador';

  @override
  String get shutdownScheduleType => 'Tipo de Programación';

  @override
  String get shutdownScheduleDaily => 'Diaria';

  @override
  String get shutdownScheduleWeekly => 'Semanal';

  @override
  String get shutdownScheduleMonthly => 'Mensual';

  @override
  String get shutdownTime => 'Hora';

  @override
  String get shutdownSelectTime => 'Seleccionar Hora';

  @override
  String get shutdownSelectDays => 'Seleccionar Días';

  @override
  String get shutdownSelectDayOfMonth => 'Seleccionar Día del Mes';

  @override
  String get shutdownDayOfMonth => 'Día del Mes';

  @override
  String get shutdownDaySunday => 'Domingo';

  @override
  String get shutdownDayMonday => 'Lunes';

  @override
  String get shutdownDayTuesday => 'Martes';

  @override
  String get shutdownDayWednesday => 'Miércoles';

  @override
  String get shutdownDayThursday => 'Jueves';

  @override
  String get shutdownDayFriday => 'Viernes';

  @override
  String get shutdownDaySaturday => 'Sábado';

  @override
  String get shutdownTimerCreated => 'Temporizador de apagado creado con éxito';

  @override
  String get shutdownTimerRemoved =>
      'Temporizador de apagado eliminado con éxito';

  @override
  String get shutdownRemoveConfirm =>
      '¿Quieres eliminar este temporizador de apagado?';

  @override
  String get shutdownNextRun => 'Próxima ejecución';

  @override
  String get shutdownStatusInactive => 'Inactivo';

  @override
  String get shutdownWeeklyDaysRequired =>
      'Selecciona al menos un día de la semana';

  @override
  String get shutdownMonthlyDayRequired => 'Selecciona un día del mes';

  @override
  String get shutdownOpenSettings => 'Abrir Configuración';

  @override
  String get shutdownEditTimer => 'Editar Temporizador';

  @override
  String get shutdownTimerDetails => 'Detalles del Temporizador';

  @override
  String get diskCacheGenerating =>
      'Leyendo y generando caché en progreso... (solo la primera vez)';

  @override
  String get licenseActivate => 'Activar versión avanzada';

  @override
  String get licenseActivateButton => 'Activar';

  @override
  String get licenseName => 'Nombre';

  @override
  String get licenseSurname => 'Apellido';

  @override
  String get licenseEmail => 'Correo electrónico';

  @override
  String get licenseCode => 'Código de licencia';

  @override
  String get licenseRequired => 'Este campo es obligatorio';

  @override
  String get licenseActivateSuccess =>
      'Versión avanzada activada correctamente.';

  @override
  String get licenseActivateError =>
      'Código no válido. Compruebe nombre, apellido y email.';

  @override
  String get licenseActivatePremium => 'Activar / Premium';

  @override
  String get licenseActivateCardTitle => 'Activar versión avanzada';

  @override
  String get licenseActivateCardDesc =>
      'La versión Advanced cuesta 19,99 €. Introduzca sus datos y el código de licencia recibido tras el pago correcto para desbloquear GRUB, Kernel y Recovery. Sin un pago válido, la aplicación no puede activarse.';

  @override
  String get noSmartDisksFound => 'No se encontraron discos con soporte SMART.';

  @override
  String get smartctlNotFound => 'smartctl no encontrado';

  @override
  String get smartctlInstallPrompt =>
      'Se necesita smartmontools para monitorear la salud del disco. ¿Quieres instalarlo?';

  @override
  String get installing => 'Instalando...';

  @override
  String get installSmartctl => 'Instalar smartmontools';

  @override
  String get selectDisk => 'Seleccionar Disco';

  @override
  String get smartHealthPassed => 'Salud: SUPERADA';

  @override
  String get smartHealthFailed => 'Salud: FALLIDA';

  @override
  String get powerOnHours => 'Horas de Encendido';

  @override
  String get powerCycleCount => 'Ciclos de Encendido';

  @override
  String get diskInformation => 'Información del Disco';

  @override
  String get serialNumber => 'Número de Serie';

  @override
  String get firmware => 'Firmware';

  @override
  String get interface => 'Interfaz';

  @override
  String get smartAvailable => 'SMART Disponible';

  @override
  String get smartEnabled => 'SMART Habilitado';

  @override
  String get smartAttributes => 'Atributos SMART';

  @override
  String get attributes => 'atributos';

  @override
  String get failedAttributes => 'Atributos Fallidos';

  @override
  String get attributeId => 'ID';

  @override
  String get attributeName => 'Atributo';

  @override
  String get attributeValue => 'Valor';

  @override
  String get attributeWorst => 'Peor';

  @override
  String get attributeThreshold => 'Umbral';

  @override
  String get attributeRaw => 'Valor Bruto';

  @override
  String get selfTest => 'Self-Test';

  @override
  String get shortTest => 'Prueba Corta';

  @override
  String get longTest => 'Prueba Extendida';

  @override
  String get selfTestHint =>
      'Se pondrá en cola un self-test en el disco. Consulta los resultados más tarde en la tabla de atributos.';

  @override
  String get selfTestStarted =>
      'Self-test iniciado correctamente. Consulta los resultados más tarde.';

  @override
  String get selfTestFailed => 'No se pudo iniciar el self-test';

  @override
  String get attributeFailedWarning =>
      '¡Este atributo ha FALLADO! El disco podría necesitar reemplazo.';

  @override
  String get smartDataNotAvailable =>
      'Datos SMART no disponibles para este disco.';

  @override
  String get smartUsbInfoTitle => 'Unidad USB';

  @override
  String get smartUsbInfoBody =>
      'Los puentes USB-SATA a menudo limitan los datos SMART al estado de salud y la temperatura. Es posible que la tabla completa de atributos no esté disponible. Si es posible, prueba una conexión SATA directa.';

  @override
  String get smartSudoPasswordRequired =>
      'Guarda primero tu contraseña de sudo en Configuración.';

  @override
  String get smartInstallFailed => 'Instalación fallida.';

  @override
  String smartInstallError(String error) {
    return 'Error de instalación: $error';
  }

  @override
  String get smartErrNoPassword =>
      'Contraseña no guardada. Guarda tu contraseña en Configuración.';

  @override
  String get smartErrWrongPassword => 'Contraseña incorrecta.';

  @override
  String get smartErrPasswordRequired =>
      'Se requiere contraseña pero no se proporcionó.';

  @override
  String get smartErrPasswordTimeout =>
      'Tiempo de espera agotado al validar la contraseña.';

  @override
  String smartErrPasswordGeneric(String error) {
    return 'Error de validación: $error';
  }

  @override
  String smartErrSudo(String error) {
    return 'Error de sudo: $error';
  }

  @override
  String get smartErrUnsupportedPm => 'Gestor de paquetes no compatible.';

  @override
  String smartErrUnexpected(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get smartErrAptLock =>
      'No se pudo actualizar: otro proceso está usando apt. Inténtalo de nuevo en unos segundos.';

  @override
  String get smartErrAptNoRepos =>
      'Repositorios no encontrados. Revisa la configuración de los repositorios.';

  @override
  String smartErrAptUpdateFailed(String error) {
    return 'Error al actualizar la caché: $error';
  }

  @override
  String get smartErrDpkgInterrupted =>
      'dpkg interrumpido. Ejecuta \"sudo dpkg --configure -a\" e inténtalo de nuevo.';

  @override
  String get smartErrGpgUnauthenticated =>
      'Paquetes no autenticados. Actualiza las claves GPG: \"sudo apt-get update\".';

  @override
  String smartErrInstallFailed(String error) {
    return 'Error de instalación: $error';
  }

  @override
  String get smartErrNotFoundAfterInstall =>
      'Instalación completada pero smartctl no encontrado. Reinicia la aplicación e inténtalo de nuevo.';

  @override
  String get servicesGuideTitle => 'Linux Services Guide';

  @override
  String get servicesGuideWhatAre => 'What are Linux Services?';

  @override
  String get servicesGuideWhatAreBody =>
      'Services (also called daemons) are background programs that start automatically when the system boots. They provide essential functions such as network management (NetworkManager), printing (CUPS), scheduling (cron), database servers (MySQL, PostgreSQL), web servers (Apache, Nginx), and many others.\n\nSome services are essential for the system to work correctly, while others are optional and depend on the specific use of the machine.';

  @override
  String get servicesGuideHowToManage => 'How services are managed';

  @override
  String get servicesGuideHowToManageBody =>
      'On modern Linux distributions, services are managed by systemd, the init system. Each service has a unit file (.service) that defines how it starts, stops, and behaves.\n\nIn this application you can:\n• Start and stop a service immediately\n• Enable a service so it starts automatically at boot\n• Disable a service so it does NOT start at boot\n• View the current status and logs of a service';

  @override
  String get servicesGuideHowToDisable =>
      'How to disable a service with this software';

  @override
  String get servicesGuideHowToDisableBody =>
      'From the \"Services\" tab, find the service you want to disable. Tap \"Stop\" to stop it immediately, or tap \"Disable\" to prevent it from starting automatically on the next boot.\n\nYou can also combine the two: tap \"Stop\" and then \"Disable\" to completely deactivate a service until you manually re-enable it.';

  @override
  String get servicesGuidePrecautions => 'Precautions and cautions';

  @override
  String get servicesGuidePrecautionsBody =>
      '• Do NOT disable services you don\'t know: some are essential for the system (e.g. NetworkManager, accounts-daemon, systemd-logind)\n• Disabling network services (NetworkManager, systemd-networkd) will cut off Internet access\n• Disabling display managers (gdm, sddm, lightdm) will prevent the graphical interface from starting\n• Always verify that you don\'t need a service before disabling it\n• The changes are system-wide: they affect all users, not just your account\n• If you make a mistake, you can re-enable the service from the same screen using \"Enable\"';

  @override
  String get servicesGuideDontShowAgain => 'Don\'t show this guide again';

  @override
  String get servicesGuideGotIt => 'Got it!';

  @override
  String get tabRepositories => 'Repositorios';

  @override
  String get repoTitle => 'Repositorios';

  @override
  String get repoCount => 'repos';

  @override
  String get repoEmpty => 'No se encontraron repositorios';

  @override
  String repoEnabled(Object name) {
    return '$name habilitado';
  }

  @override
  String repoDisabled(Object name) {
    return '$name deshabilitado';
  }

  @override
  String repoRemoved(Object name) {
    return '$name eliminado';
  }

  @override
  String get repoError => 'Operación fallida. Verifica tu contraseña sudo.';

  @override
  String get repoRemoveTitle => 'Eliminar Repositorio';

  @override
  String repoRemoveConfirm(Object name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?';
  }

  @override
  String get repoEditTitle => 'Editar Repositorio';

  @override
  String get repoFilePathLabel => 'Archivo:';

  @override
  String get repoContentLabel => 'Contenido';

  @override
  String get repoUpdated => 'Repositorio actualizado';

  @override
  String get edit => 'Editar';

  @override
  String get tabTweaks => 'Ajustes';

  @override
  String get tweaksSwap => 'Swap';

  @override
  String get tweaksSwapRecommendations => 'Recomendaciones de Swap';

  @override
  String get appCheckForUpdates => 'Buscar actualizaciones';

  @override
  String get kernelUpdateDetectedLiquorix =>
      'Actualización del kernel Liquorix disponible';

  @override
  String get kernelUpdateDetectedXanmod =>
      'Actualización del kernel Xanmod disponible';

  @override
  String get tabSystemStatus => 'Estado del sistema';

  @override
  String get tabSecurity => 'Seguridad';

  @override
  String get tabKernelTweaks => 'Ajustes del kernel';

  @override
  String get tabOperationHistory => 'Historial';

  @override
  String get statusRefresh => 'Actualizar';

  @override
  String get statusReadOnlyNote =>
      'Información del sistema de solo lectura. No se modifica nada.';

  @override
  String get statusTabKernel => 'Kernel';

  @override
  String get statusTabSecurity => 'Seguridad';

  @override
  String get statusTabVirtualization => 'Virtualización';

  @override
  String get statusTabPrinters => 'Impresoras';

  @override
  String get statusEnabled => 'Activado';

  @override
  String get statusDisabled => 'Desactivado';

  @override
  String get statusNotAvailable => 'No disponible';

  @override
  String get statusNotInstalled => 'No instalado';

  @override
  String get statusUnknown => 'Desconocido';

  @override
  String get statusNone => 'Ninguno';

  @override
  String get statusEnforcing => 'Enforcing';

  @override
  String get statusPermissive => 'Permisivo';

  @override
  String get statusKernelInfo => 'Información del kernel';

  @override
  String get statusKernelVersion => 'Versión';

  @override
  String get statusKernelBuild => 'Build';

  @override
  String get statusCpuCount => 'Número de CPU';

  @override
  String get statusKernelTuning => 'Ajuste del kernel';

  @override
  String get statusThpMode => 'Transparent Huge Pages';

  @override
  String get statusZswap => 'Zswap';

  @override
  String get statusGovernor => 'Gobernador de CPU';

  @override
  String get statusIoScheduler => 'Planificador I/O';

  @override
  String get statusMandatoryAccess => 'Control de acceso obligatorio';

  @override
  String get statusAppArmor => 'AppArmor';

  @override
  String get statusSelinux => 'SELinux';

  @override
  String get statusSecureBoot => 'Secure Boot';

  @override
  String get statusNetworkSecurity => 'Seguridad de red';

  @override
  String get statusFirewall => 'Firewall';

  @override
  String get statusFirewallBackend => 'Backend del firewall';

  @override
  String get statusSshService => 'Servicio SSH';

  @override
  String get statusRootSsh => 'Inicio de sesión root SSH';

  @override
  String get statusAutoUpdates => 'Actualizaciones automáticas';

  @override
  String get statusVirtHost => 'Host de virtualización';

  @override
  String get statusCpuVirt => 'Virtualización de CPU';

  @override
  String get statusKvmModule => 'Módulo KVM';

  @override
  String get statusIommu => 'IOMMU';

  @override
  String get statusVirtAux => 'Soporte de virtualización';

  @override
  String get statusVfio => 'VFIO';

  @override
  String get statusKsm => 'KSM';

  @override
  String get statusDocker => 'Docker';

  @override
  String get statusLibvirt => 'Libvirt';

  @override
  String get statusCups => 'CUPS';

  @override
  String get statusCupsService => 'Servicio CUPS';

  @override
  String get statusPrinters => 'Impresoras';

  @override
  String get statusPrinterDrivers => 'Controladores de impresora';

  @override
  String get securitySubtitle =>
      'Administra los servicios de seguridad del sistema. Cada acción se registra en el historial de operaciones y se puede deshacer.';

  @override
  String get securityFirewall => 'Firewall';

  @override
  String get securityFirewallDesc =>
      'Bloquea las conexiones entrantes no solicitadas con UFW o firewalld.';

  @override
  String securityFirewallBackend(Object backend) {
    return 'Activo ($backend)';
  }

  @override
  String get securitySsh => 'Servicio SSH';

  @override
  String get securitySshDesc => 'Acceso remoto a shell a través de la red.';

  @override
  String get securityRootSsh => 'Inicio de sesión root SSH';

  @override
  String get securityRootSshDesc =>
      'Permitir o denegar el inicio de sesión root directo por SSH.';

  @override
  String get securityRootAllowed => 'Inicio de sesión root permitido';

  @override
  String get securityAutoUpdates => 'Actualizaciones automáticas';

  @override
  String get securityAutoUpdatesDesc =>
      'Instala automáticamente las actualizaciones de seguridad en segundo plano.';

  @override
  String get kernelTweaksSubtitle =>
      'Aplica los ajustes del kernel de forma persistente: se vuelven a aplicar en cada arranque.';

  @override
  String get kernelTweaksPersistNote =>
      'Sin ajustes persistentes activos. Los ajustes aplicados se guardan en un servicio systemd y se vuelven a aplicar en cada arranque.';

  @override
  String get kernelTweaksPersistActive =>
      'Los ajustes persistentes del kernel están activos y se vuelven a aplicar en cada arranque.';

  @override
  String get kernelTweaksApply => 'Aplicar';

  @override
  String get kernelTweaksReset => 'Restablecer';

  @override
  String get kernelTweaksResetTitle => 'Restablecer ajustes del kernel';

  @override
  String get kernelTweaksResetConfirm =>
      'Esto elimina los ajustes persistentes del kernel y restaura los valores predeterminados. ¿Continuar?';

  @override
  String get kernelTweaksThp => 'Transparent Huge Pages';

  @override
  String get kernelTweaksThpDesc =>
      'Modo utilizado para la asignación de páginas grandes transparentes.';

  @override
  String get kernelTweaksGovernor => 'Gobernador de CPU';

  @override
  String get kernelTweaksGovernorDesc =>
      'Política de escalado de frecuencia de CPU aplicada a todos los núcleos.';

  @override
  String get kernelTweaksScheduler => 'Planificador de CPU';

  @override
  String get kernelTweaksSchedulerDesc =>
      'Ejecuta los procesos hijos recién creados antes que el padre para una mayor capacidad de respuesta.';

  @override
  String get kernelTweaksPerf => 'Rendimiento';

  @override
  String get kernelTweaksOndemand => 'Bajo demanda';

  @override
  String get kernelTweaksSchedutil => 'Schedutil';

  @override
  String get kernelTweaksPowersave => 'Ahorro de energía';

  @override
  String get kernelTweaksAlways => 'Siempre';

  @override
  String get kernelTweaksMadvise => 'Madvise';

  @override
  String get kernelTweaksNever => 'Nunca';

  @override
  String get kernelTweaksSchedOn => 'Hijos primero';

  @override
  String get kernelTweaksSchedOff => 'Predeterminado';

  @override
  String get historySubtitle =>
      'Registro de las operaciones realizadas. Restaura para deshacer una acción.';

  @override
  String get historyEmpty => 'Aún no hay operaciones registradas.';

  @override
  String get historyRestore => 'Restaurar';

  @override
  String get historyRestoreTitle => 'Restaurar operación';

  @override
  String get historyRestoreConfirm =>
      'Esto revertirá los cambios de esta operación. ¿Continuar?';

  @override
  String get historyRestored => 'Restaurada';

  @override
  String get historyClearAll => 'Vaciar historial';

  @override
  String get historyClearTitle => 'Vaciar historial';

  @override
  String get historyClearConfirm =>
      'Elimina todas las operaciones registradas del historial. No se deshace nada. ¿Continuar?';

  @override
  String get historyFirewallEnable => 'Firewall activado';

  @override
  String get historyFirewallDisable => 'Firewall desactivado';

  @override
  String get historySshEnable => 'Servicio SSH activado';

  @override
  String get historySshDisable => 'Servicio SSH desactivado';

  @override
  String get historyRootAllow => 'Inicio de sesión root SSH permitido';

  @override
  String get historyRootDeny => 'Inicio de sesión root SSH denegado';

  @override
  String get historyAutoUpdateEnable => 'Actualizaciones automáticas activadas';

  @override
  String get historyAutoUpdateDisable =>
      'Actualizaciones automáticas desactivadas';

  @override
  String get historyKernelApply => 'Ajustes del kernel aplicados';

  @override
  String get historyKernelReset => 'Ajustes del kernel restablecidos';

  @override
  String get kernelTweaksCurrent => 'Actual';

  @override
  String get kernelTweaksSavedForBoot => 'Guardado para el arranque';

  @override
  String get tabDeviceManager => 'Administrador de dispositivos';

  @override
  String get deviceManagerTitle => 'Administrador de dispositivos';

  @override
  String get deviceManagerLoading => 'Detectando dispositivos...';

  @override
  String get deviceManagerEmpty => 'No se encontraron dispositivos';

  @override
  String get deviceManagerRefresh => 'Actualizar';

  @override
  String get deviceManagerEnable => 'Habilitar';

  @override
  String get deviceManagerDisable => 'Deshabilitar';

  @override
  String get deviceManagerEnabled => 'Habilitado';

  @override
  String get deviceManagerDisabled => 'Deshabilitado';

  @override
  String deviceManagerToggleSuccess(Object action) {
    return 'Dispositivo $action correctamente';
  }

  @override
  String deviceManagerToggleError(Object action) {
    return 'Error al $action el dispositivo';
  }

  @override
  String get deviceManagerCannotDisable =>
      'Este dispositivo no se puede deshabilitar';

  @override
  String get deviceManagerDetails => 'Detalles';

  @override
  String get deviceManagerDriver => 'Controlador';

  @override
  String get deviceManagerBus => 'Bus';

  @override
  String get deviceManagerVendor => 'Fabricante';

  @override
  String get deviceManagerProduct => 'Producto';

  @override
  String get deviceManagerConfirmTitle => 'Confirmar acción';

  @override
  String get deviceManagerConfirmDisable =>
      'Deshabilitar este dispositivo puede causar inestabilidad del sistema. El cambio persistirá después del reinicio. ¿Continuar?';

  @override
  String get deviceManagerConfirmEnable =>
      '¿Habilitar este dispositivo? El cambio persistirá después del reinicio. ¿Continuar?';

  @override
  String get deviceManagerAllDevices => 'Todos los dispositivos';

  @override
  String get deviceManagerShowDisabled => 'Mostrar deshabilitados';

  @override
  String get deviceManagerStatus => 'Estado';

  @override
  String get deviceManagerProperties => 'Propiedades';

  @override
  String get deviceManagerClose => 'Cerrar';

  @override
  String get deviceManagerNoSudo =>
      'Guarda primero la contraseña de administrador en Configuración';

  @override
  String get deviceManagerPersistent => 'Persiste después del reinicio';

  @override
  String get tabDriverManager => 'Controladores';

  @override
  String get driverManagerTitle => 'Gestor de Controladores y Firmware';

  @override
  String get driverManagerScan => 'Escanear hardware';

  @override
  String get driverManagerFirmwareUpdates => 'Actualizaciones de Firmware';

  @override
  String get driverManagerAvailableDrivers => 'Controladores disponibles';

  @override
  String get driverManagerInstalledDrivers => 'Controladores instalados';

  @override
  String get driverManagerAllDriversInstalled =>
      'Todos los controladores conocidos están instalados';

  @override
  String get driverManagerNoDriversInstalled => 'Ningún controlador instalado';

  @override
  String get driverManagerCurrentDriver => 'Controlador actual';

  @override
  String get driverManagerPackage => 'Paquete';

  @override
  String get driverManagerInstall => 'Instalar';

  @override
  String get driverManagerUpdate => 'Actualizar';

  @override
  String get driverManagerRebootRequired =>
      'Reinicio necesario tras la actualización';

  @override
  String get driverManagerLinuxFirmware => 'Firmware Linux (linux-firmware)';

  @override
  String get driverManagerLinuxFirmwareDesc =>
      'Paquete de firmware completo para GPU, Wi-Fi, Bluetooth y otros dispositivos';
}
