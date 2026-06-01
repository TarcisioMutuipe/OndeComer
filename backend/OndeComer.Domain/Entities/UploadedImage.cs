namespace OndeComer.Domain.Entities;

public class UploadedImage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string OriginalFileName { get; set; } = string.Empty;
    public string StoredFileName { get; set; } = string.Empty;
    public string RelativePath { get; set; } = string.Empty;  // uploads/2026/05/guid.jpg
    public long FileSizeBytes { get; set; }
    public string EntityType { get; set; } = string.Empty;    // "Restaurant" | "Dish" | "User"
    public Guid? EntityId { get; set; }
    public Guid UploadedByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
