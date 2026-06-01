import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../viewmodels/checkin_viewmodel.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const CheckInScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _locationLoading = false;

  Future<Position?> _getCurrentPosition() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ative o GPS para fazer check-in')),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Permissão de localização necessária')),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Permissão de localização negada permanentemente. Vá em Configurações.')),
          );
        }
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _doCheckIn() async {
    final position = await _getCurrentPosition();
    if (position == null) return;

    ref.read(checkInActionProvider.notifier).doCheckIn(
          restaurantId: widget.restaurantId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final checkInState = ref.watch(checkInActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              checkInState.valueOrNull?.isValidated == true
                  ? Icons.check_circle
                  : Icons.location_on,
              size: 80,
              color: checkInState.valueOrNull?.isValidated == true
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            if (checkInState.isLoading || _locationLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando localização...'),
                ],
              )
            else if (checkInState.hasError)
              Column(
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    _extractErrorMessage(checkInState.error),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(checkInActionProvider.notifier).reset();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              )
            else if (checkInState.valueOrNull != null)
              Column(
                children: [
                  Text(
                    checkInState.value!.isValidated
                        ? 'Check-in realizado com sucesso!'
                        : 'Check-in registrado, mas você está longe do restaurante.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: checkInState.value!.isValidated
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (checkInState.value!.isValidated)
                    Text(
                      '+${checkInState.value!.pointsAwarded} pontos',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Voltar'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Text(
                    'Faça check-in neste restaurante\npara ganhar pontos!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Você precisa estar a até 200m do restaurante.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _doCheckIn,
                      icon: const Icon(Icons.pin_drop),
                      label: const Text('Fazer Check-in',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _extractErrorMessage(Object? error) {
    if (error == null) return 'Erro desconhecido';
    final str = error.toString();
    if (str.contains('Você já fez check-in')) {
      return 'Você já fez check-in neste restaurante hoje.';
    }
    return 'Erro ao realizar check-in. Tente novamente.';
  }
}
