using OndeComer.Application.DTOs.Loyalty;

namespace OndeComer.Application.Interfaces;

public interface ILoyaltyService
{
    Task<LoyaltyOverviewResponse> GetUserLoyaltyAsync(Guid userId);
    Task AwardPointsAsync(Guid userId, int basePoints, string source, Guid? referenceId = null, Guid? restaurantId = null);
    Task EvaluateBadgesAsync(Guid userId);
    Task<CampaignDto> CreateCampaignAsync(CreateCampaignRequest request);
    Task<CampaignDto> UpdateCampaignAsync(Guid campaignId, UpdateCampaignRequest request);
    Task<IEnumerable<CampaignDto>> GetActiveCampaignsAsync(Guid? restaurantId = null);
}
