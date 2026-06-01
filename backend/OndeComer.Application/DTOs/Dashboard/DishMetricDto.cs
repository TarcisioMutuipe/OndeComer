namespace OndeComer.Application.DTOs.Dashboard;

public record DishMetricDto(
    Guid DishId,
    string DishName,
    double AverageRating,
    int ReviewCount,
    int CommentCount,
    bool IsActive
);
