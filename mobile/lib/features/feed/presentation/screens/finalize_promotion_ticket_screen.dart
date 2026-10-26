import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/network/dio_client.dart' show friendlyErrorMessage;
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/finalize_promotion_ticket_viewmodel.dart';

class FinalizePromotionTicketScreen extends ConsumerStatefulWidget {
  const FinalizePromotionTicketScreen({super.key});

  @override
  ConsumerState<FinalizePromotionTicketScreen> createState() =>
      _FinalizePromotionTicketScreenState();
}

class _FinalizePromotionTicketScreenState
    extends ConsumerState<FinalizePromotionTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qrCtrl = TextEditingController();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  String? _lastScannedToken;
  bool _isScanning = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _qrCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isScanning = false);
    await ref
        .read(finalizePromotionTicketViewModelProvider.notifier)
        .finalize(_qrCtrl.text.trim());
  }

  Future<void> _handleScan(String token) async {
    if (token.isEmpty || token == _lastScannedToken) return;
    if (ref.read(finalizePromotionTicketViewModelProvider).isLoading) return;

    setState(() {
      _lastScannedToken = token;
      _isScanning = true;
      _qrCtrl.text = token;
    });

    await _scannerController.stop();
    await _submit();
  }

  void _reset() {
    _qrCtrl.clear();
    _lastScannedToken = null;
    _isScanning = false;
    ref.read(finalizePromotionTicketViewModelProvider.notifier).reset();
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finalizePromotionTicketViewModelProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finalizar ticket'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'Câmera'),
              Tab(icon: Icon(Icons.keyboard_alt), text: 'Manual'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (state.valueOrNull != null)
              _SuccessBanner(
                  message: state.valueOrNull!['message']?.toString() ??
                      'Ticket validado com sucesso.'),
            if (state.hasError)
              _ErrorBanner(message: friendlyErrorMessage(state.error)),
            Expanded(
              child: TabBarView(
                children: [
                  _ScannerTab(
                    controller: _scannerController,
                    isLoading: state.isLoading || _isScanning,
                    onScan: _handleScan,
                  ),
                  _ManualTab(
                    formKey: _formKey,
                    controller: _qrCtrl,
                    isLoading: state.isLoading,
                    onSubmit: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerTab extends StatelessWidget {
  final MobileScannerController controller;
  final bool isLoading;
  final Future<void> Function(String token) onScan;

  const _ScannerTab({
    required this.controller,
    required this.isLoading,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Aponte a câmera para o QR do ticket. Se não funcionar, use a aba manual.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      final token = capture.barcodes
                          .map((barcode) => barcode.rawValue)
                          .firstWhere((value) => value != null,
                              orElse: () => null);
                      if (token != null) {
                        onScan(token);
                      }
                    },
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dica: aproxime a câmera até o QR ficar centralizado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ManualTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function() onSubmit;

  const _ManualTab({
    required this.formKey,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cole o token do QR do ticket para validar a promoção no caixa ou no balcão.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Token do QR',
                prefixIcon: Icon(Icons.qr_code_2_outlined),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o token do QR';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(isLoading ? 'Finalizando...' : 'Finalizar ticket'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;

  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style:
            const TextStyle(fontWeight: FontWeight.w700, color: Colors.green),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.error)),
    );
  }
}
