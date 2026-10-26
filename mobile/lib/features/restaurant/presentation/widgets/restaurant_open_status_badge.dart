import 'dart:convert';
import 'package:flutter/material.dart';

/// Helper to parse if restaurant is open in Salvador time (UTC-3).
bool? parseRestaurantOpenStatus(String? openingHours, {bool? overrideIsOpen}) {
  if (overrideIsOpen != null) return overrideIsOpen;
  if (openingHours == null || openingHours.trim().isEmpty) return null;

  final str = openingHours.trim();

  // 1. JSON format: {"monday":{"open":"11:00","close":"22:00"}, ...}
  if (str.startsWith('{') && str.endsWith('}')) {
    try {
      final doc = jsonDecode(str);
      if (doc is Map<String, dynamic>) {
        // Brazil Standard Time (Salvador: UTC-3)
        final nowBrt =
            DateTime.now().toUtc().subtract(const Duration(hours: 3));
        const days = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday'
        ];
        final dayName = days[nowBrt.weekday - 1];

        final dayData = doc[dayName];
        if (dayData == null) return false;

        final openStr = dayData['open']?.toString();
        final closeStr = dayData['close']?.toString();
        if (openStr == null || closeStr == null) return false;

        final openParts = openStr.split(':');
        final closeParts = closeStr.split(':');
        final openMinutes =
            int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
        final closeMinutes =
            int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
        final currentMinutes = nowBrt.hour * 60 + nowBrt.minute;

        if (closeMinutes < openMinutes) {
          // Overnight (e.g. 18:00 to 02:00)
          return currentMinutes >= openMinutes ||
              currentMinutes <= closeMinutes;
        } else {
          return currentMinutes >= openMinutes &&
              currentMinutes <= closeMinutes;
        }
      }
    } catch (_) {
      // Fall through to regex
    }
  }

  // 2. Text range: "11:00 às 23:00", "12h às 22h", "18h - 02h"
  final match = RegExp(
          r'(\d{1,2})(?:[:h](\d{1,2}))?h?\s*(?:às|a|-|to)\s*(\d{1,2})(?:[:h](\d{1,2}))?h?',
          caseSensitive: false)
      .firstMatch(str);

  if (match != null) {
    try {
      final openH = int.parse(match.group(1)!);
      final openM = int.tryParse(match.group(2) ?? '0') ?? 0;
      final closeH = int.parse(match.group(3)!);
      final closeM = int.tryParse(match.group(4) ?? '0') ?? 0;

      final nowBrt =
          DateTime.now().toUtc().subtract(const Duration(hours: 3));
      final currentMinutes = nowBrt.hour * 60 + nowBrt.minute;
      final openMinutes = openH * 60 + openM;
      final closeMinutes = closeH * 60 + closeM;

      if (closeMinutes < openMinutes) {
        return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
      } else {
        return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
      }
    } catch (_) {
      return null;
    }
  }

  return null;
}

/// Visual status badge showing 🟢 Aberto Agora or 🔴 Fechado.
class RestaurantOpenStatusBadge extends StatelessWidget {
  final String? openingHours;
  final bool? overrideIsOpen;
  final bool compact;

  const RestaurantOpenStatusBadge({
    super.key,
    this.openingHours,
    this.overrideIsOpen,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = parseRestaurantOpenStatus(
      openingHours,
      overrideIsOpen: overrideIsOpen,
    );

    if (isOpen == null) {
      if (openingHours == null || openingHours!.trim().isEmpty || compact) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 12, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              openingHours!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final bgColor = isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final borderColor =
        isOpen ? const Color(0xFF81C784) : const Color(0xFFEF9A9A);
    final textColor =
        isOpen ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
    final dotColor =
        isOpen ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final text = isOpen ? 'Aberto Agora' : 'Fechado';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

