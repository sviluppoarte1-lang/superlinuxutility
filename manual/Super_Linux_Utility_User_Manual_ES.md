# Super Linux Utility v2.0.6
# Manual Completo del Usuario — Español

---

## Tabla de Contenidos

1. [Introducción](#1-introducción)
2. [Requisitos del Sistema](#2-requisitos-del-sistema)
3. [Instalación](#3-instalación)
4. [Primer Inicio](#4-primer-inicio)
5. [Modo Estándar — Todas las Funciones](#5-modo-estándar)
   - 5.1 Servicios
   - 5.2 Aplicaciones de Inicio
   - 5.3 Limpieza
   - 5.4 Aplicaciones Instaladas
   - 5.5 Monitor del Sistema
   - 5.6 Analizador de Discos
   - 5.7 Salud del Disco SMART
   - 5.8 Gestor de Dispositivos
   - 5.9 Recuperación
   - 5.10 Ajustes
   - 5.11 Configuración
   - 5.12 Información
6. [Modo Avanzado — Funciones Adicionales](#6-modo-avanzado)
   - 6.1 Editor GRUB
   - 6.2 Benchmark
7. [Bandeja del Sistema](#7-bandeja-del-sistema)
8. [Actualizaciones Automáticas](#8-actualizaciones-automáticas)
9. [Solución de Problemas](#9-solución-de-problemas)
10. [Preguntas Frecuentes](#10-preguntas-frecuentes)
11. [Glosario](#11-glosario)

---

## 1. Introducción

**Super Linux Utility** es una aplicación completa de gestión del sistema para Linux. Proporciona una interfaz gráfica moderna para gestionar servicios, aplicaciones de inicio, limpiar archivos temporales, monitorizar el rendimiento del sistema, analizar discos, gestionar dispositivos de hardware y mucho más.

La aplicación viene en dos ediciones:

- **Estándar (Gratis):** Todas las herramientas esenciales de gestión del sistema — servicios, aplicaciones de inicio, limpieza, aplicaciones instaladas, monitor, analizador de discos, salud SMART, gestor de dispositivos, recuperación, ajustes y configuración.
- **Avanzado (De pago):** Todo lo del Estándar, más el editor GRUB y la suite de Benchmark.

**Distribuciones compatibles:** Ubuntu, Debian, Linux Mint, LMDE, Pop!_OS, Zorin, elementary, MX Linux, Fedora, RHEL, CentOS, Arch Linux, Manjaro, EndeavourOS, CachyOS, KDE neon.

**Entornos de escritorio compatibles:** GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt.

---

## 2. Requisitos del Sistema

- **SO:** Linux (64 bits)
- **Espacio en disco:** ~200 MB instalado
- **RAM:** 512 MB mínimo, 2 GB recomendado
- **Dependencias:** GTK3, GLib 2.0+
- **Opcional:** `libappindicator` para la bandeja del sistema, `smartmontools` para la salud del disco SMART

---

## 3. Instalación

### AppImage (Recomendado)
```bash
chmod +x super-linux-utility-2.0.6-x86_64.AppImage
./super-linux-utility-2.0.6-x86_64.AppImage
```

### Debian/Ubuntu (.deb)
```bash
sudo dpkg -i super-linux-utility_2.0.6_amd64.deb
sudo apt-get install -f
```

### Desde el código fuente
```bash
git clone https://github.com/sviluppoarte1-lang/superlinuxutility.git
cd superlinuxutility
flutter build linux
```

---

## 4. Primer Inicio

Cuando abres Super Linux Utility por primera vez, aparecen tres pantallas de configuración en secuencia:

### 4.1 Selección de Idioma
Elige tu idioma preferido de entre: Italiano, Inglés, Francés, Español, Alemán, Portugués. El idioma seleccionado se aplica a todos los botones, menús, mensajes y descripciones en toda la aplicación.

### 4.2 Pantalla de Advertencia
Un descuerente te recuerda que esta aplicación puede modificar configuraciones críticas del sistema (cargador de arranque GRUB, kernel, servicios). Se recomienda encarecidamente crear una copia de seguridad del sistema antes de usar funciones avanzadas. Marca "No mostrar esta advertencia de nuevo" para omitirla en futuros inicios.

### 4.3 Configuración de Contraseña
Para usar funciones que modifican el sistema (limpieza, gestión de servicios, edición de GRUB, etc.), la aplicación necesita tu contraseña de administrador (sudo). La contraseña se almacena de forma segura usando el llavero del sistema. Puedes omitir este paso y configurarlo más tarde en Configuración.

> **Consejo para principiantes:** Si no estás seguro de si ingresar tu contraseña, puedes omitirla. La mayoría de las funciones de solo lectura (monitor, analizador de discos, SMART) funcionan sin contraseña.

---

## 5. Modo Estándar — Todas las Funciones

El modo estándar proporciona 12 pestañas accesibles desde la barra lateral izquierda. Cada pestaña contiene herramientas específicas.

---

### 5.1 Servicios

**Propósito:** Ver y gestionar los servicios systemd que se ejecutan en tu sistema.

**Pestañas:**
- **Servicios Lentos:** Lista los servicios que tardan más de 2 segundos en iniciar (detectados mediante `systemd-analyze blame`). Esto ayuda a identificar qué ralentiza tu arranque.
- **Todos los Servicios:** Lista completa de todos los servicios systemd con su estado (activo, inactivo, fallido). Toca "Analizar Todos" para cargar la lista completa.
- **Deshabilitados:** Muestra todos los servicios que están actualmente deshabilitados.

**Acciones por servicio (toca el menú de tres puntos):**
- **Deshabilitar:** Impide que el servicio se inicie con el arranque.
- **Re-habilitar:** Permite que el servicio se inicie nuevamente con el arranque.
- **Detener:** Detiene inmediatamente un servicio en ejecución.

> **Advertencia para principiantes:** No deshabilites servicios que no reconozcas. Algunos servicios son esenciales para el correcto funcionamiento de tu sistema (por ejemplo, NetworkManager, PulseAudio, systemd-resolved). En caso de duda, deja el servicio habilitado.

> **Consejo para expertos:** Usa la pestaña "Servicios Lentos" para optimizar el tiempo de arranque. Servicios como `snapd`, `plymouth` o `fwupd` a menudo se pueden deshabilitar con seguridad si no los necesitas.

**Requiere contraseña:** Sí (para operaciones de deshabilitar/habilitar/detener)

---

### 5.2 Aplicaciones de Inicio

**Propósito:** Gestionar las aplicaciones que se inician automáticamente cuando inicias sesión.

La lista muestra todas las entradas de inicio automático divididas en secciones **Habilitadas** y **Deshabilitadas**. Cada entrada muestra el nombre de la aplicación, el comando y si es una aplicación del sistema o del usuario.

**Acciones por aplicación (toca el menú de tres puntos):**
- **Deshabilitar:** Impide que la aplicación se inicie al iniciar sesión. Si la aplicación está actualmente en ejecución, se te pregunta si también deseas terminar sus procesos.
- **Re-habilitar:** Reactiva una aplicación de inicio deshabilitada.
- **Terminar Procesos:** Mata todos los procesos en ejecución de esa aplicación.
- **Eliminar:** Elimina permanentemente la entrada de inicio automático.

**Protección de aplicaciones del sistema:** Algunas aplicaciones (como GNOME Shell, NetworkManager, componentes de KDE Plasma) están marcadas como protegidas y no se pueden deshabilitar. Esto previene daños accidentales a tu entorno de escritorio.

> **Consejo para principiantes:** Si notas que tu computadora tarda en iniciar, revisa la pestaña de Aplicaciones de Inicio. Deshabilitar aplicaciones innecesarias (como clientes de almacenamiento en la nube o aplicaciones de chat que no usas al iniciar) puede acelerar significativamente el inicio de sesión.

> **Consejo para expertos:** La aplicación crea sustituciones a nivel de usuario para las entradas de inicio automático del sistema en `/etc/xdg/autostart/` en lugar de modificar los archivos del sistema. Esto es seguro y reversible.

**Requiere contraseña:** No

---

### 5.3 Limpieza

**Propósito:** Liberar espacio en disco eliminando archivos temporales, cachés y limpiando la caché de páginas de Linux.

**Fila de botones:**
- **Actualizar Dimensiones:** Recalcula el tamaño de todas las carpetas temporales/caché detectadas.
- **Limpiar Archivos Temporales (botón naranja):** Elimina archivos temporales de todas las carpetas listadas. Aparece un diálogo de confirmación antes de la eliminación. Puedes excluir carpetas específicas tocando el ícono de alternancia junto a cada carpeta.

**Caché de Páginas de Linux:**
- **Botón Limpiar Caché:** Libera la caché de páginas del kernel ejecutando `sync && echo 1 > /proc/sys/vm/drop_caches`. Esto es seguro y no elimina ningún dato de usuario — solo borra las lecturas de archivos en caché de la RAM.

**Limpiar RAM:**
- Muestra el uso actual de RAM (usada / total / porcentaje).
- **Botón Limpiar RAM:** Limpia la caché de páginas, dentries e inodes ejecutando `sync && echo 3 > /proc/sys/vm/drop_caches`. Esto libera más memoria que la limpieza básica de caché. Muestra cuánta memoria se liberó después de la operación.

**Limpieza Automática de RAM:**
- Configura en **Configuración > Limpieza de RAM** para limpiar automáticamente la RAM a intervalos: Nunca, 5 min, 10 min, 15 min o 30 min.
- Se ejecuta en segundo plano al intervalo configurado.

**Agregar Carpeta Excluida:** Agrega carpetas personalizadas para excluir de la limpieza. Útil para preservar los directorios de caché de aplicaciones específicas.

> **Consejo para principiantes:** Usa "Limpiar Archivos Temporales" regularmente para liberar espacio en disco. Los botones "Limpiar Caché" y "Limpiar RAM" son seguros — no eliminan ningún archivo personal.

> **Consejo para expertos:** El limpiador de RAM usa `echo 3` (elimina caché de páginas + dentries + inodes), que es más agresivo que `echo 1` (solo caché de páginas). Úsalo cuando necesites recuperar memoria rápidamente, por ejemplo antes de iniciar una aplicación que consuma mucha memoria.

**Requiere contraseña:** Sí (para la limpieza de caché y RAM)

---

### 5.4 Aplicaciones Instaladas

**Propósito:** Ver y desinstalar aplicaciones de todos los gestores de paquetes.

**Gestores de paquetes compatibles:**
- **APT** (Debian/Ubuntu/Mint)
- **Snap** (Paquetes universales de Linux)
- **Flatpak** (Aplicaciones en sandbox)
- **GNOME** (Aplicaciones de escritorio mediante archivos .desktop)

**Características:**
- **Búsqueda:** Filtra aplicaciones por nombre o descripción.
- **Chips de filtro:** Alterna entre vistas Todas, APT, Snap, Flatpak, GNOME.
- **Desinstalación por aplicación:** Toca el menú de tres puntos y selecciona "Eliminar". La aplicación verifica las dependencias primero — si otros paquetes dependen del que deseas eliminar, un diálogo de advertencia te muestra la lista.

> **Advertencia para principiantes:** Ten cuidado al desinstalar paquetes del sistema. Si no estás seguro, busca el nombre del paquete en línea primero.

> **Consejo para expertos:** La verificación de dependencias usa `apt-cache depends` y `apt-cache rdepends --installed` para mostrar tanto dependencias directas como inversas.

**Requiere contraseña:** Sí (para la eliminación de paquetes)

---

### 5.5 Monitor del Sistema

**Propósito:** Monitorización en tiempo real de procesos, CPU, RAM, disco y GPU.

Esta pantalla tiene tres subpestañas:

#### Pestaña de Procesos
- Muestra todos los procesos en ejecución agrupados por nombre de aplicación.
- **Columnas:** Nombre de App, CPU%, Memoria — toca un encabezado de columna para ordenar.
- **Indicadores de CPU/RAM/GPU** en el lado derecho muestran el uso en tiempo real.
- **Acciones por grupo:** Seleccionar todos, Terminar todos, Forzar terminación de todos.
- **Modo de selección múltiple:** Marca múltiples grupos de procesos, luego mátalos todos a la vez.
- Se actualiza automáticamente cada 5 segundos.

#### Pestaña del Sistema
Muestra información del hardware en formato de tarjeta:
- **CPU:** Modelo, núcleos, hilos, barra de uso, velocidad de reloj.
- **Memoria:** Total, usada, libre, en caché, uso de swap.
- **Disco:** Nombre del dispositivo por disco, sistema de archivos, barra de uso.
- **GPU:** Modelo, controlador, porcentaje de uso, memoria, temperatura (si está disponible).
- **Servidor de Pantalla:** Detección Wayland/X11/XWayland, entorno de escritorio, variables de entorno clave.

#### Pestaña de Estado
Panel de estado del sistema de solo lectura con cuatro secciones:
- **Kernel:** Versión, información de compilación, modo THP, zswap, gobernador, programador de E/S.
- **Seguridad:** AppArmor, SELinux, Secure Boot, estado del firewall, estado de SSH, actualizaciones automáticas.
- **Virtualización:** Soporte de virtualización de CPU, KVM, IOMMU, VFIO, KSM, Docker, libvirt.
- **Impresoras:** Estado del servicio CUPS, impresoras instaladas, controladores de impresión.

> **Consejo para principiantes:** La pestaña de Procesos te ayuda a encontrar qué aplicación está usando demasiada CPU o memoria. Toca un grupo de procesos para ver los procesos individuales.

> **Consejo para expertos:** La pestaña de Estado proporciona una auditoría rápida de seguridad y virtualización. Revisa el estado del firewall, SSH y Secure Boot de un vistazo.

**Requiere contraseña:** No

---

### 5.6 Analizador de Discos

**Propósito:** Explorar tu sistema de archivos, visualizar el uso del disco y gestionar archivos.

**Navegación:**
- **Inicio / Sistema de Archivos / Discos externos:** Selección rápida de rutas base.
- **Atrás / Adelante:** Navega a través del historial.
- **Ordenar:** Por tamaño (ascendente/descendente) o alfabéticamente.
- **Menú Más:** Alterna la visibilidad de archivos ocultos/sistema.

**Características:**
- **Gráfico circular:** Visualiza la distribución del tamaño de los directorios.
- **Aviso del primer análisis:** Cuando un disco se analiza por primera vez, aparece un aviso informativo indicando que la indexación está en curso y el primer análisis puede tardar un tiempo.
- **Acciones de archivo/directorio:**
  - **Mover a la Papelera:** Eliminación segura a la papelera (con confirmación).
  - **Renombrar:** Renombra archivos o directorios.
  - **Mostrar Detalles:** Ver ruta, tamaño, tipo, permisos, propietario, fecha de modificación.

> **Advertencia:** Eliminar archivos del sistema de archivos raíz (`/`) requiere privilegios de administrador y es irreversible. Ten mucho cuidado.

> **Consejo para principiantes:** Comienza analizando tu directorio personal para encontrar carpetas grandes que ocupan espacio (por ejemplo, `~/.cache`, `~/.local/share/Trash`).

**Requiere contraseña:** Sí (para eliminar desde rutas raíz)

---

### 5.7 Salud del Disco SMART

**Propósito:** Monitorizar la salud de discos duros y SSD usando datos S.M.A.R.T.

**Características:**
- **Selector de disco:** Elige qué disco inspeccionar desde el menú desplegable.
- **Estado de salud:** Muestra PASSED o FAILED con temperatura y horas de encendido.
- **Detección USB:** Identifica discos conectados por USB y advierte que los puentes USB-SATA pueden limitar los datos SMART.
- **Tabla de atributos:** Muestra todos los atributos SMART (ID, nombre, valor, peor, umbral, raw). Los atributos fallidos se resaltan en rojo.
- **Autopruebas:**
  - **Prueba Corta:** Escaneo rápido (~2 minutos).
  - **Prueba Extendida:** Escaneo exhaustivo (puede tardar horas dependiendo del tamaño del disco).
  Los resultados aparecen en la tabla de atributos después de que la prueba se complete.

**Si smartctl no está instalado:** La aplicación ofrece instalar `smartmontools` automáticamente.

> **Consejo para principiantes:** Revisa la salud de tu disco mensualmente. Un estado "FAILED" o atributos marcados en rojo indican que el disco puede necesitar reemplazo pronto.

> **Consejo para expertos:** La aplicación soporta escaneo multidistribución (lsblk + smartctl --scan + fallback de /sys/block/). Los puentes USB-SATA se prueban con `smartctl -d sat`.

**Requiere contraseña:** Sí (para instalar smartctl y ejecutar autopruebas)

---

### 5.8 Gestor de Dispositivos

**Propósito:** Ver, habilitar y deshabilitar dispositivos de hardware — similar al Gestor de Dispositivos de Windows.

**Características:**
- **Árbol de dispositivos:** Todos los dispositivos de hardware (PCI, USB, bloque, red) agrupados por categoría: Adaptadores de pantalla, Adaptadores de red, Sonido/video, Controladores USB, Almacenamiento, Procesador, Dispositivos de entrada, Multimedia.
- **Barra de búsqueda:** Filtra dispositivos por nombre o descripción.
- **Filtro de deshabilitados:** Alterna para mostrar solo dispositivos deshabilitados.

**Acciones por dispositivo (toca para expandir, luego menú de tres puntos):**
- **Habilitar/Deshabilitar:** Alterna el estado del dispositivo con diálogo de confirmación. Requiere contraseña de sudo.
- **Panel de Propiedades:** Muestra información detallada — estado, tipo de bus, proveedor, controlador, IDs de proveedor/dispositivo.

**Protección de dispositivos:** Los dispositivos críticos (Host bridge, PCI bridge, ISA bridge, IOMMU, SMBus, Processor) no se pueden deshabilitar para prevenir inestabilidad del sistema.

**Persistencia:** Los dispositivos deshabilitados se guardan en `/etc/slu_disabled_devices.conf` y se crea un servicio systemd para reaplicar la deshabilitación en cada arranque. Esto asegura que tu configuración sobreviva a los reinicios.

> **Advertencia para principiantes:** No deshabilites dispositivos que no reconozcas. Deshabilitar un adaptador de red te desconectará de internet. Deshabilitar un adaptador de pantalla puede bloquear tu escritorio.

> **Consejo para expertos:** El mecanismo de persistencia usa sysfs (`echo 0 > enable` para PCI, `echo 0 > authorized` para USB, `ip link set X down` para red) con un servicio systemd.

**Requiere contraseña:** Sí (para operaciones de habilitar/deshabilitar)

---

### 5.9 Recuperación

**Propósito:** Restaurar funciones del sistema alteradas, buscar actualizaciones e instalar software.

#### Operaciones de Recuperación
| Operación | Descripción |
|-----------|------------|
| **Reiniciar Pipewire** | Reinicia PipeWire, PipeWire-Pulse y Wireplumber para solucionar problemas de audio. |
| **Restaurar Red** | Reinicia NetworkManager o systemd-networkd para solucionar problemas de conexión. |
| **Reconstruir GRUB** | Ejecuta `update-grub` para regenerar la configuración del cargador de arranque. |
| **Restaurar Flathub** | Vuelve a agregar el remote de Flathub para Flatpak. |
| **Restaurar Repositorios** | Actualiza y restaura los repositorios de paquetes para tu distribución. |
| **Corregir Auto-suspensión WiFi** | Deshabilita la auto-suspensión USB para adaptadores WiFi para evitar desconexiones aleatorias. |

Cada operación muestra un botón "Ver Salida" para inspeccionar la salida del comando.

#### Pestaña de Verificar Actualizaciones
- **Buscar Actualizaciones:** Ejecuta el comando de actualización del gestor de paquetes correspondiente (`apt update`, `dnf check-update`, `pacman -Sy`).
- Los resultados muestran las actualizaciones disponibles por gestor de paquetes (APT, DNF, Pacman, Snap, Flatpak).
- **Aplicar Actualizaciones:** Descarga e instala todas las actualizaciones disponibles con progreso en tiempo real.

#### Pestaña de Instalador de Software
Instaladores con un clic para software esencial:
- **FFmpeg:** Framework multimedia para codificar/decodificar audio y video.
- **yt-dlp:** Descargador de videos compatible con muchos sitios web.
- **Bibliotecas del Sistema:** Bibliotecas esenciales del sistema que pueden faltar.
- **Códecs:** Códecs de video y audio para formatos comunes.
- **rsync:** Herramienta eficiente de sincronización y transferencia de archivos.

**Requiere contraseña:** Sí

---

### 5.10 Ajustes

**Propósito:** Ajuste del rendimiento del sistema para swap y DaVinci Resolve.

#### Pestaña de Swap
- Muestra la información actual del swap: tamaño de RAM, swap total/usado, valor de swappiness, dispositivo de swap.
- Proporciona recomendaciones basadas en tu configuración:
  - Crear un archivo de swap si no existe ninguno.
  - Ajustar el valor de swappiness.
  - Habilitar o deshabilitar zram.
- Cada recomendación tiene un botón "Ejecutar" que aplica el cambio sugerido.

#### Pestaña de DaVinci Resolve
- Aplica correcciones comunes de Linux para Blackmagic DaVinci Resolve:
  - Corregir rutas de bibliotecas CUDA.
  - Establecer permisos correctos de GPU.
  - Instalar dependencias faltantes.
- Cada corrección muestra si requiere reinicio y si ya ha sido aplicada.

> **Consejo para principiantes:** Si usas DaVinci Resolve en Linux y experimentas problemas con la GPU, ve a esta pestaña y aplica todas las correcciones.

> **Consejo para expertos:** Las recomendaciones de swap analizan tu `/proc/meminfo` y configuración de swap para proporcionar las sugerencias más adecuadas.

**Requiere contraseña:** Sí

---

### 5.11 Configuración

Configura las preferencias de toda la aplicación:

#### Contraseña
- Guarda, actualiza o elimina tu contraseña de administrador.
- La contraseña se almacena usando el llavero del sistema (codificada en base64 en SharedPreferences).

#### Idioma
- Selecciona de 6 idiomas: Italiano, Inglés, Francés, Español, Alemán, Portugués.
- Los cambios surten efecto después de reiniciar la aplicación.

#### Tema
- **Claro / Oscuro / Sistema:** Elige el esquema de colores de la aplicación.
- "Sistema" sigue la configuración de tema de tu entorno de escritorio.

#### Fuente
- **Familia de Fuente:** Selecciona de las fuentes del sistema disponibles.
- **Tamaño de Fuente:** Deslizador de 10sp a 24sp.

#### Bandeja del Sistema (solo Linux)
- **Habilitar Bandeja del Sistema:** Muestra/oculta el ícono de la aplicación en la bandeja del sistema.
- **Cerrar a la Bandeja:** Mantiene la aplicación ejecutándose en la bandeja cuando cierras la ventana.
- **Iniciar Minimizado:** Lanza la aplicación minimizada en la bandeja.
- **Iniciar al Iniciar Sesión:** Inicia automáticamente la aplicación cuando inicias sesión (usa el inicio automático XDG).
- **Instalar Dependencias:** Instala `libayatana-appindicator` si falta.

#### Verificación Automática de Actualizaciones
- Configura con qué frecuencia la aplicación busca actualizaciones del sistema (Nunca, 15 min, 30 min, 1 hr, 6 hr, 12 hr, diario).
- **Actualización automática desde GitHub:** Descarga e instala automáticamente el último `.deb` desde las versiones de GitHub.

#### Limpieza de RAM
- Establece un intervalo automático para limpiar la caché de páginas de Linux y la RAM: **Nunca**, **5 minutos**, **10 minutos**, **15 minutos**, **30 minutos**.
- Se ejecuta en segundo plano al intervalo configurado.

#### Programador de Apagado
- Abre la pantalla del temporizador de apagado automático (ver Sección 7).

---

### 5.12 Información

**Propósito:** Pantalla "Acerca de" con información de la aplicación.

- Versión de la aplicación, creador y descripción.
- Lista de funciones organizada por categoría.
- Licencia y descargo de responsabilidad (GPL).
- **Botón de Activación de Licencia** (solo versión Avanzada): Ingresa tu clave de licencia para desbloquear funciones avanzadas.
- **Botón de PayPal** (solo versión Avanzada): Compra una licencia por 19.99 EUR.
- Enlace al sitio web del proyecto.

---

## 6. Modo Avanzado — Funciones Adicionales

El modo avanzado desbloquea 2 pestañas adicionales y extiende la pantalla existente de Ajustes. Requiere una clave de licencia comprada (o versión Personal/De prueba).

Para cambiar entre el modo Estándar y Avanzado, usa los botones de modo en el área superior derecha de la barra lateral.

---

### 6.1 Editor GRUB

**Propósito:** Editar la configuración del cargador de arranque GRUB de forma segura.

**Características:**
- **Editor de texto:** Edita directamente `/etc/default/grub` en un editor de texto integrado.
- **Guardar y Actualizar:** Guarda la configuración, crea una copia de seguridad automática y ejecuta `update-grub` (o el equivalente para tu distribución).
- **Sugerencias de Hardware:** Analiza tu hardware y sugiere parámetros del kernel:
  - NVIDIA modeset, iommu, threadirqs, zswap, elevator, etc.
  - Cada sugerencia tiene una insignia de prioridad (alta/media/baja).
  - Toca "Aplicar" para insertar la sugerencia en el editor.
- **Restaurar Copia de Seguridad:** Revierte a la última copia de seguridad si algo sale mal.
- **Indicador de cambios sin guardar:** Aparece un banner naranja cuando tienes modificaciones sin guardar.

**Comandos de reconstrucción de GRUB por distribución:**
- Debian/Ubuntu: `update-grub`
- Fedora: `grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
- Arch: `grub-mkconfig -o /boot/grub/grub.cfg`

> **Advertencia:** Las modificaciones incorrectas de GRUB pueden evitar que tu sistema se inicie. Siempre mantén una copia de seguridad. Si tu sistema no logra arrancar, usa un USB booteable para restaurar `/etc/default/grub` desde la copia de seguridad.

**Requiere contraseña:** Sí

---

### 6.2 Benchmark

**Propósito:** Medir el rendimiento del hardware de tu sistema.

Cuatro categorías de benchmark:

| Benchmark | Qué mida |
|-----------|---------|
| **CPU** | Poder de procesamiento multinúcleo y de un solo núcleo. Los resultados se comparan con chips de referencia de Intel, AMD y Apple. |
| **GPU** | Rendimiento gráfico usando `glmark2`. Los resultados se comparan con GPUs de referencia de NVIDIA y AMD. |
| **Disco** | Velocidad de lectura/escritura secuencial. Los resultados se comparan con referencias de NVMe, SSD y HDD. |
| **Red** | Prueba de velocidad de internet. Los resultados se comparan con velocidades de red de referencia. |

Cada benchmark muestra:
- Tu puntuación.
- El hardware de referencia más cercano.
- Una calificación (Excelente, Bueno, Promedio, Por debajo del Promedio, Pobre).

> **Consejo:** Ejecuta benchmarks después de cambios en el sistema (nuevo kernel, nuevos controladores) para ver si el rendimiento mejoró.

**Requiere contraseña:** No

---

## 7. Bandeja del Sistema

Cuando está habilitada en Configuración, Super Linux Utility coloca un ícono en la bandeja del sistema (área de notificaciones). Haz clic derecho en el ícono para acceder a:

| Elemento del Menú | Acción |
|-------------------|--------|
| **Mostrar ventana principal** | Trae la ventana de la aplicación al frente. |
| **Verificar actualizaciones** | Abre el diálogo de verificación de actualizaciones. |
| **Limpiar archivos temporales y caché** | Navega a la pestaña de Limpieza. |
| **Temperatura de CPU, GPU** | Navega a la pestaña de Monitor. |
| **Uso del disco** | Navega a la pestaña de Analizador de Discos. |
| **Uso de memoria** | Muestra el uso actual de RAM. |
| **Salud del disco (SMART)** | Navega a la pestaña de SMART. |
| **Apagado automático** | Abre el diálogo del temporizador de apagado. |
| **Uso de CPU, GPU** | Abre un diálogo del gestor de tareas. |
| **Salir** | Cierra la aplicación.**

El ícono de la bandeja muestra en tooltip la temperatura en tiempo real de CPU/GPU y el uso de memoria.

---

## 8. Actualizaciones Automáticas

### Verificación de Actualizaciones del Sistema
Configurable en Configuración > Verificación Automática de Actualizaciones. Cuando está habilitada, la aplicación busca periódicamente actualizaciones en todos los gestores de paquetes instalados (APT, DNF, Pacman, Snap, Flatpak). Las notificaciones de actualización aparecen como diálogos con casillas de verificación por paquete.

### Auto-actualización de la Aplicación
Cuando está habilitada en Configuración > Actualización automática desde GitHub, la aplicación busca en las versiones de GitHub paquetes `.deb` más recientes que coincidan con tu edición (Estándar/Avanzada). Descarga e instala automáticamente usando `sudo dpkg -i`.

---

## 9. Solución de Problemas

### Error "Contraseña no guardada"
Ve a Configuración > Contraseña y vuelve a ingresar tu contraseña de sudo. La contraseña se almacena en el llavero del sistema.

### La pestaña SMART no muestra discos
Instala `smartmontools`: la aplicación ofrecerá hacerlo automáticamente. Si usas un adaptador USB-SATA, los datos SMART pueden ser limitados.

### Los cambios de GRUB no se aplican (modo Avanzado)
Asegúrate de haber tocado "Guardar y Actualizar" (no solo "Guardar"). La aplicación debe ejecutar `update-grub` con privilegios de administrador.

### El ícono de la bandeja del sistema no es visible
Instala la dependencia requerida: `sudo apt install libayatana-appindicator-3-dev`. Luego reinicia la aplicación.

### La AppImage no se inicia
La AppImage usa un runtime estático y debería funcionar sin FUSE. Si aún falla:
```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./super-linux-utility-*.AppImage
```

### El Gestor de Dispositivos no puede deshabilitar un dispositivo
Algunos dispositivos están protegidos porque deshabilitarlos bloquearía el sistema. La aplicación muestra un mensaje cuando un dispositivo no se puede deshabilitar.

---

## 10. Preguntas Frecuentes

**¿P: Es seguro usar esta aplicación?**
R: Las funciones del modo estándar son seguras para todos los usuarios. El modo avanzado modifica GRUB — siempre crea una copia de seguridad antes de usar funciones de GRUB.

**¿P: ¿La aplicación envía datos a algún lugar?**
R: No. La aplicación no recopila ni transmite ningún dato de usuario. Las únicas operaciones de red son la verificación de actualizaciones (desde GitHub o tu gestor de paquetes).

**¿P: Puedo usar la aplicación en Fedora/Arch?**
R: Sí. La aplicación detecta automáticamente tu distribución y adapta todos los comandos en consecuencia (APT, DNF, Pacman).

**¿P: ¿Qué sucede si deshabilito un servicio crítico?**
R: La aplicación protege los servicios esenciales del entorno de escritorio (GNOME, KDE, etc.) de ser deshabilitados. Sin embargo, siempre ten cuidado con servicios desconocidos.

**¿P: ¿Cómo restauro GRUB si el sistema no arranca?**
R: Arranca desde un USB booteable, monta tu partición raíz y copia `/etc/default/grub.backup` de vuelta a `/etc/default/grub`. Luego ejecuta `sudo update-grub`.

**¿P: Puedo deshabilitar cualquier dispositivo de hardware?**
R: El Gestor de Dispositivos protege los dispositivos críticos del sistema (CPU, bridges, IOMMU) de ser deshabilitados. Puedes deshabilitar con seguridad periféricos no esenciales como dispositivos USB o adaptadores de red secundarios.

---

## 11. Glosario

| Término | Definición |
|---------|-----------|
| **APT** | Advanced Package Tool — gestor de paquetes de Debian/Ubuntu. |
| **Gestor de Dispositivos** | Herramienta para ver, habilitar y deshabilitar dispositivos de hardware. |
| **DNF** | Dandified YUM — gestor de paquetes de Fedora/RHEL. |
| **Flatpak** | Formato de empaquetado de aplicaciones en sandbox para Linux. |
| **GRUB** | Grand Unified Bootloader — el programa que carga Linux al iniciar. |
| **Kernel** | El núcleo del sistema operativo Linux. |
| **PCI** | Peripheral Component Interconnect — bus estándar para dispositivos internos. |
| **Pacman** | Gestor de paquetes para Arch Linux y derivadas. |
| **PipeWire** | Servidor de audio/video moderno para Linux. |
| **SMART** | Self-Monitoring, Analysis and Reporting Technology — sistema de salud de discos duros. |
| **Snap** | Formato de paquetes universales de Linux de Canonical. |
| **systemd** | Sistema de init y gestor de servicios para Linux. |
| **systemctl** | Herramienta de línea de comandos para gestionar servicios systemd. |
| **Swap** | Espacio en disco usado como RAM virtual cuando la RAM física está llena. |
| **sysfs** | Sistema de archivos virtual que expone datos de dispositivos del kernel (`/sys/`). |
| **USB** | Universal Serial Bus — estándar para dispositivos externos. |
| **Wayland** | Protocolo moderno de servidor de pantalla que reemplaza a X11. |
| **X11** | Protocolo tradicional de servidor de pantalla para Linux. |
| **zram** | Dispositivo de swap comprimido basado en RAM. |

---

*Super Linux Utility v2.0.6 — Manual del Usuario*
*Creado por Marco Di Giangiacomo*
*Licencia: GPL v3*
