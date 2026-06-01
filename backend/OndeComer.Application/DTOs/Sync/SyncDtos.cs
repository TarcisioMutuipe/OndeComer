using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Sync;

/// <summary>One pending operation to sync from client to server.</summary>
public record PendingOperation(
    [Required] string ClientId,          // client-generated UUID (idempotency key)
    [Required] string OperationType,     // "create_review" | "create_comment"
    [Required] string EntityType,        // "review" | "comment"
    string? EntityId,                    // server ID if update/delete
    [Required] string Payload,           // JSON string
    DateTime Timestamp                   // client-side timestamp (UTC)
);

public record SyncRequest(
    [Required] List<PendingOperation> Operations
);

public record SyncResult(
    string ClientId,
    bool Success,
    string? Error,
    object? Data
);

public record SyncResponse(
    List<SyncResult> Results
);

public record DeltaResponse(
    DateTime Since,
    DateTime AsOf,
    List<object> Changes
);
