import 'package:flutter/material.dart';
import 'rating_controller.dart';

/// ---------------------------------------------------------------------------
/// AddRatingPage
/// ---------------------------------------------------------------------------
/// Tela responsável por registrar a avaliação de um navio.
///
/// Principais responsabilidades:
///  • Carregar navios já cadastrados para autocomplete.
///  • Preencher automaticamente informações quando um navio existente é detectado.
///  • Permitir inserir notas via slider (1–5).
///  • Controlar campos que ficam bloqueados se o navio já existe.
///  • Enviar a avaliação ao Firestore por meio do RatingController.
///
/// Observação:
/// - Se o navio já existir, campos de passadiço são protegidos
///   para evitar conflitos / reescritas.
/// - Identificação do avaliador é feita no controller (via FirebaseAuth).
class AddRatingPage extends StatefulWidget {
  /// IMO opcional recebido via navegação.
  /// Caso vazio, será tratado como "Não informado".
  final String imo;

  const AddRatingPage({super.key, required this.imo});

  @override
  State<AddRatingPage> createState() => _AddRatingPageState();
}

class _AddRatingPageState extends State<AddRatingPage> {
  /// FormKey para validação do formulário.
  final _formKey = GlobalKey<FormState>();

  /// Controller responsável pela persistência e consultas no Firestore.
  final _controller = RatingController();

  /// Controllers de texto para os dados principais do navio.
  final TextEditingController nomeNavioController = TextEditingController();
  final TextEditingController tripulacaoController = TextEditingController();
  final TextEditingController cabinesController = TextEditingController();

  /// Notas padrão dos critérios (1–5).
  int notaCamarote = 3;
  int notaLimpeza = 3;
  int notaAr = 3;
  int notaComida = 3;

  /// Campos booleanos representados por dropdown.
  String frigobar = 'Sim';
  String pia = 'Sim';

  /// Lista de navios cadastrados para auto sugestão.
  List<String> naviosCadastrados = [];

  /// Se verdadeiro, os campos do passadiço ficam desativados.
  bool camposPassadicoDesativados = false;

  /// Estados para loading.
  bool isLoadingNavios = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNavios();
  }

  /// -------------------------------------------------------------------------
  /// Carrega nomes de navios cadastrados no Firestore para alimentar autocomplete.
  /// -------------------------------------------------------------------------
  Future<void> _loadNavios() async {
    setState(() => isLoadingNavios = true);
    try {
      naviosCadastrados = await _controller.carregarNavios();
    } finally {
      if (mounted) setState(() => isLoadingNavios = false);
    }
  }

  /// -------------------------------------------------------------------------
  /// Verifica se um navio já existe no banco.
  /// Caso exista:
  ///  - bloqueia campos do passadiço
  ///  - preenche informações existentes
  /// Caso não exista:
  ///  - libera campos
  ///  - limpa valores temporários
  /// -------------------------------------------------------------------------
  Future<void> _verificarNavioExistente(String nome) async {
    if (nome.trim().isEmpty) return;

    final data = await _controller.verificarNavioExistente(nome.trim());
    if (!mounted) return;

    if (data != null) {
      setState(() {
        camposPassadicoDesativados = true;
        frigobar = (data['frigobar'] ?? 'Sim').toString();
        pia = (data['pia'] ?? 'Sim').toString();
        tripulacaoController.text = (data['tripulacao'] ?? '').toString();
        cabinesController.text = (data['cabines'] ?? '').toString();
      });
    } else {
      setState(() {
        camposPassadicoDesativados = false;
        frigobar = 'Sim';
        pia = 'Sim';
        tripulacaoController.clear();
        cabinesController.clear();
      });
    }
  }

  /// -------------------------------------------------------------------------
  /// Valida o formulário e dispara o salvamento via controller.
  /// Converte IMO vazio para "Não informado".
  /// Ao salvar com sucesso → retorna resultado via Navigator.pop(true).
  /// -------------------------------------------------------------------------
  Future<void> _onSalvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    /// Tratamento do IMO: substitui vazio.
    final String imoFinal = widget.imo.trim().isEmpty
        ? "Não informado"
        : widget.imo.trim();

    try {
      await _controller.salvarAvaliacao(
        nomeNavio: nomeNavioController.text.trim(),
        imoInicial: imoFinal,
        notaCamarote: notaCamarote,
        notaLimpeza: notaLimpeza,
        notaAr: notaAr,
        notaComida: notaComida,
        frigobar: frigobar,
        pia: pia,
        tripulacao: tripulacaoController.text.trim(),
        cabines: int.tryParse(cabinesController.text.trim()) ?? 0,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  /// -------------------------------------------------------------------------
  /// Componente utilitário para criar blocos de sliders com ícone + título + valor.
  /// Simplifica repetição do padrão.
  /// -------------------------------------------------------------------------
  Widget _sliderTile(String titulo, IconData icon, int valor, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(
              '$titulo: $valor',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: valor.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: Colors.indigo,
          label: valor.toString(),
          onChanged: (value) => onChanged(value.toInt()),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar Navio'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      /// Bottom bar com botão fixo de salvar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(isSaving ? 'Salvando...' : 'Salvar Avaliação'),
            onPressed: isSaving ? null : _onSalvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),

      /// Conteúdo principal do formulário
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth > 600 ? 550 : maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "Informações do Navio",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  /// Campo com autocomplete para nome do navio
                  Autocomplete<String>(
                    optionsBuilder: (text) {
                      final value = text.text.toLowerCase();
                      if (value.isEmpty) return const Iterable<String>.empty();
                      return naviosCadastrados.where(
                        (op) => op.toLowerCase().contains(value),
                      );
                    },
                    onSelected: (value) {
                      nomeNavioController.text = value;
                      _verificarNavioExistente(value);
                    },
                    fieldViewBuilder: (_, fieldController, focusNode, __) {
                      /// Sincroniza controllers
                      fieldController.addListener(() {
                        nomeNavioController.text = fieldController.text;
                      });

                      return TextFormField(
                        controller: fieldController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Nome do navio',
                          suffixIcon: isLoadingNavios
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Informe o nome do navio'
                                : null,
                        onChanged: (v) => _verificarNavioExistente(v),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),

                  /// Bloco de notas
                  const SizedBox(height: 24),
                  const Text(
                    "Notas de Avaliação",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  _sliderTile("Camarote", Icons.bed, notaCamarote,
                      (v) => setState(() => notaCamarote = v)),
                  _sliderTile("Limpeza", Icons.cleaning_services, notaLimpeza,
                      (v) => setState(() => notaLimpeza = v)),
                  _sliderTile("Ar condicionado", Icons.ac_unit, notaAr,
                      (v) => setState(() => notaAr = v)),
                  _sliderTile("Comida", Icons.restaurant, notaComida,
                      (v) => setState(() => notaComida = v)),

                  const Divider(height: 32),

                  /// Passadiço
                  const Text(
                    "Passadiço",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: frigobar,
                    items: ['Sim', 'Não']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: camposPassadicoDesativados
                        ? null
                        : (val) => setState(() => frigobar = val!),
                    decoration: const InputDecoration(
                      labelText: "Frigobar",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: pia,
                    items: ['Sim', 'Não']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: camposPassadicoDesativados
                        ? null
                        : (val) => setState(() => pia = val!),
                    decoration: const InputDecoration(
                      labelText: "Pia",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  /// Informações gerais adicionais
                  const Text(
                    "Informações Gerais",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tripulacaoController,
                    decoration: const InputDecoration(
                      labelText: 'Tripulação (nacionalidade)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cabinesController,
                    decoration: const InputDecoration(
                      labelText: 'Cabines fornecidas',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  /// Espaço final p/ evitar overlap com botão fixo
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
