namespace OndeComer.Application.DTOs.Dashboard;

public record CommentMetricDto(
    int TotalComments,
    int ApprovedComments,
    int RejectedComments,
    int PendingComments,
    double ApprovalRate,
    List<RecentCommentDto> RecentComments
);

public record RecentCommentDto(
    Guid Id,
    string DishName,
    string UserName,
    string Text,
    string Status,
    DateTime CreatedAt
);
