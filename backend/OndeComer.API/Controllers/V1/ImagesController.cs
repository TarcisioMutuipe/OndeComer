using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/images")]
[Authorize]
public class ImagesController : ControllerBase
{
    private readonly IImageService _imageService;

    public ImagesController(IImageService imageService)
    {
        _imageService = imageService;
    }

    /// <summary>
    /// Upload an image. entityType: "Restaurant" | "Dish" | "User"
    /// </summary>
    [HttpPost("upload")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> Upload(
        IFormFile file,
        [FromQuery] string entityType = "General",
        [FromQuery] Guid? entityId = null,
        CancellationToken ct = default)
    {
        var userId  = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var baseUrl = $"{Request.Scheme}://{Request.Host}";

        using var stream = file.OpenReadStream();
        var result = await _imageService.UploadAsync(
            stream, file.FileName, file.Length,
            entityType, entityId, userId, baseUrl, ct);

        return Ok(new { url = result.FullUrl, relativePath = result.RelativePath, id = result.Id });
    }
}
