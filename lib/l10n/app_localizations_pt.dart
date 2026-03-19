// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Super Linux Utility';

  @override
  String get appAlreadyRunning => 'O aplicativo já está em execução.';

  @override
  String get trayCheckUpdates => 'Verificar atualizações do sistema';

  @override
  String get trayCleanLinuxCache => 'Limpar cache do Linux';

  @override
  String get trayRemoveTempFiles => 'Remover arquivos temporários';

  @override
  String get trayCleanTempFilesAndCache =>
      'Limpar arquivos temporários e cache';

  @override
  String get trayCleanVram => 'Limpar VRAM (reset da GPU)';

  @override
  String get trayCpuGpuTemp => 'Temperatura CPU, GPU';

  @override
  String get trayDiskUsage => 'Uso do disco';

  @override
  String get trayMemoryUsage => 'Uso de memória RAM';

  @override
  String get trayShutdownTimer => 'Desligamento automático';

  @override
  String get trayShowMainWindow => 'Mostrar janela principal';

  @override
  String get trayCpuGpuUsage => 'Uso de CPU, GPU';

  @override
  String get trayExit => 'Sair';

  @override
  String get cleanupLinuxCache => 'Limpar cache';

  @override
  String get cleanupLinuxCacheDesc =>
      'Esvaziar o cache de página do kernel (drop_caches). Requer senha de administrador.';

  @override
  String get cleanupLinuxCacheSuccess => 'Cache do Linux limpo com sucesso.';

  @override
  String get cleanupLinuxCacheError => 'Erro ao limpar o cache.';

  @override
  String get cleanupVram => 'Limpar VRAM';

  @override
  String get cleanupVramConfirmTitle => 'Reset da GPU';

  @override
  String get cleanupVramConfirmMessage =>
      'Vou tentar reiniciar a placa gráfica para liberar a VRAM. Requer senha de administrador e pode causar uma interrupção temporária na tela. Continuar?';

  @override
  String get cleanupVramSuccess => 'VRAM limpa (reset da GPU) com sucesso.';

  @override
  String get cleanupVramError =>
      'Não foi possível limpar a VRAM (reset da GPU falhou).';

  @override
  String get tabServices => 'Serviços';

  @override
  String get tabStartupApps => 'Apps de Inicialização';

  @override
  String get tabCleanup => 'Limpeza';

  @override
  String get tabInstalledApps => 'Apps Instaladas';

  @override
  String get tabMonitor => 'Monitor';

  @override
  String get tabDiskAnalyzer => 'Analisador de Disco';

  @override
  String get tabAppearance => 'Aparência GNOME';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabRecovery => 'Recuperação do Sistema';

  @override
  String get tabGrub => 'GRUB';

  @override
  String get tabKernel => 'Kernel';

  @override
  String get tabSettings => 'Configurações';

  @override
  String get modeStandard => 'Padrão';

  @override
  String get modeAdvanced => 'Avançado';

  @override
  String get warningTitle => 'AVISO';

  @override
  String get warningSubtitle => 'Aplicativo para Usuários Especialistas';

  @override
  String get warningMessage =>
      'Este aplicativo permite modificar configurações críticas do sistema operacional Linux.';

  @override
  String get warningGrub => 'Modificações GRUB';

  @override
  String get warningGrubDesc =>
      'A modificação incorreta do gerenciador de inicialização pode impedir que o sistema inicie.';

  @override
  String get warningKernel => 'Remoção de Kernel';

  @override
  String get warningKernelDesc =>
      'Remover kernels essenciais pode tornar o sistema inutilizável.';

  @override
  String get warningServices => 'Gerenciamento de Serviços';

  @override
  String get warningServicesDesc =>
      'Desativar serviços críticos pode causar mau funcionamento do sistema.';

  @override
  String get warningCleanup => 'Limpeza de Arquivos';

  @override
  String get warningCleanupDesc =>
      'Excluir arquivos do sistema pode comprometer a estabilidade.';

  @override
  String get warningBackup =>
      'Recomenda-se criar um backup do sistema antes de usar este aplicativo.';

  @override
  String get warningDontShow => 'Não mostrar este aviso novamente';

  @override
  String get warningAccept => 'Entendi, Prosseguir';

  @override
  String get passwordSetupTitle => 'Configuração de Senha';

  @override
  String get passwordSetupDesc =>
      'Para usar recursos que requerem privilégios de administrador, é necessário configurar a senha do sistema.';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get passwordHint => 'Digite a senha do administrador';

  @override
  String get passwordConfirm => 'Confirmar Senha';

  @override
  String get passwordConfirmHint => 'Digite a senha novamente';

  @override
  String get passwordSave => 'Salvar Senha';

  @override
  String get passwordSkip => 'Pular por enquanto';

  @override
  String get passwordSaved =>
      'Senha salva com segurança usando o cofre do sistema.';

  @override
  String get passwordError => 'Erro ao salvar';

  @override
  String get passwordMismatch => 'As senhas não coincidem';

  @override
  String get passwordEmpty => 'Digite uma senha';

  @override
  String get passwordRequired => 'Senha Necessária';

  @override
  String get passwordRequiredMessage =>
      'A senha do administrador é necessária para acessar todos os diretórios. A senha será salva com segurança.';

  @override
  String get settingsPasswordTitle => 'Senha do Administrador';

  @override
  String get settingsPasswordDesc =>
      'Salve a senha do administrador para usar recursos que requerem privilégios sudo.';

  @override
  String get settingsPasswordSaved =>
      'Senha salva. Você pode alterá-la ou excluí-la.';

  @override
  String get settingsPasswordConfigured => 'Senha configurada';

  @override
  String get settingsPasswordUpdate => 'Atualizar Senha';

  @override
  String get settingsPasswordDelete => 'Excluir';

  @override
  String get settingsThemeTitle => 'Tema do Aplicativo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeSystemDesc => 'Segue as configurações do sistema';

  @override
  String get settingsInfoTitle => 'Informações';

  @override
  String get settingsInfoDesc => 'Este aplicativo ajuda você a:';

  @override
  String get settingsInfoItem1 =>
      'Encontrar serviços systemd que retardam a inicialização';

  @override
  String get settingsInfoItem2 => 'Gerenciar aplicativos de inicialização';

  @override
  String get settingsInfoItem3 => 'Limpar arquivos temporários do sistema';

  @override
  String get loading => 'Carregando...';

  @override
  String get loadingSettings => 'Carregando configurações do sistema';

  @override
  String get error => 'Erro';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get delete => 'Excluir';

  @override
  String get save => 'Salvar';

  @override
  String get themeRestartMessage =>
      'O tema será aplicado após reiniciar o aplicativo';

  @override
  String get themeApplied => 'Tema aplicado com sucesso';

  @override
  String get settingsFontTitle => 'Fonte e Tamanho do Texto';

  @override
  String get settingsFontDesc =>
      'Personalize a fonte e o tamanho do texto usado em todo o aplicativo.';

  @override
  String get settingsSystemTrayTitle => 'Bandeja do sistema';

  @override
  String get settingsSystemTrayDesc =>
      'Mostrar o ícone do app na bandeja do sistema para ações rápidas. Requer dependências do sistema (libappindicator).';

  @override
  String get settingsTrayDepsOk => 'Dependências instaladas.';

  @override
  String get settingsTrayDepsMissing =>
      'Dependências ausentes. Instale para habilitar a bandeja do sistema.';

  @override
  String get settingsSystemTrayEnable => 'Habilitar bandeja do sistema';

  @override
  String get settingsTrayInstallDeps => 'Instalar dependências';

  @override
  String get settingsCloseToTray => 'Manter na bandeja ao fechar';

  @override
  String get settingsCloseToTrayDesc =>
      'Quando ativo, fechar ou minimizar a janela mantém o app na bandeja do sistema.';

  @override
  String get settingsCloseToTrayOn => 'Fechar para bandeja ativado.';

  @override
  String get settingsCloseToTrayOff =>
      'Fechar para bandeja desativado. Fechar a janela encerrará o app.';

  @override
  String get settingsTrayEnabled => 'Bandeja do sistema habilitada.';

  @override
  String get settingsTrayDisabled =>
      'Bandeja do sistema desabilitada. Reinicie o app para aplicar.';

  @override
  String get settingsStartMinimized => 'Iniciar o app minimizado na bandeja';

  @override
  String get settingsStartMinimizedDesc =>
      'Quando ativo, o app inicia sem mostrar a janela principal, apenas o ícone na bandeja.';

  @override
  String get settingsStartMinimizedOn =>
      'Início minimizado ativado. Na próxima abertura, o app abrirá só na bandeja.';

  @override
  String get settingsStartMinimizedOff => 'Início minimizado desativado.';

  @override
  String get settingsStartAtLogin => 'Iniciar o app ao iniciar o sistema';

  @override
  String get settingsStartAtLoginDesc =>
      'Quando ativo, o app inicia automaticamente ao fazer login.';

  @override
  String get settingsStartAtLoginOn =>
      'Início ao login ativado. O app será iniciado ao fazer login.';

  @override
  String get settingsStartAtLoginOff => 'Início ao login desativado.';

  @override
  String get settingsStartAtLoginError =>
      'Não foi possível alterar o início ao login.';

  @override
  String get settingsAutoUpdateCheckTitle =>
      'Verificação automática de atualizações';

  @override
  String get settingsAutoUpdateCheckDesc =>
      'Verificar atualizações do sistema automaticamente no intervalo escolhido.';

  @override
  String get settingsAutoUpdateCheckInterval => 'Verificar atualizações';

  @override
  String get settingsAutoUpdateNever => 'Nunca';

  @override
  String get settingsAutoUpdateEvery15Min => 'A cada 15 minutos';

  @override
  String get settingsAutoUpdateEvery30Min => 'A cada 30 minutos';

  @override
  String get settingsAutoUpdateEvery1Hour => 'A cada hora';

  @override
  String get settingsAutoUpdateEvery6Hours => 'A cada 6 horas';

  @override
  String get settingsAutoUpdateEvery12Hours => 'A cada 12 horas';

  @override
  String get settingsAutoUpdateEveryDay => 'Diariamente';

  @override
  String updatesAvailableCount(int count) {
    return '$count atualizações disponíveis';
  }

  @override
  String get updatesAvailableDialogTitle => 'Atualizações disponíveis';

  @override
  String updatesAvailableDialogMessage(int count) {
    return '$count atualizações disponíveis. Deseja aplicá-las agora?';
  }

  @override
  String get applyNow => 'Aplicar agora';

  @override
  String get postpone => 'Depois';

  @override
  String get fontFamily => 'Família da Fonte';

  @override
  String get fontSize => 'Tamanho da Fonte';

  @override
  String get fontDefault => 'Padrão (Roboto)';

  @override
  String get fontRestartMessage =>
      'A fonte será aplicada após reiniciar o aplicativo';

  @override
  String get themeApplyError => 'Erro ao aplicar o tema';

  @override
  String get userThemesExtensionMessage =>
      'Para temas Shell completos, instale a extensão User Themes em extensions.gnome.org';

  @override
  String get themeRequiresOcsUrl =>
      'Este tema requer ocs-url para ser instalado corretamente';

  @override
  String get installOcsUrl => 'Instalar ocs-url';

  @override
  String get ocsUrlNotInstalled =>
      'ocs-url não está instalado. Alguns temas podem não funcionar corretamente.';

  @override
  String get ocsUrlInstalled => 'ocs-url instalado com sucesso!';

  @override
  String get ocsUrlInstallError =>
      'Erro ao instalar ocs-url. Verifique se a senha está correta e se o gerenciador de pacotes está disponível.';

  @override
  String get installingOcsUrl => 'Instalando ocs-url...';

  @override
  String get installingOcsUrlDescription =>
      'Esta operação é executada automaticamente na primeira inicialização.';

  @override
  String get themeToolsMessage =>
      'Para instalar temas do OpenDesktop.org/Pling.com, instale ocs-url ou PLing-store. Alguns temas requerem essas ferramentas para funcionar corretamente.';

  @override
  String get refresh => 'Atualizar';

  @override
  String get search => 'Pesquisar';

  @override
  String get noResults => 'Nenhum resultado encontrado';

  @override
  String get enabled => 'Habilitado';

  @override
  String get disabled => 'Desabilitado';

  @override
  String get active => 'Ativo';

  @override
  String get inactive => 'Inativo';

  @override
  String get start => 'Iniciar';

  @override
  String get stop => 'Parar';

  @override
  String get restart => 'Reiniciar';

  @override
  String get enable => 'Habilitar';

  @override
  String get disable => 'Desabilitar';

  @override
  String get remove => 'Remover';

  @override
  String get kill => 'Encerrar';

  @override
  String get killForce => 'Forçar Encerramento';

  @override
  String get processes => 'Processos';

  @override
  String get system => 'Sistema';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => 'Memória';

  @override
  String get disk => 'Disco';

  @override
  String get gpu => 'Placa de Vídeo';

  @override
  String get usage => 'Uso';

  @override
  String get total => 'Total';

  @override
  String get used => 'Usado';

  @override
  String get free => 'Livre';

  @override
  String get model => 'Modelo';

  @override
  String get driver => 'Driver';

  @override
  String get temperature => 'Temperatura';

  @override
  String get version => 'Versão';

  @override
  String get creator => 'Criador';

  @override
  String get creatorName => 'Marco Di Giangiacomo';

  @override
  String get appDescription =>
      'Super Linux Utility é um aplicativo completo para gerenciamento avançado do sistema Linux. Oferece ferramentas poderosas para otimizar o desempenho, gerenciar serviços, aplicativos e personalizar a aparência do sistema.';

  @override
  String get features => 'Recursos';

  @override
  String get appExpertUsers =>
      'Aplicativo projetado para usuários especialistas Linux';

  @override
  String get disclaimerLicenseTitle => 'Licença e Aviso Legal';

  @override
  String get disclaimerGplNotice =>
      'Esta aplicação é software livre; pode redistribuí-la e/ou modificá-la sob os termos da GNU General Public License publicada pela Free Software Foundation, versão 3 da Licença ou (à sua escolha) posterior.';

  @override
  String get disclaimerNoWarranty =>
      'Este programa é distribuído na esperança de que seja útil, mas SEM NENHUMA GARANTIA; sem mesmo a garantia implícita de COMERCIABILIDADE ou ADEQUAÇÃO A UM PROPÓSITO ESPECÍFICO. Consulte a GNU General Public License para mais detalhes.';

  @override
  String get disclaimerCopyright =>
      'Copyright (c) 2024-2025 Marco Di Giangiacomo. Todos os direitos reservados sob GPL-3.0.';

  @override
  String get payWithPaypal => 'Pagar com PayPal';

  @override
  String get purchaseLicenseViaPaypal =>
      'A versão Advanced custa 19,99 €. Para comprar uma licença, pague via PayPal. Após o pagamento bem-sucedido receberá o código de licença por e-mail. Sem um pagamento válido, o aplicativo não pode ser ativado.';

  @override
  String get languageSelectionTitle => 'Seleção de Idioma';

  @override
  String get languageSelectionDesc => 'Selecione o idioma do aplicativo';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageFrench => 'Francês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageGerman => 'Alemão';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get settingsLanguageTitle => 'Idioma do Aplicativo';

  @override
  String get settingsLanguageDesc => 'Selecione o idioma da interface';

  @override
  String get languageRestartMessage =>
      'O idioma será aplicado quando o aplicativo reiniciar';

  @override
  String get servicesSlow => 'Serviços Lentos';

  @override
  String get servicesAll => 'Todos os Serviços';

  @override
  String get servicesDisabled => 'Desabilitados';

  @override
  String get analyzeAll => 'Analisar Tudo';

  @override
  String get status => 'Status';

  @override
  String get startupTime => 'Tempo de inicialização';

  @override
  String get noServicesFound => 'Nenhum serviço encontrado.';

  @override
  String get reEnable => 'Reabilitar';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get cleanupConfirmTitle => 'Confirmar limpeza';

  @override
  String get cleanupConfirmMessage =>
      'Deseja excluir todos os arquivos temporários? Esta operação não pode ser desfeita.';

  @override
  String get cleanupSuccess => 'Limpeza concluída com sucesso!';

  @override
  String get cleanupPartialSuccess => 'Limpeza concluída com alguns erros.';

  @override
  String get protectedSystemApp => 'Aplicativo de Sistema Protegido';

  @override
  String cannotDisableSystemApp(String appName) {
    return 'Não é possível desabilitar \"$appName\" porque é um aplicativo de sistema essencial.';
  }

  @override
  String get systemAppsRequired =>
      'Os aplicativos do sistema são necessários para o funcionamento adequado do ambiente de desktop e não podem ser desabilitados.';

  @override
  String get checkingDependencies => 'Verificando dependências...';

  @override
  String get warning => '⚠️ Aviso';

  @override
  String get packagesDependingOnThis => 'Pacotes que dependem disto:';

  @override
  String get areYouSure => 'Tem certeza de que deseja continuar?';

  @override
  String get confirmRemoval => 'Confirmar remoção';

  @override
  String removeAppQuestion(String appName) {
    return 'Deseja remover $appName?';
  }

  @override
  String get searchApp => 'Pesquisar aplicativo';

  @override
  String get all => 'Todos';

  @override
  String get searchProcess => 'Pesquisar processo';

  @override
  String processesSelected(int count) {
    return '$count processo selecionado';
  }

  @override
  String processesSelectedPlural(int count) {
    return '$count processos selecionados';
  }

  @override
  String get app => 'App';

  @override
  String get cpuPercent => 'CPU %';

  @override
  String get name => 'Nome';

  @override
  String get pid => 'PID';

  @override
  String get user => 'Usuário';

  @override
  String get noProcessesFound => 'Nenhum processo encontrado.';

  @override
  String get selectAll => 'Selecionar todos';

  @override
  String get terminateAll => 'Encerrar todos';

  @override
  String get terminateAllForce => 'Forçar encerramento de todos';

  @override
  String get cannotLoadSystemInfo =>
      'Não é possível carregar as informações do sistema.';

  @override
  String get cores => 'Núcleos';

  @override
  String get threads => 'Threads';

  @override
  String get grubInvalidContent => 'O conteúdo do arquivo GRUB não é válido';

  @override
  String get grubConfirmSave => 'Confirmar salvamento';

  @override
  String get grubSaveWarning =>
      'Você está prestes a modificar a configuração do GRUB. Esta operação:';

  @override
  String get grubWillCreateBackup => '• Criará um backup automático';

  @override
  String get grubWillSave => '• Salvará as alterações';

  @override
  String get grubWillUpdate => '• Atualizará o GRUB';

  @override
  String get grubWarning =>
      'AVISO: Modificações incorretas podem impedir que o sistema inicie!';

  @override
  String get saveAndUpdate => 'Salvar e atualizar';

  @override
  String get grubSavedSuccess =>
      'Configuração do GRUB salva e atualizada com sucesso';

  @override
  String get grubSaveError => 'Erro ao salvar';

  @override
  String get reload => 'Recarregar';

  @override
  String get restoreBackup => 'Restaurar backup';

  @override
  String get restoreBackupQuestion =>
      'Deseja restaurar o backup da configuração do GRUB?';

  @override
  String get restore => 'Restaurar';

  @override
  String get backupRestoredSuccess => 'Backup restaurado com sucesso';

  @override
  String get backupRestoreError => 'Erro ao restaurar backup';

  @override
  String get kernelCannotRemoveActive =>
      'Não é possível remover o kernel atualmente ativo';

  @override
  String get removeKernel => 'Remover kernel';

  @override
  String removeKernelQuestion(String version) {
    return 'Deseja remover o kernel $version?';
  }

  @override
  String get thisOperation => 'Esta operação:';

  @override
  String get willRemovePackage => '• Removerá o pacote do kernel';

  @override
  String get willUpdateGrub => '• Atualizará o GRUB';

  @override
  String get kernelWarning =>
      'AVISO: Certifique-se de ter pelo menos um kernel funcional!';

  @override
  String kernelRemovedSuccess(String version) {
    return 'Kernel $version removido com sucesso';
  }

  @override
  String get kernelRemoveError => 'Erro ao remover kernel';

  @override
  String get setDefaultKernel => 'Definir kernel padrão';

  @override
  String setDefaultKernelQuestion(String version) {
    return 'Deseja definir $version como kernel padrão?';
  }

  @override
  String get set => 'Definir';

  @override
  String kernelSetDefaultSuccess(String version) {
    return 'Kernel $version definido como padrão';
  }

  @override
  String get kernelSetDefaultError => 'Erro ao definir kernel padrão';

  @override
  String get keepMax => 'Manter máx:';

  @override
  String get cleanupKernels => 'Limpeza de kernel';

  @override
  String keepOnlyRecentKernels(int count) {
    return 'Deseja manter apenas os $count kernels mais recentes?';
  }

  @override
  String totalKernels(int count) {
    return 'Kernels totais: $count';
  }

  @override
  String kernelsToKeep(int count) {
    return 'Kernels a manter: $count';
  }

  @override
  String kernelsToRemove(int count) {
    return 'Kernels a remover: $count';
  }

  @override
  String get cleanupKernelsWarning =>
      'AVISO: Apenas kernels não utilizados serão removidos.';

  @override
  String get cleanup => 'Limpar';

  @override
  String get kernelCleanupSuccess => 'Limpeza de kernel concluída com sucesso';

  @override
  String get kernelCleanupError => 'Erro durante a limpeza do kernel';

  @override
  String get invalidKernelCount =>
      'Digite um número válido de kernels a manter';

  @override
  String get noKernelsFound => 'Nenhum kernel instalado encontrado';

  @override
  String get updateGrub => 'Atualizar GRUB';

  @override
  String get updateGrubQuestion =>
      'Deseja atualizar o GRUB? Esta operação atualizará a configuração do gerenciador de inicialização.';

  @override
  String get grubUpdateSuccess => 'GRUB atualizado com sucesso';

  @override
  String get grubUpdateError => 'Erro ao atualizar o GRUB';

  @override
  String get rebootSystem => 'Reiniciar Sistema';

  @override
  String get rebootSystemQuestion =>
      'Deseja reiniciar o sistema? Todos os aplicativos abertos serão fechados.';

  @override
  String get rebootSystemSuccess => 'O sistema está reiniciando...';

  @override
  String get rebootSystemError => 'Erro ao reiniciar o sistema';

  @override
  String get package => 'Pacote';

  @override
  String get size => 'Tamanho';

  @override
  String get setAsDefault => 'Definir como padrão';

  @override
  String get refreshDimensions => 'Atualizar dimensões';

  @override
  String get cleanupTempFiles => 'Limpar arquivos temporários';

  @override
  String get disableApp => 'Desabilitar aplicativo';

  @override
  String get onlyDisable => 'Apenas desabilitar';

  @override
  String get systemApps => 'Aplicativos do sistema';

  @override
  String get close => 'Fechar';

  @override
  String get updateStartupApps => 'Atualizar aplicativos de inicialização';

  @override
  String get saving => 'Salvando...';

  @override
  String get scaleFactor => 'Fator de escala:';

  @override
  String get maximize => 'Maximizar';

  @override
  String get minimize => 'Minimizar';

  @override
  String get positioning => 'Posicionamento:';

  @override
  String get left => 'Esquerda';

  @override
  String get right => 'Direita';

  @override
  String get buttonOrder => 'Ordem dos botões:';

  @override
  String get attachedDialogs => 'Diálogos anexados';

  @override
  String get centerNewWindows => 'Centralizar novas janelas';

  @override
  String get resizeWithSecondaryClick => 'Redimensionar com clique secundário';

  @override
  String get raiseOnFocus => 'Elevar janelas quando têm o foco';

  @override
  String get backgroundImageUpdated => 'Imagem de fundo atualizada!';

  @override
  String get backgroundImageError => 'Erro ao atualizar a imagem.';

  @override
  String get preferredFonts => 'Fontes Preferidas';

  @override
  String get interfaceText => 'Texto da Interface';

  @override
  String get documentText => 'Texto do Documento';

  @override
  String get fixedWidthText => 'Texto de Largura Fixa';

  @override
  String get rendering => 'Renderização';

  @override
  String get hinting => 'Hinting';

  @override
  String get full => 'Completo';

  @override
  String get medium => 'Médio';

  @override
  String get light => 'Leve';

  @override
  String get antialiasing => 'Suavização';

  @override
  String get subpixelLCD => 'Subpixel (para telas LCD)';

  @override
  String get standardGrayscale => 'Padrão (escala de cinza)';

  @override
  String get dimensions => 'Dimensões';

  @override
  String get preview => 'Visualização:';

  @override
  String get noImageSelected => 'Nenhuma imagem selecionada';

  @override
  String get command => 'Comando:';

  @override
  String get comment => 'Comentário:';

  @override
  String get enabledApps => 'Apps Habilitadas';

  @override
  String get disabledApps => 'Apps Desabilitadas';

  @override
  String get noStartupAppsFound =>
      'Nenhum aplicativo de inicialização encontrado.';

  @override
  String get enabledStatus => 'Habilitada';

  @override
  String get disabledStatus => 'Desabilitada';

  @override
  String get styles => 'Estilos';

  @override
  String get cursor => 'Cursor';

  @override
  String get icons => 'Ícones';

  @override
  String get legacyApps => 'Aplicativos Antigos';

  @override
  String get background => 'Fundo';

  @override
  String get defaultImage => 'Imagem Padrão';

  @override
  String get darkImage => 'Imagem de Estilo Escuro';

  @override
  String get adjustment => 'Ajuste';

  @override
  String get noneOption => 'Nenhum';

  @override
  String get wallpaper => 'Papel de Parede';

  @override
  String get centered => 'Centralizado';

  @override
  String get scaled => 'Dimensionado';

  @override
  String get stretched => 'Esticado';

  @override
  String get zoom => 'Zoom';

  @override
  String get spanned => 'Estendido';

  @override
  String get windowBehavior => 'Comportamento da Janela';

  @override
  String get titlebarButtons => 'Botões da Barra de Título';

  @override
  String get clickActions => 'Ações de Clique';

  @override
  String get windowFocus => 'Foco da Janela';

  @override
  String get doubleClick => 'Duplo Clique';

  @override
  String get middleClick => 'Clique do Meio';

  @override
  String get rightClick => 'Clique Direito';

  @override
  String get toggleMaximize => 'Alternar Maximizar';

  @override
  String get toggleMaximizeHorizontal => 'Alternar Maximizar Horizontalmente';

  @override
  String get toggleMaximizeVertical => 'Alternar Maximizar Verticalmente';

  @override
  String get toggleShade => 'Alternar Sombra';

  @override
  String get toggleMenu => 'Alternar Menu';

  @override
  String get lower => 'Reduzir';

  @override
  String get menu => 'Menu';

  @override
  String get clickForFocus => 'Clique para o foco';

  @override
  String get focusOnHover => 'Foco ao passar';

  @override
  String get focusFollowsMouse => 'Foco segue o mouse';

  @override
  String get clickForFocusDesc =>
      'As janelas terão foco quando você clicar nelas.';

  @override
  String get focusOnHoverDesc =>
      'A janela tem foco quando você passa o mouse sobre ela. As janelas mantêm o foco ao passar sobre a área de trabalho.';

  @override
  String get focusFollowsMouseDesc =>
      'A janela tem foco quando você passa o mouse sobre ela. Passar sobre a área de trabalho remove o foco da janela anterior.';

  @override
  String get someProcessesNotTerminated =>
      'Alguns processos não foram encerrados corretamente';

  @override
  String get errorDisabling => 'Erro ao desabilitar';

  @override
  String appReEnabled(String appName) {
    return 'Aplicativo $appName reabilitado';
  }

  @override
  String get errorEnabling => 'Erro ao habilitar';

  @override
  String removeAppFromStartup(String appName) {
    return 'Deseja remover $appName da inicialização?';
  }

  @override
  String appRemoved(String appName) {
    return 'Aplicativo $appName removido';
  }

  @override
  String get errorRemoving => 'Erro ao remover';

  @override
  String get terminateProcesses => 'Encerrar Processos';

  @override
  String get noProcessesRunning =>
      'Nenhum processo em execução para este aplicativo';

  @override
  String get cache => 'Cache';

  @override
  String get swap => 'Swap';

  @override
  String get filesystem => 'Sistema de arquivos';

  @override
  String get temperatureUnit => '°C';

  @override
  String get removing => 'Removendo...';

  @override
  String get versionLabel => 'Versão:';

  @override
  String get selectBasePath => 'Selecionar caminho base:';

  @override
  String get root => 'Raiz';

  @override
  String get home => 'Início';

  @override
  String get externalDisks => 'Discos externos:';

  @override
  String get selectPathToAnalyze => 'Selecionar um caminho para analisar';

  @override
  String get totalSize => 'Tamanho total';

  @override
  String get files => 'Arquivos';

  @override
  String get directories => 'Diretórios';

  @override
  String get excluded => 'Excluído';

  @override
  String get exclude => 'Excluir';

  @override
  String get include => 'Incluir';

  @override
  String get analyzing => 'Analisando...';

  @override
  String get addExcludedFolder => 'Adicionar Pasta Excluída';

  @override
  String get enterFolderPath =>
      'Digite o caminho da pasta a ser excluída da limpeza:';

  @override
  String get folderPath => 'Caminho da pasta';

  @override
  String get folderExcluded => 'Pasta adicionada às exclusões';

  @override
  String get folderNotFound => 'Pasta não encontrada';

  @override
  String get add => 'Adicionar';

  @override
  String get goBack => 'Voltar';

  @override
  String get goForward => 'Avançar';

  @override
  String get goToRoot => 'Ir para a raiz';

  @override
  String get moveToTrash => 'Mover para a lixeira';

  @override
  String moveToTrashConfirm(String name) {
    return 'Deseja mover \"$name\" para a lixeira?';
  }

  @override
  String get move => 'Mover';

  @override
  String get movedToTrash => 'Movido para a lixeira';

  @override
  String get errorMovingToTrash => 'Erro ao mover para a lixeira';

  @override
  String get deleteFromRootWarning => 'AVISO: Excluir da Root';

  @override
  String deleteFromRootMessage(String name) {
    return 'Você está prestes a excluir \"$name\" do diretório raiz do sistema. Esta operação requer privilégios de administrador e pode ser irreversível. Tem certeza de que deseja continuar?';
  }

  @override
  String get deletePermanently => 'Excluir Permanentemente';

  @override
  String get emptyDirectory => 'Diretório vazio';

  @override
  String get cannotPreviewFile => 'Não é possível visualizar o arquivo';

  @override
  String get fileType => 'Tipo de arquivo';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get directory => 'Diretório';

  @override
  String get file => 'Arquivo';

  @override
  String get rename => 'Renomear';

  @override
  String get newName => 'Novo nome';

  @override
  String get details => 'Detalhes';

  @override
  String get renamedSuccessfully => 'Renomeado com sucesso';

  @override
  String get renameError => 'Erro ao renomear';

  @override
  String get type => 'Tipo';

  @override
  String get permissions => 'Permissões';

  @override
  String get owner => 'Proprietário';

  @override
  String get modified => 'Modificado';

  @override
  String get path => 'Caminho';

  @override
  String get usedSpace => 'Espaço Usado';

  @override
  String get freeSpace => 'Espaço Livre';

  @override
  String get pages => 'Páginas';

  @override
  String get title => 'Título';

  @override
  String get artist => 'Artista';

  @override
  String get duration => 'Duração';

  @override
  String get bitrate => 'Taxa de Bits';

  @override
  String get resolution => 'Resolução';

  @override
  String get codec => 'Codec';

  @override
  String get showSystemFiles => 'Mostrar arquivos do sistema';

  @override
  String get hideSystemFiles => 'Ocultar arquivos do sistema';

  @override
  String appDisabled(String appName) {
    return 'Aplicativo $appName desabilitado';
  }

  @override
  String appDisabledAndProcessesTerminated(String appName) {
    return 'Aplicativo $appName desabilitado e processos encerrados';
  }

  @override
  String terminateProcessesQuestion(int count, String appName) {
    return 'Deseja encerrar $count processo/s de \"$appName\"?';
  }

  @override
  String get totalSpaceToFree => 'Espaço total a liberar:';

  @override
  String get foldersWithErrors => 'Pastas com erros:';

  @override
  String andOthers(int count) {
    return 'e $count outras';
  }

  @override
  String get recoveryDescription =>
      'Esta seção contém ferramentas para restaurar funções do sistema alteradas. Os comandos são adaptados automaticamente com base na distribuição Linux detectada.';

  @override
  String get recoveryRestartPipewire => 'Reiniciar Pipewire';

  @override
  String get recoveryRestartPipewireDesc =>
      'Reinicia os serviços Pipewire, Pipewire-Pulse e Wireplumber para corrigir problemas de áudio.';

  @override
  String get recoveryRestoreNetwork => 'Restaurar Serviços de Rede';

  @override
  String get recoveryRestoreNetworkDesc =>
      'Reinicia os serviços de rede (NetworkManager, systemd-networkd) para corrigir problemas de conexão.';

  @override
  String get recoveryRebuildGrub => 'Reconstruir GRUB';

  @override
  String get recoveryRebuildGrubDesc =>
      'Reconstroi a configuração do GRUB e atualiza o gerenciador de inicialização. Um backup automático é criado.';

  @override
  String get recoveryRestoreFlathub => 'Restaurar Flathub';

  @override
  String get recoveryRestoreFlathubDesc =>
      'Restaura o repositório Flathub para Flatpak e atualiza os metadados dos aplicativos.';

  @override
  String get recoveryRestoreRepos => 'Restaurar Repositórios';

  @override
  String get recoveryRestoreReposDesc =>
      'Atualiza e restaura os repositórios do gerenciador de pacotes (APT, DNF, Pacman) para corrigir problemas de atualização.';

  @override
  String get recoveryCheckUpdates => 'Verificar Atualizações';

  @override
  String get recoveryCheckUpdatesDesc =>
      'Verifica atualizações disponíveis para todos os gerenciadores de pacotes instalados (APT, DNF, Pacman, Snap, Flatpak).';

  @override
  String get recoveryPerformUpdates => 'Realizar Atualizações';

  @override
  String get recoveryPerformUpdatesConfirm =>
      'Deseja realizar as atualizações disponíveis? Esta operação pode levar algum tempo.';

  @override
  String get recoveryTabRecovery => 'Recovery';

  @override
  String get recoveryTabCheckUpdates => 'Verificar atualizações';

  @override
  String get recoveryTabSoftwareInstaller =>
      'Instalador de software do sistema';

  @override
  String get recoverySoftwareInstallerDesc =>
      'Descarrega e instala automaticamente software essencial do sistema.';

  @override
  String get recoveryInstallFfmpeg => 'FFmpeg';

  @override
  String get recoveryInstallFfmpegDesc =>
      'Framework multimédia para codificação/descodificação de áudio e vídeo.';

  @override
  String get recoveryInstallYtDlp => 'yt-dlp';

  @override
  String get recoveryInstallYtDlpDesc =>
      'Descarregador de vídeo para muitos sites.';

  @override
  String get recoveryInstallSystemLibs => 'Bibliotecas do sistema';

  @override
  String get recoveryInstallSystemLibsDesc =>
      'Bibliotecas essenciais que podem corromper-se.';

  @override
  String get recoveryInstallCodecs => 'Codecs de vídeo e áudio';

  @override
  String get recoveryInstallCodecsDesc =>
      'Codecs para formatos de vídeo e áudio comuns.';

  @override
  String get recoveryInstallRsync => 'rsync';

  @override
  String get recoveryInstallRsyncDesc =>
      'Ferramenta eficiente para sincronização e transferência de ficheiros.';

  @override
  String get install => 'Instalar';

  @override
  String get execute => 'Executar';

  @override
  String get viewOutput => 'Ver Saída';

  @override
  String get infoServices => 'Serviços';

  @override
  String get infoServicesAnalysis => 'Análise de serviços do sistema';

  @override
  String get infoServicesAnalysisDesc =>
      'Identifica serviços que retardam a inicialização do sistema usando systemd-analyze blame';

  @override
  String get infoServicesManagement => 'Gerenciamento de serviços';

  @override
  String get infoServicesManagementDesc =>
      'Habilita, desabilita e reinicia serviços do sistema com controle total';

  @override
  String get infoServicesStatus => 'Exibição de status';

  @override
  String get infoServicesStatusDesc =>
      'Mostra o status de todos os serviços (ativos, inativos, falhados)';

  @override
  String get infoStartupApps => 'Apps na Inicialização';

  @override
  String get infoStartupAppsManagement =>
      'Gerenciamento de aplicativos na inicialização';

  @override
  String get infoStartupAppsManagementDesc =>
      'Ver e gerenciar todos os aplicativos que iniciam automaticamente';

  @override
  String get infoStartupAppsProtection => 'Proteção de apps do sistema';

  @override
  String get infoStartupAppsProtectionDesc =>
      'Previne a desativação acidental de aplicativos críticos do sistema';

  @override
  String get infoStartupAppsTermination => 'Encerramento de processos';

  @override
  String get infoStartupAppsTerminationDesc =>
      'Opção para encerrar processos de um app quando desativado';

  @override
  String get infoCleanup => 'Limpeza do Sistema';

  @override
  String get infoCleanupTempFiles => 'Busca de arquivos temporários';

  @override
  String get infoCleanupTempFilesDesc =>
      'Encontra automaticamente arquivos temporários de aplicativos comuns (navegador, IDE, desenvolvimento)';

  @override
  String get infoCleanupCache => 'Limpeza de cache';

  @override
  String get infoCleanupCacheDesc =>
      'Exclui cache do sistema e aplicativos para liberar espaço';

  @override
  String get infoCleanupTrash => 'Gerenciamento de lixeira';

  @override
  String get infoCleanupTrashDesc =>
      'Esvazia a lixeira e limpa arquivos temporários com segurança';

  @override
  String get infoInstalledApps => 'Apps Instaladas';

  @override
  String get infoInstalledAppsManagement =>
      'Gerenciamento de múltiplos pacotes';

  @override
  String get infoInstalledAppsManagementDesc =>
      'Ver apps instaladas via APT, Snap, Flatpak e GNOME';

  @override
  String get infoInstalledAppsDependencies => 'Verificação de dependências';

  @override
  String get infoInstalledAppsDependenciesDesc =>
      'Verifica dependências antes da remoção para evitar problemas';

  @override
  String get infoInstalledAppsWarnings => 'Avisos de segurança';

  @override
  String get infoInstalledAppsWarningsDesc =>
      'Avisa quando um pacote é usado por outro software ou pelo sistema';

  @override
  String get infoMonitor => 'Monitor do Sistema';

  @override
  String get infoMonitorProcesses => 'Monitoramento de processos';

  @override
  String get infoMonitorProcessesDesc =>
      'Ver todos os processos ativos com uso de CPU, memória e disco';

  @override
  String get infoMonitorSorting => 'Ordenação avançada';

  @override
  String get infoMonitorSortingDesc =>
      'Ordena processos por CPU ou memória em ordem crescente ou decrescente';

  @override
  String get infoMonitorTermination => 'Encerramento de processos';

  @override
  String get infoMonitorTerminationDesc =>
      'Encerra processos que não respondem diretamente da interface';

  @override
  String get infoMonitorSystemInfo => 'Informações do sistema';

  @override
  String get infoMonitorSystemInfoDesc =>
      'Mostra detalhes sobre CPU, RAM, discos e placa gráfica';

  @override
  String get infoAppearance => 'Personalização de Aparência';

  @override
  String get infoAppearanceFonts => 'Gerenciamento de fontes';

  @override
  String get infoAppearanceFontsDesc =>
      'Configura fontes para interface, documentos e texto monoespaçado com visualizações';

  @override
  String get infoAppearanceRendering => 'Renderização avançada';

  @override
  String get infoAppearanceRenderingDesc =>
      'Controla hinting, antialiasing e fator de escala';

  @override
  String get infoAppearanceThemes => 'Temas e ícones';

  @override
  String get infoAppearanceThemesDesc =>
      'Personaliza temas de cursor, ícones e aplicativos legados com visualizações';

  @override
  String get infoAppearanceWallpaper => 'Papel de parede';

  @override
  String get infoAppearanceWallpaperDesc =>
      'Define imagens de fundo para tema claro e escuro';

  @override
  String get infoAppearanceWindows => 'Comportamento de janelas';

  @override
  String get infoAppearanceWindowsDesc =>
      'Configura ações de clique, botões da barra de título e foco das janelas';

  @override
  String get infoGrub => 'Editor GRUB (Modo Avançado)';

  @override
  String get infoGrubEditor => 'Editor de configuração GRUB';

  @override
  String get infoGrubEditorDesc =>
      'Edita diretamente o arquivo /etc/default/grub com editor integrado';

  @override
  String get infoGrubBackup => 'Backup automático';

  @override
  String get infoGrubBackupDesc =>
      'Cria backups automáticos antes de cada modificação';

  @override
  String get infoGrubUpdate => 'Atualização do GRUB';

  @override
  String get infoGrubUpdateDesc =>
      'Aplica as alterações e atualiza o gerenciador de inicialização';

  @override
  String get infoGrubRestore => 'Restauração de backup';

  @override
  String get infoGrubRestoreDesc =>
      'Restaura facilmente uma configuração anterior';

  @override
  String get infoKernel => 'Gerenciamento de Kernel (Modo Avançado)';

  @override
  String get infoKernelList => 'Lista de kernels instalados';

  @override
  String get infoKernelListDesc =>
      'Ver todos os kernels instalados com versão e tamanho';

  @override
  String get infoKernelRemoval => 'Remoção de kernel';

  @override
  String get infoKernelRemovalDesc =>
      'Remove kernels antigos com segurança (protege o kernel atual)';

  @override
  String get infoKernelDefault => 'Configuração de kernel padrão';

  @override
  String get infoKernelDefaultDesc =>
      'Escolhe qual kernel inicializar por padrão';

  @override
  String get infoKernelCleanup => 'Limpeza automática';

  @override
  String get infoKernelCleanupDesc =>
      'Mantém apenas um número especificado de kernels mais recentes';

  @override
  String get infoSecurity => 'Segurança';

  @override
  String get infoSecurityPassword => 'Gerenciamento de senhas';

  @override
  String get infoSecurityPasswordDesc =>
      'Salva a senha do administrador com segurança para operações sudo';

  @override
  String get infoSecurityWarning => 'Aviso para usuários experientes';

  @override
  String get infoSecurityWarningDesc =>
      'Tela de aviso inicial para usuários experientes';

  @override
  String get infoSecurityMode => 'Modo Padrão/Avançado';

  @override
  String get infoSecurityModeDesc =>
      'Separa funcionalidades básicas das avançadas (GRUB, Kernel)';

  @override
  String get recoveryCheckUpdatesComplete => 'Busca de atualizações concluída';

  @override
  String recoveryCheckUpdatesError(String error) {
    return 'Erro durante a busca de atualizações: $error';
  }

  @override
  String get diskAnalyzerMainDirectories => 'Diretórios Principais';

  @override
  String get hardwareSuggestionsTitle => 'Sugestões GRUB baseadas em Hardware';

  @override
  String get hardwareSuggestionsDescription =>
      'As seguintes sugestões são baseadas na análise da sua configuração de hardware:';

  @override
  String get hardwareSuggestionsPriorityHigh => 'Alta';

  @override
  String get hardwareSuggestionsPriorityMedium => 'Média';

  @override
  String get hardwareSuggestionsPriorityLow => 'Baixa';

  @override
  String get hardwareSuggestionsApply => 'Aplicar';

  @override
  String get hardwareSuggestionsCancel => 'Cancelar';

  @override
  String get settingsPasswordSecurityMessage =>
      'A senha é salva com segurança usando o keyring do sistema.';

  @override
  String get tabShutdownScheduler => 'Desligamento Automático';

  @override
  String get shutdownInfoTitle => 'Desligamento Automático';

  @override
  String get shutdownInfoDescription =>
      'Configure o desligamento automático do PC em horários programados. Usa temporizadores systemd para garantir compatibilidade com todas as distribuições Linux modernas.';

  @override
  String get shutdownSystemdRequired => 'systemd Necessário';

  @override
  String get shutdownSystemdRequiredDesc =>
      'Esta funcionalidade requer systemd, disponível no Fedora, Ubuntu, Arch, Debian e outras distribuições Linux modernas.';

  @override
  String get shutdownPasswordRequired =>
      'Senha necessária. Configure a senha nas configurações.';

  @override
  String get shutdownActiveTimers => 'Temporizadores Ativos';

  @override
  String get shutdownCreateTimer => 'Criar Novo Temporizador';

  @override
  String get shutdownScheduleType => 'Tipo de Agendamento';

  @override
  String get shutdownScheduleDaily => 'Diária';

  @override
  String get shutdownScheduleWeekly => 'Semanal';

  @override
  String get shutdownScheduleMonthly => 'Mensal';

  @override
  String get shutdownTime => 'Hora';

  @override
  String get shutdownSelectTime => 'Selecionar Hora';

  @override
  String get shutdownSelectDays => 'Selecionar Dias';

  @override
  String get shutdownSelectDayOfMonth => 'Selecionar Dia do Mês';

  @override
  String get shutdownDayOfMonth => 'Dia do Mês';

  @override
  String get shutdownDaySunday => 'Domingo';

  @override
  String get shutdownDayMonday => 'Segunda-feira';

  @override
  String get shutdownDayTuesday => 'Terça-feira';

  @override
  String get shutdownDayWednesday => 'Quarta-feira';

  @override
  String get shutdownDayThursday => 'Quinta-feira';

  @override
  String get shutdownDayFriday => 'Sexta-feira';

  @override
  String get shutdownDaySaturday => 'Sábado';

  @override
  String get shutdownTimerCreated =>
      'Temporizador de desligamento criado com sucesso';

  @override
  String get shutdownTimerRemoved =>
      'Temporizador de desligamento removido com sucesso';

  @override
  String get shutdownRemoveConfirm =>
      'Deseja remover este temporizador de desligamento?';

  @override
  String get shutdownNextRun => 'Próxima execução';

  @override
  String get shutdownStatusInactive => 'Inativo';

  @override
  String get shutdownWeeklyDaysRequired =>
      'Selecione pelo menos um dia da semana';

  @override
  String get shutdownMonthlyDayRequired => 'Selecione um dia do mês';

  @override
  String get shutdownOpenSettings => 'Abrir Configurações';

  @override
  String get shutdownEditTimer => 'Editar Temporizador';

  @override
  String get shutdownTimerDetails => 'Detalhes do Temporizador';

  @override
  String get diskCacheGenerating =>
      'Lendo e gerando cache em andamento... (apenas na primeira vez)';

  @override
  String get licenseActivate => 'Ativar versão avançada';

  @override
  String get licenseActivateButton => 'Ativar';

  @override
  String get licenseName => 'Nome';

  @override
  String get licenseSurname => 'Sobrenome';

  @override
  String get licenseEmail => 'E-mail';

  @override
  String get licenseCode => 'Código de licença';

  @override
  String get licenseRequired => 'Este campo é obrigatório';

  @override
  String get licenseActivateSuccess => 'Versão avançada ativada com sucesso.';

  @override
  String get licenseActivateError =>
      'Código inválido. Verifique nome, sobrenome e e-mail.';

  @override
  String get licenseActivatePremium => 'Ativar / Premium';

  @override
  String get licenseActivateCardTitle => 'Ativar versão avançada';

  @override
  String get licenseActivateCardDesc =>
      'A versão Advanced custa 19,99 €. Digite seus dados e o código de licença recebido após o pagamento bem-sucedido para desbloquear GRUB, Kernel e Recovery. Sem um pagamento válido, o aplicativo não pode ser ativado.';
}
