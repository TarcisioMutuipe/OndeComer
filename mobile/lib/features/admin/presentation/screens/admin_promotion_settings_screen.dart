import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/admin_models.dart';

class AdminPromotionSettingsScreen extends ConsumerStatefulWidget {
  const AdminPromotionSettingsScreen({super.key});

  @override
  ConsumerState<AdminPromotionSettingsScreen> createState() =>
      _AdminPromotionSettingsScreenState();
}

class _AdminPromotionSettingsScreenState
    extends ConsumerState<AdminPromotionSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchPriceCtrl = TextEditingController();
  final _ticketsCtrl = TextEditingController();
  final _ticketValidityCtrl = TextEditingController();
  final _claimWindowCtrl = TextEditingController();
  final _pixKeyCtrl = TextEditingController();
  final _receiptPhoneCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  PromotionSettingsModel? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings =
          await ref.read(adminDatasourceProvider).getPromotionSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _batchPriceCtrl.text = settings.batchPrice.toStringAsFixed(2);
        _ticketsCtrl.text = settings.ticketsPerBatch.toString();
        _ticketValidityCtrl.text = settings.ticketValidityDays.toString();
        _claimWindowCtrl.text = settings.claimWindowDays.toString();
        _pixKeyCtrl.text = settings.pixKey ?? '';
        _receiptPhoneCtrl.text = settings.receiptPhoneNumber ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _batchPriceCtrl.dispose();
    _ticketsCtrl.dispose();
    _ticketValidityCtrl.dispose();
    _claimWindowCtrl.dispose();
    _pixKeyCtrl.dispose();
    _receiptPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final settings = PromotionSettingsModel(
        batchPrice: double.parse(_batchPriceCtrl.text.replaceAll(',', '.')),
        ticketsPerBatch: int.parse(_ticketsCtrl.text),
        ticketValidityDays: int.parse(_ticketValidityCtrl.text),
        claimWindowDays: int.parse(_claimWindowCtrl.text),
        pixKey:
            _pixKeyCtrl.text.trim().isEmpty ? null : _pixKeyCtrl.text.trim(),
        receiptPhoneNumber: _receiptPhoneCtrl.text.trim().isEmpty
            ? null
            : _receiptPhoneCtrl.text.trim(),
        updatedAt: DateTime.now().toUtc(),
      );
      final updated = await ref
          .read(adminDatasourceProvider)
          .updatePromotionSettings(settings);
      if (!mounted) return;
      setState(() => _settings = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parâmetros atualizados com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar parâmetros: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Parâmetros de Promoção')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Regras atuais',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                                'Valor do lote: R\$ ${_settings?.batchPrice.toStringAsFixed(2) ?? ''}'),
                            Text(
                                'Tickets por lote: ${_settings?.ticketsPerBatch ?? ''}'),
                            Text(
                                'Validade do ticket: ${_settings?.ticketValidityDays ?? ''} dias'),
                            Text(
                                'Janela de retirada: ${_settings?.claimWindowDays ?? ''} dias'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _batchPriceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Valor do lote (R\$)'),
                      validator: (value) {
                        final parsed =
                            double.tryParse((value ?? '').replaceAll(',', '.'));
                        if (parsed == null || parsed <= 0) {
                          return 'Informe um valor válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ticketsCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Tickets por lote'),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Informe um número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ticketValidityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Validade do ticket em dias'),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Informe um número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimWindowCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Janela de retirada em dias'),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Informe um número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pixKeyCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Chave Pix (opcional)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _receiptPhoneCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Número para comprovante (opcional)'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: AppTheme.textPrimary,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar parâmetros'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
