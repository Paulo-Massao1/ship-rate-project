import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_page.dart';
import '../ships/search_ship_page.dart';
import 'home_controller.dart';
import '../sugestoes/sugestao_page.dart';

/// ---------------------------------------------------------------------------
/// CONTROLADOR DE VERSÃO LOCAL DO APLICATIVO
/// ---------------------------------------------------------------------------
/// • `kAppVersionCode` é utilizado para comparação com a versão remota.
/// • `kAppVersionLabel` é exibido na interface (rodapé).
/// • `kAppChannelLabel` pode marcar canal BETA/PROD etc.
const int kAppVersionCode = 2;
const String kAppVersionLabel = '1.1.0';
const String kAppChannelLabel = 'VERSÃO BETA';

/// ---------------------------------------------------------------------------
/// MAIN SCREEN (HOME) DO APLICATIVO
/// ---------------------------------------------------------------------------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showUpdateBanner = false;
  int _remoteVersionCode = kAppVersionCode;

  @override
  void initState() {
    super.initState();
    _checkRemoteVersion();
  }

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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShipRate', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      /// =========================
      /// DRAWER REALMENTE NOVO
      /// =========================
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER CUSTOM (não DrawerHeader)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.directions_boat, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'ShipRate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Avaliação profissional de navios',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _drawerItem(
                icon: Icons.search,
                label: 'Buscar / Avaliar Navios',
                onTap: () => Navigator.pop(context),
              ),

              _drawerItem(
                icon: Icons.lightbulb_outline,
                label: 'Enviar Sugestão',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SugestaoPage()),
                  );
                },
              ),

              const Spacer(),
              const Divider(),

              _drawerItem(
                icon: Icons.logout,
                label: 'Sair',
                color: Colors.redAccent,
                onTap: _handleLogout,
              ),
            ],
          ),
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

  Widget _drawerItem({
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
