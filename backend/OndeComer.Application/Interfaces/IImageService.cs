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
    Task AssociateDishImageAsync(Guid dishId, string? imageUrl, CancellationToken ct = default);
    Task<IReadOnlyList<string>> PrepareDishImagesForDeletionAsync(
        Guid dishId, string? imageUrl, CancellationToken ct = default);
    void DeleteStoredImages(IEnumerable<string> relativePaths);
}
