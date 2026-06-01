# Onde Comer Em Salvador — Contexto para Novo Chat

## Stack & Infraestrutura

- **Backend**: .NET 8 / ASP.NET Core, PostgreSQL 18 (porta 5433, user `postgres`, senha `Mutuipe01`, db `ondecomer_dev`)
- **Frontend**: Flutter 3.44.0 / Dart 3.12.0, roda em Chrome via `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000`
- **ORM**: EF Core com auto-migrate no startup. Migrations aplicadas via `dotnet ef database update`
- **State**: Riverpod (StateNotifier pattern). Provider de Dio: `dioProvider` (não `dioClientProvider`)
- **Roteamento**: GoRouter ^14.2.7 — rotas estáticas ANTES de rotas parametrizadas
- **Models Flutter**: Freezed + JsonSerializable — `.freezed.dart` e `.g.dart` gerados via `dart run build_runner build --delete-conflicting-outputs`
- **API URL**: `http://localhost:5000`; estáticos em `wwwroot/`

## Como Rodar

```powershell
# Backend (terminal 1)
Set-Location "C:\OndeComerEmSalvador\backend\OndeComer.API"; dotnet run

# Flutter (terminal 2)
Set-Location "C:\OndeComerEmSalvador\mobile"; flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000

# Build runner (quando criar novos modelos Freezed)
Set-Location "C:\OndeComerEmSalvador\mobile"; dart run build_runner build --delete-conflicting-outputs

# Parar API antes de build (DLL bloqueada)
Stop-Process -Name "OndeComer.API" -ErrorAction SilentlyContinue
```

## Convenções Críticas

- **Exceções**: só `AppException(msg, statusCode)`, `NotFoundException`, `ConflictException`, `UnauthorizedException`, `ForbiddenException` — não existem outras
- **profileType** no Flutter é `String` (`'Restaurant'` para donos, `'Consumer'` para clientes)
- `IRestaurantService.GetByOwnerIdAsync(Guid ownerId, ct)` retorna `RestaurantDto?`
- `IUserRepository.GetByIdAsync(Guid id, ct)` existe
- `CachedNetworkImage` usa `errorWidget:` (não `errorBuilder:`)
- Imagem upload: `multipart/form-data` via `ImageUploadService` (no Flutter)
- Instagram: campo `instagramUrl` armazenado sem prefixo, exibido com `instagram.com/`

---

## Arquitetura Backend

```
backend/
  OndeComer.sln
  OndeComer.Domain/
    Entities/        User, RefreshToken, Restaurant, Dish, Promotion, Review, Comment, UploadedImage
    Enums/           ProfileType, ReviewStatus
    Interfaces/      IUnitOfWork, IUserRepository, IRestaurantRepository, IDishRepository,
                     IPromotionRepository, IReviewRepository, ICommentRepository,
                     IRefreshTokenRepository, IUploadedImageRepository
  OndeComer.Application/
    DTOs/Auth/       RegisterRequest, LoginRequest, GoogleAuthRequest, RefreshTokenRequest,
                     UpdateProfileRequest, UserDto, AuthResponse
    DTOs/Restaurant/ CreateRestaurantRequest, UpdateRestaurantRequest, RestaurantDto, RestaurantListItemDto
    DTOs/Dish/       CreateDishRequest, UpdateDishRequest, DishDto
    DTOs/Promotion/  CreatePromotionRequest, PromotionDto
    DTOs/Review/     CreateReviewRequest, ReviewDto
    DTOs/Comment/    CreateCommentRequest, CommentDto, ModerateRequest
    DTOs/Sync/       SyncDtos (PendingOperation, SyncRequest, SyncResponse, DeltaResponse)
    DTOs/Images/     UploadedImageDto
    Interfaces/      IAuthService, IUserService, ITokenService, IRestaurantService, IDishService,
                     IImageService, IReviewService, ICommentService
    Services/        AuthService, UserService, RestaurantService, DishService, ReviewService,
                     CommentService, UserMappingExtensions
    Common/          AppException, IConfiguration
  OndeComer.Infrastructure/
    Data/            AppDbContext, AppDbContextFactory
    Repositories/    UserRepository, RefreshTokenRepository, RestaurantRepository, DishRepository,
                     PromotionRepository, ReviewRepository, CommentRepository, UploadedImageRepository
    UnitOfWork/      UnitOfWork
    Security/        TokenService
    Services/        ImageService, IWebHostEnvironmentWrapper (UploadPathOptions pattern)
    Migrations/      6 migrations aplicadas (última: AddReviewsAndComments)
  OndeComer.API/
    Controllers/V1/  AuthController, UsersController, RestaurantsController, DishesController,
                     PromotionsController, ReviewsController, ImagesController, SyncController
    Middleware/      GlobalExceptionMiddleware
    Program.cs       (auto-migrate, CORS, JWT, Serilog, static files)
    appsettings.json (ConnectionStrings, Jwt, AllowedOrigins, UploadPath)
```

### Endpoints Principais

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| POST | `/api/v1/auth/register` | — | Cadastro |
| POST | `/api/v1/auth/login` | — | Login |
| POST | `/api/v1/auth/google` | — | Google OAuth |
| POST | `/api/v1/auth/refresh` | — | Refresh token |
| GET/PUT | `/api/v1/users/me` | ✓ | Perfil |
| GET/POST | `/api/v1/restaurants` | GET público | Listar/criar restaurante |
| GET | `/api/v1/restaurants/me` | ✓ | Meu restaurante |
| GET | `/api/v1/restaurants/{id}` | — | Detalhe |
| GET/POST | `/api/v1/restaurants/{id}/dishes` | POST ✓ | Cardápio |
| PUT/DELETE | `/api/v1/dishes/{id}` | ✓ | Editar/excluir prato |
| GET | `/api/v1/promotions` | — | Feed de promoções (filtra ExpiresAt) |
| POST/DELETE | `/api/v1/promotions` | ✓ | Criar/desativar promoção |
| POST | `/api/v1/dishes/{dishId}/review` | ✓ | Avaliar prato (1-5 estrelas) |
| POST | `/api/v1/dishes/{dishId}/comment` | ✓ | Comentar prato |
| GET | `/api/v1/dishes/{dishId}/comments` | — | Listar comentários aprovados |
| GET | `/api/v1/reviews/pending` | ✓ | Reviews pendentes do dono |
| PUT | `/api/v1/reviews/{id}/moderate` | ✓ | Aprovar/rejeitar review |
| GET | `/api/v1/comments/pending` | ✓ | Comentários pendentes do dono |
| PUT | `/api/v1/comments/{id}/moderate` | ✓ | Aprovar/rejeitar comentário |
| POST | `/api/v1/sync` | ✓ | Batch sync de operações offline |
| GET | `/api/v1/sync/changes?since=` | ✓ | Delta sync |
| POST | `/api/v1/images/upload` | ✓ | Upload de imagem |

---

## Arquitetura Flutter

```
mobile/lib/
  main.dart                        (Hive init + SyncQueueService override)
  app/app.dart                     (MaterialApp + GoRouter)
  core/
    constants/api_constants.dart   (todas as URLs/rotas da API)
    network/
      connectivity_service.dart    (connectivityProvider, isOfflineProvider)
      dio_client.dart              (dioProvider, _AuthInterceptor com refresh automático)
      image_upload_service.dart    (uploadImage — multipart)
    offline/
      pending_operation.dart       (HiveObject TypeId=0 — operações offline)
      pending_operation.g.dart     (PendingOperationAdapter — manual, não gerado)
      sync_queue_service.dart      (SyncQueueService — box 'sync_queue')
      sync_processor.dart          (SyncProcessor StateNotifier — processa fila ao reconectar)
    router/app_router.dart         (GoRouter + AppRoutes constants)
    theme/app_theme.dart           (cores, estilos)
  features/
    auth/
      data/models/user_model.dart  (Freezed)
      data/datasources/auth_remote_datasource.dart
      data/repositories/auth_repository_impl.dart
      domain/repositories/auth_repository.dart
      presentation/viewmodels/auth_viewmodel.dart  (authViewModelProvider)
      presentation/screens/       splash, login, register, profile
    feed/
      data/models/promotion_model.dart  (Freezed: id,restaurantId,title,discountPercent,expiresAt...)
      data/datasources/feed_remote_datasource.dart  (getPromotions, getByRestaurant, create, delete)
      presentation/viewmodels/
        feed_viewmodel.dart         (feedViewModelProvider — paginação)
        owner_promotion_viewmodel.dart  (ownerPromotionViewModelProvider.family por restaurantId)
      presentation/screens/
        feed_screen.dart            (_ExpirationBadge: countdown por horas/minutos/dias)
        owner_promotions_screen.dart  (lista + form bottomsheet + guard offline)
    home/
      presentation/screens/home_screen.dart
    restaurant/
      data/models/
        restaurant_model.dart  (Freezed)
        dish_model.dart        (Freezed: id,name,price,category,description,imageUrl,ratingAverage,ratingCount,isActive)
      data/datasources/        restaurant_remote_datasource, dish_remote_datasource
      data/repositories/       restaurant_repository_impl
      domain/repositories/     restaurant_repository
      presentation/viewmodels/ restaurant_viewmodel, restaurant_list_viewmodel, dish_viewmodel
      presentation/screens/
        restaurant_detail_screen.dart   (tiles de prato tappáveis → /dish/:dishId)
        restaurant_dashboard_screen.dart (botões: Gerenciar Promoções, Moderação)
        restaurant_form_screen.dart
        restaurant_list_screen.dart
        menu_screen.dart
        dish_form_screen.dart
        dish_detail_screen.dart         (imagem + info + DishReviewSection)
      presentation/widgets/restaurant_card.dart
    reviews/
      data/models/
        review_model.dart   (Freezed)
        comment_model.dart  (Freezed)
      data/datasources/review_datasource.dart
      presentation/viewmodels/review_viewmodel.dart
        (dishReviewViewModelProvider.family por dishId, moderationViewModelProvider)
      presentation/screens/
        dish_review_section.dart   (estrelas + comentário + guard offline → showOfflineActionModal)
        moderation_screen.dart     (aprovar/rejeitar reviews e comentários pendentes)
    search/
      presentation/screens/search_screen.dart
  shared/widgets/
    main_scaffold.dart         (OfflineBanner integrado no body, nav tabs)
    offline_banner.dart        (banner vermelho quando sem internet)
    offline_action_modal.dart  (bottomsheet: "Esta ação requer conexão")
    sync_pending_badge.dart    (badge de nuvem com contador de pendentes)
    skeleton_loader.dart
```

### Rotas GoRouter (AppRoutes)

| Constante | Path | Screen |
|-----------|------|--------|
| `splash` | `/` | SplashScreen |
| `login` | `/login` | LoginScreen |
| `register` | `/register` | RegisterScreen |
| `home` | `/home` | HomeScreen |
| `profile` | `/profile` | ProfileScreen |
| `search` | `/search` | SearchScreen |
| `feed` | `/feed` | FeedScreen |
| `restaurantDashboard` | `/restaurant/dashboard` | RestaurantDashboardScreen |
| `restaurantForm` | `/restaurant/form` | RestaurantFormScreen |
| `moderation` | `/restaurant/moderation` | ModerationScreen |
| `ownerPromotions` | `/restaurant/promotions` | OwnerPromotionsScreen (extra: restaurantId String) |
| — | `/restaurant/:restaurantId/menu` | MenuScreen |
| — | `/restaurant/:restaurantId/dish/form` | DishFormScreen (extra: DishModel?) |
| — | `/dish/:dishId` | DishDetailScreen (extra: DishModel) |
| — | `/restaurant/:restaurantId` | RestaurantDetailScreen |

---

## Entregas Implementadas

### ENTREGA 1 — Autenticação
- Register/Login/Google OAuth/Refresh Token/Logout
- JWT Bearer + refresh automático via Dio interceptor
- User com ProfileType (Consumer/Restaurant)

### ENTREGA 2 — Restaurantes e Cardápio
- CRUD restaurante (só dono, 1 por usuário)
- CRUD prato (com upload de imagem, categoria, preço)
- Busca/filtro de restaurantes (cidade, categoria, nome)
- Feed público de restaurantes com paginação
- Upload de imagens via `POST /api/v1/images/upload` (multipart, retorna URL)
- `instagramUrl` com prefixo `instagram.com/` no form

### ENTREGA 3 — Feed de Promoções
- Promoções com `ExpiresAt`, `DiscountPercent`, `IsActive`
- Feed público paginado com filtro automático de expiradas
- Countdown badge: vermelho (<1h), laranja (<24h), cinza (>24h)
- Dono cria/exclui via `OwnerPromotionsScreen` (soft delete)

### ENTREGA 4 — Avaliações e Comentários com Moderação
- `Review` (1-5 estrelas, 1 por usuário por prato, unique index)
- `Comment` (texto livre, até 1000 chars)
- Ambos com `ReviewStatus` (Pending/Approved/Rejected)
- Ao aprovar review: recalcula `RatingAverage` e `RatingCount` no Dish
- `DishReviewSection` no `DishDetailScreen`
- `ModerationScreen` para dono aprovar/rejeitar

### ENTREGA 5 — Promoções (parte Flutter)
- `OwnerPromotionsScreen`: lista + form inline (bottomsheet) com date picker
- Expiração validada no backend (deve ser futura)
- Badge countdown no `FeedScreen`

### ENTREGA 6 — Offline-First e Sincronização
- `connectivity_plus` monitora rede em tempo real via `isOfflineProvider`
- `OfflineBanner` vermelho fixo no topo quando sem internet (integrado em `MainScaffold`)
- `PendingOperation` (Hive TypeId=0): `clientId`, `operationType`, `entityType`, `payload`, `retryCount`, `timestamp`
- `SyncQueueService`: wrapper do box Hive `sync_queue`
- `SyncProcessor` (StateNotifier):
  - Escuta `connectivityProvider` — ao reconectar, dispara `processQueue()`
  - Máx 3 tentativas por operação (dead-letter removido após limite)
  - Batch POST para `/api/v1/sync`
  - Idempotência: `ConflictException` no backend = sucesso silencioso
- `showOfflineActionModal`: bottomsheet amigável com texto preservado
- `SyncPendingBadge`: ícone de nuvem com badge vermelho (contagem de pendentes)
- Guards em `DishReviewSection._submit()` e `OwnerPromotionsScreen._submit()`
- Backend `POST /api/v1/sync`: processa batch de operações, retorna `SyncResponse` com resultado por `clientId`
- Backend `GET /api/v1/sync/changes?since=`: retorna delta (estrutura preparada, sem persistência de eventos)

---

## Pendências / Próximas Entregas

> O usuário disse "Aguarde minha validação para prosseguir" — não iniciar próximas entregas até confirmação.

### Possíveis Entregas Futuras (ainda não iniciadas)
- **ENTREGA 7**: Busca avançada (filtros por avaliação, distância, promoção ativa)
- **ENTREGA 8**: Notificações push (moderação aprovada, nova promoção)
- **ENTREGA 9**: Analytics do restaurante (visualizações, avaliação média ao longo do tempo)
- **ENTREGA 10**: Onboarding / tutorial de primeiro uso

---

## Problemas Conhecidos e Soluções

| Problema | Solução |
|----------|---------|
| `IFormFile` na Application layer | Usar `Stream + fileName + fileSize` — Application permanece sem dependência de ASP.NET |
| `BadRequestException` não existe | Usar `AppException(message, 400)` |
| DLL bloqueada ao buildar | `Stop-Process -Name "OndeComer.API" -ErrorAction SilentlyContinue` antes do build |
| `GetByOwnerAsync` não existe | Método correto: `GetByOwnerIdAsync` |
| `debugPrint` conflito (flutter vs dio_client.dart) | Usar `kDebugMode` + `print()` em vez de `debugPrint()` no offline |
| `CachedNetworkImage` não tem `errorBuilder` | Usar `errorWidget: (_, __, ___) =>` |
| GoRouter: rota não encontrada | Rotas estáticas (`/restaurant/dashboard`) ANTES de parametrizadas (`/restaurant/:id`) |
| `profileType` comparison no Flutter | É `String`, comparar com `== 'Restaurant'` |

---

## Dependências Flutter (pubspec.yaml)

```yaml
flutter_riverpod: ^2.5.1
go_router: ^14.2.7
dio: ^5.7.0
connectivity_plus: ^6.0.5
hive: ^2.2.3
hive_flutter: ^1.1.0
flutter_cache_manager: ^3.3.1
flutter_secure_storage: ^9.2.2
google_sign_in: ^6.2.1
cached_network_image: ^3.4.1
shimmer: ^3.0.0
intl: ^0.19.0
freezed_annotation: ^2.4.4
json_annotation: ^4.9.0
image_picker: ^1.1.2
```
