namespace OndeComer.Application.DTOs.Images;

public record UploadedImageDto(
    Guid Id,
    string RelativePath,
    string FullUrl,
    long FileSizeBytes,
    string EntityType,
    Guid? EntityId,
    DateTime CreatedAt
);
