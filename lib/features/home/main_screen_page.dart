import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import '../ships/search_ship_page.dart';
import 'home_controller.dart';
import '../suggestions/suggestion_page.dart';
import '../ships/my_ratings_page.dart';
import '../../data/services/version_service.dart';

/// ============================================================================
/// MAIN SCREEN (HOME)
/// ============================================================================
/// Tela principal do aplicativo ShipRate.
///
/// Responsabilidades:
/// ------------------
/// • Gerenciar Drawer de navegação principal
/// • Controlar ciclo de vida do app (foreground/background)
/// • Forçar atualização de dados ao retornar ao app
/// • Exibir banner de atualização quando disponível
/// • Gerenciar navegação entre telas principais
///
/// Sistema de Versionamento:
/// -------------------------
/// • Verifica versão ao abrir app (initState)
/// • Verifica versão ao retornar ao app (resumed)
/// • Compara versão local (localStorage) com remota (Firestore)
/// • Exibe banner azul quando há atualização disponível
/// • Usuário clica OK → banner desaparece
/// • Ao reabrir app → código atualizado aplicado
///
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// ============================================================================
/// MAIN SCREEN STATE
/// ============================================================================
/// State da tela principal com observação de ciclo de vida.
///
/// Implementa [WidgetsBindingObserver] para escutar eventos do sistema:
/// • App voltou para foreground (resumed)
/// • App foi para background (paused)
/// • App foi fechado (detached)
///
class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  /// Controla exibição do banner de atualização
  bool _showUpdateBanner = false;
  
  /// Mensagem personalizada exibida no banner (vem do Firestore)
  String _updateMessage = '';

  /// Chave usada para forçar rebuild completo da árvore de widgets
  /// Útil para limpar caches e recarregar dados do Firestore
  Key _rebuildKey = UniqueKey();

  /// --------------------------------------------------------------------------
  /// Inicialização
  /// --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    // Registra observer para eventos de ciclo de vida
    WidgetsBinding.instance.addObserver(this);

    // Força atualização inicial ao abrir o app
    _forceRefresh();
    
    // Verifica se há atualização disponível
    _checkForUpdates();
  }

  /// --------------------------------------------------------------------------
  /// Limpeza
  /// --------------------------------------------------------------------------
  @override
  void dispose() {
    // Remove observer para evitar memory leaks
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// --------------------------------------------------------------------------
  /// Callback de mudança no ciclo de vida
  /// --------------------------------------------------------------------------
  /// Chamado quando o app muda de estado (resumed, paused, detached).
  ///
  /// Comportamento:
  /// • resumed: App voltou para foreground → força refresh e verifica updates
  /// • paused: App foi para background → sem ação
  /// • detached: App foi fechado → sem ação
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _forceRefresh();
      _checkForUpdates();
    }
  }

  /// --------------------------------------------------------------------------
  /// Força atualização completa dos dados
  /// --------------------------------------------------------------------------
  /// Gera nova Key para forçar rebuild completo do KeyedSubtree.
  /// Isso limpa caches e força recarregamento de dados do Firestore.
  ///
  /// Chamado:
  /// • Automaticamente ao abrir app
  /// • Automaticamente ao retornar ao app (resumed)
  /// • Manualmente quando necessário
  Future<void> _forceRefresh() async {
    if (!mounted) return;

    setState(() {
      _rebuildKey = UniqueKey();
    });
  }

  /// --------------------------------------------------------------------------
  /// Verifica se há atualização disponível
  /// --------------------------------------------------------------------------
  /// Consulta VersionService que compara versão local com remota (Firestore).
  /// Se houver diferença e usuário ainda não viu banner, exibe banner azul.
  Future<void> _checkForUpdates() async {
    final result = await VersionService.shouldShowUpdateBanner();
    
    if (!mounted) return;

    if (result['shouldShow'] == true) {
      setState(() {
        _showUpdateBanner = true;
        _updateMessage = result['message'] ?? 
            'Nova atualização disponível. Por favor, feche e reabra o app.';
      });
    }
  }

  /// --------------------------------------------------------------------------
  /// Realiza logout do usuário
  /// --------------------------------------------------------------------------
  /// Fluxo de execução:
  /// 1. Chama logout via MainScreenController (Firebase Auth)
  /// 2. Remove todas as telas da pilha de navegação
  /// 3. Navega para LoginPage como nova root
  ///
  /// Usa pushAndRemoveUntil para limpar pilha de navegação completamente,
  /// prevenindo que usuário volte à tela principal após logout.
  Future<void> _handleLogout() async {
    final controller = MainScreenController();
    await controller.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  /// --------------------------------------------------------------------------
  /// Constrói banner de atualização
  /// --------------------------------------------------------------------------
  /// Banner azul exibido no topo da tela quando há atualização disponível.
  /// 
  /// Comportamento:
  /// • Invisível quando _showUpdateBanner = false
  /// • Visível com mensagem personalizada quando há update
  /// • Botão OK marca banner como visto e esconde
  /// 
  /// Design:
  /// • Gradiente azul
  /// • Ícone de atualização
  /// • Mensagem em duas linhas
  /// • Botão OK alinhado à direita
  Widget _buildUpdateBanner() {
    if (!_showUpdateBanner) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade600,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.system_update,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atualização Disponível',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _updateMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await VersionService.markBannerAsSeen();
              setState(() => _showUpdateBanner = false);
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// Build principal
  /// --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// -----------------------------------------------------------------------
      /// AppBar
      /// -----------------------------------------------------------------------
      appBar: AppBar(
        title: const Text(
          'ShipRate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      /// -----------------------------------------------------------------------
      /// Drawer de navegação principal
      /// -----------------------------------------------------------------------
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header do drawer com identidade visual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3F51B5),
                      Color(0xFF2F3E9E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.directions_boat_filled,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'ShipRate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Avaliação profissional de navios',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Navegação: Buscar / Avaliar Navios
              _buildDrawerItem(
                icon: Icons.search,
                label: 'Buscar / Avaliar Navios',
                onTap: () => Navigator.pop(context),
              ),

              /// Navegação: Minhas Avaliações
              _buildDrawerItem(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Minhas Avaliações',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyRatingsPage(),
                    ),
                  );
                },
              ),

              /// Navegação: Enviar Sugestão
              _buildDrawerItem(
                icon: Icons.lightbulb_outline,
                label: 'Enviar Sugestão',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuggestionPage(),
                    ),
                  );
                },
              ),

              const Divider(
                height: 32,
                thickness: 1,
              ),

              /// Ação: Logout
              _buildDrawerItem(
                icon: Icons.logout,
                label: 'Sair',
                color: Colors.redAccent,
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ),

      /// -----------------------------------------------------------------------
      /// Body com rebuild controlado
      /// -----------------------------------------------------------------------
      /// KeyedSubtree permite forçar rebuild completo ao trocar a Key.
      /// Banner de atualização aparece no topo quando há update disponível.
      body: KeyedSubtree(
        key: _rebuildKey,
        child: Column(
          children: [
            /// Banner de atualização (condicional)
            _buildUpdateBanner(),

            /// Conteúdo principal: tela de busca/avaliação
            const Expanded(child: SearchAndRateShipPage()),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// Constrói item padrão do drawer
  /// --------------------------------------------------------------------------
  /// Widget reutilizável para itens de navegação do drawer.
  ///
  /// Parâmetros:
  ///   • [icon] - Ícone exibido à esquerda
  ///   • [label] - Texto do item
  ///   • [onTap] - Ação ao tocar no item
  ///   • [color] - Cor customizada (opcional, padrão: preto)
  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}
