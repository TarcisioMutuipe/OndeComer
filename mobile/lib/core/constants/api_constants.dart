import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

final String _baseUrl = const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
).isNotEmpty
    ? const String.fromEnvironment('API_BASE_URL')
    : (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux)
        ? 'http://localhost:5000'
        : 'http://10.0.2.2:5000';

class ApiConstants {
  ApiConstants._();

  static final String baseUrl = _baseUrl;
  static const String apiVersion = '/api/v1';
  static const String authBase = '$apiVersion/auth';
  static const String usersBase = '$apiVersion/users';

  // Auth
  static const String register = '$authBase/register';
  static const String login = '$authBase/login';
  static const String google = '$authBase/google';
  static const String refresh = '$authBase/refresh';
  static const String logout = '$authBase/logout';

  // Users
  static const String me = '$usersBase/me';
  static const String checkEmail = '$usersBase/check-email';
  static const String checkUsername = '$usersBase/check-username';

  // Restaurants
  static const String restaurantsBase = '$apiVersion/restaurants';
  static const String restaurantMe = '$restaurantsBase/me';
  static String restaurantById(String id) => '$restaurantsBase/$id';
  static String restaurantDishes(String id, {bool onlyAvailable = false}) =>
      '$restaurantsBase/$id/dishes?onlyAvailable=$onlyAvailable';
  static String restaurantsList({
    String? search,
    String? category,
    String city = 'Salvador',
    int page = 1,
    int pageSize = 20,
  }) {
    final params = <String, String>{
      'city': city,
      'page': '$page',
      'pageSize': '$pageSize',
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    return '$restaurantsBase?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
  }

  // Restaurants - advanced search
  static const String restaurantsSearch = '$restaurantsBase/search';

  // Favorites
  static const String favoritesBase = '$apiVersion/favorites';
  static const String favoritesToggle = '$favoritesBase/toggle';
  static const String favoritesCheck = '$favoritesBase/check';

  // Wishlists
  static const String wishlistsBase = '$apiVersion/wishlists';
  static String wishlistById(String id) => '$wishlistsBase/$id';
  static String wishlistShare(String id) => '$wishlistsBase/$id/share';
  static String wishlistItems(String id) => '$wishlistsBase/$id/items';
  static String wishlistItemById(String itemId) =>
      '$wishlistsBase/items/$itemId';
  static String wishlistPublic(String token) => '$wishlistsBase/public/$token';

  // Promotions / Feed
  static const String promotionsBase = '$apiVersion/promotions';
  static String promotionsByRestaurant(String restaurantId) =>
      '$promotionsBase/restaurant/$restaurantId';
  static String claimPromotion(String promotionId) =>
      '$promotionsBase/$promotionId/claim';
  static const String myPromotionTickets = '$promotionsBase/me/tickets';
  static const String restaurantPromotionTickets =
      '$promotionsBase/restaurant/tickets';
  static const String finalizePromotionTicket = '$promotionsBase/finalize';

  // Sync
  static const String syncBase = '$apiVersion/sync';
  static const String syncChanges = '$apiVersion/sync/changes';

  // Dishes
  static const String dishesBase = '$apiVersion/dishes';
  static const String dishFeed = '$dishesBase/feed';
  static String createDish(String restaurantId) => '$dishesBase/$restaurantId';
  static String dishById(String id) => '$dishesBase/$id';

  // Dashboard Metrics
  static String dashboardOverview(String restaurantId) =>
      '$restaurantsBase/$restaurantId/dashboard/overview';
  static String dashboardDishMetrics(String restaurantId) =>
      '$restaurantsBase/$restaurantId/dashboard/metrics/dishes';
  static String dashboardHourMetrics(String restaurantId) =>
      '$restaurantsBase/$restaurantId/dashboard/metrics/hours';
  static String dashboardCommentMetrics(String restaurantId) =>
      '$restaurantsBase/$restaurantId/dashboard/metrics/comments';

  // Notifications
  static const String notificationsBase = '$apiVersion/notifications';
  static const String notificationsRegisterDevice =
      '$notificationsBase/register-device';
  static const String notificationsUnregisterDevice =
      '$notificationsBase/unregister-device';
  static const String notificationsPreferences =
      '$notificationsBase/preferences';

  // Check-ins
  static const String checkInsBase = '$apiVersion/checkins';
  static const String checkInHistory = '$checkInsBase/history';
  static const String checkInPoints = '$checkInsBase/points';
  static String checkInQr(String restaurantId) =>
      '$checkInsBase/qr/$restaurantId';
  static String checkInRestaurant(String restaurantId) =>
      '$checkInsBase/restaurant/$restaurantId';

  // Loyalty
  static const String loyaltyBase = '$apiVersion/loyalty';
  static const String loyaltyMe = '$loyaltyBase/me';
  static const String loyaltyCampaigns = '$loyaltyBase/campaigns';
  static String loyaltyCampaignById(String id) => '$loyaltyCampaigns/$id';

  // Admin
  static const String adminBase = '$apiVersion/admin';
  static const String adminDashboard = '$adminBase/dashboard';
  static const String adminUsers = '$adminBase/users';
  static const String adminRestaurants = '$adminBase/restaurants';
  static const String adminModerationLogs = '$adminBase/moderation/logs';
  static String adminUserExport(String userId) => '$adminUsers/$userId/export';

  // Account (LGPD)
  static const String accountBase = '$apiVersion/account';
  static const String accountDeleteMe = '$accountBase/me';
  static const String accountExportMe = '$accountBase/me/export';

  // Locales
  static const String locales = '$apiVersion/locales';

  // Rankings / Trending
  static const String rankingsBase = '$apiVersion/rankings';
  static const String topRestaurants = '$rankingsBase/restaurants';
  static const String topDishes = '$rankingsBase/dishes';
  static const String trendingDishes = '$apiVersion/dishes/trending';
  static const String featuredPromotions = '$promotionsBase/featured';

  // Email / Auth extras
  static const String sendConfirmation = '$authBase/send-confirmation';
  static const String confirmEmail = '$authBase/confirm-email';
  static const String forgotPassword = '$authBase/forgot-password';
  static const String resetPassword = '$authBase/reset-password';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}

class StorageKeys {
  StorageKeys._();
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String user = 'cached_user';
}
