using OndeComer.Application.DTOs.Loyalty;
using OndeComer.Application.Interfaces;
using OndeComer.Application.Common.Exceptions;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;

namespace OndeComer.Infrastructure.Services;

public class LoyaltyService : ILoyaltyService
{
    private readonly ILoyaltyRepository _loyaltyRepository;

    public LoyaltyService(ILoyaltyRepository loyaltyRepository)
    {
        _loyaltyRepository = loyaltyRepository;
    }

    public async Task<LoyaltyOverviewResponse> GetUserLoyaltyAsync(Guid userId)
    {
        var totalPoints = await _loyaltyRepository.GetTotalPointsAsync(userId);
        var totalCheckIns = await _loyaltyRepository.GetUserCheckInCountAsync(userId);
        var totalReviews = await _loyaltyRepository.GetUserReviewCountAsync(userId);
        var allBadges = await _loyaltyRepository.GetAllBadgesAsync();
        var userBadges = await _loyaltyRepository.GetUserBadgesAsync(userId);
        var recentPoints = await _loyaltyRepository.GetPointsHistoryAsync(userId, 1, 10);

        var userBadgeIds = userBadges.Select(ub => ub.BadgeId).ToHashSet();

        var badgeDtos = allBadges.Select(b =>
        {
            var ub = userBadges.FirstOrDefault(x => x.BadgeId == b.Id);
            return new BadgeDto(
                b.Id, b.Name, b.Description, b.IconUrl, b.Category,
                b.RequiredPoints, b.RequiredCheckIns, b.RequiredReviews,
                userBadgeIds.Contains(b.Id),
                ub?.UnlockedAt
            );
        });

        var unlockedBadgeDtos = badgeDtos.Where(b => b.IsUnlocked);

        var pointsDtos = recentPoints.Select(p => new PointsHistoryDto(
            p.Id, p.Points, p.Source, p.EarnedAt, p.Campaign?.Title
        ));

        return new LoyaltyOverviewResponse(
            totalPoints, totalCheckIns, totalReviews,
            badgeDtos, unlockedBadgeDtos, pointsDtos
        );
    }

    public async Task AwardPointsAsync(Guid userId, int basePoints, string source, Guid? referenceId = null, Guid? restaurantId = null)
    {
        var multiplier = 1.0;
        Guid? campaignId = null;

        // Check for active campaign if restaurant is known
        if (restaurantId.HasValue)
        {
            var campaign = await _loyaltyRepository.GetActiveCampaignForRestaurantAsync(restaurantId.Value);
            if (campaign != null)
            {
                multiplier = campaign.PointsMultiplier;
                campaignId = campaign.Id;
            }
        }

        var finalPoints = (int)Math.Round(basePoints * multiplier);

        var loyaltyPoints = new LoyaltyPoints
        {
            UserId = userId,
            Points = finalPoints,
            Source = source,
            ReferenceId = referenceId,
            CampaignId = campaignId
        };

        await _loyaltyRepository.AddPointsAsync(loyaltyPoints);

        // Evaluate badges after awarding points
        await EvaluateBadgesAsync(userId);
    }

    public async Task EvaluateBadgesAsync(Guid userId)
    {
        var totalPoints = await _loyaltyRepository.GetTotalPointsAsync(userId);
        var totalCheckIns = await _loyaltyRepository.GetUserCheckInCountAsync(userId);
        var totalReviews = await _loyaltyRepository.GetUserReviewCountAsync(userId);
        var allBadges = await _loyaltyRepository.GetAllBadgesAsync();

        foreach (var badge in allBadges)
        {
            // Check if already unlocked
            var existing = await _loyaltyRepository.GetUserBadgeAsync(userId, badge.Id);
            if (existing != null) continue;

            // Check conditions
            var meetsPoints = totalPoints >= badge.RequiredPoints;
            var meetsCheckIns = !badge.RequiredCheckIns.HasValue || totalCheckIns >= badge.RequiredCheckIns.Value;
            var meetsReviews = !badge.RequiredReviews.HasValue || totalReviews >= badge.RequiredReviews.Value;

            if (meetsPoints && meetsCheckIns && meetsReviews)
            {
                await _loyaltyRepository.AddUserBadgeAsync(new UserBadge
                {
                    UserId = userId,
                    BadgeId = badge.Id
                });
            }
        }
    }

    public async Task<CampaignDto> CreateCampaignAsync(CreateCampaignRequest request)
    {
        var campaign = new LoyaltyCampaign
        {
            RestaurantId = request.RestaurantId,
            Title = request.Title,
            Description = request.Description,
            PointsMultiplier = request.PointsMultiplier,
            StartDate = request.StartDate,
            EndDate = request.EndDate
        };

        await _loyaltyRepository.AddCampaignAsync(campaign);
        return MapCampaign(campaign);
    }

    public async Task<CampaignDto> UpdateCampaignAsync(Guid campaignId, UpdateCampaignRequest request)
    {
        var campaign = await _loyaltyRepository.GetCampaignByIdAsync(campaignId)
            ?? throw new NotFoundException("Campanha não encontrada.");

        if (request.Title != null) campaign.Title = request.Title;
        if (request.Description != null) campaign.Description = request.Description;
        if (request.PointsMultiplier.HasValue) campaign.PointsMultiplier = request.PointsMultiplier.Value;
        if (request.StartDate.HasValue) campaign.StartDate = request.StartDate.Value;
        if (request.EndDate.HasValue) campaign.EndDate = request.EndDate.Value;
        if (request.IsActive.HasValue) campaign.IsActive = request.IsActive.Value;

        await _loyaltyRepository.UpdateCampaignAsync(campaign);
        return MapCampaign(campaign);
    }

    public async Task<IEnumerable<CampaignDto>> GetActiveCampaignsAsync(Guid? restaurantId = null)
    {
        var campaigns = await _loyaltyRepository.GetActiveCampaignsAsync(restaurantId);
        return campaigns.Select(MapCampaign);
    }

    private static CampaignDto MapCampaign(LoyaltyCampaign c) => new(
        c.Id, c.RestaurantId, c.Title, c.Description,
        c.PointsMultiplier, c.StartDate, c.EndDate, c.IsActive, c.CreatedAt
    );
}
