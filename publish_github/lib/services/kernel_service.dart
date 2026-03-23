import 'dart:io';
import 'dart:convert';
import '../models/kernel_info.dart';
import 'password_storage.dart';
import 'system_detector.dart';

class KernelService {
  static Future<ProcessResult> _runSudoCommand(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password non salvata. Salva la password nelle impostazioni.');
    }
    
    final escapedPassword = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`');
    
    final fullCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S $command';
    
    return await Process.run(
      'bash',
      ['-c', fullCommand],
      runInShell: true,
    );
  }

  static Future<String> getCurrentKernel() async {
    try {
      final result = await Process.run('uname', ['-r']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Valore grezzo di `saved_entry` da grubenv (titolo voce GRUB, id o indice).
  static Future<String?> getDefaultKernel() async {
    try {
      const envPaths = ['/boot/grub/grubenv', '/boot/grub2/grubenv'];
      for (final envPath in envPaths) {
        final file = File(envPath);
        if (!await file.exists()) continue;

        final result = await Process.run('grub-editenv', [envPath, 'list']);
        if (result.exitCode != 0) continue;

        for (final line in (result.stdout as String).split('\n')) {
          final t = line.trim();
          if (t.startsWith('saved_entry=')) {
            var v = t.substring('saved_entry='.length).trim();
            if (v.length >= 2 &&
                ((v.startsWith('"') && v.endsWith('"')) ||
                    (v.startsWith("'") && v.endsWith("'")))) {
              v = v.substring(1, v.length - 1);
            }
            if (v.isNotEmpty) return v;
          }
        }
      }

      // Fallback: pipe (alcuni sistemi)
      final pipeResult = await Process.run(
        'bash',
        ['-c', 'grub-editenv list 2>/dev/null | grep "^saved_entry=" | head -1 || true'],
      );
      if (pipeResult.exitCode == 0) {
        final line = pipeResult.stdout.toString().trim();
        if (line.startsWith('saved_entry=')) {
          var v = line.substring('saved_entry='.length).trim();
          if (v.length >= 2 &&
              ((v.startsWith('"') && v.endsWith('"')) ||
                  (v.startsWith("'") && v.endsWith("'")))) {
            v = v.substring(1, v.length - 1);
          }
          if (v.isNotEmpty) return v;
        }
      }

      // grubby (Fedora/RHEL): kernel path → versione
      try {
        final grubbyResult = await Process.run('grubby', ['--default-kernel']);
        if (grubbyResult.exitCode == 0) {
          final kernel = grubbyResult.stdout.toString().trim();
          if (kernel.isNotEmpty) {
            return kernel.split('/').last.replaceAll('vmlinuz-', '');
          }
        }
      } catch (e) {
        // grubby non disponibile
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Confronta la versione installata (es. da dpkg) con [savedEntry] (titolo menu o id GRUB).
  static bool kernelMatchesGrubSavedEntry(String installedVersion, String? savedEntry) {
    if (savedEntry == null || savedEntry.isEmpty) return false;
    final s = savedEntry.trim();
    if (s.isEmpty) return false;

    // Indice numerico: non confrontabile con la sola stringa versione
    if (RegExp(r'^\d+$').hasMatch(s)) return false;

    final iv = installedVersion.trim().toLowerCase();
    final sv = s.toLowerCase();
    if (iv.isEmpty) return false;
    if (sv == iv) return true;
    if (sv.contains(iv) || iv.contains(sv)) return true;

    try {
      if (RegExp(RegExp.escape(iv)).hasMatch(sv)) return true;
    } catch (_) {}

    // Titoli tipo "… Linux 6.18.19-rt-x64v3-xanmod1"
    final m = RegExp(
      r'(\d+\.\d+\.[\d.]+(?:-[\w.-]+)?)',
    ).firstMatch(s);
    if (m != null) {
      final extracted = m.group(1)!.toLowerCase();
      if (iv == extracted || iv.contains(extracted) || extracted.contains(iv)) {
        return true;
      }
    }

    return false;
  }

  /// Lista tutti i kernel installati
  static Future<List<KernelInfo>> getInstalledKernels() async {
    try {
      final kernels = <KernelInfo>[];
      
      // Ottieni il kernel attuale
      final currentKernel = await getCurrentKernel();
      final defaultKernel = await getDefaultKernel();

      // Lista i pacchetti kernel installati
      final result = await Process.run(
        'dpkg',
        ['-l'],
      );

      if (result.exitCode != 0) {
        return kernels;
      }

      final lines = (result.stdout as String).split('\n');
      
      for (final line in lines) {
        if (line.contains('linux-image-') && line.contains('ii')) {
          // Formato: ii  linux-image-5.15.0-91-generic  5.15.0-91.101  amd64  Signed kernel image and modules
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 3) {
            final packageName = parts[1];
            final version = packageName.replaceAll('linux-image-', '');
            
            final isActive = version == currentKernel;
            final isDefault = kernelMatchesGrubSavedEntry(version, defaultKernel);

            int? size;
            try {
              final sizeResult = await Process.run(
                'dpkg-query',
                ['-W', '-f=\${Installed-Size}', packageName],
              );
              if (sizeResult.exitCode == 0) {
                final sizeStr = sizeResult.stdout.toString().trim();
                size = int.tryParse(sizeStr);
                if (size != null) {
                  size = size * 1024;
                }
              }
            } catch (e) {
            }

            kernels.add(KernelInfo(
              version: version,
              packageName: packageName,
              isInstalled: true,
              isActive: isActive,
              isDefault: isDefault,
              description: parts.length > 4 ? parts.sublist(4).join(' ') : null,
              size: size,
            ));
          }
        }
      }

      kernels.sort((a, b) {
        final aVersion = _parseVersion(a.version);
        final bVersion = _parseVersion(b.version);
        return _compareVersions(bVersion, aVersion);
      });

      return kernels;
    } catch (e) {
      return [];
    }
  }

  /// Parsing semplificato della versione del kernel per il confronto
  static List<int> _parseVersion(String version) {
    // Esempio: "5.15.0-91-generic" -> [5, 15, 0, 91]
    final parts = version.split('-')[0].split('.');
    final versionNumbers = <int>[];
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num != null) {
        versionNumbers.add(num);
      }
    }
    return versionNumbers;
  }

  static int _compareVersions(List<int> a, List<int> b) {
    final maxLength = a.length > b.length ? a.length : b.length;
    for (int i = 0; i < maxLength; i++) {
      final aVal = i < a.length ? a[i] : 0;
      final bVal = i < b.length ? b[i] : 0;
      if (aVal != bVal) {
        return aVal.compareTo(bVal);
      }
    }
    return 0; // Versioni uguali
  }

  /// Rimuove un kernel
  static Future<bool> removeKernel(String packageName) async {
    try {
      // Non permettere la rimozione del kernel attivo
      final currentKernel = await getCurrentKernel();
      if (packageName.contains(currentKernel)) {
        throw Exception('Non è possibile rimuovere il kernel attualmente in uso');
      }

      final result = await _runSudoCommand(
        'apt-get remove --purge -y $packageName',
      );

      if (result.exitCode == 0) {
        // Aggiorna GRUB dopo la rimozione
        await updateGrub();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Errore durante la rimozione del kernel: $e');
    }
  }

  /// Rimuove più kernel (mantenendo solo quelli specificati)
  static Future<bool> removeKernels(List<String> packageNames) async {
    try {
      final currentKernel = await getCurrentKernel();
      
      // Filtra i kernel attivi
      final safeToRemove = packageNames.where((pkg) {
        return !pkg.contains(currentKernel);
      }).toList();

      if (safeToRemove.isEmpty) {
        throw Exception('Nessun kernel può essere rimosso (tutti sono in uso)');
      }

      final packages = safeToRemove.join(' ');
      final result = await _runSudoCommand(
        'apt-get remove --purge -y $packages',
      );

      if (result.exitCode == 0) {
        // Aggiorna GRUB dopo la rimozione
        await updateGrub();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Errore durante la rimozione dei kernel: $e');
    }
  }

  /// Trova l'indice della voce GRUB corrispondente alla versione del kernel
  /// Ritorna anche informazioni sul sottomenu se presente
  /// Questo metodo è migliorato per essere più robusto e accurato
  static Future<Map<String, dynamic>?> _findGrubMenuEntryInfo(String version) async {
    try {
      // Ottieni il percorso corretto del grub.cfg basato sulla distribuzione
      final systemInfo = await SystemDetector.detectSystem();
      final grubConfigPath = systemInfo.grubConfigPath;
      
      // Lista di percorsi possibili per grub.cfg
      final possiblePaths = [
        grubConfigPath,
        '/boot/grub/grub.cfg',
        '/boot/grub2/grub.cfg',
        '/boot/efi/EFI/fedora/grub.cfg',
        '/boot/efi/EFI/ubuntu/grub.cfg',
        '/boot/efi/EFI/debian/grub.cfg',
      ];

      // Prova con grubby per ottenere l'indice (metodo più affidabile su Fedora/RHEL)
      try {
        final grubbyResult = await Process.run(
          'bash',
          ['-c', 'grubby --info /boot/vmlinuz-$version 2>/dev/null | grep "^index=" || true'],
        );
        if (grubbyResult.exitCode == 0) {
          final output = grubbyResult.stdout.toString().trim();
          if (output.isNotEmpty && output.contains('index=')) {
            final indexStr = output.split('=')[1].trim();
            final index = int.tryParse(indexStr);
            if (index != null) {
              return {'index': index, 'name': null, 'submenu': null};
            }
          }
        }
      } catch (e) {
        // grubby non disponibile o errore, continua
      }

      // Cerca nel grub.cfg usando uno script migliorato che gestisce meglio i pattern
      final escapedVersion = version.replaceAll("'", "'\"'\"'");
      
      final bashScript = '''
        # Funzione per cercare nel file grub.cfg
        search_in_grub_cfg() {
          local cfg_file="\$1"
          local version="\$2"
          
          if [ ! -f "\$cfg_file" ]; then
            return 1
          fi
          
          # Usa awk per cercare il kernel con pattern più flessibili
          awk -v version="\$version" '
            BEGIN { 
              idx = -1
              submenu_idx = -1
              in_submenu = 0
              submenu_name = ""
              entry_name = ""
              found = 0
            }
            /^submenu / {
              submenu_idx++
              in_submenu = 1
              match(\$0, /'"'"'[^'"'"']*'"'"'/)
              if (RSTART > 0) {
                submenu_name = substr(\$0, RSTART + 1, RLENGTH - 2)
              }
              idx = -1
              next
            }
            /^menuentry / {
              idx++
              match(\$0, /'"'"'[^'"'"']*'"'"'/)
              if (RSTART > 0) {
                entry_name = substr(\$0, RSTART + 1, RLENGTH - 2)
              }
              in_entry = 1
              next
            }
            in_entry {
              # Cerca pattern più flessibili - usa index() per matching parziale
              # Rimuovi caratteri speciali dalla versione per matching più flessibile
              version_clean = version
              gsub(/[^0-9a-zA-Z.-]/, "", version_clean)
              
              # Cerca in vari formati
              if (index(\$0, version) > 0 || 
                  index(\$0, version_clean) > 0 ||
                  index(\$0, "vmlinuz-" version) > 0 ||
                  index(\$0, "vmlinuz-" version_clean) > 0 ||
                  index(\$0, "/vmlinuz-" version) > 0 ||
                  index(\$0, "/vmlinuz-" version_clean) > 0 ||
                  index(\$0, "linux-image-" version) > 0 ||
                  index(\$0, "linux-image-" version_clean) > 0 ||
                  \$0 ~ version ||
                  \$0 ~ version_clean) {
                found = 1
                if (in_submenu && submenu_name != "") {
                  print submenu_name ">" entry_name "|" idx
                } else {
                  print entry_name "|" idx
                }
                exit 0
              }
            }
            /^}/ {
              if (in_entry) {
                in_entry = 0
              } else if (in_submenu) {
                in_submenu = 0
                submenu_name = ""
              }
            }
          ' "\$cfg_file"
        }
        
        # Prova tutti i percorsi possibili
        for cfg in ${possiblePaths.map((p) => '"$p"').join(' ')}; do
          if [ -f "\$cfg" ]; then
            result=\$(search_in_grub_cfg "\$cfg" "$escapedVersion")
            if [ -n "\$result" ]; then
              echo "\$result"
              exit 0
            fi
          fi
        done
        
        exit 1
      ''';

      final result = await Process.run(
        'bash',
        ['-c', bashScript],
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isNotEmpty) {
          final parts = output.split('|');
          if (parts.length == 2) {
            final name = parts[0].trim();
            final index = int.tryParse(parts[1].trim());
            if (index != null) {
              if (name.contains('>')) {
                final submenuParts = name.split('>');
                return {
                  'index': index,
                  'name': submenuParts.length > 1 ? submenuParts[1] : name,
                  'submenu': submenuParts[0],
                  'fullName': name,
                };
              } else {
                return {'index': index, 'name': name, 'submenu': null, 'fullName': name};
              }
            }
          }
        }
      }

      // Metodo alternativo: cerca direttamente usando grep e conta le menuentry
      for (final cfgPath in possiblePaths) {
        try {
          final file = File(cfgPath);
          if (await file.exists()) {
            // Cerca la riga con il kernel
            final grepResult = await Process.run(
              'bash',
              ['-c', 'grep -n "vmlinuz-$version" "$cfgPath" 2>/dev/null | head -1 || true'],
            );
            
            if (grepResult.exitCode == 0 && grepResult.stdout.toString().trim().isNotEmpty) {
              final output = grepResult.stdout.toString().trim();
              final parts = output.split(':');
              if (parts.length >= 2) {
                final lineNum = int.tryParse(parts[0]);
                if (lineNum != null) {
                  // Conta le menuentry prima di questa riga
                  final countResult = await Process.run(
                    'bash',
                    ['-c', 'head -n $lineNum "$cfgPath" 2>/dev/null | grep -c "^menuentry " || echo "0"'],
                  );
                  final countStr = countResult.stdout.toString().trim();
                  final count = int.tryParse(countStr);
                  if (count != null && count > 0) {
                    final index = count - 1; // Gli indici partono da 0
                    // Prova a ottenere il nome della menuentry
                    final nameResult = await Process.run(
                      'bash',
                      ['-c', 'sed -n "${count}p" "$cfgPath" 2>/dev/null | sed "s/.*menuentry //" | sed "s/ .*//" | tr -d "\'" || echo ""'],
                    );
                    final entryName = nameResult.stdout.toString().trim();
                    return {
                      'index': index,
                      'name': entryName.isNotEmpty ? entryName : null,
                      'submenu': null,
                      'fullName': entryName.isNotEmpty ? entryName : null,
                    };
                  }
                }
              }
            }
          }
        } catch (e) {
          // Continua con il prossimo percorso
          continue;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }


  /// Modifica GRUB_DEFAULT nel file /etc/default/grub
  static Future<bool> _setGrubDefaultInConfig(String grubDefaultValue) async {
    try {
      const grubConfigPath = '/etc/default/grub';
      
      // Verifica che il file esista
      final checkFile = await Process.run('test', ['-f', grubConfigPath]);
      if (checkFile.exitCode != 0) {
        throw Exception('File $grubConfigPath non trovato');
      }
      
      // Leggi il contenuto attuale del file usando sudo
      final readResult = await _runSudoCommand('cat $grubConfigPath');
      if (readResult.exitCode != 0) {
        throw Exception('Impossibile leggere $grubConfigPath: ${readResult.stderr.toString()}');
      }
      final content = readResult.stdout.toString();

      // Modifica GRUB_DEFAULT
      final lines = content.split('\n');
      bool found = false;
      final newLines = <String>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('GRUB_DEFAULT=')) {
          newLines.add('GRUB_DEFAULT=$grubDefaultValue');
          found = true;
        } else if (trimmed.startsWith('#GRUB_DEFAULT=')) {
          // Se è commentato, decommenta e imposta
          newLines.add('GRUB_DEFAULT=$grubDefaultValue');
          found = true;
        } else {
          newLines.add(line);
        }
      }

      // Se non trovato, aggiungi dopo GRUB_TIMEOUT o all'inizio
      if (!found) {
        bool inserted = false;
        final finalLines = <String>[];
        for (final line in newLines) {
          finalLines.add(line);
          if (!inserted && (line.trim().startsWith('GRUB_TIMEOUT=') || 
                           line.trim().startsWith('GRUB_CMDLINE_LINUX_DEFAULT='))) {
            finalLines.add('GRUB_DEFAULT=$grubDefaultValue');
            inserted = true;
          }
        }
        if (!inserted) {
          finalLines.insert(0, 'GRUB_DEFAULT=$grubDefaultValue');
        }
        newLines.clear();
        newLines.addAll(finalLines);
      }

      final newContent = newLines.join('\n');

      // Salva il file usando sudo con diversi metodi
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('/tmp/grub_default_$timestamp');
      await tempFile.writeAsString(newContent);

      final tempPathEscaped = tempFile.path.replaceAll("'", "'\"'\"'");
      var result = await _runSudoCommand(
        "cp '$tempPathEscaped' '$grubConfigPath' && chmod 644 '$grubConfigPath'",
      );

      // Se fallisce, prova con tee
      if (result.exitCode != 0) {
        final contentBase64 = base64Encode(utf8.encode(newContent));
        result = await _runSudoCommand(
          "echo '$contentBase64' | base64 -d | tee '$grubConfigPath' > /dev/null && chmod 644 '$grubConfigPath'",
        );
      }

      // Se ancora fallisce, prova con cat
      if (result.exitCode != 0) {
        result = await _runSudoCommand(
          "cat > '$grubConfigPath' << 'EOF'\n$newContent\nEOF\nchmod 644 '$grubConfigPath'",
        );
      }

      try {
        await tempFile.delete();
      } catch (e) {
        // Ignora errori nella rimozione del file temporaneo
      }

      // Verifica che il file sia stato salvato correttamente
      if (result.exitCode == 0) {
        final verifyResult = await _runSudoCommand('grep "^GRUB_DEFAULT=" $grubConfigPath');
        if (verifyResult.exitCode == 0) {
          final savedValue = verifyResult.stdout.toString().trim();
          final expectedValue = grubDefaultValue.replaceAll('"', '');
          if (savedValue.contains(expectedValue)) {
            return true;
          } else {
            throw Exception('Verifica fallita: valore salvato "$savedValue" non corrisponde a "$expectedValue"');
          }
        } else {
          throw Exception('Impossibile verificare GRUB_DEFAULT: ${verifyResult.stderr.toString()}');
        }
      } else {
        throw Exception('Impossibile salvare $grubConfigPath: ${result.stderr.toString()}');
      }
    } catch (e) {
      // Rilancia l'eccezione per avere più informazioni
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Errore in _setGrubDefaultInConfig: $e');
    }
  }

  /// Imposta il kernel predefinito al prossimo riavvio (GRUB 2).
  /// Ordine tipico: [grub-editenv] su `saved_entry` con `GRUB_DEFAULT=saved`,
  /// oppure [grubby --set-default], [grub-set-default], infine [GRUB_DEFAULT] in
  /// `/etc/default/grub` + `update-grub` / `grub-mkconfig`.
  static Future<bool> setDefaultKernel(String version) async {
    String? lastError;
    
    try {
      // Verifica che la password sia salvata
      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) {
        throw Exception('Password non salvata. Salva la password nelle impostazioni.');
      }

      final systemInfo = await SystemDetector.detectSystem();
      
      // Metodo 0: Usa GRUB_DEFAULT=saved + grub-editenv (metodo più moderno e affidabile)
      try {
        // Prima assicurati che GRUB_DEFAULT=saved sia impostato
        final checkSaved = await _runSudoCommand('grep "^GRUB_DEFAULT=" /etc/default/grub 2>/dev/null || echo ""');
        final hasSaved = checkSaved.stdout.toString().contains('GRUB_DEFAULT=saved');
        
        if (!hasSaved) {
          // Imposta GRUB_DEFAULT=saved
          final setSavedResult = await _setGrubDefaultInConfig('saved');
          if (!setSavedResult) {
            // Se non riesce, continua comunque
          }
        }
        
        // Trova il nome esatto della menuentry
        final menuInfo = await _findGrubMenuEntryInfo(version);
        if (menuInfo != null) {
          final fullName = menuInfo['fullName'] as String?;
          final menuIndex = menuInfo['index'] as int?;
          
          // Prova prima con il nome completo (se disponibile e senza sottomenu)
          if (fullName != null && !fullName.contains('>')) {
            // Usa grub-editenv per impostare saved_entry con il nome
            var result = await _runSudoCommand('grub-editenv /boot/grub/grubenv set saved_entry="$fullName"');
            if (result.exitCode == 0) {
              return true;
            }
            // Prova anche con grubenv in altri percorsi
            result = await _runSudoCommand('grub-editenv /boot/grub2/grubenv set saved_entry="$fullName"');
            if (result.exitCode == 0) {
              return true;
            }
          }
          
          // Se il nome non funziona, prova con l'indice numerico
          if (menuIndex != null) {
            var result = await _runSudoCommand('grub-editenv /boot/grub/grubenv set saved_entry=$menuIndex');
            if (result.exitCode == 0) {
              return true;
            }
            result = await _runSudoCommand('grub-editenv /boot/grub2/grubenv set saved_entry=$menuIndex');
            if (result.exitCode == 0) {
              return true;
            }
          }
        }
      } catch (e) {
        // grub-editenv non disponibile o errore, continua con altri metodi
        lastError = 'grub-editenv non disponibile: $e';
      }
      
      // Metodo 1: Prova grubby per TUTTE le distribuzioni (se disponibile)
      // grubby è il metodo più affidabile quando disponibile
      try {
        // Verifica se grubby è disponibile
        final checkGrubby = await Process.run('which', ['grubby']);
        if (checkGrubby.exitCode == 0) {
          // Prova prima con il percorso completo
          var result = await _runSudoCommand(
            'grubby --set-default /boot/vmlinuz-$version',
          );
          if (result.exitCode == 0) {
            return true; // grubby ha successo, non serve update-grub
          }
          
          // Se fallisce, prova a trovare il percorso corretto del vmlinuz
          final findVmlinuz = await Process.run(
            'bash',
            ['-c', 'ls -1 /boot/vmlinuz-*$version* 2>/dev/null | head -1 || true'],
          );
          if (findVmlinuz.exitCode == 0 && findVmlinuz.stdout.toString().trim().isNotEmpty) {
            final vmlinuzPath = findVmlinuz.stdout.toString().trim();
            result = await _runSudoCommand('grubby --set-default "$vmlinuzPath"');
            if (result.exitCode == 0) {
              return true;
            }
          }
          
          lastError = 'grubby fallito: ${result.stderr.toString()}';
        }
      } catch (e) {
        lastError = 'grubby non disponibile: $e';
        // grubby non disponibile, continua con il metodo standard
      }

      // Metodo 2: Per tutte le distribuzioni basate su GRUB 2
      // Trova informazioni sulla voce menuentry (indice, nome, sottomenu)
      final menuInfo = await _findGrubMenuEntryInfo(version);
      
      if (menuInfo != null) {
        final menuIndex = menuInfo['index'] as int?;
        final fullName = menuInfo['fullName'] as String?;
        final submenu = menuInfo['submenu'] as String?;
        
        // Se c'è un sottomenu, usa il formato "submenu>entry"
        if (submenu != null && fullName != null) {
          try {
            final escapedName = fullName.replaceAll('"', '\\"');
            final success = await _setGrubDefaultInConfig('"$escapedName"');
            if (success) {
              await updateGrub();
              return true;
            }
          } catch (e) {
            lastError = 'Impossibile impostare GRUB_DEFAULT con sottomenu "$fullName": $e';
          }
        }
        
        // Se non c'è sottomenu, prova prima con l'indice numerico (metodo più semplice)
        if (menuIndex != null) {
          try {
            final success = await _setGrubDefaultInConfig('$menuIndex');
            if (success) {
              await updateGrub();
              return true;
            }
          } catch (e) {
            lastError = 'Impossibile impostare GRUB_DEFAULT con indice $menuIndex: $e';
          }
        }
        
        // Se l'indice non funziona, prova con il nome esatto
        if (fullName != null) {
          try {
            final escapedName = fullName.replaceAll('"', '\\"');
            final success = await _setGrubDefaultInConfig('"$escapedName"');
            if (success) {
              await updateGrub();
              return true;
            }
          } catch (e) {
            lastError = 'Impossibile impostare GRUB_DEFAULT con nome "$fullName": $e';
          }
        }
      } else {
        // Se non trovato, prova un metodo alternativo più aggressivo
        // Cerca direttamente nel grub.cfg usando un approccio diverso
        try {
          final systemInfo = await SystemDetector.detectSystem();
          final grubCfgPaths = [
            systemInfo.grubConfigPath,
            '/boot/grub/grub.cfg',
            '/boot/grub2/grub.cfg',
          ];
          
          for (final cfgPath in grubCfgPaths) {
            try {
              // Leggi il file grub.cfg usando sudo
              final readResult = await _runSudoCommand('cat "$cfgPath" 2>/dev/null');
              if (readResult.exitCode == 0) {
                final content = readResult.stdout.toString();
                
                // Cerca tutte le occorrenze del kernel
                final lines = content.split('\n');
                int entryCount = -1;
                bool inEntry = false;
                String? currentEntryName;
                
                for (int i = 0; i < lines.length; i++) {
                  final line = lines[i];
                  
                  // Conta le menuentry (non i submenu)
                  if (line.trim().startsWith('menuentry ') && !line.trim().startsWith('submenu ')) {
                    entryCount++;
                    inEntry = true;
                    // Estrai il nome - gestisci sia virgolette singole che doppie
                    final matchSingle = RegExp(r"menuentry\s+'([^']+)'").firstMatch(line);
                    final matchDouble = RegExp(r'menuentry\s+"([^"]+)"').firstMatch(line);
                    if (matchSingle != null) {
                      currentEntryName = matchSingle.group(1);
                    } else if (matchDouble != null) {
                      currentEntryName = matchDouble.group(1);
                    }
                    continue;
                  }
                  
                  // Cerca il kernel nella entry corrente
                  if (inEntry) {
                    // Cerca pattern più ampi
                    if (line.contains(version) || 
                        line.contains('vmlinuz-$version') ||
                        line.contains('/vmlinuz-$version') ||
                        line.contains('linux-image-$version')) {
                      // Trovato! Usa l'indice trovato
                      if (entryCount >= 0) {
                        // Prova con grub-set-default
                        var result = await _runSudoCommand('grub-set-default $entryCount');
                        if (result.exitCode == 0) {
                          await updateGrub();
                          return true;
                        }
                        // Se grub-set-default fallisce, usa GRUB_DEFAULT
                        final success = await _setGrubDefaultInConfig('$entryCount');
                        if (success) {
                          await updateGrub();
                          return true;
                        }
                      }
                      // Se abbiamo il nome, prova anche con quello
                      if (currentEntryName != null) {
                        final escapedName = currentEntryName.replaceAll('"', '\\"');
                        final success = await _setGrubDefaultInConfig('"$escapedName"');
                        if (success) {
                          await updateGrub();
                          return true;
                        }
                      }
                    }
                  }
                  
                  // Reset inEntry quando troviamo }
                  if (line.trim() == '}') {
                    inEntry = false;
                    currentEntryName = null;
                  }
                }
              }
            } catch (e) {
              continue;
            }
          }
        } catch (e) {
          // Ignora errori
        }
        
        lastError = 'Kernel $version non trovato nel menu GRUB';
      }

      // Metodo 3: Se non troviamo la voce, prova a cercare usando grep direttamente nel grub.cfg
      // e poi usa grub-set-default con l'indice trovato
      try {
        final grepResult = await Process.run(
          'bash',
          ['-c', 'grep -n "vmlinuz-$version" /boot/grub/grub.cfg /boot/grub2/grub.cfg 2>/dev/null | head -1 || true'],
        );
        if (grepResult.exitCode == 0 && grepResult.stdout.toString().trim().isNotEmpty) {
          // Conta le menuentry prima di questa riga
          final lineNum = grepResult.stdout.toString().split(':')[1];
          final countResult = await Process.run(
            'bash',
            ['-c', 'head -n $lineNum /boot/grub/grub.cfg 2>/dev/null | grep -c "^menuentry " || head -n $lineNum /boot/grub2/grub.cfg 2>/dev/null | grep -c "^menuentry " || echo "0"'],
          );
          final countStr = countResult.stdout.toString().trim();
          final count = int.tryParse(countStr);
          if (count != null && count > 0) {
            try {
              final index = count - 1; // Gli indici partono da 0
              final success = await _setGrubDefaultInConfig('$index');
              if (success) {
                await updateGrub();
                return true;
              }
            } catch (e) {
              lastError = 'Impossibile impostare GRUB_DEFAULT con indice calcolato: $e';
            }
          }
        }
      } catch (e) {
        if (lastError == null) {
          lastError = 'Errore nel metodo grep: $e';
        }
      }

      // Metodo 4: Prova a usare grub-set-default direttamente con il nome del kernel
      try {
        // Cerca tutte le menuentry e trova quella corrispondente
        final listResult = await Process.run(
          'bash',
          ['-c', 'grep -n "^menuentry" /boot/grub/grub.cfg /boot/grub2/grub.cfg 2>/dev/null | head -20 || true'],
        );
        
        if (listResult.exitCode == 0 && listResult.stdout.toString().trim().isNotEmpty) {
          final lines = listResult.stdout.toString().split('\n');
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.contains(version) || line.contains('vmlinuz-$version')) {
              // Usa grub-set-default con l'indice
              final result = await _runSudoCommand('grub-set-default $i');
              if (result.exitCode == 0) {
                await updateGrub();
                return true;
              }
            }
          }
        }
      } catch (e) {
        if (lastError == null) {
          lastError = 'Errore nel metodo grub-set-default diretto: $e';
        }
      }

      // Metodo 5: Fallback - usa grub-set-default con l'indice trovato (se disponibile)
      if (menuInfo != null) {
        final menuIndex = menuInfo['index'] as int?;
        if (menuIndex != null) {
          final result = await _runSudoCommand(
            'grub-set-default $menuIndex',
          );
          if (result.exitCode == 0) {
            await updateGrub();
            return true;
          } else {
            lastError = 'grub-set-default fallito: ${result.stderr.toString()}';
          }
        }
      }

      // Metodo 6: Cerca il kernel partendo dal file vmlinuz
      try {
        // Verifica se esiste il file vmlinuz per questo kernel
        final vmlinuzPath = '/boot/vmlinuz-$version';
        final checkVmlinuz = await Process.run('test', ['-f', vmlinuzPath]);
        if (checkVmlinuz.exitCode == 0) {
          // Cerca nel grub.cfg usando il percorso completo del vmlinuz
          final searchScript = '''
            for cfg in /boot/grub/grub.cfg /boot/grub2/grub.cfg; do
              if [ -f "\$cfg" ]; then
                # Cerca la riga con il percorso vmlinuz
                line_num=\$(grep -n "$vmlinuzPath" "\$cfg" | head -1 | cut -d: -f1)
                if [ -n "\$line_num" ]; then
                  # Conta le menuentry prima di questa riga
                  count=\$(head -n "\$line_num" "\$cfg" | grep -c "^menuentry ")
                  if [ "\$count" -gt 0 ]; then
                    echo \$((count - 1))
                    exit 0
                  fi
                fi
              fi
            done
            exit 1
          ''';
          
          final searchResult = await Process.run('bash', ['-c', searchScript]);
          if (searchResult.exitCode == 0) {
            final indexStr = searchResult.stdout.toString().trim();
            final index = int.tryParse(indexStr);
            if (index != null) {
              // Prova con grub-set-default
              var result = await _runSudoCommand('grub-set-default $index');
              if (result.exitCode == 0) {
                await updateGrub();
                return true;
              }
              // Se grub-set-default fallisce, prova con GRUB_DEFAULT
              final success = await _setGrubDefaultInConfig('$index');
              if (success) {
                await updateGrub();
                return true;
              }
            }
          }
        }
      } catch (e) {
        if (lastError == null) {
          lastError = 'Errore nel metodo di ricerca vmlinuz: $e';
        }
      }

      // Metodo 7: Ultimo tentativo - cerca manualmente nel grub.cfg usando un approccio diverso
      try {
        final systemInfo = await SystemDetector.detectSystem();
        final grubCfgPath = systemInfo.grubConfigPath;
        
        // Crea uno script che cerca il kernel in modo più flessibile
        final searchScript = '''
          # Cerca il kernel nel grub.cfg
          for cfg in "$grubCfgPath" /boot/grub/grub.cfg /boot/grub2/grub.cfg; do
            if [ -f "\$cfg" ]; then
              # Conta le menuentry e trova quella con il kernel
              awk -v version="$version" '
                BEGIN { idx = -1 }
                /^menuentry / {
                  idx++
                  entry_idx = idx
                  in_entry = 1
                  next
                }
                in_entry && (index(\$0, version) > 0 || index(\$0, "vmlinuz-" version) > 0) {
                  print entry_idx
                  exit 0
                }
                /^}/ {
                  in_entry = 0
                }
              ' "\$cfg" && exit 0
            fi
          done
          exit 1
        ''';
        
        final searchResult = await Process.run('bash', ['-c', searchScript]);
        if (searchResult.exitCode == 0) {
          final indexStr = searchResult.stdout.toString().trim();
          final index = int.tryParse(indexStr);
          if (index != null) {
            // Prova con grub-set-default
            var result = await _runSudoCommand('grub-set-default $index');
            if (result.exitCode == 0) {
              await updateGrub();
              return true;
            }
            // Se grub-set-default fallisce, prova con GRUB_DEFAULT
            final success = await _setGrubDefaultInConfig('$index');
            if (success) {
              await updateGrub();
              return true;
            }
          }
        }
      } catch (e) {
        if (lastError == null) {
          lastError = 'Errore nel metodo di ricerca manuale: $e';
        }
      }

      // Se tutti i metodi falliscono, lancia un'eccezione con il messaggio di errore
      throw Exception(lastError ?? 'Impossibile impostare il kernel default: tutti i metodi sono falliti');
    } catch (e) {
      // Se è già un'Exception, rilanciala
      if (e is Exception) {
        rethrow;
      }
      // Altrimenti, crea una nuova Exception
      throw Exception('Errore durante l\'impostazione del kernel default: $e');
    }
  }

  /// Rimuove i kernel più vecchi mantenendo solo i N più recenti
  static Future<bool> keepOnlyRecentKernels(int maxKernels) async {
    try {
      final kernels = await getInstalledKernels();
      
      if (kernels.length <= maxKernels) {
        return true; // Nessun kernel da rimuovere
      }

      // Ordina per versione (più recente prima)
      kernels.sort((a, b) {
        final aVersion = _parseVersion(a.version);
        final bVersion = _parseVersion(b.version);
        return _compareVersions(bVersion, aVersion); // Ordine decrescente (più recente prima)
      });

      // Mantieni i primi maxKernels e rimuovi gli altri
      final toRemove = kernels.sublist(maxKernels);
      final packageNames = toRemove.map((k) => k.packageName).toList();

      return await removeKernels(packageNames);
    } catch (e) {
      throw Exception('Errore durante la pulizia dei kernel: $e');
    }
  }

  /// Aggiorna GRUB dopo modifiche ai kernel
  static Future<bool> updateGrub() async {
    try {
      // Rileva la distribuzione e usa il comando corretto
      final systemInfo = await SystemDetector.detectSystem();
      final distribution = systemInfo.distribution.toLowerCase();
      final command = systemInfo.grubUpdateCommand;
      
      // Esegui il comando specifico per la distribuzione
      ProcessResult result = await _runSudoCommand('$command 2>&1');
      
      // Se fallisce, prova i comandi alternativi come fallback in base alla distribuzione
      if (result.exitCode != 0) {
        // Ubuntu/Debian/Mint e derivate
        if (distribution.contains('ubuntu') || 
            distribution.contains('debian') || 
            distribution.contains('mint') ||
            distribution.contains('zorin') ||
            distribution.contains('elementary') ||
            distribution.contains('pop')) {
          // Prova update-grub
          result = await _runSudoCommand('update-grub 2>&1');
          if (result.exitCode != 0) {
            // Fallback: grub-mkconfig
            result = await _runSudoCommand('grub-mkconfig -o /boot/grub/grub.cfg 2>&1');
          }
        }
        // Fedora/RHEL/CentOS
        else if (distribution.contains('fedora') || 
                 distribution.contains('rhel') ||
                 distribution.contains('centos') ||
                 distribution.contains('oracle')) {
          // Prova grub2-mkconfig con percorso standard
          result = await _runSudoCommand('grub2-mkconfig -o /boot/grub2/grub.cfg 2>&1');
          if (result.exitCode != 0) {
            // Prova percorso EFI
            result = await _runSudoCommand('grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg 2>&1');
          }
          if (result.exitCode != 0) {
            // Prova con grubby (se disponibile)
            result = await _runSudoCommand('grubby --update-kernel=ALL 2>&1');
          }
        }
        // Arch/Manjaro
        else if (distribution.contains('arch') || 
                 distribution.contains('manjaro')) {
          result = await _runSudoCommand('grub-mkconfig -o /boot/grub/grub.cfg 2>&1');
        }
        // openSUSE
        else if (distribution.contains('opensuse') || 
                 distribution.contains('suse')) {
          result = await _runSudoCommand('grub2-mkconfig -o /boot/grub2/grub.cfg 2>&1');
        }
        // Default: prova tutti i comandi in ordine
        else {
          // Prova update-grub
          result = await _runSudoCommand('update-grub 2>&1');
          if (result.exitCode != 0) {
            // Prova grub-mkconfig
            result = await _runSudoCommand('grub-mkconfig -o /boot/grub/grub.cfg 2>&1');
          }
          if (result.exitCode != 0) {
            // Prova grub2-mkconfig
            result = await _runSudoCommand('grub2-mkconfig -o /boot/grub2/grub.cfg 2>&1');
          }
        }
      }

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Riavvia il sistema
  static Future<bool> rebootSystem() async {
    try {
      await _runSudoCommand('reboot');
      // Il comando reboot potrebbe non ritornare se il sistema si riavvia immediatamente
      return true;
    } catch (e) {
      // Anche se c'è un errore, potrebbe essere perché il sistema si sta riavviando
      return true;
    }
  }

  /// Formatta la dimensione in formato leggibile
  static String formatSize(int? bytes) {
    if (bytes == null) return 'N/A';
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

