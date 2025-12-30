import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// AUTH CONTROLLER
/// ============================================================================
/// Controlador responsável por autenticação e gerenciamento de usuários.
///
/// Objetivo:
/// ---------
/// Centralizar toda a lógica de autenticação (login, registro, logout e
/// recuperação de senha), abstraindo completamente as camadas de Firebase
/// Authentication e Firestore.
///
/// Estrutura Operacional:
/// ----------------------
/// • Firebase Auth: Gerencia sessão, criação e validação de credenciais
/// • Firestore: Armazena dados complementares do usuário na coleção `usuarios`:
///     - email: E-mail do usuário
///     - nomeGuerra: Nome de guerra (identificação pública no app)
///     - createdAt: Timestamp de criação da conta
///
/// Fluxo Típico de Uso:
/// --------------------
/// 1. Usuário se registra via [register]
/// 2. Dados extras são persistidos em `usuarios/{uid}`
/// 3. Sessão é mantida automaticamente pelo Firebase
/// 4. UI reage via StreamBuilder no AuthGate
///
/// Tratamento de Erros:
/// --------------------
/// • Os métodos convertem erros do FirebaseAuth em mensagens claras
///   lançando [AuthException]
/// • Diferentes códigos de erro são normalizados para o usuário:
///     - invalid-email
///     - wrong-password / invalid-credential
///     - user-not-found
///     - too-many-requests
///
/// Segurança e Validação:
/// ----------------------
/// • Campos obrigatórios são validados antes da chamada ao Firebase
/// • Confirmação de senha é tratada no registro
/// • Reset de senha exige e-mail válido
///
class AuthController {
  /// Instância do Firebase Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Instância do Firestore para dados de usuário
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// --------------------------------------------------------------------------
  /// Registra um novo usuário
  /// --------------------------------------------------------------------------
  /// Cria uma nova conta no Firebase Authentication e salva dados adicionais
  /// no Firestore.
  ///
  /// Parâmetros:
  ///   • [email] - E-mail institucional ou pessoal do prático
  ///   • [password] - Senha definida pelo usuário
  ///   • [confirmPassword] - Confirmação da senha
  ///   • [callSign] - Nome de guerra usado nas avaliações
  ///
  /// Fluxo:
  ///   1. Valida campos obrigatórios
  ///   2. Valida se senha == confirmação
  ///   3. Cria credencial no Firebase Auth
  ///   4. Cria documento em `usuarios/{uid}`
  ///
  /// Exceções:
  ///   • [AuthException] - Erros de validação ou Firebase convertidos
  ///
  /// Exemplo:
  /// ```dart
  /// await authController.register(
  ///   email: 'pratico@exemplo.com',
  ///   password: 'senha123',
  ///   confirmPassword: 'senha123',
  ///   callSign: 'Capitão Silva',
  /// );
  /// ```
  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String callSign,
  }) async {
    /// Validação de campos obrigatórios
    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        callSign.isEmpty) {
      throw AuthException('Preencha todos os campos.');
    }

    /// Validação de confirmação de senha
    if (password != confirmPassword) {
      throw AuthException('As senhas não coincidem.');
    }

    try {
      /// Cria usuário no Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      /// Salva dados complementares no Firestore
      await _firestore
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'nomeGuerra': callSign,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.message ?? 'Erro ao cadastrar usuário.');
    }
  }

  /// --------------------------------------------------------------------------
  /// Realiza login do usuário
  /// --------------------------------------------------------------------------
  /// Autentica usuário via Firebase Authentication usando e-mail e senha.
  ///
  /// Parâmetros:
  ///   • [email] - Credencial de acesso
  ///   • [password] - Senha associada à conta
  ///
  /// Mapeamento Inteligente de Erros:
  ///   • invalid-email → E-mail inválido
  ///   • wrong-password, invalid-credential → Credenciais incorretas
  ///   • user-not-found → Conta não encontrada
  ///   • too-many-requests → Limite de tentativas excedido
  ///
  /// Exceções:
  ///   • [AuthException] - Erro de autenticação com mensagem amigável
  ///
  /// Exemplo:
  /// ```dart
  /// try {
  ///   await authController.login(
  ///     email: 'pratico@exemplo.com',
  ///     password: 'senha123',
  ///   );
  /// } on AuthException catch (e) {
  ///   print(e.message);
  /// }
  /// ```
  Future<void> login({
    required String email,
    required String password,
  }) async {
    /// Validação de campos obrigatórios
    if (email.isEmpty || password.isEmpty) {
      throw AuthException('Preencha todos os campos.');
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      /// Log para debug em modo de desenvolvimento
      debugPrint('🔐 FirebaseAuth login error: ${error.code} - ${error.message}');

      /// Mapeia códigos de erro para mensagens amigáveis
      switch (error.code) {
        case 'invalid-email':
          throw AuthException('O e-mail informado é inválido.');
        case 'user-disabled':
          throw AuthException('Esta conta foi desativada.');
        case 'user-not-found':
          throw AuthException('Nenhuma conta encontrada com este e-mail.');
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          throw AuthException('E-mail ou senha incorretos. Tente novamente.');
        case 'too-many-requests':
          throw AuthException('Muitas tentativas. Aguarde alguns minutos.');
        default:
          throw AuthException(
            'Não foi possível realizar o login. Verifique suas credenciais.',
          );
      }
    }
  }

  /// --------------------------------------------------------------------------
  /// Realiza logout do usuário
  /// --------------------------------------------------------------------------
  /// Finaliza a sessão atual do usuário, invalidando token e cache local.
  /// O redirecionamento para tela de login é gerenciado automaticamente
  /// pelo AuthGate via StreamBuilder.
  ///
  /// Exemplo:
  /// ```dart
  /// await authController.logout();
  /// ```
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// --------------------------------------------------------------------------
  /// Envia e-mail de recuperação de senha
  /// --------------------------------------------------------------------------
  /// Dispara o fluxo automático de reset de senha do Firebase Authentication.
  /// O usuário receberá um e-mail com link para redefinir a senha.
  ///
  /// Parâmetros:
  ///   • [email] - Deve corresponder a uma conta existente
  ///
  /// Observações:
  ///   • Depende do template configurado no Firebase Console
  ///   • Não retorna erro se e-mail não existir (segurança)
  ///
  /// Exceções:
  ///   • [AuthException] - Erro ao enviar e-mail
  ///
  /// Exemplo:
  /// ```dart
  /// await authController.sendPasswordReset('pratico@exemplo.com');
  /// ```
  Future<void> sendPasswordReset(String email) async {
    /// Validação de campo obrigatório
    if (email.isEmpty) {
      throw AuthException('Informe o e-mail.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.message ?? 'Erro ao enviar e-mail.');
    }
  }
}

/// ============================================================================
/// AUTH EXCEPTION
/// ============================================================================
/// Exceção customizada para encapsular erros de autenticação.
///
/// Objetivo:
/// ---------
/// Permitir mensagens legíveis e controladas na UI, evitando expor
/// diretamente códigos internos do Firebase para o usuário final.
///
/// Uso:
/// ```dart
/// try {
///   await authController.login(...);
/// } on AuthException catch (e) {
///   showDialog(message: e.message);
/// }
/// ```
class AuthException implements Exception {
  /// Mensagem de erro amigável para exibição ao usuário
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}