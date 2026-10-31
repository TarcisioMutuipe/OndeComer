using Microsoft.EntityFrameworkCore;
using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Admin;
using OndeComer.Application.DTOs.Restaurant;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Infrastructure.Data;
using System.Text;
using System.Text.Json;

namespace OndeComer.Infrastructure.Services;

public class AdminService : IAdminService
{
    private readonly AppDbContext _context;

    public AdminService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<AdminDashboardDto> GetDashboardAsync()
    {
        var now = DateTime.UtcNow;
        var today = now.Date;
        var weekAgo = today.AddDays(-7);

        var totalUsers = await _context.Users.CountAsync();
        var totalRestaurants = await _context.Restaurants.CountAsync();
        var totalDishes = await _context.Dishes.CountAsync();
        var totalReviews = await _context.Reviews.CountAsync();
        var totalComments = await _context.Comments.CountAsync();
        var totalCheckIns = await _context.CheckIns.CountAsync();
        var pendingModerations = await _context.ModerationLogs.CountAsync(m => m.Result == "flagged" && !m.ReviewedByHuman);
        var flaggedModerations = await _context.ModerationLogs.CountAsync(m => m.Result == "flagged");
        var activeCampaigns = await _context.LoyaltyCampaigns.CountAsync(c => c.IsActive && c.StartDate <= now && c.EndDate >= now);
        var usersToday = await _context.Users.CountAsync(u => u.CreatedAt >= today);
        var usersThisWeek = await _context.Users.CountAsync(u => u.CreatedAt >= weekAgo);
        var restaurantFavorites = _context.Favorites
            .AsNoTracking()
            .Where(f => f.RestaurantId.HasValue)
            .GroupBy(f => f.RestaurantId!.Value)
            .Select(group => new
            {
                RestaurantId = group.Key,
                FavoriteCount = group.Count()
            });
        var mostFollowedRestaurants = await restaurantFavorites
            .Join(_context.Restaurants.AsNoTracking(),
                favorites => favorites.RestaurantId,
                restaurant => restaurant.Id,
                (favorites, restaurant) => new AdminMostFollowedRestaurantDto(
                    restaurant.Id,
                    restaurant.Name,
                    favorites.FavoriteCount))
            .OrderByDescending(r => r.FavoriteCount)
            .ThenBy(r => r.RestaurantName)
            .Take(5)
            .ToListAsync();

        return new AdminDashboardDto(
            totalUsers, totalRestaurants, totalDishes, totalReviews,
            totalComments, totalCheckIns, pendingModerations, flaggedModerations,
            activeCampaigns, usersToday, usersThisWeek, mostFollowedRestaurants
        );
    }

    public async Task<IEnumerable<AdminUserDto>> GetUsersAsync(string? search, string? profileType, int page, int pageSize)
    {
        var query = _context.Users.AsQueryable();

        if (!string.IsNullOrEmpty(search))
            query = query.Where(u => u.Name.Contains(search) || u.Email.Contains(search) || u.Username.Contains(search));

        if (!string.IsNullOrEmpty(profileType) && Enum.TryParse<ProfileType>(profileType, true, out var pt))
            query = query.Where(u => u.ProfileType == pt);

        var users = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return users.Select(u => new AdminUserDto(
            u.Id, u.Name, u.Email, u.Username,
            u.ProfileType.ToString(), u.IsActive, u.CreatedAt, u.LastLogin
        ));
    }

    public async Task<AdminUserDto> UpdateUserAsync(Guid userId, AdminUpdateUserRequest request)
    {
        var user = await _context.Users.FindAsync(userId)
            ?? throw new NotFoundException("Usuário não encontrado.");

        if (request.Name != null) user.Name = request.Name;
        if (request.Email != null) user.Email = request.Email;
        if (request.IsActive.HasValue) user.IsActive = request.IsActive.Value;
        if (request.ProfileType != null && Enum.TryParse<ProfileType>(request.ProfileType, true, out var pt))
            user.ProfileType = pt;

        await _context.SaveChangesAsync();

        return new AdminUserDto(user.Id, user.Name, user.Email, user.Username,
            user.ProfileType.ToString(), user.IsActive, user.CreatedAt, user.LastLogin);
    }

    public async Task DeleteUserAsync(Guid userId)
    {
        var user = await _context.Users.FindAsync(userId)
            ?? throw new NotFoundException("Usuário não encontrado.");

        // Soft delete
        user.IsActive = false;
        user.Email = $"deleted_{userId}@removed.local";
        user.Name = "Usuário Removido";
        user.PasswordHash = null;
        user.GoogleSub = null;

        await _context.SaveChangesAsync();
    }

    public async Task<IEnumerable<AdminRestaurantDto>> GetRestaurantsAsync(string? search, string? category, int page, int pageSize)
    {
        var duplicateStatuses = await GetDuplicateNameStatusesAsync();
        var query = _context.Restaurants.Include(r => r.Owner).AsQueryable();

        if (!string.IsNullOrEmpty(search))
            query = query.Where(r => r.Name.Contains(search) || r.Address.Contains(search));

        if (!string.IsNullOrEmpty(category))
            query = query.Where(r => r.Category == category);

        var restaurants = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new AdminRestaurantDto(
                r.Id, r.Name, r.Owner.Name, r.Category, r.City,
                r.IsActive, r.Dishes.Count, r.CreatedAt,
                r.Description, r.Address, r.Latitude, r.Longitude,
                r.LogoUrl, r.CoverUrl, r.InstagramUrl, r.YouTubeVideoUrl,
                r.OpeningHours, r.OwnerUserId, false, false
            ))
            .ToListAsync();

        return restaurants.Select(restaurant => WithDuplicateStatus(restaurant, duplicateStatuses));
    }

    public async Task<AdminRestaurantDto> CreateRestaurantAsync(Guid ownerId, CreateRestaurantRequest request)
    {
        var restaurant = new Restaurant
        {
            OwnerUserId = ownerId,
            Name = request.Name.Trim(),
            Description = request.Description,
            Address = request.Address,
            City = request.City,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Category = request.Category,
            LogoUrl = request.LogoUrl,
            CoverUrl = request.CoverUrl,
            InstagramUrl = request.InstagramUrl,
            YouTubeVideoUrl = request.YouTubeVideoUrl,
            OpeningHours = request.OpeningHours ?? string.Empty
        };

        _context.Restaurants.Add(restaurant);
        await _context.SaveChangesAsync();
        return await GetRestaurantByIdAsync(restaurant.Id);
    }

    public async Task<AdminRestaurantDto> GetRestaurantByIdAsync(Guid restaurantId)
    {
        var restaurant = await _context.Restaurants.Include(r => r.Owner).FirstOrDefaultAsync(r => r.Id == restaurantId)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        var dishCount = await _context.Dishes.CountAsync(d => d.RestaurantId == restaurantId);
        var dto = new AdminRestaurantDto(
            restaurant.Id, restaurant.Name, restaurant.Owner.Name,
            restaurant.Category, restaurant.City, restaurant.IsActive, dishCount, restaurant.CreatedAt,
            restaurant.Description, restaurant.Address, restaurant.Latitude, restaurant.Longitude,
            restaurant.LogoUrl, restaurant.CoverUrl, restaurant.InstagramUrl, restaurant.YouTubeVideoUrl,
            restaurant.OpeningHours, restaurant.OwnerUserId);
        return WithDuplicateStatus(dto, await GetDuplicateNameStatusesAsync());
    }

    public async Task<AdminRestaurantDto> UpdateRestaurantAsync(Guid restaurantId, AdminUpdateRestaurantRequest request)
    {
        var restaurant = await _context.Restaurants.Include(r => r.Owner).FirstOrDefaultAsync(r => r.Id == restaurantId)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        if (request.Name != null) restaurant.Name = request.Name;
        if (request.Description != null) restaurant.Description = request.Description;
        if (request.Address != null) restaurant.Address = request.Address;
        if (request.City != null) restaurant.City = request.City;
        if (request.Latitude.HasValue) restaurant.Latitude = request.Latitude.Value;
        if (request.Longitude.HasValue) restaurant.Longitude = request.Longitude.Value;
        if (request.Category != null) restaurant.Category = request.Category;
        if (request.LogoUrl != null) restaurant.LogoUrl = request.LogoUrl;
        if (request.CoverUrl != null) restaurant.CoverUrl = request.CoverUrl;
        if (request.InstagramUrl != null) restaurant.InstagramUrl = request.InstagramUrl;
        if (request.YouTubeVideoUrl != null) restaurant.YouTubeVideoUrl = request.YouTubeVideoUrl;
        if (request.OpeningHours != null) restaurant.OpeningHours = request.OpeningHours;
        if (request.IsActive.HasValue) restaurant.IsActive = request.IsActive.Value;

        await _context.SaveChangesAsync();

        var dishCount = await _context.Dishes.CountAsync(d => d.RestaurantId == restaurantId);
        var dto = new AdminRestaurantDto(
            restaurant.Id, restaurant.Name, restaurant.Owner.Name,
            restaurant.Category, restaurant.City, restaurant.IsActive, dishCount, restaurant.CreatedAt,
            restaurant.Description, restaurant.Address, restaurant.Latitude, restaurant.Longitude,
            restaurant.LogoUrl, restaurant.CoverUrl, restaurant.InstagramUrl, restaurant.YouTubeVideoUrl,
            restaurant.OpeningHours, restaurant.OwnerUserId);
        return WithDuplicateStatus(dto, await GetDuplicateNameStatusesAsync());
    }

    private async Task<Dictionary<string, DuplicateNameStatus>> GetDuplicateNameStatusesAsync()
    {
        var restaurants = await _context.Restaurants
            .AsNoTracking()
            .Select(r => new { r.Name, r.Owner.ProfileType })
            .ToListAsync();

        return restaurants
            .GroupBy(r => NormalizeRestaurantName(r.Name), StringComparer.OrdinalIgnoreCase)
            .Where(group => group.Count() > 1)
            .ToDictionary(
                group => group.Key,
                group => new DuplicateNameStatus(
                    HasDuplicateName: true,
                    HasAdminAndUserDuplicate:
                        group.Any(r => r.ProfileType == ProfileType.Admin) &&
                        group.Any(r => r.ProfileType != ProfileType.Admin)),
                StringComparer.OrdinalIgnoreCase);
    }

    private static AdminRestaurantDto WithDuplicateStatus(
        AdminRestaurantDto restaurant,
        IReadOnlyDictionary<string, DuplicateNameStatus> statuses)
    {
        if (!statuses.TryGetValue(NormalizeRestaurantName(restaurant.Name), out var status))
            return restaurant;

        return restaurant with
        {
            HasDuplicateName = status.HasDuplicateName,
            HasAdminAndUserDuplicate = status.HasAdminAndUserDuplicate
        };
    }

    private static string NormalizeRestaurantName(string name) => name.Trim();

    private sealed record DuplicateNameStatus(bool HasDuplicateName, bool HasAdminAndUserDuplicate);

    public async Task DeleteRestaurantAsync(Guid restaurantId)
    {
        var restaurant = await _context.Restaurants.FindAsync(restaurantId)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        restaurant.IsActive = false;
        await _context.SaveChangesAsync();
    }

    public async Task<byte[]> ExportUserDataAsync(Guid userId, string format)
    {
        var user = await _context.Users.FindAsync(userId)
            ?? throw new NotFoundException("Usuário não encontrado.");

        var reviews = await _context.Reviews.Where(r => r.UserId == userId).ToListAsync();
        var comments = await _context.Comments.Where(c => c.UserId == userId).ToListAsync();
        var checkIns = await _context.CheckIns.Where(c => c.UserId == userId).Include(c => c.Restaurant).ToListAsync();

        if (format.Equals("json", StringComparison.OrdinalIgnoreCase))
        {
            var data = new
            {
                user = new { user.Id, user.Name, user.Email, user.Username, user.ProfileType, user.CreatedAt },
                reviews = reviews.Select(r => new { r.Id, r.DishId, r.Rating, r.CreatedAt }),
                comments = comments.Select(c => new { c.Id, c.DishId, c.Text, c.CreatedAt }),
                checkIns = checkIns.Select(c => new { c.Id, RestaurantName = c.Restaurant.Name, c.CheckInTime, c.PointsAwarded })
            };
            return Encoding.UTF8.GetBytes(JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true }));
        }
        else // CSV
        {
            var sb = new StringBuilder();
            sb.AppendLine("Type,Id,Detail,Date");
            sb.AppendLine($"User,{user.Id},{user.Name} ({user.Email}),{user.CreatedAt:O}");
            foreach (var r in reviews)
                sb.AppendLine($"Review,{r.Id},Rating:{r.Rating} DishId:{r.DishId},{r.CreatedAt:O}");
            foreach (var c in comments)
                sb.AppendLine($"Comment,{c.Id},\"{c.Text.Replace("\"", "'")}\",{c.CreatedAt:O}");
            foreach (var ci in checkIns)
                sb.AppendLine($"CheckIn,{ci.Id},{ci.Restaurant.Name},+{ci.PointsAwarded}pts,{ci.CheckInTime:O}");
            return Encoding.UTF8.GetBytes(sb.ToString());
        }
    }
}
