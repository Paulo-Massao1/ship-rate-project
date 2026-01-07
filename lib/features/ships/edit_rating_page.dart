import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// EDIT RATING PAGE
/// ============================================================================
/// Tela para editar uma avaliação existente.
///
/// Funcionalidades:
/// ----------------
/// • Preenche formulário com dados existentes
/// • Permite editar TODOS os campos da avaliação
/// • Atualiza dados no Firestore
/// • Validação de campos obrigatórios
///
/// Campos Editáveis:
/// -----------------
/// • Nome do navio (pode mudar se digitou errado)
/// • IMO (opcional)
/// • Data de desembarque
/// • Tipo de cabine
/// • Informações do navio (tripulação, cabines, frigobar, pia)
/// • Notas de todos os critérios
/// • Observações por critério
/// • Observação geral
///
class EditRatingPage extends StatefulWidget {
  /// Documento da avaliação a ser editada
  final QueryDocumentSnapshot rating;

  const EditRatingPage({
    super.key,
    required this.rating,
  });

  @override
  State<EditRatingPage> createState() => _EditRatingPageState();
}

class _EditRatingPageState extends State<EditRatingPage> {
  /// Form key para validação
  final _formKey = GlobalKey<FormState>();

  /// Estado de salvamento
  bool _isSaving = false;

  /// Controllers
  late TextEditingController _shipNameController;
  late TextEditingController _shipImoController;
  late TextEditingController _observacaoGeralController;
  late TextEditingController _crewNationalityController;
  late TextEditingController _cabinCountController;

  /// Data de desembarque
  DateTime? _disembarkationDate;

  /// Tipo de cabine
  String? _cabinType;

  /// Informações do navio
  bool _hasFrigobar = false;
  bool _hasSink = false;

  /// Notas dos critérios
  final Map<String, double> _ratings = {
    'Dispositivo de Embarque/Desembarque': 3.0,
    'Temperatura da Cabine': 3.0,
    'Limpeza da Cabine': 3.0,
    'Passadiço – Equipamentos': 3.0,
    'Passadiço – Temperatura': 3.0,
    'Comida': 3.0,
    'Relacionamento com comandante/tripulação': 3.0,
  };

  /// Observações por critério
  final Map<String, TextEditingController> _observationControllers = {};

  /// Referência ao documento do navio
  DocumentReference? _shipRef;

  /// --------------------------------------------------------------------------
  /// Inicialização
  /// --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _shipNameController = TextEditingController();
    _shipImoController = TextEditingController();
    _observacaoGeralController = TextEditingController();
    _crewNationalityController = TextEditingController();
    _cabinCountController = TextEditingController();

    // Inicializa controllers de observações
    for (final criterio in _ratings.keys) {
      _observationControllers[criterio] = TextEditingController();
    }

    _loadExistingData();
  }

  /// --------------------------------------------------------------------------
  /// Carrega dados existentes da avaliação
  /// --------------------------------------------------------------------------
  Future<void> _loadExistingData() async {
    try {
      final data = widget.rating.data() as Map<String, dynamic>;

      // Busca dados do navio
      _shipRef = widget.rating.reference.parent.parent!;
      final shipDoc = await _shipRef!.get();
      final shipData = shipDoc.data() as Map<String, dynamic>?;

      setState(() {
        // Dados do navio (editáveis)
        _shipNameController.text = shipData?['nome'] ?? '';
        _shipImoController.text = shipData?['imo'] ?? '';

        // Data de desembarque
        final desembarqueTs = data['dataDesembarque'] as Timestamp?;
        _disembarkationDate = desembarqueTs?.toDate();

        // Tipo de cabine
        _cabinType = data['tipoCabine'];

        // Informações do navio
        final shipInfo = data['infoNavio'] as Map<String, dynamic>?;
        if (shipInfo != null) {
          _crewNationalityController.text = shipInfo['nacionalidadeTripulacao'] ?? '';
          final cabinCount = shipInfo['numeroCabines'];
          _cabinCountController.text = cabinCount != null ? cabinCount.toString() : '';
          _hasFrigobar = shipInfo['frigobar'] ?? false;
          _hasSink = shipInfo['pia'] ?? false;
        }

        // Observação geral
        _observacaoGeralController.text = data['observacaoGeral'] ?? '';

        // Notas e observações por critério
        final itens = data['itens'] as Map<String, dynamic>?;
        if (itens != null) {
          itens.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              final nota = value['nota'];
              final observacao = value['observacao'] ?? '';

              if (_ratings.containsKey(key) && nota is num) {
                _ratings[key] = nota.toDouble();
              }

              if (_observationControllers.containsKey(key)) {
                _observationControllers[key]!.text = observacao;
              }
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// --------------------------------------------------------------------------
  /// Dispose
  /// --------------------------------------------------------------------------
  @override
  void dispose() {
    _shipNameController.dispose();
    _shipImoController.dispose();
    _observacaoGeralController.dispose();
    _crewNationalityController.dispose();
    _cabinCountController.dispose();
    for (final controller in _observationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// --------------------------------------------------------------------------
  /// Seleciona data de desembarque
  /// --------------------------------------------------------------------------
  Future<void> _selectDisembarkationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _disembarkationDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _disembarkationDate = picked;
      });
    }
  }

  /// --------------------------------------------------------------------------
  /// Formata data para exibição
  /// --------------------------------------------------------------------------
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// --------------------------------------------------------------------------
  /// Salva alterações
  /// --------------------------------------------------------------------------
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final shipName = _shipNameController.text.trim();
    if (shipName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome do navio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_disembarkationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data de desembarque'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_cabinType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o tipo de cabine'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Monta estrutura de itens avaliados
      final Map<String, dynamic> itens = {};
      _ratings.forEach((criterio, nota) {
        itens[criterio] = {
          'nota': nota,
          'observacao': _observationControllers[criterio]?.text.trim() ?? '',
        };
      });

      // Monta informações do navio
      final cabinCountText = _cabinCountController.text.trim();
      final Map<String, dynamic> shipInfo = {
        'nacionalidadeTripulacao': _crewNationalityController.text.trim().isNotEmpty 
            ? _crewNationalityController.text.trim() 
            : null,
        'numeroCabines': cabinCountText.isNotEmpty ? int.tryParse(cabinCountText) : null,
        'frigobar': _hasFrigobar,
        'pia': _hasSink,
      };

      // Atualiza dados do navio (nome e IMO podem ter mudado)
      if (_shipRef != null) {
        await _shipRef!.update({
          'nome': shipName,
          'imo': _shipImoController.text.trim(),
        });
      }

      // Atualiza documento da avaliação no Firestore
      await widget.rating.reference.update({
        'dataDesembarque': Timestamp.fromDate(_disembarkationDate!),
        'tipoCabine': _cabinType,
        'itens': itens,
        'observacaoGeral': _observacaoGeralController.text.trim(),
        'infoNavio': shipInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação atualizada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Volta para tela anterior
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// --------------------------------------------------------------------------
  /// Build
  /// --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Editar Avaliação',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// Aviso no topo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(77)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edite apenas erros de digitação. Para mudanças no navio, crie nova avaliação.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Informações do Navio (EDITÁVEIS)
            _buildSectionTitle('Informações do Navio'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _shipNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Navio *',
                        prefixIcon: Icon(Icons.directions_boat, color: Colors.orange),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite o nome do navio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shipImoController,
                      decoration: const InputDecoration(
                        labelText: 'IMO (opcional)',
                        prefixIcon: Icon(Icons.tag, color: Colors.orange),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Data de Desembarque
            _buildSectionTitle('Data de Desembarque *'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: _selectDisembarkationDate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.orange),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data de Desembarque',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _disembarkationDate != null
                                  ? _formatDate(_disembarkationDate!)
                                  : 'Selecione a data',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _disembarkationDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.orange),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Tipo de Cabine
            _buildSectionTitle('Tipo de Cabine *'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: _cabinType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.bed, color: Colors.orange),
                  ),
                  hint: const Text('Selecione o tipo de cabine'),
                  items: const [
                    DropdownMenuItem(value: 'PRT', child: Text('PRT')),
                    DropdownMenuItem(value: 'OWNER', child: Text('OWNER')),
                    DropdownMenuItem(value: 'Spare Officer', child: Text('Spare Officer')),
                    DropdownMenuItem(value: 'Crew', child: Text('Crew')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _cabinType = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Informações do Navio (editáveis)
            _buildSectionTitle('Detalhes do Navio'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _crewNationalityController,
                      decoration: const InputDecoration(
                        labelText: 'Nacionalidade da Tripulação',
                        prefixIcon: Icon(Icons.public, color: Colors.orange),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cabinCountController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de Cabines',
                        prefixIcon: Icon(Icons.meeting_room, color: Colors.orange),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Frigobar'),
                      value: _hasFrigobar,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setState(() {
                          _hasFrigobar = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Pia'),
                      value: _hasSink,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setState(() {
                          _hasSink = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Critérios de Avaliação
            _buildSectionTitle('Critérios de Avaliação'),
            ..._buildRatingSliders(),

            const SizedBox(height: 24),

            /// Observação Geral
            _buildSectionTitle('Observação Geral (Opcional)'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _observacaoGeralController,
                  decoration: const InputDecoration(
                    hintText: 'Adicione comentários gerais sobre a viagem...',
                    border: InputBorder.none,
                  ),
                  maxLines: 5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            /// Botão Salvar
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Salvar Alterações',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// Widgets auxiliares
  /// --------------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  List<Widget> _buildRatingSliders() {
    return _ratings.keys.map((criterio) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      criterio,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _ratings[criterio]!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _ratings[criterio]!,
                min: 0,
                max: 5,
                divisions: 10,
                activeColor: Colors.orange,
                onChanged: (value) {
                  setState(() {
                    _ratings[criterio] = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observationControllers[criterio],
                decoration: InputDecoration(
                  hintText: 'Observações (opcional)',
                  hintStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}