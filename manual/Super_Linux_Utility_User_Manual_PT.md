# Super Linux Utility v2.0.6
# Manual Completo do Usuário — Português

---

## Índice

1. [Introdução](#1-introdução)
2. [Requisitos do Sistema](#2-requisitos-do-sistema)
3. [Instalação](#3-instalação)
4. [Primeira Inicialização](#4-primeira-inicialização)
5. [Modo Padrão — Todos os Recursos](#5-modo-padrão)
   - 5.1 Serviços
   - 5.2 Aplicativos de Inicialização
   - 5.3 Limpeza
   - 5.4 Aplicativos Instalados
   - 5.5 Monitor do Sistema
   - 5.6 Analisador de Disco
   - 5.7 Saúde do Disco SMART
   - 5.8 Gerenciador de Dispositivos
   - 5.9 Recuperação
   - 5.10 Ajustes
   - 5.11 Configurações
   - 5.12 Informações
6. [Modo Avançado — Recursos Adicionais](#6-modo-avançado)
   - 6.1 Editor GRUB
   - 6.2 Benchmark
7. [Bandeja do Sistema](#7-bandeja-do-sistema)
8. [Atualizações Automáticas](#8-atualizações-automáticas)
9. [Solução de Problemas](#9-solução-de-problemas)
10. [Perguntas Frequentes](#10-faq)
11. [Glossário](#11-glossário)

---

## 1. Introdução

**Super Linux Utility** é um aplicativo abrangente de gerenciamento de sistemas para Linux. Ele fornece uma interface gráfica moderna para gerenciar serviços, aplicativos de inicialização, limpar arquivos temporários, monitorar o desempenho do sistema, analisar discos, gerenciar dispositivos de hardware e muito mais.

O aplicativo é disponível em duas edições:

- **Padrão (Gratuita):** Todas as ferramentas essenciais de gerenciamento de sistemas — serviços, aplicativos de inicialização, limpeza, aplicativos instalados, monitor, analisador de disco, saúde SMART, gerenciador de dispositivos, recuperação, ajustes e configurações.
- **Avançada (Pago):** Tudo do Padrão, além do editor GRUB e suíte de Benchmark.

**Distribuições suportadas:** Ubuntu, Debian, Linux Mint, LMDE, Pop!_OS, Zorin, elementary, MX Linux, Fedora, RHEL, CentOS, Arch Linux, Manjaro, EndeavourOS, CachyOS, KDE neon.

**Ambientes de desktop suportados:** GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt.

---

## 2. Requisitos do Sistema

- **SO:** Linux (64 bits)
- **Espaço em disco:** ~200 MB instalado
- **RAM:** 512 MB mínimo, 2 GB recomendado
- **Dependências:** GTK3, GLib 2.0+
- **Opcional:** `libappindicator` para bandeja do sistema, `smartmontools` para saúde do disco SMART

---

## 3. Instalação

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

### A partir do código fonte
```bash
git clone https://github.com/sviluppoarte1-lang/superlinuxutility.git
cd superlinuxutility
flutter build linux
```

---

## 4. Primeira Inicialização

Quando você abre o Super Linux Utility pela primeira vez, três telas de configuração aparecem em sequência:

### 4.1 Seleção de Idioma
Escolha seu idioma preferido entre: Italiano, Inglês, Francês, Espanhol, Alemão, Português. O idioma selecionado se aplica a todos os botões, menus, mensagens e descrições em todo o aplicativo.

### 4.2 Tela de Aviso
Um aviso lembra que este aplicativo pode modificar configurações críticas do sistema (carregador de inicialização GRUB, kernel, serviços). É altamente recomendado criar um backup do sistema antes de usar recursos avançados. Marque "Não mostrar este aviso novamente" para pulá-lo nas inicializações futuras.

### 4.3 Configuração de Senha
Para usar recursos que modificam o sistema (limpeza, gerenciamento de serviços, edição do GRUB, etc.), o aplicativo precisa da sua senha de administrador (sudo). A senha é armazenada de forma segura usando o chaveiro do sistema. Você pode pular esta etapa e configurá-la depois nas Configurações.

> **Dica para iniciantes:** Se você não tem certeza se deve inserir sua senha, pode pular. A maioria dos recursos somente leitura (monitor, analisador de disco, SMART) funciona sem senha.

---

## 5. Modo Padrão — Todos os Recursos

O modo padrão fornece 12 abas acessíveis pela barra lateral esquerda. Cada aba contém ferramentas específicas.

---

### 5.1 Serviços

**Objetivo:** Visualizar e gerenciar serviços systemd que são executados no seu sistema.

**Abas:**
- **Serviços Lentos:** Lista serviços que demoram mais de 2 segundos para iniciar (detectados via `systemd-analyze blame`). Isso ajuda a identificar o que desacelera sua inicialização.
- **Todos os Serviços:** Lista completa de todos os serviços systemd com seu status (ativo, inativo, com falha). Toque em "Analisar Todos" para carregar a lista completa.
- **Desativados:** Mostra todos os serviços que estão atualmente desativados.

**Ações por serviço (toque no menu de três pontos):**
- **Desativar:** Impede que o serviço inicie na inicialização do sistema.
- **Reativar:** Permite que o serviço inicie novamente na inicialização do sistema.
- **Parar:** Para imediatamente um serviço em execução.

> **Aviso para iniciantes:** Não desative serviços que você não reconhece. Alguns serviços são essenciais para o funcionamento correto do seu sistema (ex.: NetworkManager, PulseAudio, systemd-resolved). Em caso de dúvida, deixe o serviço ativado.

> **Dica para especialistas:** Use a aba "Serviços Lentos" para otimizar o tempo de inicialização. Serviços como `snapd`, `plymouth` ou `fwupd` podem geralmente ser desativados com segurança se você não os utiliza.

**Requer senha:** Sim (para operações de desativar/reativar/parar)

---

### 5.2 Aplicativos de Inicialização

**Objetivo:** Gerenciar aplicativos que iniciam automaticamente quando você faz login.

A lista mostra todas as entradas de inicialização automática divididas nas seções **Ativados** e **Desativados**. Cada entrada exibe o nome do aplicativo, o comando e se é um aplicativo do sistema ou do usuário.

**Ações por aplicativo (toque no menu de três pontos):**
- **Desativar:** Impede que o aplicativo inicie no login. Se o aplicativo estiver em execução, você será perguntado se também deseja encerrar seus processos.
- **Reativar:** Reativa um aplicativo de inicialização desativado.
- **Encerrar Processos:** Encerra todos os processos em execução daquele aplicativo.
- **Remover:** Exclui permanentemente a entrada de inicialização automática.

**Proteção de aplicativos do sistema:** Alguns aplicativos (como GNOME Shell, NetworkManager, componentes do KDE Plasma) são marcados como protegidos e não podem ser desativados. Isso evita danos acidentais ao seu ambiente de desktop.

> **Dica para iniciantes:** Se você notar que seu computador demora para iniciar, verifique a aba de Aplicativos de Inicialização. Desativar aplicativos desnecessários (como clientes de armazenamento em nuvem ou aplicativos de bate-papo que você não usa na inicialização) pode acelerar significativamente o login.

> **Dica para especialistas:** O aplicativo cria substituições a nível de usuário para entradas de inicialização automática do sistema em `/etc/xdg/autostart/` em vez de modificar arquivos do sistema. Isso é seguro e reversível.

**Requer senha:** Não

---

### 5.3 Limpeza

**Objetivo:** Liberar espaço em disco removendo arquivos temporários, caches e limpando a cache de páginas do Linux.

**Linha de botões:**
- **Atualizar Dimensões:** Recalcula o tamanho de todas as pastas temporárias/cache detectadas.
- **Limpar Arquivos Temporários (botão laranja):** Exclui arquivos temporários de todas as pastas listadas. Um diálogo de confirmação aparece antes da exclusão. Você pode excluir pastas específicas tocando no ícone de alternância ao lado de cada pasta.

**Cache de Páginas do Linux:**
- **Botão Limpar Cache:** Libera a cache de páginas do kernel executando `sync && echo 1 > /proc/sys/vm/drop_caches`. Isso é seguro e não exclui nenhum dado do usuário — apenas limpa as leituras de arquivos em cache da RAM.

**Limpar RAM:**
- Mostra o uso atual da RAM (usada / total / porcentagem).
- **Botão Limpar RAM:** Limpa a cache de páginas, dentries e inodes executando `sync && echo 3 > /proc/sys/vm/drop_caches`. Isso libera mais memória do que a limpeza básica de cache. Mostra quanta memória foi liberada após a operação.

**Limpeza Automática da RAM:**
- Configure em **Configurações > Limpeza da RAM** para limpar automaticamente a RAM em intervalos: Nunca, 5 min, 10 min, 15 min ou 30 min.
- Executa em segundo plano no intervalo configurado.

**Adicionar Pasta Excluída:** Adicione pastas personalizadas para excluir da limpeza. Útil para preservar diretórios de cache de aplicativos específicos.

> **Dica para iniciantes:** Use "Limpar Arquivos Temporários" regularmente para liberar espaço em disco. Os botões "Limpar Cache" e "Limpar RAM" são seguros — não excluem nenhum arquivo pessoal.

> **Dica para especialistas:** O limpeador de RAM usa `echo 3` (descarta cache de páginas + dentries + inodes), que é mais agressivo que `echo 1` (somente cache de páginas). Use quando precisar recuperar memória rapidamente, por exemplo, antes de iniciar um aplicativo que consome muita memória.

**Requer senha:** Sim (para limpeza de cache e RAM)

---

### 5.4 Aplicativos Instalados

**Objetivo:** Visualizar e desinstalar aplicativos de todos os gerenciadores de pacotes.

**Gerenciadores de pacotes suportados:**
- **APT** (Debian/Ubuntu/Mint)
- **Snap** (Pacotes universais para Linux)
- **Flatpak** (Aplicativos em sandbox)
- **GNOME** (Aplicativos de desktop via arquivos .desktop)

**Recursos:**
- **Pesquisa:** Filtre aplicativos por nome ou descrição.
- **Filtros:** Alterne entre visualizações Todos, APT, Snap, Flatpak, GNOME.
- **Desinstalação por aplicativo:** Toque no menu de três pontos e selecione "Remover". O aplicativo verifica dependências primeiro — se outros pacotes dependem do que você deseja remover, um diálogo de aviso mostra a lista.

> **Aviso para iniciantes:** Tenha cuidado ao desinstalar pacotes do sistema. Se você não tem certeza, pesquise na internet o nome do pacote primeiro.

> **Dica para especialistas:** A verificação de dependências usa `apt-cache depends` e `apt-cache rdepends --installed` para mostrar dependências diretas e inversas.

**Requer senha:** Sim (para remoção de pacotes)

---

### 5.5 Monitor do Sistema

**Objetivo:** Monitoramento em tempo real de processos, CPU, RAM, disco e GPU.

Esta tela tem três sub-abas:

#### Aba de Processos
- Exibe todos os processos em execução agrupados por nome de aplicativo.
- **Colunas:** Nome do App, CPU%, Memória — toque no cabeçalho de uma coluna para ordenar.
- **Medidores de CPU/RAM/GPU** no lado direito mostram o uso em tempo real.
- **Ações por grupo:** Selecionar todos, Encerrar todos, Forçar encerramento de todos.
- **Modo de seleção múltipla:** Marque vários grupos de processos e depois encerre-os todos de uma vez.
- Atualização automática a cada 5 segundos.

#### Aba de Sistema
Mostra informações de hardware no formato de cartão:
- **CPU:** Modelo, núcleos, threads, barra de uso, velocidade do clock.
- **Memória:** Total, usada, livre, em cache, uso de swap.
- **Disco:** Nome do dispositivo por disco, sistema de arquivos, barra de uso.
- **GPU:** Modelo, driver, porcentagem de uso, memória, temperatura (se disponível).
- **Servidor de Exibição:** Detecção Wayland/X11/XWayland, ambiente de desktop, variáveis de ambiente importantes.

#### Aba de Status
Painel de status do sistema somente leitura com quatro seções:
- **Kernel:** Versão, informações de compilação, modo THP, zswap, governor, agendador de E/S.
- **Security:** Status do AppArmor, SELinux, Secure Boot, firewall, SSH, atualizações automáticas.
- **Virtualização:** Suporte de virtualização de CPU, KVM, IOMMU, VFIO, KSM, Docker, libvirt.
- **Impressoras:** Status do serviço CUPS, impressoras instaladas, drivers de impressão.

> **Dica para iniciantes:** A aba de Processos ajuda a encontrar qual aplicativo está usando muita CPU ou memória. Toque em um grupo de processos para ver os processos individuais.

> **Dica para especialistas:** A aba de Status fornece uma auditoria rápida de segurança e virtualização. Verifique o status do firewall, SSH e Secure Boot de uma vez.

**Requer senha:** Não

---

### 5.6 Analisador de Disco

**Objetivo:** Navegar pelo seu sistema de arquivos, visualizar o uso do disco e gerenciar arquivos.

**Navegação:**
- **Home / Sistema de Arquivos / Discos externos:** Seleção rápida de caminhos base.
- **Voltar / Avançar:** Navegue pelo histórico.
- **Ordenar:** Por tamanho (crescente/decrescente) ou alfabeticamente.
- **Mais:** Alterne a visibilidade de arquivos ocultos/sistema.

**Recursos:**
- **Gráfico de pizza:** Visualiza a distribuição do tamanho dos diretórios.
- **Aviso da primeira análise:** Quando um disco é analisado pela primeira vez, um aviso informativo aparece informando que a indexação está em andamento e a primeira análise pode levar algum tempo.
- **Ações de arquivo/diretório:**
  - **Mover para Lixeira:** Exclusão segura para a lixeira (com confirmação).
  - **Renomear:** Renomear arquivos ou diretórios.
  - **Mostrar Detalhes:** Visualizar caminho, tamanho, tipo, permissões, proprietário, data de modificação.

> **Aviso:** Excluir arquivos do sistema de arquivos raiz (`/`) requer privilégios de administrador e é irreversível. Tenha muito cuidado.

> **Dica para iniciantes:** Comece analisando seu diretório home para encontrar pastas grandes que ocupam espaço (ex.: `~/.cache`, `~/.local/share/Trash`).

**Requer senha:** Sim (para exclusão de caminhos raiz)

---

### 5.7 Saúde do Disco SMART

**Objetivo:** Monitorar a saúde de discos rígidos e SSDs usando dados S.M.A.R.T.

**Recursos:**
- **Seletor de disco:** Escolha qual disco inspecionar no menu suspenso.
- **Status de saúde:** Mostra PASSOU ou FALHOU com temperatura e horas ligado.
- **Detecção USB:** Identifica discos conectados via USB e avisa que conversores USB-SATA podem limitar os dados SMART.
- **Tabela de atributos:** Exibe todos os atributos SMART (ID, nome, valor, pior, limite, bruto). Atributos com falha são destacados em vermelho.
- **Auto-testes:**
  - **Teste Curto:** Verificação rápida (~2 minutos).
  - **Teste Estendido:** Verificação completa (pode levar horas dependendo do tamanho do disco).
  Os resultados aparecem na tabela de atributos após a conclusão do teste.

**Se smartctl não estiver instalado:** O aplicativo oferece instalar `smartmontools` automaticamente.

> **Dica para iniciantes:** Verifique a saúde do seu disco mensalmente. Um status "FALHOU" ou atributos marcados em vermelho indicam que o disco pode precisar de substituição em breve.

> **Dica para especialistas:** O aplicativo suporta varredura multi-distribuição (lsblk + smartctl --scan + fallback /sys/block/). Conversores USB-SATA são testados com `smartctl -d sat`.

**Requer senha:** Sim (para instalar smartctl e executar auto-testes)

---

### 5.8 Gerenciador de Dispositivos

**Objetivo:** Visualizar, ativar e desativar dispositivos de hardware — similar ao Gerenciador de Dispositivos do Windows.

**Recursos:**
- **Árvore de dispositivos:** Todos os dispositivos de hardware (PCI, USB, bloco, rede) agrupados por categoria: Placas de vídeo, Placas de rede, Som/vídeo, Controladores USB, Armazenamento, Processador, Dispositivos de entrada, Multimídia.
- **Barra de pesquisa:** Filtre dispositivos por nome ou descrição.
- **Filtro mostrar desativados:** Alterne para mostrar apenas dispositivos desativados.

**Ações por dispositivo (toque para expandir, depois menu de três pontos):**
- **Ativar/Desativar:** Alterne o estado do dispositivo com diálogo de confirmação. Requer senha sudo.
- **Painel de propriedades:** Mostra informações detalhadas — status, tipo de barramento, fabricante, driver, IDs de fabricante/dispositivo.

**Proteção de dispositivos:** Dispositivos críticos (Host bridge, PCI bridge, ISA bridge, IOMMU, SMBus, Processador) não podem ser desativados para evitar instabilidade do sistema.

**Persistência:** Dispositivos desativados são salvos em `/etc/slu_disabled_devices.conf` e um serviço systemd é criado para reaplicar a desativação a cada inicialização. Isso garante que suas configurações persistam após reinicializações.

> **Aviso para iniciantes:** Não desative dispositivos que você não reconhece. Desativar uma placa de rede desconectará você da internet. Desativar uma placa de vídeo pode travar seu desktop.

> **Dica para especialistas:** O mecanismo de persistência usa sysfs (`echo 0 > enable` para PCI, `echo 0 > authorized` para USB, `ip link set X down` para rede) com um serviço systemd.

**Requer senha:** Sim (para operações de ativar/desativar)

---

### 5.9 Recuperação

**Objetivo:** Restaurar funções do sistema alteradas, verificar atualizações e instalar software.

#### Operações de Recuperação
| Operação | Descrição |
|----------|-----------|
| **Reiniciar Pipewire** | Reinicia PipeWire, PipeWire-Pulse e Wireplumber para corrigir problemas de áudio. |
| **Restaurar Rede** | Reinicia NetworkManager ou systemd-networkd para corrigir problemas de conexão. |
| **Reconstruir GRUB** | Executa `update-grub` para regenerar a configuração do carregador de inicialização. |
| **Restaurar Flathub** | Recompõe o repositório remoto Flathub para Flatpak. |
| **Restaurar Repositórios** | Atualiza e restaura repositórios de pacotes para sua distribuição. |
| **Corrigir Auto-Suspensão WiFi** | Desativa a auto-suspensão USB para adaptadores WiFi para evitar desconexões aleatórias. |

Cada operação exibe um botão "Ver Saída" para inspecionar a saída do comando.

#### Aba de Verificar Atualizações
- **Verificar Atualizações:** Executa o comando apropriado de atualização do gerenciador de pacotes (`apt update`, `dnf check-update`, `pacman -Sy`).
- Os resultados mostram atualizações disponíveis por gerenciador de pacotes (APT, DNF, Pacman, Snap, Flatpak).
- **Aplicar Atualizações:** Baixa e instala todas as atualizações disponíveis com progresso em tempo real.

#### Aba Instalador de Software
Instaladores de clique único para software essencial:
- **FFmpeg:** Framework multimídia para codificação/decodificação de áudio e vídeo.
- **yt-dlp:** Baixador de vídeos suportando muitos sites.
- **Bibliotecas do Sistema:** Bibliotecas essenciais do sistema que podem estar faltando.
- **Codecs:** Codecs de vídeo e áudio para formatos comuns.
- **rsync:** Ferramenta eficiente de sincronização e transferência de arquivos.

**Requer senha:** Sim

---

### 5.10 Ajustes

**Objetivo:** Ajuste de desempenho do sistema para swap e DaVinci Resolve.

#### Aba Swap
- Mostra informações atuais do swap: tamanho da RAM, swap total/usado, valor de swappiness, dispositivo de swap.
- Fornece recomendações baseadas na sua configuração:
  - Criar um arquivo de swap se não existir.
  - Ajustar o valor de swappiness.
  - Ativar ou desativar zram.
- Cada recomendação tem um botão "Executar" que aplica a mudança sugerida.

#### Aba DaVinci Resolve
- Aplica correções comuns do Linux para o Blackmagic DaVinci Resolve:
  - Corrigir caminhos das bibliotecas CUDA.
  - Definir permissões corretas da GPU.
  - Instalar dependências faltantes.
- Cada correção mostra se requer reinicialização e se já foi aplicada.

> **Dica para iniciantes:** Se você usa DaVinci Resolve no Linux e tem problemas com a GPU, vá até esta aba e aplique todas as correções.

> **Dica para especialistas:** As recomendações de swap analisam seu `/proc/meminfo` e configuração de swap para fornecer as sugestões mais adequadas.

**Requer senha:** Sim

---

### 5.11 Configurações

Configure preferências globais do aplicativo:

#### Senha
- Salve, atualize ou exclua sua senha de administrador.
- A senha é armazenada usando o chaveiro do sistema (codificada em base64 no SharedPreferences).

#### Idioma
- Selecione entre 6 idiomas: Italiano, Inglês, Francês, Espanhol, Alemão, Português.
- As mudanças entram em vigor após reiniciar o aplicativo.

#### Tema
- **Claro / Escuro / Sistema:** Escolha o esquema de cores do aplicativo.
- "Sistema" segue a configuração de tema do seu ambiente de desktop.

#### Fonte
- **Família da Fonte:** Selecione entre as fontes disponíveis no sistema.
- **Tamanho da Fonte:** Deslizador de 10sp a 24sp.

#### Bandeja do Sistema (apenas Linux)
- **Ativar Bandeja do Sistema:** Mostrar/ocultar o ícone do aplicativo na bandeja do sistema.
- **Fechar na Bandeja:** Manter o aplicativo em execução na bandeja quando você fechar a janela.
- **Iniciar Minimizado:** Iniciar o aplicativo minimizado na bandeja.
- **Iniciar no Login:** Iniciar automaticamente o aplicativo quando você faz login (usa inicialização automática XDG).
- **Instalar Dependências:** Instala `libayatana-appindicator` se estiver faltando.

#### Verificação Automática de Atualização
- Configure com frequência o aplicativo verifica atualizações do sistema (Nunca, 15 min, 30 min, 1 hr, 6 hr, 12 hr, diariamente).
- **Atualização automática do GitHub:** Baixa e instala automaticamente o mais recente `.deb` das versões do GitHub.

#### Limpeza da RAM
- Defina um intervalo automático para limpar a cache de páginas do Linux e a RAM: **Nunca**, **5 minutos**, **10 minutos**, **15 minutos**, **30 minutos**.
- Executa em segundo plano no intervalo configurado.

#### Agendador de Desligamento
- Abre a tela de temporizador de desligamento automático (veja Seção 7).

---

### 5.12 Informações

**Objetivo:** Tela Sobre com informações do aplicativo.

- Versão do aplicativo, criador e descrição.
- Lista de recursos organizada por categoria.
- Licença e aviso legal (GPL).
- **Botão Ativar Licença** (apenas versão Avançada): Insira sua chave de licença para desbloquear recursos avançados.
- **Botão PayPal** (apenas versão Avançada): Compre uma licença por 19,99 EUR.
- Link do site do projeto.

---

## 6. Modo Avançado — Recursos Adicionais

O modo avançado desbloqueia 2 abas adicionais e estende a tela existente de Ajustes. Requer uma chave de licença comprada (ou versão Pessoal/Teste).

Para alternar entre o modo Padrão e Avançado, use os botões de modo na área superior direita da barra lateral.

---

### 6.1 Editor GRUB

**Objetivo:** Editar a configuração do carregador de inicialização GRUB com segurança.

**Recursos:**
- **Editor de texto:** Edite diretamente `/etc/default/grub` em um editor de texto integrado.
- **Salvar e Atualizar:** Salva a configuração, cria um backup automático e executa `update-grub` (ou equivalente para sua distribuição).
- **Sugestões de Hardware:** Analisa seu hardware e sugere parâmetros do kernel:
  - NVIDIA modeset, iommu, threadirqs, zswap, elevador, etc.
  - Cada sugestão tem um selo de prioridade (alta/média/baixa).
  - Toque em "Aplicar" para inserir a sugestão no editor.
- **Restaurar Backup:** Reverte para o último backup se algo der errado.
- **Indicador de alterações não salvas:** Um banner laranja aparece quando você tem modificações não salvas.

**Comandos de reconstrução do GRUB por distribuição:**
- Debian/Ubuntu: `update-grub`
- Fedora: `grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
- Arch: `grub-mkconfig -o /boot/grub/grub.cfg`

> **Aviso:** Modificações incorretas no GRUB podem impedir que seu sistema inicie. Sempre mantenha um backup. Se seu sistema falhar ao inicializar, use um USB bootável para restaurar `/etc/default/grub` a partir do backup.

**Requer senha:** Sim

---

### 6.2 Benchmark

**Objetivo:** Medir o desempenho do hardware do seu sistema.

Quatro categorias de benchmark:

| Benchmark | O que mede |
|-----------|------------|
| **CPU** | Poder de processamento multi-núcleo e de núcleo único. Resultados comparados com referências de chips Intel, AMD e Apple. |
| **GPU** | Desempenho gráfico usando `glmark2`. Resultados comparados com GPUs de referência NVIDIA e AMD. |
| **Disco** | Velocidade de leitura/escrita sequencial. Resultados comparados com referências NVMe, SSD e HDD. |
| **Rede** | Teste de velocidade da internet. Resultados comparados com velocidades de rede de referência. |

Cada benchmark mostra:
- Sua pontuação.
- O hardware de referência mais próximo.
- Uma classificação (Excelente, Bom, Médio, Abaixo da Média, Ruim).

> **Dica:** Execute benchmarks após mudanças no sistema (novo kernel, novos drivers) para ver se o desempenho melhorou.

**Requer senha:** Não

---

## 7. Bandeja do Sistema

Quando ativado nas Configurações, o Super Linux Utility coloca um ícone na bandeja do sistema (área de notificação). Clique com o botão direito no ícone para acessar:

| Item do Menu | Ação |
|--------------|------|
| **Mostrar janela principal** | Traz a janela do aplicativo para o primeiro plano. |
| **Verificar atualizações** | Abre o diálogo de verificação de atualizações. |
| **Limpar arquivos temporários e cache** | Navega para a aba de Limpeza. |
| **Temperatura da CPU, GPU** | Navega para a aba de Monitor. |
| **Uso do disco** | Navega para a aba de Analisador de Disco. |
| **Uso da memória** | Mostra o uso atual da RAM. |
| **Saúde do disco (SMART)** | Navega para a aba SMART. |
| **Desligamento automático** | Abre o diálogo de temporizador de desligamento. |
| **Uso de CPU, GPU** | Abre um diálogo de gerenciador de tarefas. |
| **Sair** | Fecha o aplicativo. |

A dica do ícone da bandeja mostra a temperatura da CPU/GPU e o uso da memória em tempo real.

---

## 8. Atualizações Automáticas

### Verificação de Atualização do Sistema
Configurável em Configurações > Verificação Automática de Atualização. Quando ativado, o aplicativo periodicamente verifica atualizações em todos os gerenciador de pacotes instalados (APT, DNF, Pacman, Snap, Flatpak). As notificações de atualização aparecem como diálogos com caixas de seleção por pacote.

### Auto-atualização do Aplicativo
Quando ativado em Configurações > Atualização automática do GitHub, o aplicativo verifica as versões do GitHub para pacotes `.deb` mais recentes correspondentes à sua edição (Padrão/Avançada). Baixa e instala automaticamente usando `sudo dpkg -i`.

---

## 9. Solução de Problemas

### Erro "Senha não salva"
Vá até Configurações > Senha e insira novamente sua senha sudo. A senha é armazenada no chaveiro do sistema.

### Aba SMART não mostra discos
Instale `smartmontools`: o aplicativo oferecerá fazer isso automaticamente. Se estiver usando um adaptador USB-SATA, os dados SMART podem ser limitados.

### Alterações do GRUB não aplicadas (modo Avançado)
Certifique-se de tocar em "Salvar e Atualizar" (não apenas "Salvar"). O aplicativo deve executar `update-grub` com privilégios de administrador.

### Ícone da bandeja do sistema não visível
Instale a dependência necessária: `sudo apt install libayatana-appindicator-3-dev`. Em seguida, reinicie o aplicativo.

### AppImage não inicia
O AppImage usa um runtime estático e deve funcionar sem FUSE. Se ainda falhar:
```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./super-linux-utility-*.AppImage
```

### Gerenciador de Dispositivos não pode desativar um dispositivo
Alguns dispositivos são protegidos porque desativá-los travaria o sistema. O aplicativo exibe uma mensagem quando um dispositivo não pode ser desativado.

---

## 10. FAQ

**P: É seguro usar este aplicativo?**
R: Os recursos do modo padrão são seguros para todos os usuários. O modo avançado modifica o GRUB — sempre crie um backup antes de usar recursos do GRUB.

**P: O aplicativo envia dados para algum lugar?**
R: Não. O aplicativo não coleta ou transmite nenhum dado do usuário. As únicas operações de rede são a verificação de atualizções (do GitHub ou do seu gerenciador de pacotes).

**P: Posso usar o aplicativo no Fedora/Arch?**
R: Sim. O aplicativo detecta automaticamente sua distribuição e adapta todos os comandos conforme necessário (APT, DNF, Pacman).

**P: O que acontece se eu desativar um serviço crítico?**
R: O aplicativo protege os serviços essenciais do ambiente de desktop (GNOME, KDE, etc.) de serem desativados. No entanto, sempre tenha cuidado com serviços desconhecidos.

**P: Como restauro o GRUB se o sistema não iniciar?**
R: Inicie a partir de um USB bootável, monte sua partição raiz e copie `/etc/default/grub.backup` de volta para `/etc/default/grub`. Em seguida, execute `sudo update-grub`.

**P: Posso desativar qualquer dispositivo de hardware?**
R: O Gerenciador de Dispositivos protege dispositivos críticos do sistema (CPU, bridges, IOMMU) de serem desativados. Você pode desativar com segurança periféricos não essenciais como dispositivos USB ou placas de rede secundárias.

---

## 11. Glossário

| Termo | Definição |
|-------|-----------|
| **APT** | Advanced Package Tool — Gerenciador de pacotes Debian/Ubuntu. |
| **Gerenciador de Dispositivos** | Ferramenta para visualizar, ativar e desativar dispositivos de hardware. |
| **DNF** | Dandified YUM — Gerenciador de pacotes Fedora/RHEL. |
| **Flatpak** | Formato de empacotamento de aplicativos em sandbox para Linux. |
| **GRUB** | Grand Unified Bootloader — o programa que carrega o Linux na inicialização. |
| **Kernel** | O núcleo do sistema operacional Linux. |
| **PCI** | Peripheral Component Interconnect — barramento padrão para dispositivos internos. |
| **Pacman** | Gerenciador de pacotes para Arch Linux e derivados. |
| **PipeWire** | Servidor moderno de áudio/vídeo para Linux. |
| **SMART** | Self-Monitoring, Analysis and Reporting Technology — sistema de saúde de discos rígidos. |
| **Snap** | Formato universal de pacotes Linux da Canonical. |
| **systemd** | Sistema de init e gerenciador de serviços para Linux. |
| **systemctl** | Ferramenta de linha de comando para gerenciar serviços systemd. |
| **Swap** | Espaço em disco usado como RAM virtual quando a RAM física está cheia. |
| **sysfs** | Sistema de arquivos virtual que expõe dados de dispositivos do kernel (`/sys/`). |
| **USB** | Universal Serial Bus — padrão para dispositivos externos. |
| **Wayland** | Protocolo moderno de servidor de exibição substituindo o X11. |
| **X11** | Protocolo tradicional de servidor de exibição para Linux. |
| **zram** | Dispositivo de swap baseado em RAM comprimida. |

---

*Super Linux Utility v2.0.6 — Manual do Usuário*
*Criado por Marco Di Giangiacomo*
*Licença: GPL v3*
