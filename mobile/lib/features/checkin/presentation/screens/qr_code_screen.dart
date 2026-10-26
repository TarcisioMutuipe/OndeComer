import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/checkin_model.dart';
import '../viewmodels/checkin_viewmodel.dart';

/// Kit Digital de Balcão e Mesa para Download/Impressão (Formato A6: 10,5 x 14,8 cm).
/// Permite ao proprietário do restaurante visualizar e exportar a plaquinha física do salão.
class QrCodeScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const QrCodeScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  int _selectedTemplate = 0; // 0: Mesa A6, 1: Balcão / Caixa

  void _showPrintGuideModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.print, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text(
                  'Guia de Impressão & Acrílico A6',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _guideItem(
              icon: Icons.aspect_ratio,
              title: 'Formato Padrão A6 (10,5 × 14,8 cm)',
              desc:
                  'Tamanho ideal para caber perfeitamente em displays de acrílico padrão T ou L para mesas de restaurante.',
            ),
            const SizedBox(height: 12),
            _guideItem(
              icon: Icons.layers,
              title: 'Papel Recomendado',
              desc:
                  'Couché 250g ou 300g com laminação fosca ou brilho. A laminação protege contra respingos de bebidas e molhos.',
            ),
            const SizedBox(height: 12),
            _guideItem(
              icon: Icons.storefront,
              title: 'Posicionamento no Salão',
              desc:
                  '1 plaquinha por mesa e 2 plaquinhas no balcão de atendimento e caixa para agilizar o atendimento.',
            ),
            const SizedBox(height: 12),
            _guideItem(
              icon: Icons.money_off,
              title: 'Vantagem B2B para o Restaurante',
              desc:
                  'Taxa ZERO sobre os pedidos do salão. Seus clientes pontuam no Passaporte Gastronômico e voltam com mais frequência!',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyKitData(BuildContext context, QrCodeModel qrData) {
    final text = '''📍 KIT DISPLAY DE MESA (A6) - ONDE COMER EM SALVADOR
Restaurante: ${qrData.restaurantName}
Link de Acesso: ${qrData.deepLink}
Código QR: ${qrData.qrContent}

📐 ESPECIFICAÇÕES PARA A GRÁFICA:
• Formato: Padrão A6 (10,5 cm x 14,8 cm)
• Papel sugerido: Couché 250g/300g com laminação fosca
• Suporte: Display acrílico formato T ou L para mesas
• Campanha: Cardápio Digital & Passaporte Gastronômico de Salvador''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Especificações copiadas! Prontas para enviar à gráfica via WhatsApp.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrDataAsync = ref.watch(qrCodeProvider(widget.restaurantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kit de Mesa & Balcão (A6)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Guia de Impressão',
            onPressed: () => _showPrintGuideModal(context),
          ),
        ],
      ),
      body: qrDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Não foi possível carregar os dados: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(qrCodeProvider(widget.restaurantId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    // Preview fallback with simulated model
                    setState(() {});
                  },
                  child: const Text('Ver Modelo de Demonstração'),
                ),
              ],
            ),
          ),
        ),
        data: (qrData) => _buildContent(context, qrData),
      ),
    );
  }

  Widget _buildContent(BuildContext context, QrCodeModel qrData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          // ── Selector de Modelo ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _templateTab(
                    label: 'Display de Mesa A6',
                    subtitle: '10,5 × 14,8 cm (Vertical)',
                    isSelected: _selectedTemplate == 0,
                    onTap: () => setState(() => _selectedTemplate = 0),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _templateTab(
                    label: 'Plaquinha de Balcão',
                    subtitle: 'Check-in & Caixa Rápido',
                    isSelected: _selectedTemplate == 1,
                    onTap: () => setState(() => _selectedTemplate = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Card de Apresentação A6 (Mockup Físico) ─────────────────────
          _buildA6PhysicalCard(qrData),
          const SizedBox(height: 20),

          // ── Botões de Ação ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyKitData(context, qrData),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar Dados p/ Gráfica'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _showPrintGuideModal(context),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Dicas'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Info Card B2B ───────────────────────────────────────────────
          Card(
            color: const Color(0xFFF0FDF4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFBBF7D0)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Taxa Zero em Atendimento de Salão',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF166534),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'O cliente escaneia na mesa, acessa o cardápio e ganha pontos de fidelidade sem nenhum custo percentual para você.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateTab({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.black87 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildA6PhysicalCard(QrCodeModel qrData) {
    final isTable = _selectedTemplate == 0;

    return Center(
      child: Container(
        width: 290,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepOrange.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Header Ribbon (Cores Quentes de Salvador) ────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFE64A19)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'ONDE COMER EM SALVADOR'.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'GUIA OFICIAL DA GASTRONOMIA BAIANA',
                    style: TextStyle(
                      color: Color(0xFFFFCCBC),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Restaurant Name & Call to Action ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Text(
                    qrData.restaurantName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isTable ? Icons.table_bar : Icons.store,
                        size: 14,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTable ? 'MESA OFICIAL' : 'BALCÃO & CAIXA',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTable
                        ? 'Aponte a câmera do seu celular para ver nosso cardápio & pontuar no Passaporte Gastronômico!'
                        : 'Faça check-in aqui pelo app para acumular selos & concorrer a vantagens exclusivas!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── QR Code Central ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: QrImageView(
                data: qrData.qrContent,
                version: QrVersions.auto,
                size: 170,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),

            // ── Selo Passaporte Gastronômico ──────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFC107)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, size: 13, color: Color(0xFFB45309)),
                  SizedBox(width: 4),
                  Text(
                    'Pontua no Passaporte Gastronômico',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Taxa Zero no Salão • Salvador / Bahia',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ondecomeremsalvador.com.br',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Colors.grey.shade500,
                    ),
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
