using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;

namespace OndeComer.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Restaurant> Restaurants => Set<Restaurant>();
    public DbSet<Dish> Dishes => Set<Dish>();
    public DbSet<Promotion> Promotions => Set<Promotion>();
      public DbSet<PromotionTicket> PromotionTickets => Set<PromotionTicket>();
      public DbSet<PromotionSettings> PromotionSettings => Set<PromotionSettings>();
    public DbSet<UploadedImage> UploadedImages => Set<UploadedImage>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<Wishlist> Wishlists => Set<Wishlist>();
    public DbSet<WishlistItem> WishlistItems => Set<WishlistItem>();
    public DbSet<NotificationDevice> NotificationDevices => Set<NotificationDevice>();
    public DbSet<NotificationPreference> NotificationPreferences => Set<NotificationPreference>();
    public DbSet<CheckIn> CheckIns => Set<CheckIn>();
    public DbSet<Badge> Badges => Set<Badge>();
    public DbSet<UserBadge> UserBadges => Set<UserBadge>();
    public DbSet<LoyaltyCampaign> LoyaltyCampaigns => Set<LoyaltyCampaign>();
    public DbSet<LoyaltyPoints> LoyaltyPoints => Set<LoyaltyPoints>();
    public DbSet<ModerationLog> ModerationLogs => Set<ModerationLog>();
    public DbSet<EmailConfirmationToken> EmailConfirmationTokens => Set<EmailConfirmationToken>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);
            entity.Property(u => u.Email).HasMaxLength(256).IsRequired();
            entity.HasIndex(u => u.Email).IsUnique();
            entity.Property(u => u.Username).HasMaxLength(50).IsRequired();
            entity.HasIndex(u => u.Username).IsUnique();
            entity.Property(u => u.Name).HasMaxLength(200).IsRequired();
            entity.Property(u => u.PasswordHash).HasMaxLength(500);
            entity.Property(u => u.GoogleSub).HasMaxLength(200);
            entity.Property(u => u.Address).HasMaxLength(500);
            entity.Property(u => u.PreferredLanguage).HasMaxLength(10).HasDefaultValue("pt-BR");
            entity.Property(u => u.ProfileType).HasConversion<string>().HasMaxLength(20);
            entity.HasMany(u => u.RefreshTokens)
                  .WithOne(r => r.User)
                  .HasForeignKey(r => r.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.Property(r => r.Token).HasMaxLength(500).IsRequired();
            entity.HasIndex(r => r.Token).IsUnique();
        });

        modelBuilder.Entity<Restaurant>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.Property(r => r.Name).HasMaxLength(200).IsRequired();
            entity.Property(r => r.Address).HasMaxLength(500).IsRequired();
            entity.Property(r => r.City).HasMaxLength(100).HasDefaultValue("Salvador");
            entity.Property(r => r.Category).HasMaxLength(100).IsRequired();
            entity.Property(r => r.Description).HasMaxLength(1000);
            entity.Property(r => r.LogoUrl).HasMaxLength(500);
            entity.Property(r => r.CoverUrl).HasMaxLength(500);
            entity.Property(r => r.OpeningHours).HasColumnType("text").HasDefaultValue("");
            entity.HasIndex(r => new { r.Latitude, r.Longitude })
                  .HasDatabaseName("IX_Restaurants_LatLng");
            entity.HasOne(r => r.Owner)
                  .WithMany()
                  .HasForeignKey(r => r.OwnerUserId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Dish>(entity =>
        {
            entity.HasKey(d => d.Id);
            entity.Property(d => d.Name).HasMaxLength(200).IsRequired();
            entity.Property(d => d.Category).HasMaxLength(100).IsRequired();
            entity.Property(d => d.Description).HasMaxLength(1000);
            entity.Property(d => d.ImageUrl).HasMaxLength(500);
            entity.Property(d => d.Price).HasPrecision(10, 2);
            entity.Property(d => d.RatingAverage).HasPrecision(3, 2);
            entity.HasOne(d => d.Restaurant)
                  .WithMany(r => r.Dishes)
                  .HasForeignKey(d => d.RestaurantId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Promotion>(entity =>
        {
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Title).HasMaxLength(300).IsRequired();
            entity.Property(p => p.Description).HasMaxLength(1000);
            entity.Property(p => p.ImageUrl).HasMaxLength(500);
            entity.Property(p => p.DiscountPercent).HasPrecision(5, 2);
                  entity.Property(p => p.Scope).HasConversion<string>().HasMaxLength(30);
                  entity.Property(p => p.TargetDishIdsJson).HasColumnType("text");
                  entity.Property(p => p.PixKey).HasMaxLength(200);
                  entity.Property(p => p.TotalTickets).HasDefaultValue(10);
                  entity.Property(p => p.RemainingTickets).HasDefaultValue(10);
                  entity.Property(p => p.ClaimStartsAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
                  entity.Property(p => p.ClaimEndsAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
                  entity.Property(p => p.TicketValidityDays).HasDefaultValue(7);
            entity.HasOne(p => p.Restaurant)
                  .WithMany()
                  .HasForeignKey(p => p.RestaurantId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

            modelBuilder.Entity<PromotionTicket>(entity =>
            {
                  entity.HasKey(t => t.Id);
                  entity.Property(t => t.QrCodeToken).HasMaxLength(200).IsRequired();
                  entity.HasIndex(t => t.QrCodeToken).IsUnique();
                  entity.Property(t => t.Status).HasConversion<string>().HasMaxLength(20);
                  entity.Property(t => t.ExpirationReason).HasMaxLength(500);
                  entity.Property(t => t.ReminderSentAt).HasColumnType("timestamp with time zone");
                  entity.HasOne(t => t.Promotion)
                          .WithMany(p => p.Tickets)
                          .HasForeignKey(t => t.PromotionId)
                          .OnDelete(DeleteBehavior.Cascade);
                  entity.HasOne(t => t.User)
                          .WithMany()
                          .HasForeignKey(t => t.UserId)
                          .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<PromotionSettings>(entity =>
            {
                  entity.HasKey(s => s.Id);
                  entity.Property(s => s.BatchPrice).HasPrecision(10, 2);
                  entity.Property(s => s.PixKey).HasMaxLength(200);
                  entity.Property(s => s.ReceiptPhoneNumber).HasMaxLength(30);
            });

        modelBuilder.Entity<UploadedImage>(entity =>
        {
            entity.HasKey(i => i.Id);
            entity.Property(i => i.OriginalFileName).HasMaxLength(500);
            entity.Property(i => i.StoredFileName).HasMaxLength(500).IsRequired();
            entity.Property(i => i.RelativePath).HasMaxLength(500).IsRequired();
            entity.Property(i => i.EntityType).HasMaxLength(50);
        });

        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.Property(r => r.Status).HasConversion<string>().HasMaxLength(20);
            entity.HasIndex(r => new { r.DishId, r.UserId }).IsUnique(); // 1 review per user per dish
            entity.HasOne(r => r.Dish)
                  .WithMany()
                  .HasForeignKey(r => r.DishId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(r => r.User)
                  .WithMany()
                  .HasForeignKey(r => r.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Comment>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.Property(c => c.Text).HasMaxLength(1000).IsRequired();
            entity.Property(c => c.Status).HasConversion<string>().HasMaxLength(20);
            entity.HasOne(c => c.Dish)
                  .WithMany()
                  .HasForeignKey(c => c.DishId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(c => c.User)
                  .WithMany()
                  .HasForeignKey(c => c.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Favorite>(entity =>
        {
            entity.HasKey(f => f.Id);
            // Unicidade: 1 favorito por (usuário, restaurante) ou (usuário, prato)
            entity.HasIndex(f => new { f.UserId, f.RestaurantId, f.DishId }).IsUnique()
                  .HasFilter(null); // índice parcial não é necessário — EF cuida da nulidade
            entity.HasOne(f => f.User)
                  .WithMany()
                  .HasForeignKey(f => f.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(f => f.Restaurant)
                  .WithMany()
                  .HasForeignKey(f => f.RestaurantId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .IsRequired(false);
            entity.HasOne(f => f.Dish)
                  .WithMany()
                  .HasForeignKey(f => f.DishId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .IsRequired(false);
        });

        modelBuilder.Entity<Wishlist>(entity =>
        {
            entity.HasKey(w => w.Id);
            entity.Property(w => w.Name).HasMaxLength(200).IsRequired();
            entity.Property(w => w.Description).HasMaxLength(1000);
            entity.Property(w => w.ShareToken).HasMaxLength(64);
            entity.HasIndex(w => w.ShareToken).IsUnique().HasFilter("\"ShareToken\" IS NOT NULL");
            entity.HasOne(w => w.User)
                  .WithMany()
                  .HasForeignKey(w => w.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasMany(w => w.Items)
                  .WithOne(i => i.Wishlist)
                  .HasForeignKey(i => i.WishlistId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<WishlistItem>(entity =>
        {
            entity.HasKey(i => i.Id);
            entity.Property(i => i.Note).HasMaxLength(500);
            entity.HasOne(i => i.Restaurant)
                  .WithMany()
                  .HasForeignKey(i => i.RestaurantId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .IsRequired(false);
            entity.HasOne(i => i.Dish)
                  .WithMany()
                  .HasForeignKey(i => i.DishId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .IsRequired(false);
        });

        modelBuilder.Entity<CheckIn>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.HasIndex(c => new { c.UserId, c.RestaurantId, c.CheckInTime })
                  .HasDatabaseName("IX_CheckIns_User_Restaurant_Time");
            entity.HasOne(c => c.User)
                  .WithMany()
                  .HasForeignKey(c => c.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(c => c.Restaurant)
                  .WithMany()
                  .HasForeignKey(c => c.RestaurantId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Badge>(entity =>
        {
            entity.HasKey(b => b.Id);
            entity.Property(b => b.Name).HasMaxLength(200).IsRequired();
            entity.Property(b => b.Description).HasMaxLength(500);
            entity.Property(b => b.IconUrl).HasMaxLength(500);
            entity.Property(b => b.Category).HasMaxLength(50);
        });

        modelBuilder.Entity<UserBadge>(entity =>
        {
            entity.HasKey(ub => ub.Id);
            entity.HasIndex(ub => new { ub.UserId, ub.BadgeId }).IsUnique();
            entity.HasOne(ub => ub.User)
                  .WithMany()
                  .HasForeignKey(ub => ub.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(ub => ub.Badge)
                  .WithMany()
                  .HasForeignKey(ub => ub.BadgeId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<LoyaltyCampaign>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.Property(c => c.Title).HasMaxLength(300).IsRequired();
            entity.Property(c => c.Description).HasMaxLength(1000);
            entity.Property(c => c.PointsMultiplier).HasPrecision(5, 2);
            entity.HasOne(c => c.Restaurant)
                  .WithMany()
                  .HasForeignKey(c => c.RestaurantId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<LoyaltyPoints>(entity =>
        {
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Source).HasMaxLength(50).IsRequired();
            entity.HasIndex(p => p.UserId).HasDatabaseName("IX_LoyaltyPoints_UserId");
            entity.HasOne(p => p.User)
                  .WithMany()
                  .HasForeignKey(p => p.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(p => p.Campaign)
                  .WithMany()
                  .HasForeignKey(p => p.CampaignId)
                  .OnDelete(DeleteBehavior.SetNull)
                  .IsRequired(false);
        });

        modelBuilder.Entity<EmailConfirmationToken>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Token).HasMaxLength(256).IsRequired();
            entity.HasIndex(e => e.Token).IsUnique();
            entity.HasOne(e => e.User)
                  .WithMany()
                  .HasForeignKey(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<PasswordResetToken>(entity =>
        {
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Token).HasMaxLength(256).IsRequired();
            entity.HasIndex(p => p.Token).IsUnique();
            entity.HasOne(p => p.User)
                  .WithMany()
                  .HasForeignKey(p => p.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ModerationLog>(entity =>
        {
            entity.HasKey(m => m.Id);
            entity.Property(m => m.ContentType).HasMaxLength(20).IsRequired();
            entity.Property(m => m.EntityType).HasMaxLength(50).IsRequired();
            entity.Property(m => m.Result).HasMaxLength(20).IsRequired();
            entity.Property(m => m.Categories).HasColumnType("text");
            entity.Property(m => m.OriginalContent).HasMaxLength(500);
            entity.Property(m => m.Reason).HasMaxLength(500);
            entity.HasIndex(m => m.Result).HasDatabaseName("IX_ModerationLogs_Result");
            entity.HasIndex(m => m.CreatedAt).HasDatabaseName("IX_ModerationLogs_CreatedAt");
            entity.HasOne(m => m.User)
                  .WithMany()
                  .HasForeignKey(m => m.UserId)
                  .OnDelete(DeleteBehavior.SetNull)
                  .IsRequired(false);
        });
    }
}
