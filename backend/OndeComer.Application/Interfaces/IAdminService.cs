using OndeComer.Application.DTOs.Admin;

namespace OndeComer.Application.Interfaces;

public interface IAdminService
{
    Task<AdminDashboardDto> GetDashboardAsync();
    Task<IEnumerable<AdminUserDto>> GetUsersAsync(string? search, string? profileType, int page, int pageSize);
    Task<AdminUserDto> UpdateUserAsync(Guid userId, AdminUpdateUserRequest request);
    Task DeleteUserAsync(Guid userId);
    Task<IEnumerable<AdminRestaurantDto>> GetRestaurantsAsync(string? search, string? category, int page, int pageSize);
    Task<AdminRestaurantDto> UpdateRestaurantAsync(Guid restaurantId, AdminUpdateRestaurantRequest request);
    Task DeleteRestaurantAsync(Guid restaurantId);
    Task<byte[]> ExportUserDataAsync(Guid userId, string format);
}
