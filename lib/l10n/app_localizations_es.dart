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
  String get trayShutdownTimer => 'Apagado automático';

  @override
  String get trayShowMainWindow => 'Mostrar ventana principal';

  @override
  String get trayCpuGpuUsage => 'Uso CPU, GPU';

  @override
  String get trayExit => 'Salir';

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
      'Super Linux Utility es una aplicación completa para la gestión avanzada del sistema Linux. Ofrece herramientas poderosas para optimizar el rendimiento, gestionar servicios, aplicaciones y personalizar la apariencia del sistema.';

  @override
  String get features => 'Características';

  @override
  String get appExpertUsers =>
      'Aplicación diseñada para usuarios expertos de Linux';

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
  String get languageRestartMessage =>
      'El idioma se aplicará al reiniciar la aplicación';

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
  String get recoveryCheckUpdates => 'Buscar Actualizaciones';

  @override
  String get recoveryCheckUpdatesDesc =>
      'Busca actualizaciones disponibles para todos los gestores de paquetes instalados (APT, DNF, Pacman, Snap, Flatpak).';

  @override
  String get recoveryPerformUpdates => 'Realizar Actualizaciones';

  @override
  String get recoveryPerformUpdatesConfirm =>
      '¿Desea realizar las actualizaciones disponibles? Esta operación puede tardar algún tiempo.';

  @override
  String get recoveryTabRecovery => 'Recovery';

  @override
  String get recoveryTabCheckUpdates => 'Buscar actualizaciones';

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
  String get settingsPasswordSecurityMessage =>
      'La contraseña se guarda de forma segura utilizando el keyring del sistema.';

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
}
