using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Comment;

/// <summary>Action: "approve" or "reject"</summary>
public record ModerateRequest(
    [Required] string Action
);
