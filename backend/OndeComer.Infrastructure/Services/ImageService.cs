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

        // Gera thumbnail otimizado (~400px, 75% qualidade) para listagens rapidas
        var thumbFileName = $"{Path.GetFileNameWithoutExtension(storedFileName)}_thumb.jpg";
        var thumbPath = Path.Combine(datePath, thumbFileName);
        using var thumb = image.Clone(ctx =>
        {
            if (image.Width > 400)
            {
                var thumbRatio = 400.0 / image.Width;
                ctx.Resize(400, (int)(image.Height * thumbRatio));
            }
        });
        await thumb.SaveAsync(thumbPath, new JpegEncoder { Quality = 75 }, ct);

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

    public async Task AssociateDishImageAsync(Guid dishId, string? imageUrl, CancellationToken ct = default)
    {
        var relativePath = GetUploadRelativePath(imageUrl);
        if (relativePath is null) return;

        var image = await _uow.UploadedImages.GetByRelativePathAsync(relativePath, ct);
        if (image is null || image.EntityType != "Dish") return;
        image.EntityId = dishId;
    }

    public async Task<IReadOnlyList<string>> PrepareDishImagesForDeletionAsync(
        Guid dishId, string? imageUrl, CancellationToken ct = default)
    {
        var images = (await _uow.UploadedImages.GetByEntityAsync("Dish", dishId, ct)).ToList();
        var relativePath = GetUploadRelativePath(imageUrl);
        if (relativePath is not null)
        {
            var linkedImage = await _uow.UploadedImages.GetByRelativePathAsync(relativePath, ct);
            if (linkedImage is not null && images.All(image => image.Id != linkedImage.Id))
                images.Add(linkedImage);
        }

        var relativePaths = images.Select(image => image.RelativePath).ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach (var image in images)
        {
            _uow.UploadedImages.Delete(image);
        }

        if (relativePath is not null) relativePaths.Add(relativePath);
        return relativePaths.ToList();
    }

    public void DeleteStoredImages(IEnumerable<string> relativePaths)
    {
        foreach (var relativePath in relativePaths)
            DeleteStoredImage(relativePath);
    }

    private static string? GetUploadRelativePath(string? imageUrl)
    {
        if (string.IsNullOrWhiteSpace(imageUrl)) return null;
        var path = Uri.TryCreate(imageUrl, UriKind.Absolute, out var uri)
            ? uri.AbsolutePath
            : imageUrl;
        path = Uri.UnescapeDataString(path).TrimStart('/').Replace('\\', '/');
        return path.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase) ? path : null;
    }

    private void DeleteStoredImage(string relativePath)
    {
        const string prefix = "uploads/";
        if (!relativePath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)) return;

        var uploadsRoot = Path.GetFullPath(_uploadsBasePath) + Path.DirectorySeparatorChar;
        var fullPath = Path.GetFullPath(Path.Combine(
            _uploadsBasePath,
            relativePath[prefix.Length..].Replace('/', Path.DirectorySeparatorChar)));
        if (!fullPath.StartsWith(uploadsRoot, StringComparison.OrdinalIgnoreCase)) return;

        File.Delete(fullPath);
        var thumbnailPath = Path.Combine(
            Path.GetDirectoryName(fullPath)!,
            $"{Path.GetFileNameWithoutExtension(fullPath)}_thumb.jpg");
        File.Delete(thumbnailPath);
    }
}
