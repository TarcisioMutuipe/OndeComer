import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/restaurant/data/models/dish_model.dart';
import '../../features/restaurant/data/models/restaurant_model.dart';
import '../../features/feed/data/models/promotion_model.dart';
import '../../features/restaurant/presentation/screens/restaurant_dashboard_screen.dart';
import '../../features/restaurant/presentation/screens/restaurant_form_screen.dart';
import '../../features/restaurant/presentation/screens/restaurant_detail_screen.dart';
import '../../features/restaurant/presentation/screens/dish_detail_screen.dart';
import '../../features/restaurant/presentation/screens/menu_screen.dart';
import '../../features/restaurant/presentation/screens/restaurant_menu_qr_screen.dart';
import '../../features/restaurant/presentation/screens/dish_form_screen.dart';
import '../../features/restaurant/presentation/screens/metrics_dashboard_screen.dart';
import '../../features/restaurant/presentation/screens/my_reservations_screen.dart';
import '../../features/restaurant/presentation/screens/restaurant_reservations_screen.dart';
import '../../features/reviews/presentation/screens/moderation_screen.dart';
import '../../features/feed/presentation/screens/owner_promotions_screen.dart';
import '../../features/feed/presentation/screens/my_tickets_screen.dart';
import '../../features/feed/presentation/screens/finalize_promotion_ticket_screen.dart';
import '../../features/feed/presentation/screens/promotion_detail_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/favorites/presentation/screens/minhas_favoritas_screen.dart';
import '../../features/favorites/presentation/screens/minhas_listas_screen.dart';
import '../../features/favorites/presentation/screens/lista_publica_screen.dart';
import '../../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../../features/checkin/presentation/screens/checkin_screen.dart';
import '../../features/checkin/presentation/screens/qr_code_screen.dart';
import '../../features/checkin/presentation/screens/checkin_history_screen.dart';
import '../../features/loyalty/presentation/screens/loyalty_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_restaurant_list_screen.dart';
import '../../features/admin/presentation/screens/admin_dish_list_screen.dart';
import '../../features/admin/presentation/screens/admin_promotion_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_promotion_tickets_screen.dart';
import '../../features/legal/presentation/screens/terms_of_use_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/rankings/presentation/screens/rankings_screen.dart';
import '../../features/social/presentation/screens/onde_comer_hoje_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isPublicMenu = state.matchedLocation.startsWith('/restaurant/') &&
          state.matchedLocation.endsWith('/menu');
      final isAdminRoute = state.matchedLocation == AppRoutes.admin ||
          state.matchedLocation.startsWith('${AppRoutes.admin}/');
      final isAdmin = authState.user?.profileType == 'Admin';

      if (isSplash) return null;
      if (!isLoggedIn && !isAuth && !isPublicMenu) return AppRoutes.login;
      if (isLoggedIn && isAuth)
        return isAdmin ? AppRoutes.admin : AppRoutes.home;
      if (isAdmin && !isAdminRoute && !isPublicMenu) return AppRoutes.admin;
      if (isAdminRoute && !isAdmin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // Bottom nav tabs (wrapped in MainScaffold)
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => MainScaffold(child: const SearchScreen()),
      ),
      GoRoute(
        path: AppRoutes.feed,
        builder: (context, state) => MainScaffold(child: const FeedScreen()),
      ),
      GoRoute(
        path: AppRoutes.promotionDetails,
        builder: (context, state) => PromotionDetailScreen(
          promotion: state.extra as PromotionModel,
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => MainScaffold(child: const ProfileScreen()),
      ),
      // Wishlists — rota pública ANTES das autenticadas
      GoRoute(
        path: '/wishlists/public/:shareToken',
        builder: (context, state) => ListaPublicaScreen(
          shareToken: state.pathParameters['shareToken']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) =>
            MainScaffold(child: const MinhasFavoritasScreen()),
      ),
      GoRoute(
        path: AppRoutes.wishlists,
        builder: (context, state) =>
            MainScaffold(child: const MinhasListasScreen()),
      ),
      GoRoute(
        path: AppRoutes.myTickets,
        builder: (context, state) =>
            MainScaffold(child: const MyTicketsScreen()),
      ),
      GoRoute(
        path: AppRoutes.myReservations,
        builder: (context, state) =>
            MainScaffold(child: const MyReservationsScreen()),
      ),
      // Restaurant owner routes (static — must come before parameterized :restaurantId)
      GoRoute(
        path: '/restaurant/panel',
        builder: (context, state) => const MetricsDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.restaurantDashboard,
        builder: (context, state) => const RestaurantDashboardScreen(),
      ),
      GoRoute(
        path: '/restaurant/metrics/:restaurantId',
        builder: (context, state) => MetricsDashboardScreen(
          restaurantId: state.pathParameters['restaurantId'],
        ),
      ),
      GoRoute(
        path: '/restaurant/:restaurantId/reservations',
        builder: (context, state) => RestaurantReservationsScreen(
          restaurantId: state.pathParameters['restaurantId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.restaurantForm,
        builder: (context, state) => RestaurantFormScreen(
          restaurant: state.extra as RestaurantModel?,
          isAdmin: state.uri.queryParameters['admin'] == 'true',
        ),
      ),
      GoRoute(
        path: '/restaurant/:restaurantId/menu/qr',
        builder: (context, state) => RestaurantMenuQrScreen(
          restaurantId: state.pathParameters['restaurantId']!,
        ),
      ),
      GoRoute(
        path: '/restaurant/:restaurantId/menu',
        builder: (context, state) => MenuScreen(
          restaurantId: state.pathParameters['restaurantId']!,
          initialCategory: state.uri.queryParameters['categoria'],
          initialSubcategory: state.uri.queryParameters['subcategoria'],
          focusDishId: state.uri.queryParameters['prato'],
        ),
      ),
      GoRoute(
        path: '/restaurant/:restaurantId/dish/form',
        builder: (context, state) => DishFormScreen(
          restaurantId: state.pathParameters['restaurantId']!,
          dish: state.extra as DishModel?,
        ),
      ),
      // Dish detail with reviews
      GoRoute(
        path: '/dish/:dishId',
        builder: (context, state) => DishDetailScreen(
          dish: state.extra as DishModel,
        ),
      ),
      // Restaurant moderation (owner only)
      GoRoute(
        path: AppRoutes.moderation,
        builder: (context, state) => const ModerationScreen(),
      ),
      // Owner promotions management
      GoRoute(
        path: AppRoutes.ownerPromotions,
        builder: (context, state) => OwnerPromotionsScreen(
          restaurantId: state.extra as String,
        ),
      ),
      GoRoute(
        path: AppRoutes.finalizePromotionTicket,
        builder: (context, state) => const FinalizePromotionTicketScreen(),
      ),
      // Restaurant public detail (parameterized — must come after static routes)
      GoRoute(
        path: '/restaurant/:restaurantId',
        builder: (context, state) => RestaurantDetailScreen(
          restaurantId: state.pathParameters['restaurantId']!,
        ),
      ),
      // Notification preferences
      GoRoute(
        path: AppRoutes.notificationPreferences,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      // Check-in (deep link: ondecomer://checkin/:restaurantId)
      GoRoute(
        path: '/checkin/:restaurantId',
        builder: (context, state) => CheckInScreen(
          restaurantId: state.pathParameters['restaurantId']!,
        ),
      ),
      // QR Code screen for restaurant owner
      GoRoute(
        path: '/restaurant/:restaurantId/qr',
        builder: (context, state) => QrCodeScreen(
          restaurantId: state.pathParameters['restaurantId']!,
        ),
      ),
      // Check-in history
      GoRoute(
        path: AppRoutes.checkInHistory,
        builder: (context, state) => const CheckInHistoryScreen(),
      ),
      // Loyalty / Fidelidade
      GoRoute(
        path: AppRoutes.loyalty,
        builder: (context, state) => const LoyaltyScreen(),
      ),
      // Admin
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'promotions/settings',
            builder: (context, state) => const AdminPromotionSettingsScreen(),
          ),
          GoRoute(
            path: 'promotions/tickets',
            builder: (context, state) => const AdminPromotionTicketsScreen(),
          ),
          GoRoute(
            path: 'restaurants',
            builder: (context, state) => const AdminRestaurantListScreen(),
          ),
          GoRoute(
            path: 'restaurant/:restaurantId/dishes',
            builder: (context, state) => AdminDishListScreen(
              restaurantId: state.pathParameters['restaurantId']!,
            ),
          ),
        ],
      ),
      // Legal
      GoRoute(
        path: AppRoutes.termsOfUse,
        builder: (context, state) => const TermsOfUseScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      // Rankings & Trending
      GoRoute(
        path: AppRoutes.rankings,
        builder: (context, state) =>
            MainScaffold(child: const RankingsScreen()),
      ),
      // Onde Comer Hoje (Enquete & Roleta de Decisão Social)
      GoRoute(
        path: AppRoutes.ondeComerHoje,
        builder: (context, state) =>
            MainScaffold(child: const OndeComerHojeScreen()),
      ),
    ],
  );
});

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const profile = '/profile';
  static const search = '/search';
  static const feed = '/feed';
  static const restaurantDashboard = '/restaurant/dashboard';
  static const restaurantForm = '/restaurant/form';
  static const moderation = '/restaurant/moderation';
  static const ownerPromotions = '/restaurant/promotions';
  static const finalizePromotionTicket = '/restaurant/promotions/finalize';
  static const favorites = '/favorites';
  static const wishlists = '/wishlists';
  static const myTickets = '/tickets';
  static const myReservations = '/reservations/my';
  static const promotionDetails = '/promotion/details';
  static const notificationPreferences = '/notifications/preferences';
  static const checkInHistory = '/checkins/history';
  static const loyalty = '/loyalty';
  static const admin = '/admin';
  static const adminPromotionSettings = '/admin/promotions/settings';
  static const adminPromotionTickets = '/admin/promotions/tickets';
  static const adminRestaurants = '/admin/restaurants';
  static const termsOfUse = '/terms';
  static const privacyPolicy = '/privacy';
  static const rankings = '/rankings';
  static const ondeComerHoje = '/onde-comer-hoje';
}
