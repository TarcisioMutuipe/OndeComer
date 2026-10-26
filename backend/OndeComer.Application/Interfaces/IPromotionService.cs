using OndeComer.Application.DTOs.Promotion;
using OndeComer.Application.Common;
using OndeComer.Domain.Enums;

namespace OndeComer.Application.Interfaces;

public interface IPromotionService
{
    Task<PromotionSummaryDto> GetSummaryAsync(CancellationToken ct = default);
    Task<PromotionSettingsDto> GetSettingsAsync(CancellationToken ct = default);
    Task<PromotionSettingsDto> UpdateSettingsAsync(UpdatePromotionSettingsRequest request, CancellationToken ct = default);
    Task<PagedResult<PromotionDto>> GetFeedAsync(int page, int pageSize, CancellationToken ct = default);
    Task<IEnumerable<PromotionDto>> GetByRestaurantAsync(Guid restaurantId, CancellationToken ct = default);
    Task<PromotionDto> CreateAsync(Guid ownerId, CreatePromotionRequest request, CancellationToken ct = default);
    Task<PromotionDto> UpdateAsync(Guid ownerId, Guid promotionId, UpdatePromotionRequest request, CancellationToken ct = default);
    Task DeleteAsync(Guid ownerId, Guid promotionId, CancellationToken ct = default);
    Task<ClaimPromotionTicketResponse> ClaimAsync(Guid userId, Guid promotionId, CancellationToken ct = default);
    Task<IEnumerable<PromotionTicketDto>> GetMyTicketsAsync(Guid userId, CancellationToken ct = default);
    Task<IEnumerable<PromotionTicketDto>> GetRestaurantTicketsAsync(Guid ownerId, CancellationToken ct = default);
    Task<PromotionTicketDto> FinalizeAsync(Guid ownerId, FinalizePromotionTicketRequest request, CancellationToken ct = default);
    Task<PromotionTicketsAdminSummaryDto> GetAdminTicketsSummaryAsync(Guid? restaurantId, PromotionTicketStatus? status, DateTime? from, DateTime? to, CancellationToken ct = default);
    Task<PagedResult<PromotionTicketAdminDto>> GetAdminTicketsAsync(Guid? restaurantId, PromotionTicketStatus? status, DateTime? from, DateTime? to, int page, int pageSize, CancellationToken ct = default);
}
