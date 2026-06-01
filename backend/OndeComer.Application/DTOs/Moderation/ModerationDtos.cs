namespace OndeComer.Application.DTOs.Moderation;

public record ScanTextRequest(
    string Text,
    string EntityType,  // "comment", "review"
    Guid? EntityId,
    Guid? UserId
);

public record ScanImageRequest(
    string ImageUrl,
    string EntityType,  // "dish_image", "profile_image"
    Guid? EntityId,
    Guid? UserId
);

public record ModerationResult(
    string Result,       // "approved", "flagged", "blocked"
    double ConfidenceScore,
    string[] DetectedCategories,
    string? Reason
);

public record ModerationLogDto(
    Guid Id,
    string ContentType,
    string EntityType,
    Guid? EntityId,
    Guid? UserId,
    string Result,
    double ConfidenceScore,
    string? Categories,
    string? Reason,
    bool ReviewedByHuman,
    DateTime CreatedAt
);

public record ReviewModerationRequest(
    string Decision  // "approve", "reject"
);
