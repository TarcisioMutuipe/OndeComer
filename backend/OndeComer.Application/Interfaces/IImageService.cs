using OndeComer.Application.DTOs.Images;

namespace OndeComer.Application.Interfaces;

public interface IImageService
{
    Task<UploadedImageDto> UploadAsync(
        Stream fileStream,
        string fileName,
        long fileSize,
        string entityType,
        Guid? entityId,
        Guid uploadedByUserId,
        string requestBaseUrl,
        CancellationToken ct = default);
}
