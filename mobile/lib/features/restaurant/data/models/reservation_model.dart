class ReservationModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String userId;
  final String customerName;
  final String customerPhone;
  final DateTime reservationDate;
  final String timeSlot;
  final int partySize;
  final int toleranceMinutes;
  final String? notes;
  final int status; // 0=Pending, 1=Confirmed, 2=Cancelled, 3=Completed, 4=NoShow
  final String? cancellationReason;
  final DateTime createdAt;

  const ReservationModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.reservationDate,
    required this.timeSlot,
    required this.partySize,
    this.toleranceMinutes = 15,
    this.notes,
    required this.status,
    this.cancellationReason,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case 0:
        return 'Pendente';
      case 1:
        return 'Confirmada';
      case 2:
        return 'Cancelada';
      case 3:
        return 'Concluída';
      case 4:
        return 'Não compareceu';
      default:
        return 'Confirmada';
    }
  }

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: (json['id'] ?? '').toString(),
      restaurantId: (json['restaurantId'] ?? '').toString(),
      restaurantName: json['restaurantName'] as String? ?? 'Restaurante',
      userId: (json['userId'] ?? '').toString(),
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      reservationDate: json['reservationDate'] != null
          ? DateTime.tryParse(json['reservationDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeSlot: json['timeSlot'] as String? ?? '',
      partySize: (json['partySize'] as num?)?.toInt() ?? 1,
      toleranceMinutes: (json['toleranceMinutes'] as num?)?.toInt() ?? 15,
      notes: json['notes'] as String?,
      status: (json['status'] as num?)?.toInt() ?? 1,
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

