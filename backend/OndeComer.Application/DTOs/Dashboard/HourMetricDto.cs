namespace OndeComer.Application.DTOs.Dashboard;

public record HourMetricDto(
    int Hour,
    int ReviewCount,
    int CommentCount,
    int TotalInteractions
);
