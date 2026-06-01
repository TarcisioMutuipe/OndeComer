using Microsoft.Extensions.DependencyInjection;
using OndeComer.Application.Interfaces;
using OndeComer.Application.Services;

namespace OndeComer.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IRestaurantService, RestaurantService>();
        services.AddScoped<IDishService, DishService>();
        services.AddScoped<IFavoriteService, FavoriteService>();
        services.AddScoped<IWishlistService, WishlistService>();
        services.AddScoped<IDashboardService, DashboardService>();
        return services;
    }
}
