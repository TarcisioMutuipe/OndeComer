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
  bool _chargeEnabled = false;
  bool _loadingPendingPayments = true;
  PromotionSettingsModel? _settings;
  List<PendingPromotionPaymentModel> _pendingPayments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final datasource = ref.read(adminDatasourceProvider);
      final settings = await datasource.getPromotionSettings();
      var pendingPayments = <PendingPromotionPaymentModel>[];
      try {
        pendingPayments = await datasource.getPendingPromotionPayments();
      } catch (_) {
        // Settings remain usable if the pending queue cannot be loaded.
      }
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _chargeEnabled = settings.chargeEnabled;
        _pendingPayments = pendingPayments;
        _loadingPendingPayments = false;
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
      setState(() {
        _loading = false;
        _loadingPendingPayments = false;
      });
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
        chargeEnabled: _chargeEnabled,
        updatedAt: DateTime.now().toUtc(),
      );
      final updated = await ref
          .read(adminDatasourceProvider)
          .updatePromotionSettings(settings);
      if (!mounted) return;
      setState(() {
        _settings = updated;
        _chargeEnabled = updated.chargeEnabled;
      });
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

  Future<void> _approvePayment(PendingPromotionPaymentModel payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar recebimento do Pix?'),
        content: Text(
          'Confirme somente depois de verificar o pagamento de ${payment.restaurantName} para “${payment.title}”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar Pix'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(adminDatasourceProvider)
          .approvePromotionPayment(payment.promotionId);
      final pending =
          await ref.read(adminDatasourceProvider).getPendingPromotionPayments();
      if (!mounted) return;
      setState(() => _pendingPayments = pending);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pagamento confirmado e promoção liberada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível confirmar o pagamento: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cobrança de tickets promocionais'),
                      subtitle: Text(_chargeEnabled
                          ? 'Promoções aguardam o Pix e a conferência do administrador.'
                          : 'Promoções seguem gratuitas e são publicadas normalmente.'),
                      value: _chargeEnabled,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _chargeEnabled = value),
                    ),
                    const SizedBox(height: 8),
                    Text('Conferência de pagamentos Pix',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_loadingPendingPayments)
                      const LinearProgressIndicator()
                    else if (_pendingPayments.isEmpty)
                      const Text('Nenhum pagamento aguardando conferência.')
                    else
                      ..._pendingPayments.map((payment) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payment.restaurantName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Text(payment.title),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${payment.totalTickets} tickets · R\$ ${(payment.paymentAmount ?? 0).toStringAsFixed(2)}',
                                  ),
                                  if (payment.pixKey != null)
                                    SelectableText('Pix: ${payment.pixKey}'),
                                  if (payment.receiptPhoneNumber != null)
                                    SelectableText(
                                        'Comprovante: ${payment.receiptPhoneNumber}'),
                                  Text(
                                    'Início previsto: ${payment.claimStartsAt.toLocal().toString().substring(0, 16)}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.icon(
                                      onPressed: _saving
                                          ? null
                                          : () => _approvePayment(payment),
                                      icon: const Icon(Icons.verified_outlined),
                                      label: const Text('Confirmar Pix'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Regras atuais',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Valor do lote: R\$ ${_settings?.batchPrice.toStringAsFixed(2) ?? ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tickets por lote: ${_settings?.ticketsPerBatch ?? ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Validade do ticket: ${_settings?.ticketValidityDays ?? ''} dias',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Janela de retirada: ${_settings?.claimWindowDays ?? ''} dias',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
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
                          labelText: 'Chave Pix para recebimento'),
                      validator: (value) => _chargeEnabled &&
                              (value == null || value.trim().isEmpty)
                          ? 'Informe a chave Pix para habilitar a cobrança'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _receiptPhoneCtrl,
                      decoration: const InputDecoration(
                          labelText: 'WhatsApp/telefone para comprovantes'),
                      validator: (value) => _chargeEnabled &&
                              (value == null || value.trim().isEmpty)
                          ? 'Informe o telefone de comprovantes para habilitar a cobrança'
                          : null,
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
