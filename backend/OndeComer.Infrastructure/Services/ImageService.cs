using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Images;
// AppException(message, 400) is the bad-request equivalent
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;

namespace OndeComer.Infrastructure.Services;

public class ImageService : IImageService
{
    private readonly IUnitOfWork _uow;
    private readonly string _uploadsBasePath;

    private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".webp", ".gif"];
    private const int MaxWidthPx = 1200;
    private const int JpegQuality = 80;
    private const long MaxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

    public ImageService(IUnitOfWork uow, UploadPathOptions options)
    {
        _uow = uow;
        _uploadsBasePath = Path.Combine(options.WebRootPath, "uploads");
    }

    public async Task<UploadedImageDto> UploadAsync(
        Stream fileStream,
        string fileName,
        long fileSize,
        string entityType,
        Guid? entityId,
        Guid uploadedByUserId,
        string requestBaseUrl,
        CancellationToken ct = default)
    {
        if (fileSize == 0)
            throw new AppException("Arquivo vazio.");

        if (fileSize > MaxFileSizeBytes)
            throw new AppException("Arquivo muito grande. Maximo: 10 MB.");

        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(ext))
            throw new AppException("Formato invalido. Use JPG, PNG, WEBP ou GIF.");

        var year  = DateTime.UtcNow.Year.ToString();
        var month = DateTime.UtcNow.Month.ToString("00");
        var datePath = Path.Combine(_uploadsBasePath, year, month);
        Directory.CreateDirectory(datePath);

        var storedFileName = $"{Guid.NewGuid()}.jpg";
        var fullPath = Path.Combine(datePath, storedFileName);

        using var image = await Image.LoadAsync(fileStream, ct);
        if (image.Width > MaxWidthPx)
        {
            var ratio = (double)MaxWidthPx / image.Width;
            image.Mutate(x => x.Resize(
                (int)(image.Width  * ratio),
                (int)(image.Height * ratio)));
        }
        await image.SaveAsync(fullPath, new JpegEncoder { Quality = JpegQuality }, ct);

        var fileInfo     = new FileInfo(fullPath);
        var relativePath = $"uploads/{year}/{month}/{storedFileName}";

        var record = new UploadedImage
        {
            OriginalFileName  = fileName,
            StoredFileName    = storedFileName,
            RelativePath      = relativePath,
            FileSizeBytes     = fileInfo.Length,
            EntityType        = entityType,
            EntityId          = entityId,
            UploadedByUserId  = uploadedByUserId,
        };

        await _uow.UploadedImages.AddAsync(record, ct);
        await _uow.CommitAsync(ct);

        var fullUrl = $"{requestBaseUrl.TrimEnd('/')}/{relativePath}";
        return new UploadedImageDto(
            record.Id, record.RelativePath, fullUrl,
            record.FileSizeBytes, record.EntityType, record.EntityId, record.CreatedAt);
    }
}
