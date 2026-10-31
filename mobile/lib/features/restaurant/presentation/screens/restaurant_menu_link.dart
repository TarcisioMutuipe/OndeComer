import 'package:flutter/foundation.dart' show kIsWeb;

const _publicWebOrigin = 'https://ondecomeremsalvador.com.br';

String restaurantMenuLink(String restaurantId) {
  final base = kIsWeb ? Uri.base : Uri.parse('$_publicWebOrigin/');
  return base
      .replace(
          path: '/', query: null, fragment: '/restaurant/$restaurantId/menu')
      .toString();
}
