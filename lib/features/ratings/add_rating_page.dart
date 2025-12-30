import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'rating_controller.dart';

/// ============================================================================
/// ADD RATING PAGE
/// ============================================================================
/// Tela de cadastro de avaliação de navio.
///
/// Responsabilidades:
/// ------------------
/// • Criar nova avaliação de navio
/// • Autocomplete de navios já cadastrados
/// • Bloquear campos quando navio já existe (evitar dados duplicados)
/// • Coletar notas e observações por critério
/// • Validar dados antes de salvar
///
/// Funcionalidades:
/// ----------------
/// • Autocomplete inteligente com highlight de caracteres coincidentes
/// • Campos bloqueados automaticamente quando navio existe
/// • Slider para notas (1.0 a 5.0 com incrementos de 0.1)
/// • Validação de campos obrigatórios
/// • Persistência via RatingController
///
/// Fluxo de Uso:
/// -------------
/// 1. Usuário digita nome do navio (autocomplete sugere opções)
/// 2. Se navio existe: campos de info são bloqueados e preenchidos
/// 3. Se navio novo: todos os campos ficam habilitados
/// 4. Preenche tipo de cabine, data de desembarque, notas por critério
/// 5. Salva via RatingController
/// 6. Retorna para tela anterior com resultado true
///
class AddRatingPage extends StatefulWidget {
  /// IMO do navio (opcional, pode ser vazio)
  final String imo;

  const AddRatingPage({
    super.key,
    required this.imo,
  });

  @override
  State<AddRatingPage> createState() => _AddRatingPageState();
}

/// ============================================================================
/// ADD RATING PAGE STATE
/// ============================================================================
class _AddRatingPageState extends State<AddRatingPage> {
  /// Form key para validação
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controller de lógica de negócio
  final RatingController _ratingController = RatingController();

  /// --------------------------------------------------------------------------
  /// Controllers de campos principais
  /// --------------------------------------------------------------------------
  final TextEditingController _shipNameController = TextEditingController();
  final TextEditingController _imoController = TextEditingController();
  final TextEditingController _generalObservationController =
      TextEditingController();
  final TextEditingController _crewNationalityController =
      TextEditingController();
  final TextEditingController _cabinCountController = TextEditingController();

  /// FocusNode persistente para evitar bugs no autocomplete
  final FocusNode _shipNameFocusNode = FocusNode();

  /// --------------------------------------------------------------------------
  /// Estado local
  /// --------------------------------------------------------------------------
  
  /// Lista de navios cadastrados (para autocomplete)
  List<QueryDocumentSnapshot> _registeredShips = [];

  /// Nome atual do navio sendo digitado
  String _currentShipName = '';

  /// Tipo de cabine selecionado
  String? _selectedCabinType;

  /// Data de desembarque selecionada
  DateTime? _disembarkationDate;

  /// Checkbox states
  bool _hasMinibar = false;
  bool _hasSink = false;

  /// Loading state
  bool _isSaving = false;

  /// Se navio já existe no banco (campos ficam bloqueados)
  bool _shipAlreadyExists = false;

  /// --------------------------------------------------------------------------
  /// Constantes
  /// --------------------------------------------------------------------------
  
  /// Tipos de cabine disponíveis
  static const List<String> _cabinTypes = [
    'PRT',
    'OWNER',
    'Spare Officer',
    'Crew',
  ];

  /// Itens avaliados (ordem oficial do sistema)
  static const List<String> _ratingCriteria = [
    'Dispositivo de Embarque/Desembarque',
    'Temperatura da Cabine',
    'Limpeza da Cabine',
    'Passadiço – Equipamentos',
    'Passadiço – Temperatura',
    'Comida',
    'Relacionamento com comandante/tripulação',
  ];

  /// --------------------------------------------------------------------------
  /// Maps de notas e observações por critério
  /// --------------------------------------------------------------------------
  
  /// Notas por item (1.0 a 5.0, padrão 3.0)
  late final Map<String, double> _ratingsByItem;

  /// Controllers de observações por item
  late final Map<String, TextEditingController> _observationControllers;

  /// --------------------------------------------------------------------------
  /// Inicialização
  /// --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    /// Carrega navios cadastrados para autocomplete
    _loadShips();

    /// Inicializa notas com valor padrão 3.0
    _ratingsByItem = {
      for (final item in _ratingCriteria) item: 3.0,
    };

    /// Inicializa controllers de observações
    _observationControllers = {
      for (final item in _ratingCriteria) item: TextEditingController(),
    };
  }

  /// --------------------------------------------------------------------------
  /// Carrega navios para autocomplete
  /// --------------------------------------------------------------------------
  Future<void> _loadShips() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('navios').get();

    if (!mounted) return;

    setState(() {
      _registeredShips = snapshot.docs;
    });
  }

  /// --------------------------------------------------------------------------
  /// Limpeza
  /// --------------------------------------------------------------------------
  @override
  void dispose() {
    _shipNameFocusNode.dispose();
    _shipNameController.dispose();
    _imoController.dispose();
    _generalObservationController.dispose();
    _crewNationalityController.dispose();
    _cabinCountController.dispose();

    /// Dispose de todos os controllers de observações
    for (final controller in _observationControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  /// --------------------------------------------------------------------------
  /// Destaca caracteres coincidentes no autocomplete
  /// --------------------------------------------------------------------------
  /// Aplica negrito nos caracteres que coincidem com a busca.
  ///
  /// Parâmetros:
  ///   • [text] - Texto completo a ser exibido
  ///   • [query] - Texto digitado pelo usuário
  ///
  /// Retorno:
  ///   • TextSpan com caracteres coincidentes em negrito
  TextSpan _highlightMatch(String text, String query) {
    if (query.isEmpty) return TextSpan(text: text);

    final queryChars = query.toLowerCase().split('');

    return TextSpan(
      children: text.split('').map((char) {
        final isMatch = queryChars.contains(char.toLowerCase());
        return TextSpan(
          text: char,
          style: TextStyle(
            fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  /// --------------------------------------------------------------------------
  /// Salva avaliação
  /// --------------------------------------------------------------------------
  /// Valida formulário e persiste dados via RatingController.
  ///
  /// Validações:
  ///   • Campos obrigatórios preenchidos
  ///   • Data de desembarque selecionada
  ///   • Tipo de cabine selecionado
  ///
  /// Fluxo:
  ///   1. Valida formulário
  ///   2. Ativa loading
  ///   3. Chama RatingController.salvarAvaliacao
  ///   4. Retorna para tela anterior com resultado true
  ///   5. Em caso de erro, mantém usuário na tela
  Future<void> _saveRating() async {
    if (!_formKey.currentState!.validate()) return;

    if (_disembarkationDate == null || _selectedCabinType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _ratingController.salvarAvaliacao(
        nomeNavio: _currentShipName.trim(),
        imoInicial: _imoController.text.trim(),
        dataDesembarque: _disembarkationDate!,
        tipoCabine: _selectedCabinType!,
        observacaoGeral: _generalObservationController.text.trim(),
        infoNavio: {
          'nacionalidadeTripulacao': _crewNationalityController.text.trim(),
          'numeroCabines': int.tryParse(_cabinCountController.text) ?? 0,
          'frigobar': _hasMinibar,
          'pia': _hasSink,
        },
        itens: {
          for (final item in _ratingCriteria)
            item: {
              'nota': _ratingsByItem[item]!,
              'observacao': _observationControllers[item]!.text.trim(),
            }
        },
      );

      if (!mounted) return;

      /// Retorna com resultado true indicando sucesso
      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// --------------------------------------------------------------------------
  /// Seleciona data de desembarque
  /// --------------------------------------------------------------------------
  Future<void> _selectDisembarkationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _disembarkationDate = picked);
    }
  }

  /// --------------------------------------------------------------------------
  /// Build principal
  /// --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar Navio'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      /// Botão fixo na parte inferior
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveRating,
          child: Text(_isSaving ? 'Salvando...' : 'Salvar Avaliação'),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildShipAutocomplete(),
              const SizedBox(height: 12),
              _buildImoField(),
              const Divider(height: 32),
              _buildCabinTypeDropdown(),
              const SizedBox(height: 16),
              _buildDisembarkationDatePicker(),
              const Divider(height: 32),
              _buildShipInfoSection(),
              const Divider(height: 32),
              
              /// Lista de critérios avaliados
              for (final item in _ratingCriteria) _buildRatingItem(item),
              
              const Divider(height: 32),
              _buildGeneralObservationField(),
            ],
          ),
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// Widgets auxiliares
  /// --------------------------------------------------------------------------

  /// Autocomplete de nome do navio
  Widget _buildShipAutocomplete() {
    return RawAutocomplete<QueryDocumentSnapshot>(
      textEditingController: _shipNameController,
      focusNode: _shipNameFocusNode,
      displayStringForOption: (opt) => opt['nome'],
      optionsBuilder: (value) {
        if (value.text.isEmpty) {
          return const Iterable<QueryDocumentSnapshot>.empty();
        }

        return _registeredShips.where((doc) {
          final nome = doc['nome'].toString().toLowerCase();
          return nome.contains(value.text.toLowerCase());
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(labelText: 'Nome do navio'),
          validator: (v) =>
              v == null || v.isEmpty ? 'Informe o nome do navio' : null,
          onChanged: (v) {
            _currentShipName = v;
            setState(() => _shipAlreadyExists = false);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (options.isEmpty) {
          return const SizedBox.shrink();
        }

        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (_, index) {
              final opt = options.elementAt(index);
              final data = opt.data() as Map<String, dynamic>;
              final info = (data['info'] ?? {}) as Map<String, dynamic>;

              return ListTile(
                leading: const Icon(Icons.directions_boat),
                title: RichText(
                  text: _highlightMatch(
                    data['nome'],
                    _shipNameController.text,
                  ),
                ),
                onTap: () {
                  onSelected(opt);

                  setState(() {
                    _shipAlreadyExists = true;
                    _shipNameController.text = data['nome'];
                    _currentShipName = data['nome'];
                    _imoController.text = data['imo'] ?? '';

                    _crewNationalityController.text =
                        info['nacionalidadeTripulacao'] ?? '';
                    _cabinCountController.text =
                        info['numeroCabines']?.toString() ?? '';
                    _hasMinibar = info['frigobar'] ?? false;
                    _hasSink = info['pia'] ?? false;
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Campo de IMO (bloqueado se navio já existe)
  Widget _buildImoField() {
    return TextFormField(
      controller: _imoController,
      enabled: !_shipAlreadyExists,
      decoration: const InputDecoration(labelText: 'IMO (opcional)'),
    );
  }

  /// Dropdown de tipo de cabine
  Widget _buildCabinTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCabinType,
      decoration: const InputDecoration(labelText: 'Tipo da cabine'),
      items: _cabinTypes
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCabinType = v),
    );
  }

  /// Seletor de data de desembarque
  Widget _buildDisembarkationDatePicker() {
    return ListTile(
      leading: const Icon(Icons.event),
      title: const Text('Data de desembarque'),
      subtitle: Text(
        _disembarkationDate == null
            ? 'Selecionar'
            : '${_disembarkationDate!.day}/${_disembarkationDate!.month}/${_disembarkationDate!.year}',
      ),
      onTap: _selectDisembarkationDate,
    );
  }

  /// Seção de informações do navio
  Widget _buildShipInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações do navio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _crewNationalityController,
          enabled: !_shipAlreadyExists,
          decoration: const InputDecoration(
            labelText: 'Nacionalidade da tripulação',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cabinCountController,
          enabled: !_shipAlreadyExists,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade de cabines',
          ),
        ),
        SwitchListTile(
          title: const Text('Possui frigobar'),
          value: _hasMinibar,
          onChanged: _shipAlreadyExists
              ? null
              : (v) => setState(() => _hasMinibar = v),
        ),
        SwitchListTile(
          title: const Text('Possui pia'),
          value: _hasSink,
          onChanged:
              _shipAlreadyExists ? null : (v) => setState(() => _hasSink = v),
        ),
      ],
    );
  }

  /// Item individual de avaliação (slider + observação)
  Widget _buildRatingItem(String item) {
    final valor = _ratingsByItem[item]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: valor,
              min: 1,
              max: 5,
              divisions: 40,
              label: valor.toStringAsFixed(1),
              onChanged: (v) => setState(() => _ratingsByItem[item] = v),
            ),
            TextField(
              controller: _observationControllers[item],
              decoration: const InputDecoration(
                hintText: 'Observação (opcional)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo de observação geral
  Widget _buildGeneralObservationField() {
    return TextFormField(
      controller: _generalObservationController,
      maxLines: 4,
      decoration: const InputDecoration(labelText: 'Observação geral'),
    );
  }
}