using OndeComer.Application.DTOs.Moderation;

namespace OndeComer.Application.Interfaces;

public interface IModerationService
{
    Task<ModerationResult> ScanTextAsync(ScanTextRequest request);
    Task<ModerationResult> ScanImageAsync(ScanImageRequest request);
    Task<IEnumerable<ModerationLogDto>> GetLogsAsync(string? result = null, string? entityType = null, int page = 1, int pageSize = 20);
    Task<ModerationLogDto> ReviewLogAsync(Guid logId, Guid reviewerUserId, string decision);
}
