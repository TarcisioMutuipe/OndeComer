using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using OndeComer.Application.Interfaces;
using OndeComer.Application.Services;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;
using OndeComer.Infrastructure.Repositories;
using OndeComer.Infrastructure.Security;
using OndeComer.Infrastructure.Services;
using OndeComer.Infrastructure.UnitOfWork;

namespace OndeComer.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' não encontrada.");

        var usePostgres = configuration.GetValue<bool>("UsePostgres", true);

        if (usePostgres)
            services.AddDbContext<AppDbContext>(opts => opts.UseNpgsql(connectionString));
        else
            services.AddDbContext<AppDbContext>(opts => opts.UseSqlServer(connectionString));

        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();
        services.AddScoped<IRestaurantRepository, RestaurantRepository>();
        services.AddScoped<IDishRepository, DishRepository>();
        services.AddScoped<IPromotionRepository, PromotionRepository>();
        services.AddScoped<IUploadedImageRepository, UploadedImageRepository>();
        services.AddScoped<IReviewRepository, ReviewRepository>();
        services.AddScoped<ICommentRepository, CommentRepository>();
        services.AddScoped<IDashboardRepository, DashboardRepository>();
        services.AddScoped<IFavoriteRepository, FavoriteRepository>();
        services.AddScoped<IWishlistRepository, WishlistRepository>();
        services.AddScoped<IWishlistItemRepository, WishlistItemRepository>();
        services.AddScoped<IEmailConfirmationTokenRepository, EmailConfirmationTokenRepository>();
        services.AddScoped<IPasswordResetTokenRepository, PasswordResetTokenRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork.UnitOfWork>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IImageService, ImageService>();
        services.AddScoped<IReviewService, ReviewService>();
        services.AddScoped<ICommentService, CommentService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IPromotionTicketLifecycleService, PromotionTicketLifecycleService>();
        services.AddScoped<IPromotionService, PromotionService>();
        services.AddHostedService<InactiveDishCleanupHostedService>();
        services.AddScoped<ICheckInRepository, CheckInRepository>();
        services.AddScoped<ICheckInService, CheckInService>();
        services.AddScoped<ILoyaltyRepository, LoyaltyRepository>();
        services.AddScoped<ILoyaltyService, LoyaltyService>();
        services.AddScoped<IModerationService, ModerationService>();
        services.AddScoped<IAdminService, AdminService>();
        services.AddScoped<ICityEventService, CityEventService>();
        services.AddScoped<IReservationService, ReservationService>();
        services.AddSingleton<IPushSender, FcmPushSender>();
        services.AddScoped<IEmailService, ResendEmailService>();
        services.AddHostedService<PromotionTicketReminderHostedService>();
        services.AddHttpClient("FCM");
        services.AddHttpClient("Moderation");
        services.AddHttpClient("Resend");

        var redisConnection = configuration.GetConnectionString("Redis");
        if (!string.IsNullOrEmpty(redisConnection))
        {
            services.AddStackExchangeRedisCache(opts => opts.Configuration = redisConnection);
        }
        else
        {
            services.AddMemoryCache();
            services.AddDistributedMemoryCache();
        }

        return services;
    }
}
