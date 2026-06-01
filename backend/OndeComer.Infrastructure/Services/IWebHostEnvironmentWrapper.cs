namespace OndeComer.Infrastructure.Services;

/// <summary>Options bag that carries the WebRootPath into Infrastructure services.</summary>
public class UploadPathOptions
{
    public string WebRootPath { get; init; } = string.Empty;
}
