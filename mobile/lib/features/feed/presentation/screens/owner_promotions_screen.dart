import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/offline_action_modal.dart';
import '../viewmodels/owner_promotion_viewmodel.dart';
import '../../data/models/promotion_model.dart';

class OwnerPromotionsScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const OwnerPromotionsScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<OwnerPromotionsScreen> createState() =>
      _OwnerPromotionsScreenState();
}

class _OwnerPromotionsScreenState extends ConsumerState<OwnerPromotionsScreen> {
  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(ownerPromotionViewModelProvider(widget.restaurantId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Promoções'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(ownerPromotionViewModelProvider(widget.restaurantId)
                    .notifier)
                .load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova promoção'),
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(ownerPromotionViewModelProvider(widget.restaurantId).notifier)
            .load(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.promotions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer_outlined,
                              size: 64, color: AppTheme.divider),
                          SizedBox(height: 12),
                          Text('Nenhuma promoção ativa.',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.promotions.length,
                    itemBuilder: (_, i) => _PromotionTile(
                      promotion: state.promotions[i],
                      onDelete: () =>
                          _confirmDelete(context, state.promotions[i].id),
                    ),
                  ),
      ),
    );
  }

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _PromotionForm(
        restaurantId: widget.restaurantId,
        onSaved: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String promotionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir promoção?'),
        content: const Text('A promoção será removida do feed imediatamente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(ownerPromotionViewModelProvider(widget.restaurantId)
                      .notifier)
                  .delete(promotionId);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────
class _PromotionTile extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback onDelete;
  const _PromotionTile({required this.promotion, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final diff =
        promotion.expiresAt?.toUtc().difference(DateTime.now().toUtc());
    final expiredSoon = diff != null && !diff.isNegative && diff.inHours < 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading:
            const Icon(Icons.local_offer, color: AppTheme.primaryYellowDark),
        title: Text(promotion.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (promotion.discountPercent != null)
              Text('${promotion.discountPercent!.toStringAsFixed(0)}% OFF',
                  style: const TextStyle(color: AppTheme.primaryYellowDark)),
            if (promotion.expiresAt != null)
              Text(
                'Expira: ${DateFormat('dd/MM/yyyy HH:mm').format(promotion.expiresAt!.toLocal())}',
                style: TextStyle(
                  fontSize: 12,
                  color: expiredSoon
                      ? Colors.red.shade600
                      : AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

// ── Form (BottomSheet) ────────────────────────────────────────────────────
class _PromotionForm extends ConsumerStatefulWidget {
  final String restaurantId;
  final VoidCallback onSaved;
  const _PromotionForm({required this.restaurantId, required this.onSaved});

  @override
  ConsumerState<_PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends ConsumerState<_PromotionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  DateTime? _expiresAt;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (!mounted) return;
    setState(() {
      _expiresAt = time == null
          ? picked
          : DateTime(
              picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Guard: block when offline
    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) {
      if (mounted) await showOfflineActionModal(context);
      return;
    }

    final discount = _discountCtrl.text.trim().isNotEmpty
        ? double.tryParse(_discountCtrl.text.trim().replaceAll(',', '.'))
        : null;

    final ok = await ref
        .read(ownerPromotionViewModelProvider(widget.restaurantId).notifier)
        .create(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim(),
          discountPercent: discount,
          expiresAt: _expiresAt,
        );
    if (ok && mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref
        .watch(ownerPromotionViewModelProvider(widget.restaurantId))
        .isSaving;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nova Promoção',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Descrição (opcional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountCtrl,
                decoration: const InputDecoration(
                    labelText: 'Desconto % (opcional)', hintText: 'Ex: 20'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final d = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (d == null || d < 1 || d > 100) {
                    return 'Entre 1 e 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                    labelText: 'URL da imagem (opcional)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(_expiresAt == null
                    ? 'Definir data de expiração (opcional)'
                    : 'Expira: ${DateFormat('dd/MM/yyyy HH:mm').format(_expiresAt!)}'),
              ),
              if (_expiresAt != null)
                TextButton(
                  onPressed: () => setState(() => _expiresAt = null),
                  child: const Text('Remover data',
                      style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.textPrimary,
                    minimumSize: const Size.fromHeight(48)),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publicar Promoção'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
