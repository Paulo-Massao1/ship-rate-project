import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_page.dart';
import '../ships/search_ship_page.dart';
import 'home_controller.dart';
import '../sugestoes/sugestao_page.dart'; // Página para envio de sugestões

/// ---------------------------------------------------------------------------
/// CONTROLADOR DE VERSÃO LOCAL DO APLICATIVO
/// ---------------------------------------------------------------------------
/// • `kAppVersionCode` é utilizado para comparação com a versão remota.
/// • `kAppVersionLabel` é exibido na interface (rodapé).
/// • `kAppChannelLabel` pode marcar canal BETA/PROD etc.
/// 
/// IMPORTANTE:
/// Sempre que realizar um novo deploy, atualizar:
///   - kAppVersionCode (int)
///   - kAppVersionLabel (string)
///
/// E atualizar o documento em Firestore:
///   config/app { versao_atual: <num> }
///
/// Dessa forma, o app renderiza um banner avisando sobre atualização.
const int kAppVersionCode = 2;
const String kAppVersionLabel = '1.1.0';
const String kAppChannelLabel = 'VERSÃO BETA';

/// ---------------------------------------------------------------------------
/// MAIN SCREEN (HOME) DO APLICATIVO
/// ---------------------------------------------------------------------------
/// Responsável por:
/// • Controlar o layout principal após login.
/// • Conter AppBar, Drawer e conteúdo principal.
/// • Renderizar a feature de busca/avaliação.
/// • Exibir aviso de atualização (versão do Firestore).
/// • Expor acesso ao menu lateral (logout, sugestões).
///
/// Fluxo:
/// - `initState()` → verifica versão remota no Firestore.
/// - `_checkRemoteVersion()` → compara versão atual com remota.
/// - `_handleLogout()` → delega logout ao controller.
/// - Menu Drawer:
///     Buscar/Avaliar Navios
///     Enviar Sugestão
///     Logout
///
/// - `body` → monta:
///     banner de atualização
///     conteúdo da tela (BuscarAvaliarNavioPage)
///     rodapé com versão e canal
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Controla a exibição do banner de atualização.
  bool _showUpdateBanner = false;

  /// Armazena a versão remota obtida no Firestore.
  int _remoteVersionCode = kAppVersionCode;

  @override
  void initState() {
    super.initState();
    _checkRemoteVersion();
  }

  /// -------------------------------------------------------------------------
  /// Consulta o Firestore procurando a versão mais recente do app.
  ///
  /// Estrutura esperada no Firestore:
  ///   collection: config
  ///   document: app
  ///   field: versao_atual
  ///
  /// Se a versão remota > versão local:
  ///   → exibe aviso solicitando recarregar o app/PWA.
  Future<void> _checkRemoteVersion() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app')
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final remote = (data['versao_atual'] ?? kAppVersionCode) as int;

      setState(() {
        _remoteVersionCode = remote;
        _showUpdateBanner = remote > kAppVersionCode;
      });
    } catch (e) {
      debugPrint('Erro ao consultar versão remota: $e');
    }
  }

  /// -------------------------------------------------------------------------
  /// Realiza logout do app.
  ///
  /// Observação:
  ///   - Implementação futura deve ser centralizada no MainScreenController
  ///     ou AuthController.
  ///
  /// A navegação limpa a stack para não permitir retorno ao MainScreen.
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

  /// Banner exibido somente quando existe versão remota > local.
  Widget _buildUpdateBanner() {
    if (!_showUpdateBanner) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.amber.shade700,
      child: Text(
        'Nova atualização disponível (v$_remoteVersionCode).\n'
        'Feche o app e abra novamente para aplicar.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Rodapé fixo exibindo versão + canal (ex.: BETA).
  Widget _buildVersionFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.grey.shade200,
      child: Text(
        '$kAppChannelLabel • v$kAppVersionLabel',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// Build principal da tela
  /// -------------------------------------------------------------------------
  /// Composição:
  /// - AppBar personalizada
  /// - Drawer com navegação lateral
  /// - Corpo contendo o fluxo principal (buscar/avaliar navios)
  /// - Banner de atualização condicional
  /// - Rodapé com versão
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ShipRate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),

      drawer: Drawer(
        child: Column(
          children: [
            /// Cabeçalho do Drawer com branding
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.directions_boat, size: 60, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    "ShipRate",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),

            /// Navegação para fluxo principal
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text("Buscar/Avaliar Navios"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            /// Navegação da feature "Enviar Sugestão"
            /// Tela utiliza Firestore para persistir feedbacks.
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text("Enviar Sugestão"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SugestaoPage()),
                );
              },
            ),

            const Divider(),

            /// Logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sair"),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          _buildUpdateBanner(),
          const Expanded(child: BuscarAvaliarNavioPage()),
          _buildVersionFooter(),
        ],
      ),
    );
  }
}
