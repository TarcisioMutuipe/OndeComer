using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;
using OndeComer.Infrastructure.Repositories;

namespace OndeComer.Infrastructure.UnitOfWork;

public class UnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _context;

    public IUserRepository Users { get; }
    public IRefreshTokenRepository RefreshTokens { get; }
    public IRestaurantRepository Restaurants { get; }
    public IDishRepository Dishes { get; }
    public IPromotionRepository Promotions { get; }
    public IUploadedImageRepository UploadedImages { get; }
    public IReviewRepository Reviews { get; }
    public ICommentRepository Comments { get; }
    public IFavoriteRepository Favorites { get; }
    public IWishlistRepository Wishlists { get; }
    public IWishlistItemRepository WishlistItems { get; }
    public IEmailConfirmationTokenRepository EmailConfirmationTokens { get; }
    public IPasswordResetTokenRepository PasswordResetTokens { get; }

    public UnitOfWork(AppDbContext context, IUserRepository users, IRefreshTokenRepository refreshTokens,
        IRestaurantRepository restaurants, IDishRepository dishes, IPromotionRepository promotions,
        IUploadedImageRepository uploadedImages, IReviewRepository reviews, ICommentRepository comments,
        IFavoriteRepository favorites, IWishlistRepository wishlists, IWishlistItemRepository wishlistItems,
        IEmailConfirmationTokenRepository emailConfirmationTokens, IPasswordResetTokenRepository passwordResetTokens)
    {
        _context = context;
        Users = users;
        RefreshTokens = refreshTokens;
        Restaurants = restaurants;
        Dishes = dishes;
        Promotions = promotions;
        UploadedImages = uploadedImages;
        Reviews = reviews;
        Comments = comments;
        Favorites = favorites;
        Wishlists = wishlists;
        WishlistItems = wishlistItems;
        EmailConfirmationTokens = emailConfirmationTokens;
        PasswordResetTokens = passwordResetTokens;
    }

    public async Task<int> CommitAsync(CancellationToken ct = default)
        => await _context.SaveChangesAsync(ct);
}
