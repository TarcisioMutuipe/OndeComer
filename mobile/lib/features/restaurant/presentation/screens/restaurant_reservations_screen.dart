import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/reservation_remote_datasource.dart';
import '../../data/models/reservation_model.dart';

class RestaurantReservationsScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const RestaurantReservationsScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantReservationsScreen> createState() =>
      _RestaurantReservationsScreenState();
}

class _RestaurantReservationsScreenState
    extends ConsumerState<RestaurantReservationsScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedStatus; // null = all
  bool _isLoading = true;
  String? _error;
  List<ReservationModel> _reservations = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ref
          .read(reservationRemoteDatasourceProvider)
          .getRestaurantReservations(
            restaurantId: widget.restaurantId,
            date: _selectedDate,
            status: _selectedStatus,
          );
      if (mounted) {
        setState(() {
          _reservations = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String reservationId, int newStatus, {String? reason}) async {
    try {
      await ref.read(reservationRemoteDatasourceProvider).updateStatus(
            reservationId: reservationId,
            status: newStatus,
            cancellationReason: reason,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status da reserva atualizado!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadReservations();
    }
  }

  void _callOrWhatsAppCustomer(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/55$cleanPhone');
    launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
      return false;
    });
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas do Salão'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppTheme.primaryYellowDark, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yyyy (EEE)', 'pt_BR').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Hoje',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _selectedDate = DateTime.now());
                    _loadReservations();
                  },
                  icon: const Icon(Icons.today, size: 16),
                  label: const Text('Hoje'),
                ),
              ],
            ),
          ),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('Todas', null),
                const SizedBox(width: 6),
                _filterChip('Pendentes', 0),
                const SizedBox(width: 6),
                _filterChip('Confirmadas', 1),
                const SizedBox(width: 6),
                _filterChip('Concluídas', 3),
                const SizedBox(width: 6),
                _filterChip('Canceladas', 2),
                const SizedBox(width: 6),
                _filterChip('No Show', 4),
              ],
            ),
          ),
          const Divider(height: 1),

          // Reservation List
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? status) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (isSelected && status != null) {
          setState(() => _selectedStatus = null);
        } else {
          setState(() => _selectedStatus = status);
        }
        _loadReservations();
      },
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erro ao carregar reservas',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadReservations,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_seat_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Nenhuma reserva para este filtro/data.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'As reservas feitas pelos clientes no app aparecerão aqui em tempo real.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reservations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final res = _reservations[index];
          final color = _getStatusColor(res.status);

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          res.timeSlot,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryYellowDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              res.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${res.partySize} ${res.partySize == 1 ? 'pessoa' : 'pessoas'} • Tolerância: ${res.toleranceMinutes} min',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Text(
                          res.statusLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 15, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(res.customerPhone, style: const TextStyle(fontSize: 13)),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: () => _callOrWhatsAppCustomer(res.customerPhone),
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  if (res.notes != null && res.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        'Obs do cliente: ${res.notes}',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Actions based on status
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: [
                      if (res.status == 0) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _updateStatus(res.id, 1),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Confirmar'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _updateStatus(res.id, 2, reason: 'Recusado pelo restaurante'),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Recusar'),
                        ),
                      ] else if (res.status == 1) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _updateStatus(res.id, 3),
                          icon: const Icon(Icons.done_all, size: 16),
                          label: const Text('Concluir / Atendido'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.purple),
                          onPressed: () => _updateStatus(res.id, 4, reason: 'Cliente não compareceu'),
                          icon: const Icon(Icons.person_off_outlined, size: 16),
                          label: const Text('Não Compareceu'),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _updateStatus(res.id, 2, reason: 'Cancelado pelo restaurante'),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Cancelar'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

