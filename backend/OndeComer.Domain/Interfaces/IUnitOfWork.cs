namespace OndeComer.Domain.Interfaces;

public interface IUnitOfWork
{
    IUserRepository Users { get; }
    IRefreshTokenRepository RefreshTokens { get; }
    IRestaurantRepository Restaurants { get; }
    IDishRepository Dishes { get; }
    IPromotionRepository Promotions { get; }
    IUploadedImageRepository UploadedImages { get; }
    IReviewRepository Reviews { get; }
    ICommentRepository Comments { get; }
    IFavoriteRepository Favorites { get; }
    IWishlistRepository Wishlists { get; }
    IWishlistItemRepository WishlistItems { get; }
    IEmailConfirmationTokenRepository EmailConfirmationTokens { get; }
    IPasswordResetTokenRepository PasswordResetTokens { get; }
    Task<int> CommitAsync(CancellationToken ct = default);
}
