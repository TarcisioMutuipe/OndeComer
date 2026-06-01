using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Review;

public record CreateReviewRequest(
    [Required][Range(1, 5)] int Rating
);
