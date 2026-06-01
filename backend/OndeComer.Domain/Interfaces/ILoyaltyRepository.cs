using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface ILoyaltyRepository
{
    // Points
    Task<LoyaltyPoints> AddPointsAsync(LoyaltyPoints points);
    Task<int> GetTotalPointsAsync(Guid userId);
    Task<IEnumerable<LoyaltyPoints>> GetPointsHistoryAsync(Guid userId, int page, int pageSize);

    // Badges
    Task<IEnumerable<Badge>> GetAllBadgesAsync();
    Task<IEnumerable<UserBadge>> GetUserBadgesAsync(Guid userId);
    Task<UserBadge?> GetUserBadgeAsync(Guid userId, Guid badgeId);
    Task<UserBadge> AddUserBadgeAsync(UserBadge userBadge);

    // Campaigns
    Task<LoyaltyCampaign> AddCampaignAsync(LoyaltyCampaign campaign);
    Task<LoyaltyCampaign?> GetCampaignByIdAsync(Guid id);
    Task<LoyaltyCampaign> UpdateCampaignAsync(LoyaltyCampaign campaign);
    Task<IEnumerable<LoyaltyCampaign>> GetActiveCampaignsAsync(Guid? restaurantId = null);
    Task<LoyaltyCampaign?> GetActiveCampaignForRestaurantAsync(Guid restaurantId);

    // Stats for badge evaluation
    Task<int> GetUserCheckInCountAsync(Guid userId);
    Task<int> GetUserReviewCountAsync(Guid userId);
}
