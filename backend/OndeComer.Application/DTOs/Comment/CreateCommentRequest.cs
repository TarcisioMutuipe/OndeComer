using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Comment;

public record CreateCommentRequest(
    [Required][MaxLength(1000)] string Text
);
