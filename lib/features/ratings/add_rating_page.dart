import 'package:flutter/material.dart';
import 'rating_controller.dart';

class AddRatingPage extends StatefulWidget {
  final String imo;

  const AddRatingPage({super.key, required this.imo});

  @override
  State<AddRatingPage> createState() => _AddRatingPageState();
}

class _AddRatingPageState extends State<AddRatingPage> {
  final _formKey = GlobalKey<FormState>();
  final RatingController _controller = RatingController();

  final TextEditingController nomeNavioController = TextEditingController();
  final TextEditingController imoController = TextEditingController();
  final TextEditingController observacaoGeralController =
      TextEditingController();
  final TextEditingController nacionalidadeTripulacaoController =
      TextEditingController();
  final TextEditingController numeroCabinesController =
      TextEditingController();

  String _nomeNavioAtual = '';
  String? tipoCabine;
  DateTime? dataDesembarque;

  bool possuiFrigobar = false;
  bool possuiPia = false;
  bool isSaving = false;

  static const List<String> tiposCabine = [
    'PRT',
    'OWNER',
    'Spare Officer',
    'Crew',
  ];

  static const List<String> _itensAvaliacao = [
    'Dispositivo de Embarque/Desembarque',
    'Temperatura da Cabine',
    'Limpeza da Cabine',
    'Passadiço – Equipamentos',
    'Passadiço – Temperatura',
    'Comida',
    'Relacionamento com comandante/tripulação',
  ];

  late final Map<String, double> notasPorItem;
  late final Map<String, TextEditingController> obsPorItemController;

  @override
  void initState() {
    super.initState();

    notasPorItem = {
      for (final item in _itensAvaliacao) item: 3.0,
    };

    obsPorItemController = {
      for (final item in _itensAvaliacao) item: TextEditingController(),
    };
  }

  @override
  void dispose() {
    nomeNavioController.dispose();
    imoController.dispose();
    observacaoGeralController.dispose();
    nacionalidadeTripulacaoController.dispose();
    numeroCabinesController.dispose();
    for (final c in obsPorItemController.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onSalvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (dataDesembarque == null || tipoCabine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await _controller.salvarAvaliacao(
        nomeNavio: _nomeNavioAtual.trim(),
        imoInicial: imoController.text.trim(),
        dataDesembarque: dataDesembarque!,
        tipoCabine: tipoCabine!,
        observacaoGeral: observacaoGeralController.text.trim(),
        infoNavio: {
          'nacionalidadeTripulacao':
              nacionalidadeTripulacaoController.text.trim(),
          'numeroCabines':
              int.tryParse(numeroCabinesController.text) ?? 0,
          'frigobar': possuiFrigobar,
          'pia': possuiPia,
        },
        itens: {
          for (final item in _itensAvaliacao)
            item: {
              'nota': notasPorItem[item]!,
              'observacao': obsPorItemController[item]!.text.trim(),
            }
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => dataDesembarque = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar Navio'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: isSaving ? null : _onSalvar,
          child: Text(isSaving ? 'Salvando...' : 'Salvar Avaliação'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// ================= DADOS DO NAVIO =================
              TextFormField(
                controller: nomeNavioController,
                decoration:
                    const InputDecoration(labelText: 'Nome do navio'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome do navio' : null,
                onChanged: (v) => _nomeNavioAtual = v,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: imoController,
                decoration: const InputDecoration(
                  labelText: 'IMO (opcional)',
                ),
              ),

              const Divider(height: 32),

              /// ================= CABINE / DATA =================
              DropdownButtonFormField<String>(
                value: tipoCabine,
                decoration:
                    const InputDecoration(labelText: 'Tipo da cabine'),
                items: tiposCabine
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => tipoCabine = v),
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Data de desembarque'),
                subtitle: Text(
                  dataDesembarque == null
                      ? 'Selecionar'
                      : '${dataDesembarque!.day}/${dataDesembarque!.month}/${dataDesembarque!.year}',
                ),
                onTap: _selecionarData,
              ),

              const Divider(height: 32),

              /// ================= INFORMAÇÕES DO NAVIO =================
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
                controller: nacionalidadeTripulacaoController,
                decoration: const InputDecoration(
                  labelText: 'Nacionalidade da tripulação',
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: numeroCabinesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de cabines',
                ),
              ),

              SwitchListTile(
                title: const Text('Possui frigobar'),
                value: possuiFrigobar,
                onChanged: (v) => setState(() => possuiFrigobar = v),
              ),

              SwitchListTile(
                title: const Text('Possui pia'),
                value: possuiPia,
                onChanged: (v) => setState(() => possuiPia = v),
              ),

              const Divider(height: 32),

              /// ================= ITENS DE AVALIAÇÃO =================
              for (final item in _itensAvaliacao)
                _avaliacaoItemCard(item),

              const Divider(height: 32),

              /// ================= OBSERVAÇÃO GERAL =================
              TextFormField(
                controller: observacaoGeralController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observação geral',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avaliacaoItemCard(String item) {
    final valor = notasPorItem[item]!;
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
              onChanged: (v) => setState(() => notasPorItem[item] = v),
            ),
            TextField(
              controller: obsPorItemController[item],
              decoration:
                  const InputDecoration(hintText: 'Observação (opcional)'),
            ),
          ],
        ),
      ),
    );
  }
}
