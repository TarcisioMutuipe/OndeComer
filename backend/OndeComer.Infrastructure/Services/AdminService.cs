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
        var today = DateTime.SpecifyKind(now.Date, DateTimeKind.Utc);
        var weekAgo = today.AddDays(-7);

        int totalUsers = 0, totalRestaurants = 0, totalDishes = 0, totalReviews = 0;
        int totalComments = 0, totalCheckIns = 0, pendingModerations = 0, flaggedModerations = 0;
        int activeCampaigns = 0, usersToday = 0, usersThisWeek = 0;
        int totalConsumers = 0, totalRestaurantOwners = 0, totalAdmins = 0;
        int activeUsers = 0, inactiveUsers = 0, activeRestaurants = 0, inactiveRestaurants = 0;
        int totalDishesInFeed = 0, totalPromotions = 0, activePromotions = 0;
        int ticketsClaimed = 0, ticketsRedeemed = 0, ticketsExpired = 0;
        int totalReservations = 0, pendingReservations = 0, confirmedReservations = 0, totalEvents = 0;
        var mostFollowedRestaurants = new List<AdminMostFollowedRestaurantDto>();
        var topRatedDishes = new List<AdminTopDishDto>();

        try { totalUsers = await _context.Users.CountAsync(); } catch { }
        try { totalRestaurants = await _context.Restaurants.CountAsync(); } catch { }
        try { totalDishes = await _context.Dishes.CountAsync(); } catch { }
        try { totalReviews = await _context.Reviews.CountAsync(); } catch { }
        try { totalComments = await _context.Comments.CountAsync(); } catch { }
        try { totalCheckIns = await _context.CheckIns.CountAsync(); } catch { }
        try { pendingModerations = await _context.ModerationLogs.CountAsync(m => m.Result == "flagged" && !m.ReviewedByHuman); } catch { }
        try { flaggedModerations = await _context.ModerationLogs.CountAsync(m => m.Result == "flagged"); } catch { }
        try { activeCampaigns = await _context.LoyaltyCampaigns.CountAsync(c => c.IsActive && c.StartDate <= now && c.EndDate >= now); } catch { }
        try { usersToday = await _context.Users.CountAsync(u => u.CreatedAt >= today); } catch { }
        try { usersThisWeek = await _context.Users.CountAsync(u => u.CreatedAt >= weekAgo); } catch { }

        try { totalConsumers = await _context.Users.CountAsync(u => u.ProfileType == ProfileType.Consumer); } catch { }
        try { totalRestaurantOwners = await _context.Users.CountAsync(u => u.ProfileType == ProfileType.Restaurant); } catch { }
        try { totalAdmins = await _context.Users.CountAsync(u => u.ProfileType == ProfileType.Admin); } catch { }
        try { activeUsers = await _context.Users.CountAsync(u => u.IsActive); } catch { }
        inactiveUsers = Math.Max(0, totalUsers - activeUsers);

        try { activeRestaurants = await _context.Restaurants.CountAsync(r => r.IsActive); } catch { }
        inactiveRestaurants = Math.Max(0, totalRestaurants - activeRestaurants);
        try { totalDishesInFeed = await _context.Dishes.CountAsync(d => d.IsActive && d.ShowInFeed); } catch { }

        try { totalPromotions = await _context.Promotions.CountAsync(); } catch { }
        try { activePromotions = await _context.Promotions.CountAsync(p => p.IsActive && (p.ExpiresAt == null || p.ExpiresAt > now)); } catch { }
        try { ticketsClaimed = await _context.PromotionTickets.CountAsync(t => t.Status == PromotionTicketStatus.Claimed); } catch { }
        try { ticketsRedeemed = await _context.PromotionTickets.CountAsync(t => t.Status == PromotionTicketStatus.Redeemed); } catch { }
        try { ticketsExpired = await _context.PromotionTickets.CountAsync(t => t.Status == PromotionTicketStatus.Expired); } catch { }

        try { totalReservations = await _context.RestaurantReservations.CountAsync(); } catch { }
        try { pendingReservations = await _context.RestaurantReservations.CountAsync(r => r.Status == OndeComer.Domain.Enums.ReservationStatus.Pending); } catch { }
        try { confirmedReservations = await _context.RestaurantReservations.CountAsync(r => r.Status == OndeComer.Domain.Enums.ReservationStatus.Confirmed); } catch { }
        try { totalEvents = await _context.CityEvents.CountAsync(); } catch { }

        try
        {
            var topFavorites = await _context.Favorites
                .AsNoTracking()
                .Where(f => f.RestaurantId != null)
                .GroupBy(f => f.RestaurantId)
                .Select(g => new
                {
                    RestaurantId = g.Key!.Value,
                    Count = g.Count()
                })
                .OrderByDescending(g => g.Count)
                .Take(5)
                .ToListAsync();

            if (topFavorites.Any())
            {
                var restaurantIds = topFavorites.Select(f => f.RestaurantId).ToList();
                var restaurantNames = await _context.Restaurants
                    .AsNoTracking()
                    .Where(r => restaurantIds.Contains(r.Id))
                    .ToDictionaryAsync(r => r.Id, r => r.Name);

                mostFollowedRestaurants = topFavorites
                    .Select(f => new AdminMostFollowedRestaurantDto(
                        f.RestaurantId,
                        restaurantNames.GetValueOrDefault(f.RestaurantId, "Restaurante"),
                        f.Count))
                    .OrderByDescending(r => r.FavoriteCount)
                    .ThenBy(r => r.RestaurantName)
                    .ToList();
            }
        }
        catch { }

        try
        {
            var dishes = await _context.Dishes
                .AsNoTracking()
                .Include(d => d.Restaurant)
                .Where(d => d.IsActive && d.RatingCount > 0)
                .OrderByDescending(d => d.RatingAverage)
                .ThenByDescending(d => d.RatingCount)
                .Take(5)
                .ToListAsync();

            topRatedDishes = dishes.Select(d => new AdminTopDishDto(
                d.Id,
                d.Name,
                d.Restaurant != null ? d.Restaurant.Name : "Restaurante",
                d.RatingAverage,
                d.RatingCount,
                d.Price
            )).ToList();
        }
        catch { }

        return new AdminDashboardDto(
            totalUsers, totalRestaurants, totalDishes, totalReviews,
            totalComments, totalCheckIns, pendingModerations, flaggedModerations,
            activeCampaigns, usersToday, usersThisWeek, mostFollowedRestaurants,
            totalConsumers, totalRestaurantOwners, totalAdmins, activeUsers, inactiveUsers,
            activeRestaurants, inactiveRestaurants, totalDishesInFeed,
            totalPromotions, activePromotions, ticketsClaimed, ticketsRedeemed, ticketsExpired,
            topRatedDishes,
            totalReservations, pendingReservations, confirmedReservations, totalEvents
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
                r.Id, r.Name, r.Owner != null ? r.Owner.Name : "Administrador", r.Category, r.City,
                r.IsActive, r.Dishes.Count, r.CreatedAt,
                r.Description, r.Address, r.Latitude, r.Longitude,
                r.LogoUrl, r.CoverUrl, r.InstagramUrl, r.YouTubeVideoUrl,
                r.OpeningHours, r.OwnerUserId, false, false,
                r.TotalTables, r.HasEventSpace, r.EventSpaceCapacity,
                r.AllowsReservations, r.TablesAvailableForReservation
            ))
            .ToListAsync();

        return restaurants.Select(restaurant => WithDuplicateStatus(restaurant, duplicateStatuses));
    }

    public async Task<AdminRestaurantDto> CreateRestaurantAsync(Guid ownerId, CreateRestaurantRequest request)
    {
        var name = request.Name.Trim();
        var address = request.Address.Trim();

        var exists = await _context.Restaurants.AnyAsync(r =>
            r.Name.ToLower() == name.ToLower() && r.Address.ToLower() == address.ToLower());
        if (exists)
            throw new ConflictException("Já existe um restaurante cadastrado com este mesmo nome no mesmo endereço.");

        var restaurant = new Restaurant
        {
            OwnerUserId = ownerId,
            Name = name,
            Description = request.Description,
            Address = address,
            City = string.IsNullOrWhiteSpace(request.City) ? "Salvador" : request.City.Trim(),
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Category = request.Category,
            LogoUrl = request.LogoUrl,
            CoverUrl = request.CoverUrl,
            InstagramUrl = request.InstagramUrl,
            YouTubeVideoUrl = request.YouTubeVideoUrl,
            OpeningHours = request.OpeningHours ?? string.Empty,
            TotalTables = request.TotalTables,
            HasEventSpace = request.HasEventSpace,
            EventSpaceCapacity = request.EventSpaceCapacity,
            AllowsReservations = request.AllowsReservations,
            TablesAvailableForReservation = request.TablesAvailableForReservation
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
            restaurant.Id, restaurant.Name, restaurant.Owner != null ? restaurant.Owner.Name : "Administrador",
            restaurant.Category, restaurant.City, restaurant.IsActive, dishCount, restaurant.CreatedAt,
            restaurant.Description, restaurant.Address, restaurant.Latitude, restaurant.Longitude,
            restaurant.LogoUrl, restaurant.CoverUrl, restaurant.InstagramUrl, restaurant.YouTubeVideoUrl,
            restaurant.OpeningHours, restaurant.OwnerUserId, false, false,
            restaurant.TotalTables, restaurant.HasEventSpace, restaurant.EventSpaceCapacity,
            restaurant.AllowsReservations, restaurant.TablesAvailableForReservation);
        return WithDuplicateStatus(dto, await GetDuplicateNameStatusesAsync());
    }

    public async Task<AdminRestaurantDto> UpdateRestaurantAsync(Guid restaurantId, AdminUpdateRestaurantRequest request)
    {
        var restaurant = await _context.Restaurants.Include(r => r.Owner).FirstOrDefaultAsync(r => r.Id == restaurantId)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        var targetName = (request.Name ?? restaurant.Name).Trim();
        var targetAddress = (request.Address ?? restaurant.Address).Trim();

        var exists = await _context.Restaurants.AnyAsync(r =>
            r.Id != restaurantId &&
            r.Name.ToLower() == targetName.ToLower() &&
            r.Address.ToLower() == targetAddress.ToLower());
        if (exists)
            throw new ConflictException("Já existe outro restaurante cadastrado com este mesmo nome no mesmo endereço.");

        if (request.Name != null) restaurant.Name = targetName;
        if (request.Description != null) restaurant.Description = request.Description;
        if (request.Address != null) restaurant.Address = targetAddress;
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
        if (request.TotalTables.HasValue) restaurant.TotalTables = request.TotalTables.Value;
        if (request.HasEventSpace.HasValue) restaurant.HasEventSpace = request.HasEventSpace.Value;
        if (request.EventSpaceCapacity.HasValue) restaurant.EventSpaceCapacity = request.EventSpaceCapacity.Value;
        if (request.AllowsReservations.HasValue) restaurant.AllowsReservations = request.AllowsReservations.Value;
        if (request.TablesAvailableForReservation.HasValue) restaurant.TablesAvailableForReservation = request.TablesAvailableForReservation.Value;

        await _context.SaveChangesAsync();

        var dishCount = await _context.Dishes.CountAsync(d => d.RestaurantId == restaurantId);
        var dto = new AdminRestaurantDto(
            restaurant.Id, restaurant.Name, restaurant.Owner != null ? restaurant.Owner.Name : "Administrador",
            restaurant.Category, restaurant.City, restaurant.IsActive, dishCount, restaurant.CreatedAt,
            restaurant.Description, restaurant.Address, restaurant.Latitude, restaurant.Longitude,
            restaurant.LogoUrl, restaurant.CoverUrl, restaurant.InstagramUrl, restaurant.YouTubeVideoUrl,
            restaurant.OpeningHours, restaurant.OwnerUserId, false, false,
            restaurant.TotalTables, restaurant.HasEventSpace, restaurant.EventSpaceCapacity,
            restaurant.AllowsReservations, restaurant.TablesAvailableForReservation);
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
