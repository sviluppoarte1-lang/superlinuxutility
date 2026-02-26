import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'dart:io';
import '../services/appearance_service.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _error;

  // Font
  String _interfaceFont = '';
  double _interfaceFontSize = 10.0;
  String _documentFont = '';
  double _documentFontSize = 10.0;
  String _monospaceFont = '';
  double _monospaceFontSize = 10.0;
  List<String> _availableFonts = [];

  // Rendering
  String _hinting = 'slight';
  String _antialiasing = 'rgba';
  double _scaleFactor = 1.0;

  // Stili (temi rimossi)

  // Sfondo
  String _backgroundImage = '';
  String _darkBackgroundImage = '';
  String _backgroundAdjustment = 'zoom';

  // Comportamento finestre
  String _doubleClickAction = 'toggle-maximize';
  String _middleClickAction = 'lower';
  String _rightClickAction = 'menu';
  bool _maximizeButtonVisible = true;
  bool _minimizeButtonVisible = true;
  String _buttonPosition = 'right';
  List<String> _buttonOrder = ['close', 'minimize', 'maximize'];
  bool _attachedDialogs = false;
  bool _centerNewWindows = false;
  bool _resizeWithSecondaryClick = false;
  String _windowFocus = 'click';
  bool _raiseOnFocus = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // NON caricare automaticamente - carica solo quando la tab diventa visibile
    // Questo evita blocchi all'avvio
    setState(() {
      _isLoading = false;
      _hasLoadedOnce = false; // Non ancora caricato - verrà caricato quando la tab diventa visibile
      _availableFonts = ['Ubuntu', 'Sans', 'Serif', 'Monospace']; // Valori di default
    });
  }

  /// Metodo pubblico per forzare il refresh quando la tab diventa visibile
  void refresh() {
    if (!mounted || _isLoading) return;
    
    // Carica solo se non abbiamo ancora caricato
    if (!_hasLoadedOnce) {
      // Usa un delay per assicurarsi che l'UI sia completamente renderizzata
      // e per evitare blocchi immediati
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isLoading) {
          _loadSettings();
        }
      });
    }
  }

  Future<void> _loadSettings() async {
    if (_isLoading) return;
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false; // Non mostrare loading per non bloccare
      _hasLoadedOnce = true;
      // Imposta valori di default immediati
      _availableFonts = ['Ubuntu', 'Sans', 'Serif', 'Monospace'];
    });

    // Carica i dati in modo completamente asincrono senza bloccare
    // Usa un delay per assicurarsi che l'UI sia renderizzata
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadEssentialDataAsync();
        _loadHeavyDataAsync();
      }
    });
  }

  Future<void> _loadHeavyData() async {
    // Metodo deprecato - usa _loadHeavyDataAsync invece
    _loadHeavyDataAsync();
  }

  /// Carica i dati essenziali in modo completamente asincrono senza bloccare
  void _loadEssentialDataAsync() {
    // Carica ogni valore indipendentemente per evitare blocchi
    Future.microtask(() async {
      try {
        final futures = [
          () => AppearanceService.getInterfaceFont().timeout(const Duration(seconds: 2), onTimeout: () => ''),
          () => AppearanceService.getDocumentFont().timeout(const Duration(seconds: 2), onTimeout: () => ''),
          () => AppearanceService.getMonospaceFont().timeout(const Duration(seconds: 2), onTimeout: () => ''),
          () => AppearanceService.getHinting().timeout(const Duration(seconds: 2), onTimeout: () => 'slight'),
          () => AppearanceService.getAntialiasing().timeout(const Duration(seconds: 2), onTimeout: () => 'rgba'),
          () => AppearanceService.getScaleFactor().timeout(const Duration(seconds: 2), onTimeout: () => 1.0),
          () => AppearanceService.getInterfaceFontSize().timeout(const Duration(seconds: 2), onTimeout: () => 10.0),
          () => AppearanceService.getDocumentFontSize().timeout(const Duration(seconds: 2), onTimeout: () => 10.0),
          () => AppearanceService.getMonospaceFontSize().timeout(const Duration(seconds: 2), onTimeout: () => 10.0),
        ];

        // Carica ogni valore indipendentemente e aggiorna l'UI quando disponibile
        futures[0]().then((value) {
          if (mounted) setState(() => _interfaceFont = value as String);
        }).catchError((e) => print('Errore getInterfaceFont: $e'));
        
        futures[1]().then((value) {
          if (mounted) setState(() => _documentFont = value as String);
        }).catchError((e) => print('Errore getDocumentFont: $e'));
        
        futures[2]().then((value) {
          if (mounted) setState(() => _monospaceFont = value as String);
        }).catchError((e) => print('Errore getMonospaceFont: $e'));
        
        futures[3]().then((value) {
          if (mounted) setState(() => _hinting = value as String);
        }).catchError((e) => print('Errore getHinting: $e'));
        
        futures[4]().then((value) {
          if (mounted) setState(() => _antialiasing = value as String);
        }).catchError((e) => print('Errore getAntialiasing: $e'));
        
        futures[5]().then((value) {
          if (mounted) setState(() => _scaleFactor = value as double);
        }).catchError((e) => print('Errore getScaleFactor: $e'));
        
        futures[6]().then((value) {
          if (mounted) setState(() => _interfaceFontSize = value as double);
        }).catchError((e) => print('Errore getInterfaceFontSize: $e'));
        
        futures[7]().then((value) {
          if (mounted) setState(() => _documentFontSize = value as double);
        }).catchError((e) => print('Errore getDocumentFontSize: $e'));
        
        futures[8]().then((value) {
          if (mounted) setState(() => _monospaceFontSize = value as double);
        }).catchError((e) => print('Errore getMonospaceFontSize: $e'));
      } catch (e) {
        print('Errore nel caricamento dati essenziali: $e');
      }
    });
  }


  /// Carica i dati pesanti in modo completamente asincrono senza bloccare
  void _loadHeavyDataAsync() {
    Future.microtask(() async {
      // Carica ogni valore indipendentemente per evitare blocchi
      AppearanceService.getAvailableFonts()
          .timeout(const Duration(seconds: 8), onTimeout: () {
        return ['Ubuntu', 'Sans', 'Serif', 'Monospace'];
      }).then((fonts) {
        if (mounted) setState(() => _availableFonts = fonts);
      }).catchError((e) => print('Errore getAvailableFonts: $e'));

      AppearanceService.getBackgroundImage()
          .timeout(const Duration(seconds: 3), onTimeout: () => '')
          .then((bgUri) {
        if (mounted) setState(() => _backgroundImage = bgUri.replaceAll('file://', '').replaceAll('%20', ' '));
      }).catchError((e) => print('Errore getBackgroundImage: $e'));

      AppearanceService.getDarkBackgroundImage()
          .timeout(const Duration(seconds: 3), onTimeout: () => '')
          .then((darkBgUri) {
        if (mounted) setState(() => _darkBackgroundImage = darkBgUri.replaceAll('file://', '').replaceAll('%20', ' '));
      }).catchError((e) => print('Errore getDarkBackgroundImage: $e'));

      AppearanceService.getBackgroundAdjustment()
          .timeout(const Duration(seconds: 3), onTimeout: () => 'zoom')
          .then((adj) {
        if (mounted) setState(() => _backgroundAdjustment = adj);
      }).catchError((e) => print('Errore getBackgroundAdjustment: $e'));

      AppearanceService.getDoubleClickAction()
          .timeout(const Duration(seconds: 3), onTimeout: () => 'toggle-maximize')
          .then((action) {
        if (mounted) setState(() => _doubleClickAction = action);
      }).catchError((e) => print('Errore getDoubleClickAction: $e'));

      AppearanceService.getMiddleClickAction()
          .timeout(const Duration(seconds: 3), onTimeout: () => 'lower')
          .then((action) {
        if (mounted) setState(() => _middleClickAction = action);
      }).catchError((e) => print('Errore getMiddleClickAction: $e'));

      AppearanceService.getRightClickAction()
          .timeout(const Duration(seconds: 3), onTimeout: () => 'menu')
          .then((action) {
        if (mounted) setState(() => _rightClickAction = action);
      }).catchError((e) => print('Errore getRightClickAction: $e'));

      AppearanceService.getMaximizeButtonVisible()
          .timeout(const Duration(seconds: 3), onTimeout: () => true)
          .then((visible) {
        if (mounted) setState(() => _maximizeButtonVisible = visible);
      }).catchError((e) => print('Errore getMaximizeButtonVisible: $e'));

      AppearanceService.getMinimizeButtonVisible()
          .timeout(const Duration(seconds: 3), onTimeout: () => true)
          .then((visible) {
        if (mounted) setState(() => _minimizeButtonVisible = visible);
      }).catchError((e) => print('Errore getMinimizeButtonVisible: $e'));

      AppearanceService.getButtonPosition()
          .timeout(const Duration(seconds: 3), onTimeout: () => 'right')
          .then((pos) {
        if (mounted) setState(() => _buttonPosition = pos);
      }).catchError((e) => print('Errore getButtonPosition: $e'));

      AppearanceService.getButtonOrder()
          .timeout(const Duration(seconds: 3), onTimeout: () => ['close', 'minimize', 'maximize'])
          .then((order) {
        if (mounted) setState(() => _buttonOrder = order);
      }).catchError((e) => print('Errore getButtonOrder: $e'));

      AppearanceService.getAttachedDialogs()
          .timeout(const Duration(seconds: 3), onTimeout: () => false)
          .then((attached) {
        if (mounted) setState(() => _attachedDialogs = attached);
      }).catchError((e) => print('Errore getAttachedDialogs: $e'));

      AppearanceService.getCenterNewWindows()
          .timeout(const Duration(seconds: 3), onTimeout: () => false)
          .then((center) {
        if (mounted) setState(() => _centerNewWindows = center);
      }).catchError((e) => print('Errore getCenterNewWindows: $e'));

      AppearanceService.getResizeWithSecondaryClick()
          .timeout(const Duration(seconds: 3), onTimeout: () => false)
          .then((resize) {
        if (mounted) setState(() => _resizeWithSecondaryClick = resize);
      }).catchError((e) => print('Errore getResizeWithSecondaryClick: $e'));

      AppearanceService.getWindowFocus()
          .timeout(const Duration(seconds: 3), onTimeout: () => 'click')
          .then((focus) {
        if (mounted) setState(() => _windowFocus = focus);
      }).catchError((e) => print('Errore getWindowFocus: $e'));

      AppearanceService.getRaiseOnFocus()
          .timeout(const Duration(seconds: 3), onTimeout: () => false)
          .then((raise) {
        if (mounted) setState(() => _raiseOnFocus = raise);
      }).catchError((e) => print('Errore getRaiseOnFocus: $e'));
    });
  }



  Future<void> _pickImage({required bool isDark}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      final imagePath = result.files.single.path!;
      final success = isDark
          ? await AppearanceService.setDarkBackgroundImage(imagePath)
          : await AppearanceService.setBackgroundImage(imagePath);

      if (success) {
        setState(() {
          if (isDark) {
            _darkBackgroundImage = imagePath;
          } else {
            _backgroundImage = imagePath;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backgroundImageUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backgroundImageError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Richiesto per AutomaticKeepAliveClientMixin
    
    // Mostra loading solo al primo caricamento, non ai successivi
    if (_isLoading && !_hasLoadedOnce) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.loading,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.loadingSettings,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${AppLocalizations.of(context)!.error}: $_error',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSettings,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    return RepaintBoundary(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // FONT PREFERENCES
          _buildSection(
            title: AppLocalizations.of(context)!.preferredFonts,
            children: [
              _buildFontSelector(
                label: AppLocalizations.of(context)!.interfaceText,
                fontName: _interfaceFont,
                fontSize: _interfaceFontSize,
                onFontChanged: (String? newValue) async {
                  if (newValue != null && mounted) {
                    try {
                      final success = await AppearanceService.setInterfaceFont(newValue, fontSize: _interfaceFontSize)
                          .timeout(const Duration(seconds: 5), onTimeout: () => false);
                      if (success && mounted) {
                      setState(() => _interfaceFont = newValue);
                      }
                    } catch (e) {
                      print('Errore nel cambio font: $e');
                    }
                  }
                },
                onSizeChanged: (double? newSize) async {
                  if (newSize != null && mounted) {
                    try {
                      final success = await AppearanceService.setInterfaceFont(_interfaceFont, fontSize: newSize)
                          .timeout(const Duration(seconds: 5), onTimeout: () => false);
                      if (success && mounted) {
                      setState(() => _interfaceFontSize = newSize);
                      }
                    } catch (e) {
                      print('Errore nel cambio dimensione font: $e');
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildFontSelector(
                label: AppLocalizations.of(context)!.documentText,
                fontName: _documentFont,
                fontSize: _documentFontSize,
                onFontChanged: (String? newValue) async {
                  if (newValue != null && mounted) {
                    try {
                      final success = await AppearanceService.setDocumentFont(newValue, fontSize: _documentFontSize)
                          .timeout(const Duration(seconds: 5), onTimeout: () => false);
                      if (success && mounted) {
                      setState(() => _documentFont = newValue);
                      }
                    } catch (e) {
                      print('Errore nel cambio font documento: $e');
                    }
                  }
                },
                onSizeChanged: (double? newSize) async {
                  if (newSize != null && mounted) {
                    try {
                      final success = await AppearanceService.setDocumentFont(_documentFont, fontSize: newSize)
                          .timeout(const Duration(seconds: 5), onTimeout: () => false);
                      if (success && mounted) {
                      setState(() => _documentFontSize = newSize);
                      }
                    } catch (e) {
                      print('Errore nel cambio dimensione font documento: $e');
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildFontSelector(
                label: AppLocalizations.of(context)!.fixedWidthText,
                fontName: _monospaceFont,
                fontSize: _monospaceFontSize,
                onFontChanged: (String? newValue) async {
                  if (newValue != null && mounted) {
                    try {
                      final success = await AppearanceService.setMonospaceFont(newValue, fontSize: _monospaceFontSize)
                          .timeout(const Duration(seconds: 5), onTimeout: () => false);
                      if (success && mounted) {
                      setState(() => _monospaceFont = newValue);
                      }
                    } catch (e) {
                      print('Errore nel cambio font monospace: $e');
                    }
                  }
                },
                onSizeChanged: (double? newSize) async {
                  if (newSize != null && mounted) {
                    try {
                      final success = await AppearanceService.setMonospaceFont(_monospaceFont, fontSize: newSize)
                          .timeout(const Duration(seconds: 5), onTimeout: () => false);
                      if (success && mounted) {
                      setState(() => _monospaceFontSize = newSize);
                      }
                    } catch (e) {
                      print('Errore nel cambio dimensione font monospace: $e');
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // RENDERING
          _buildSection(
            title: AppLocalizations.of(context)!.rendering,
            children: [
              _buildSubSection(
                title: AppLocalizations.of(context)!.hinting,
                children: [
                  _buildRadioGroup<String>(
                    value: _hinting,
                    options: [
                      ('full', AppLocalizations.of(context)!.full),
                      ('medium', AppLocalizations.of(context)!.medium),
                      ('slight', AppLocalizations.of(context)!.light),
                      ('none', AppLocalizations.of(context)!.no),
                    ],
                    onChanged: (String? value) async {
                      if (value != null) {
                        final success = await AppearanceService.setHinting(value);
                        if (success) {
                          setState(() => _hinting = value);
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSubSection(
                title: AppLocalizations.of(context)!.antialiasing,
                children: [
                  _buildRadioGroup<String>(
                    value: _antialiasing,
                    options: [
                      ('rgba', AppLocalizations.of(context)!.subpixelLCD),
                      ('grayscale', AppLocalizations.of(context)!.standardGrayscale),
                      ('none', AppLocalizations.of(context)!.no),
                    ],
                    onChanged: (String? value) async {
                      if (value != null) {
                        final success = await AppearanceService.setAntialiasing(value);
                        if (success) {
                          setState(() => _antialiasing = value);
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSubSection(
                title: AppLocalizations.of(context)!.dimensions,
                children: [
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.scaleFactor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: _scaleFactor.toStringAsFixed(2)),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            final factor = double.tryParse(value);
                            if (factor != null && factor >= 0.5 && factor <= 3.0) {
                              setState(() => _scaleFactor = factor);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () async {
                          final newFactor = (_scaleFactor - 0.1).clamp(0.5, 3.0);
                          final success = await AppearanceService.setScaleFactor(newFactor);
                          if (success) {
                            setState(() => _scaleFactor = newFactor);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final newFactor = (_scaleFactor + 0.1).clamp(0.5, 3.0);
                          final success = await AppearanceService.setScaleFactor(newFactor);
                          if (success) {
                            setState(() => _scaleFactor = newFactor);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // SFONDO
          const SizedBox(height: 24),

          _buildSection(
            title: AppLocalizations.of(context)!.background,
            children: [
              _buildImageSelector(
                label: AppLocalizations.of(context)!.defaultImage,
                value: _backgroundImage,
                onPick: () => _pickImage(isDark: false),
              ),
              const SizedBox(height: 16),
              _buildImageSelector(
                label: AppLocalizations.of(context)!.darkImage,
                value: _darkBackgroundImage,
                onPick: () => _pickImage(isDark: true),
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                label: AppLocalizations.of(context)!.adjustment,
                value: _backgroundAdjustment,
                items: [
                  ('none', AppLocalizations.of(context)!.noneOption),
                  ('wallpaper', AppLocalizations.of(context)!.wallpaper),
                  ('centered', AppLocalizations.of(context)!.centered),
                  ('scaled', AppLocalizations.of(context)!.scaled),
                  ('stretched', AppLocalizations.of(context)!.stretched),
                  ('zoom', AppLocalizations.of(context)!.zoom),
                  ('spanned', AppLocalizations.of(context)!.spanned),
                ],
                onChanged: (String? value) async {
                  if (value != null) {
                    final success = await AppearanceService.setBackgroundAdjustment(value);
                    if (success) {
                      setState(() => _backgroundAdjustment = value);
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // COMPORTAMENTO FINESTRE
          _buildSection(
            title: AppLocalizations.of(context)!.windowBehavior,
            children: [
              _buildDropdown<String>(
                label: AppLocalizations.of(context)!.doubleClick,
                value: _doubleClickAction,
                items: [
                  ('toggle-maximize', AppLocalizations.of(context)!.toggleMaximize),
                  ('toggle-maximize-horizontally', AppLocalizations.of(context)!.toggleMaximizeHorizontal),
                  ('toggle-maximize-vertically', AppLocalizations.of(context)!.toggleMaximizeVertical),
                  ('toggle-shade', AppLocalizations.of(context)!.toggleShade),
                  ('toggle-menu', AppLocalizations.of(context)!.toggleMenu),
                  ('minimize', AppLocalizations.of(context)!.minimize),
                  ('none', AppLocalizations.of(context)!.noneOption),
                  ('lower', AppLocalizations.of(context)!.lower),
                ],
                onChanged: (String? value) async {
                  if (value != null) {
                    final success = await AppearanceService.setDoubleClickAction(value);
                    if (success) {
                      setState(() => _doubleClickAction = value);
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                label: AppLocalizations.of(context)!.middleClick,
                value: _middleClickAction,
                items: [
                  ('toggle-maximize', AppLocalizations.of(context)!.toggleMaximize),
                  ('toggle-shade', AppLocalizations.of(context)!.toggleShade),
                  ('minimize', AppLocalizations.of(context)!.minimize),
                  ('lower', AppLocalizations.of(context)!.lower),
                  ('menu', AppLocalizations.of(context)!.menu),
                  ('none', AppLocalizations.of(context)!.noneOption),
                ],
                onChanged: (String? value) async {
                  if (value != null) {
                    final success = await AppearanceService.setMiddleClickAction(value);
                    if (success) {
                      setState(() => _middleClickAction = value);
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                label: AppLocalizations.of(context)!.rightClick,
                value: _rightClickAction,
                items: [
                  ('menu', AppLocalizations.of(context)!.menu),
                  ('toggle-maximize', AppLocalizations.of(context)!.toggleMaximize),
                  ('toggle-shade', AppLocalizations.of(context)!.toggleShade),
                  ('minimize', AppLocalizations.of(context)!.minimize),
                  ('lower', AppLocalizations.of(context)!.lower),
                  ('none', AppLocalizations.of(context)!.noneOption),
                ],
                onChanged: (String? value) async {
                  if (value != null) {
                    final success = await AppearanceService.setRightClickAction(value);
                    if (success) {
                      setState(() => _rightClickAction = value);
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSubSection(
                title: AppLocalizations.of(context)!.titlebarButtons,
                children: [
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.maximize),
                    value: _maximizeButtonVisible,
                    onChanged: (bool value) async {
                      final success = await AppearanceService.setMaximizeButtonVisible(value);
                      if (success) {
                        setState(() => _maximizeButtonVisible = value);
                        // Ricarica l'ordine dopo la modifica
                        _buttonOrder = await AppearanceService.getButtonOrder();
                      }
                    },
                  ),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.minimize),
                    value: _minimizeButtonVisible,
                    onChanged: (bool value) async {
                      final success = await AppearanceService.setMinimizeButtonVisible(value);
                      if (success) {
                        setState(() => _minimizeButtonVisible = value);
                        // Ricarica l'ordine dopo la modifica
                        _buttonOrder = await AppearanceService.getButtonOrder();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.positioning),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(value: 'left', label: Text(AppLocalizations.of(context)!.left)),
                            ButtonSegment(value: 'right', label: Text(AppLocalizations.of(context)!.right)),
                          ],
                          selected: {_buttonPosition},
                          onSelectionChanged: (Set<String> newSelection) async {
                            final value = newSelection.first;
                            final success = await AppearanceService.setButtonLayout(
                              buttons: _buttonOrder,
                              position: value,
                            );
                            if (success) {
                              setState(() => _buttonPosition = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.buttonOrder),
                  const SizedBox(height: 8),
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final newOrder = List<String>.from(_buttonOrder);
                      final item = newOrder.removeAt(oldIndex);
                      newOrder.insert(newIndex, item);
                      
                      final success = await AppearanceService.setButtonLayout(
                        buttons: newOrder,
                        position: _buttonPosition,
                      );
                      if (success) {
                        setState(() => _buttonOrder = newOrder);
                      }
                    },
                    children: _buttonOrder.map((button) {
                      String label;
                      IconData icon;
                      switch (button) {
                        case 'close':
                          label = AppLocalizations.of(context)!.close;
                          icon = Icons.close;
                          break;
                        case 'minimize':
                          label = AppLocalizations.of(context)!.minimize;
                          icon = Icons.minimize;
                          break;
                        case 'maximize':
                          label = AppLocalizations.of(context)!.maximize;
                          icon = Icons.crop_free;
                          break;
                        default:
                          label = button;
                          icon = Icons.circle;
                      }
                      return ListTile(
                        key: ValueKey(button),
                        leading: Icon(icon),
                        title: Text(label),
                        trailing: const Icon(Icons.drag_handle),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSubSection(
                title: AppLocalizations.of(context)!.clickActions,
                children: [
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.attachedDialogs),
                    subtitle: const Text(
                      'Quando attivata, le finestre di dialogo allegate sono attaccate alle loro finestre parenti e non possono essere mosse.',
                    ),
                    value: _attachedDialogs,
                    onChanged: (bool value) async {
                      final success = await AppearanceService.setAttachedDialogs(value);
                      if (success) {
                        setState(() => _attachedDialogs = value);
                      }
                    },
                  ),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.centerNewWindows),
                    value: _centerNewWindows,
                    onChanged: (bool value) async {
                      final success = await AppearanceService.setCenterNewWindows(value);
                      if (success) {
                        setState(() => _centerNewWindows = value);
                      }
                    },
                  ),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.resizeWithSecondaryClick),
                    value: _resizeWithSecondaryClick,
                    onChanged: (bool value) async {
                      final success = await AppearanceService.setResizeWithSecondaryClick(value);
                      if (success) {
                        setState(() => _resizeWithSecondaryClick = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSubSection(
                title: AppLocalizations.of(context)!.windowFocus,
                children: [
                  _buildRadioGroup<String>(
                    value: _windowFocus,
                    options: [
                      ('click', AppLocalizations.of(context)!.clickForFocus),
                      ('sloppy', AppLocalizations.of(context)!.focusOnHover),
                      ('mouse', AppLocalizations.of(context)!.focusFollowsMouse),
                    ],
                    onChanged: (String? value) async {
                      if (value != null) {
                        final success = await AppearanceService.setWindowFocus(value);
                        if (success) {
                          setState(() => _windowFocus = value);
                        }
                      }
                    },
                    descriptions: {
                      'click': AppLocalizations.of(context)!.clickForFocusDesc,
                      'sloppy': AppLocalizations.of(context)!.focusOnHoverDesc,
                      'mouse': AppLocalizations.of(context)!.focusFollowsMouseDesc,
                    },
                  ),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.raiseOnFocus),
                    value: _raiseOnFocus,
                    onChanged: (bool value) async {
                      final success = await AppearanceService.setRaiseOnFocus(value);
                      if (success) {
                        setState(() => _raiseOnFocus = value);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return RepaintBoundary(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildFontSelector({
    required String label,
    required String fontName,
    required double fontSize,
    required ValueChanged<String?> onFontChanged,
    required ValueChanged<double?> onSizeChanged,
  }) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(label),
              ),
              Expanded(
                flex: 2,
                child: DropdownButton<String>(
                  value: fontName.isNotEmpty ? fontName : null,
                  isExpanded: true,
                  items: _availableFonts.map((font) {
                    return DropdownMenuItem(
                      value: font,
                      child: Text(
                        font,
                        style: TextStyle(fontFamily: font),
                      ),
                    );
                  }).toList(),
                  onChanged: onFontChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: TextEditingController(text: fontSize.toStringAsFixed(0)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.size,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    final size = double.tryParse(value);
                    if (size != null && size >= 6 && size <= 72) {
                      onSizeChanged(size);
                    }
                  },
                ),
              ),
            ],
          ),
          if (fontName.isNotEmpty) ...[
            const SizedBox(height: 8),
            RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.preview,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The quick brown fox jumps over the lazy dog\n0123456789 !@#\$%^&*()',
                      style: TextStyle(
                        fontFamily: fontName,
                        fontSize: fontSize,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildImageSelector({
    required String label,
    required String value,
    required VoidCallback onPick,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isNotEmpty ? value.split('/').last : AppLocalizations.of(context)!.noImageSelected,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder),
                onPressed: onPick,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<(T, String)> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label),
        ),
        Expanded(
          flex: 3,
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item.$1,
                child: Text(item.$2),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioGroup<T>({
    required T value,
    required List<(T, String)> options,
    required ValueChanged<T?> onChanged,
    Map<T, String>? descriptions,
  }) {
    return Column(
      children: options.map((option) {
        return RadioListTile<T>(
          title: Text(option.$2),
          subtitle: descriptions != null && descriptions.containsKey(option.$1)
              ? Text(descriptions[option.$1]!)
              : null,
          value: option.$1,
          groupValue: value,
          onChanged: onChanged,
        );
      }).toList(),
    );
  }
}


