import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/restaurant_list_viewmodel.dart';
import 'restaurant_menu_link.dart';

class RestaurantMenuQrScreen extends ConsumerWidget {
  final String restaurantId;

  const RestaurantMenuQrScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurant = ref.watch(restaurantDetailProvider(restaurantId));
    final menuUrl = restaurantMenuLink(restaurantId);

    return Scaffold(
      appBar: AppBar(title: const Text('QR do cardápio')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 240,
                    height: 82,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    restaurant.valueOrNull == null
                        ? 'Aponte a câmera para abrir o cardápio'
                        : 'Cardápio de ${restaurant.valueOrNull!.name}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: menuUrl,
                          version: QrVersions.auto,
                          size: 260,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/logo_mark.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'QR Code do Onde Comer em Salvador',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/restaurant/$restaurantId/menu'),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Pré-visualizar cardápio'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: menuUrl));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copiado.')),
                        );
                      },
                      icon: const Icon(Icons.content_copy),
                      label: const Text('Copiar link do cardápio'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
