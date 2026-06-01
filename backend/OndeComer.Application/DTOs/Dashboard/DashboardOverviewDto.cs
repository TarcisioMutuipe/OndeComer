namespace OndeComer.Application.DTOs.Dashboard;

public record DashboardOverviewDto(
    int TotalDishes,
    int ActiveDishes,
    int TotalReviews,
    int ApprovedReviews,
    int PendingReviews,
    int TotalComments,
    int PendingComments,
    double AverageRating,
    double ApprovalRate
);
