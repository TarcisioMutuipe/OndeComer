using Microsoft.EntityFrameworkCore;
using OndeComer.Application.Common;
using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Notification;
using OndeComer.Application.DTOs.Promotion;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Infrastructure.Data;
using System.Text.Json;

namespace OndeComer.Infrastructure.Services;

public class PromotionService : IPromotionService
{
    private readonly AppDbContext _context;
    private readonly INotificationService _notificationService;
    private readonly IPromotionTicketLifecycleService _ticketLifecycleService;

    public PromotionService(
        AppDbContext context,
        INotificationService notificationService,
        IPromotionTicketLifecycleService ticketLifecycleService)
    {
        _context = context;
        _notificationService = notificationService;
        _ticketLifecycleService = ticketLifecycleService;
    }

    public async Task<PromotionSummaryDto> GetSummaryAsync(CancellationToken ct = default)
    {
        await ExpireDueTicketsAsync(ct);
        var now = DateTime.UtcNow;

        var totalPromotions = await _context.Promotions.CountAsync(ct);
        var activePromotions = await _context.Promotions.CountAsync(p => p.IsActive && p.ClaimStartsAt <= now && p.ClaimEndsAt >= now, ct);
        var upcomingPromotions = await _context.Promotions.CountAsync(p => p.IsActive && p.ClaimStartsAt > now, ct);
        var totalTickets = await _context.PromotionTickets.CountAsync(ct);
        var claimedTickets = await _context.PromotionTickets.CountAsync(p => p.Status == PromotionTicketStatus.Claimed, ct);
        var redeemedTickets = await _context.PromotionTickets.CountAsync(p => p.Status == PromotionTicketStatus.Redeemed, ct);
        var expiredTickets = await _context.PromotionTickets.CountAsync(p => p.Status == PromotionTicketStatus.Expired, ct);
        var usersOnCooldown = await GetUsersOnCooldownCountAsync(ct);

        return new PromotionSummaryDto(totalPromotions, activePromotions, upcomingPromotions, totalTickets, claimedTickets, redeemedTickets, expiredTickets, usersOnCooldown);
    }

    public async Task<PromotionSettingsDto> GetSettingsAsync(CancellationToken ct = default)
    {
        var settings = await EnsureSettingsAsync(ct);
        return Map(settings);
    }

    public async Task<PromotionSettingsDto> UpdateSettingsAsync(UpdatePromotionSettingsRequest request, CancellationToken ct = default)
    {
        var settings = await EnsureSettingsAsync(ct);
        settings.BatchPrice = request.BatchPrice;
        settings.TicketsPerBatch = request.TicketsPerBatch;
        settings.TicketValidityDays = request.TicketValidityDays;
        settings.ClaimWindowDays = request.ClaimWindowDays;
        settings.PixKey = request.PixKey;
        settings.ReceiptPhoneNumber = request.ReceiptPhoneNumber;
        settings.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(ct);
        return Map(settings);
    }

    public async Task<PagedResult<PromotionDto>> GetFeedAsync(int page, int pageSize, CancellationToken ct = default)
    {
        pageSize = Math.Clamp(pageSize, 1, 50);
        page = Math.Max(page, 1);
        var now = DateTime.UtcNow;

        var query = _context.Promotions
            .AsNoTracking()
            .Include(p => p.Restaurant)
            .Where(p => p.IsActive && p.ClaimEndsAt >= now)
            .OrderBy(p => p.ClaimStartsAt)
            .ThenByDescending(p => p.CreatedAt);

        var totalCount = await query.CountAsync(ct);
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);
        var dtos = await MapManyAsync(items, now, ct);
        return new PagedResult<PromotionDto>(dtos, page, pageSize, totalCount);
    }

    public async Task<IEnumerable<PromotionDto>> GetByRestaurantAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var items = await _context.Promotions
            .AsNoTracking()
            .Include(p => p.Restaurant)
            .Where(p => p.RestaurantId == restaurantId)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

        return await MapManyAsync(items, now, ct);
    }

    public async Task<PromotionDto> CreateAsync(Guid ownerId, CreatePromotionRequest request, CancellationToken ct = default)
    {
        var settings = await EnsureSettingsAsync(ct);
        var restaurant = await _context.Restaurants.FirstOrDefaultAsync(r => r.OwnerUserId == ownerId, ct)
            ?? throw new NotFoundException("Restaurante não encontrado para este usuário.");

        var now = DateTime.UtcNow;
        var claimStartsAt = request.ClaimStartsAt?.ToUniversalTime() ?? now;
        var claimEndsAt = request.ClaimEndsAt?.ToUniversalTime() ?? claimStartsAt.AddDays(settings.ClaimWindowDays);
        if (claimEndsAt <= claimStartsAt)
            throw new AppException("A data final deve ser maior que a data inicial.", 400);

        var ticketCount = request.TicketCount ?? settings.TicketsPerBatch;
        if (ticketCount <= 0 || ticketCount % settings.TicketsPerBatch != 0)
            throw new AppException($"A quantidade de tickets precisa ser múltipla de {settings.TicketsPerBatch}.", 400);

        if (request.Scope == PromotionScope.SpecificDishes)
        {
            var targetDishIds = request.TargetDishIds?.ToArray() ?? Array.Empty<Guid>();
            if (targetDishIds.Length == 0)
                throw new AppException("Selecione os pratos da promoção.", 400);

            var validCount = await _context.Dishes.CountAsync(d => d.RestaurantId == restaurant.Id && targetDishIds.Contains(d.Id), ct);
            if (validCount != targetDishIds.Length)
                throw new AppException("Um ou mais pratos da promoção não pertencem a este restaurante.", 400);
        }

        var promotion = new Promotion
        {
            RestaurantId = restaurant.Id,
            Title = request.Title,
            Description = request.Description,
            ImageUrl = request.ImageUrl,
            DiscountPercent = request.DiscountPercent,
            Scope = request.Scope,
            TargetDishIdsJson = request.TargetDishIds == null ? null : JsonSerializer.Serialize(request.TargetDishIds),
            TotalTickets = ticketCount,
            RemainingTickets = ticketCount,
            ClaimStartsAt = claimStartsAt,
            ClaimEndsAt = claimEndsAt,
            TicketValidityDays = settings.TicketValidityDays,
            PixKey = string.IsNullOrWhiteSpace(request.PixKey) ? settings.PixKey : request.PixKey,
            IsActive = true,
            ExpiresAt = claimEndsAt
        };

        await _context.Promotions.AddAsync(promotion, ct);
        await _context.SaveChangesAsync(ct);

        try
        {
            await _notificationService.SendPushToPromotionSubscribersAsync(
                new PushNotificationDto(
                    $"Nova promoção em {restaurant.Name}",
                    $"{promotion.Title}. Abra o app e pegue seu ticket antes que acabem.",
                    "/feed",
                    new Dictionary<string, string>
                    {
                        ["promotionId"] = promotion.Id.ToString(),
                        ["restaurantId"] = restaurant.Id.ToString(),
                        ["type"] = "promotion_created"
                    }),
                ct);
        }
        catch
        {
            // Notificação não pode impedir a publicação da promoção.
        }

        return await MapAsync(promotion, now, ct);
    }

    public async Task<PromotionDto> UpdateAsync(Guid ownerId, Guid promotionId, UpdatePromotionRequest request, CancellationToken ct = default)
    {
        var promotion = await _context.Promotions
            .Include(p => p.Restaurant)
            .FirstOrDefaultAsync(p => p.Id == promotionId && p.Restaurant.OwnerUserId == ownerId, ct)
            ?? throw new NotFoundException("Promoção não encontrada.");

        var settings = await EnsureSettingsAsync(ct);
        if (request.Title != null) promotion.Title = request.Title;
        if (request.Description != null) promotion.Description = request.Description;
        if (request.ImageUrl != null) promotion.ImageUrl = request.ImageUrl;
        if (request.DiscountPercent.HasValue) promotion.DiscountPercent = request.DiscountPercent;
        if (request.Scope.HasValue) promotion.Scope = request.Scope.Value;
        if (request.TargetDishIds != null) promotion.TargetDishIdsJson = JsonSerializer.Serialize(request.TargetDishIds);
        if (request.TicketCount.HasValue)
        {
            if (request.TicketCount.Value <= 0 || request.TicketCount.Value % settings.TicketsPerBatch != 0)
                throw new AppException($"A quantidade de tickets precisa ser múltipla de {settings.TicketsPerBatch}.", 400);

            promotion.TotalTickets = request.TicketCount.Value;
            promotion.RemainingTickets = Math.Min(promotion.RemainingTickets, promotion.TotalTickets);
        }
        if (request.ClaimStartsAt.HasValue) promotion.ClaimStartsAt = request.ClaimStartsAt.Value.ToUniversalTime();
        if (request.ClaimEndsAt.HasValue) promotion.ClaimEndsAt = request.ClaimEndsAt.Value.ToUniversalTime();
        else if (request.ClaimStartsAt.HasValue) promotion.ClaimEndsAt = promotion.ClaimStartsAt.AddDays(settings.ClaimWindowDays);
        if (request.PixKey != null) promotion.PixKey = request.PixKey;
        if (request.IsActive.HasValue) promotion.IsActive = request.IsActive.Value;

        promotion.ExpiresAt = promotion.ClaimEndsAt;
        await _context.SaveChangesAsync(ct);
        return await MapAsync(promotion, DateTime.UtcNow, ct);
    }

    public async Task DeleteAsync(Guid ownerId, Guid promotionId, CancellationToken ct = default)
    {
        var promotion = await _context.Promotions
            .Include(p => p.Restaurant)
            .FirstOrDefaultAsync(p => p.Id == promotionId && p.Restaurant.OwnerUserId == ownerId, ct)
            ?? throw new NotFoundException("Promoção não encontrada.");

        promotion.IsActive = false;
        await _context.SaveChangesAsync(ct);
    }

    public async Task<ClaimPromotionTicketResponse> ClaimAsync(Guid userId, Guid promotionId, CancellationToken ct = default)
    {
        await ExpireDueTicketsAsync(ct);
        var settings = await EnsureSettingsAsync(ct);
        var now = DateTime.UtcNow;

        await using var transaction = await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable, ct);

        var promotion = await _context.Promotions
            .Include(p => p.Restaurant)
            .FirstOrDefaultAsync(p => p.Id == promotionId, ct)
            ?? throw new NotFoundException("Promoção não encontrada.");

        if (!promotion.IsActive || promotion.ClaimStartsAt > now || promotion.ClaimEndsAt < now)
            throw new AppException("Esta promoção não está disponível para retirada no momento.", 400);

        if (promotion.RemainingTickets <= 0)
            throw new ConflictException("Todos os tickets já foram pegos, tente na próxima.");

        var cooldownUntil = await GetUserCooldownUntilAsync(userId, ct);
        if (cooldownUntil.HasValue && cooldownUntil.Value > now)
            throw new ForbiddenException($"Você precisa aguardar até {cooldownUntil.Value:dd/MM/yyyy HH:mm} para pegar novos tickets.");

        var hasActiveTicket = await _context.PromotionTickets.AnyAsync(t =>
            t.PromotionId == promotionId && t.UserId == userId && t.Status == PromotionTicketStatus.Claimed, ct);
        if (hasActiveTicket)
            throw new ConflictException("Você já pegou um ticket desta promoção.");

        var ticket = new PromotionTicket
        {
            PromotionId = promotion.Id,
            UserId = userId,
            ClaimedAt = now,
            ExpiresAt = now.AddDays(settings.TicketValidityDays),
            QrCodeToken = Guid.NewGuid().ToString("N"),
            Status = PromotionTicketStatus.Claimed
        };

        promotion.RemainingTickets -= 1;
        _context.PromotionTickets.Add(ticket);
        await _context.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);

        return new ClaimPromotionTicketResponse(
            ticket.Id,
            promotion.Id,
            promotion.Title,
            promotion.Restaurant.Name,
            ticket.QrCodeToken,
            ticket.ClaimedAt,
            ticket.ExpiresAt,
            $"Ticket obtido com sucesso. Você tem {settings.TicketValidityDays} dias para consumir o ticket.");
    }

    public async Task<IEnumerable<PromotionTicketDto>> GetMyTicketsAsync(Guid userId, CancellationToken ct = default)
    {
        await ExpireDueTicketsAsync(ct);
        var tickets = await _context.PromotionTickets
            .AsNoTracking()
            .Include(t => t.Promotion).ThenInclude(p => p.Restaurant)
            .Include(t => t.User)
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.ClaimedAt)
            .ToListAsync(ct);

        return tickets.Select(ToTicketDto);
    }

    public async Task<IEnumerable<PromotionTicketDto>> GetRestaurantTicketsAsync(Guid ownerId, CancellationToken ct = default)
    {
        await ExpireDueTicketsAsync(ct);
        var restaurantId = await _context.Restaurants.Where(r => r.OwnerUserId == ownerId).Select(r => r.Id).FirstOrDefaultAsync(ct);
        if (restaurantId == Guid.Empty)
            throw new NotFoundException("Restaurante não encontrado para este usuário.");

        var tickets = await _context.PromotionTickets
            .AsNoTracking()
            .Include(t => t.Promotion).ThenInclude(p => p.Restaurant)
            .Include(t => t.User)
            .Where(t => t.Promotion.RestaurantId == restaurantId)
            .OrderByDescending(t => t.ClaimedAt)
            .ToListAsync(ct);

        return tickets.Select(ToTicketDto);
    }

    public async Task<PromotionTicketDto> FinalizeAsync(Guid ownerId, FinalizePromotionTicketRequest request, CancellationToken ct = default)
    {
        await ExpireDueTicketsAsync(ct);
        var ticket = await _context.PromotionTickets
            .Include(t => t.Promotion).ThenInclude(p => p.Restaurant)
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.QrCodeToken == request.QrCodeToken, ct)
            ?? throw new NotFoundException("Ticket não encontrado.");

        if (ticket.Promotion.Restaurant.OwnerUserId != ownerId)
            throw new ForbiddenException("Você não pode finalizar este ticket.");

        if (ticket.Status == PromotionTicketStatus.Redeemed)
            return ToTicketDto(ticket);

        if (ticket.Status == PromotionTicketStatus.Expired || ticket.ExpiresAt <= DateTime.UtcNow)
        {
            ticket.Status = PromotionTicketStatus.Expired;
            await _context.SaveChangesAsync(ct);
            throw new ConflictException("Este ticket expirou.");
        }

        ticket.Status = PromotionTicketStatus.Redeemed;
        ticket.RedeemedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(ct);
        return ToTicketDto(ticket);
    }

    public async Task<PromotionTicketsAdminSummaryDto> GetAdminTicketsSummaryAsync(
        Guid? restaurantId,
        PromotionTicketStatus? status,
        DateTime? from,
        DateTime? to,
        CancellationToken ct = default)
    {
        await ExpireDueTicketsAsync(ct);
        var now = DateTime.UtcNow;
        var tickets = await BuildAdminTicketsQuery(restaurantId, status, from, to)
            .ToListAsync(ct);

        var userIds = tickets.Select(t => t.UserId).Distinct().ToList();
        var usersOnCooldown = 0;
        foreach (var userId in userIds)
        {
            var cooldownUntil = await GetUserCooldownUntilAsync(userId, ct);
            if (cooldownUntil.HasValue && cooldownUntil.Value > now)
                usersOnCooldown++;
        }

        return new PromotionTicketsAdminSummaryDto(
            tickets.Count,
            tickets.Count(t => t.Status == PromotionTicketStatus.Claimed),
            tickets.Count(t => t.Status == PromotionTicketStatus.Redeemed),
            tickets.Count(t => t.Status == PromotionTicketStatus.Expired),
            tickets.Count(t => t.Status == PromotionTicketStatus.Claimed),
            tickets.Count(t => t.Status == PromotionTicketStatus.Claimed && t.ExpiresAt <= now.AddHours(24)),
            usersOnCooldown);
    }

    public async Task<PagedResult<PromotionTicketAdminDto>> GetAdminTicketsAsync(
        Guid? restaurantId,
        PromotionTicketStatus? status,
        DateTime? from,
        DateTime? to,
        int page,
        int pageSize,
        CancellationToken ct = default)
    {
        await ExpireDueTicketsAsync(ct);
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var now = DateTime.UtcNow;
        var query = BuildAdminTicketsQuery(restaurantId, status, from, to);
        var totalCount = await query.CountAsync(ct);
        var tickets = await query
            .OrderByDescending(t => t.ClaimedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var userIds = tickets.Select(t => t.UserId).Distinct().ToList();
        var expiredCounts = await _context.PromotionTickets
            .Where(t => t.Status == PromotionTicketStatus.Expired && userIds.Contains(t.UserId))
            .GroupBy(t => t.UserId)
            .Select(g => new { UserId = g.Key, Count = g.Count() })
            .ToListAsync(ct);
        var expiredMap = expiredCounts.ToDictionary(x => x.UserId, x => x.Count);

        var items = new List<PromotionTicketAdminDto>(tickets.Count);
        foreach (var ticket in tickets)
        {
            var userExpiredTickets = expiredMap.TryGetValue(ticket.UserId, out var count) ? count : 0;
            var cooldownUntil = await GetUserCooldownUntilAsync(ticket.UserId, ct);
            items.Add(new PromotionTicketAdminDto(
                ticket.Id,
                ticket.PromotionId,
                ticket.Promotion.Title,
                ticket.Promotion.RestaurantId,
                ticket.Promotion.Restaurant.Name,
                ticket.UserId,
                ticket.User.Name,
                ticket.User.Email,
                ticket.QrCodeToken,
                ticket.Status,
                ticket.ClaimedAt,
                ticket.ExpiresAt,
                ticket.RedeemedAt,
                ticket.ExpirationReason
                    ?? (ticket.Status == PromotionTicketStatus.Expired
                        ? "Ticket expirou dentro da janela de consumo."
                        : ticket.Status == PromotionTicketStatus.Redeemed
                            ? "Ticket consumido no restaurante."
                            : null),
                userExpiredTickets,
                cooldownUntil.HasValue && cooldownUntil.Value > now,
                cooldownUntil,
                ticket.Promotion.DiscountPercent,
                ticket.Promotion.Scope));
        }

        return new PagedResult<PromotionTicketAdminDto>(items, page, pageSize, totalCount);
    }

    private async Task<PromotionSettings> EnsureSettingsAsync(CancellationToken ct)
    {
        var settings = await _context.PromotionSettings.FirstOrDefaultAsync(ct);
        if (settings != null) return settings;

        settings = new PromotionSettings();
        _context.PromotionSettings.Add(settings);
        await _context.SaveChangesAsync(ct);
        return settings;
    }

    private static PromotionSettingsDto Map(PromotionSettings settings)
        => new(settings.BatchPrice, settings.TicketsPerBatch, settings.TicketValidityDays, settings.ClaimWindowDays, settings.PixKey, settings.ReceiptPhoneNumber, settings.UpdatedAt);

    private async Task<List<PromotionDto>> MapManyAsync(IReadOnlyCollection<Promotion> promotions, DateTime now, CancellationToken ct)
    {
        var result = new List<PromotionDto>(promotions.Count);
        foreach (var promotion in promotions)
            result.Add(await MapAsync(promotion, now, ct));
        return result;
    }

    private async Task<PromotionDto> MapAsync(Promotion promotion, DateTime now, CancellationToken ct)
    {
        var targetDishIds = ParseTargetDishIds(promotion.TargetDishIdsJson);
        var targetDishNames = targetDishIds.Count == 0
            ? new List<string>()
            : await _context.Dishes.AsNoTracking()
                .Where(d => targetDishIds.Contains(d.Id))
                .OrderBy(d => d.Name)
                .Select(d => d.Name)
                .ToListAsync(ct);

        return new PromotionDto(
            promotion.Id,
            promotion.RestaurantId,
            promotion.Restaurant?.Name ?? string.Empty,
            promotion.Restaurant?.LogoUrl,
            promotion.Title,
            promotion.Description,
            promotion.ImageUrl,
            promotion.DiscountPercent,
            promotion.Scope,
            targetDishIds,
            targetDishNames,
            promotion.TotalTickets,
            promotion.RemainingTickets,
            promotion.ExpiresAt,
            promotion.ClaimStartsAt,
            promotion.ClaimEndsAt,
            promotion.TicketValidityDays,
            promotion.PixKey,
            promotion.IsActive && promotion.ClaimStartsAt <= now && promotion.ClaimEndsAt >= now && promotion.RemainingTickets > 0,
            promotion.CreatedAt);
    }

    private static List<Guid> ParseTargetDishIds(string? json)
        => string.IsNullOrWhiteSpace(json) ? [] : (JsonSerializer.Deserialize<List<Guid>>(json) ?? []);

    private IQueryable<PromotionTicket> BuildAdminTicketsQuery(
        Guid? restaurantId,
        PromotionTicketStatus? status,
        DateTime? from,
        DateTime? to)
    {
        var query = _context.PromotionTickets
            .AsNoTracking()
            .Include(t => t.Promotion).ThenInclude(p => p.Restaurant)
            .Include(t => t.User)
            .AsQueryable();

        if (restaurantId.HasValue)
            query = query.Where(t => t.Promotion.RestaurantId == restaurantId.Value);

        if (status.HasValue)
            query = query.Where(t => t.Status == status.Value);

        if (from.HasValue)
            query = query.Where(t => t.ClaimedAt >= from.Value.ToUniversalTime());

        if (to.HasValue)
            query = query.Where(t => t.ClaimedAt <= to.Value.ToUniversalTime());

        return query;
    }

    private static PromotionTicketDto ToTicketDto(PromotionTicket ticket)
        => new(
            ticket.Id,
            ticket.PromotionId,
            ticket.Promotion.Title,
            ticket.Promotion.Restaurant.Name,
            ticket.UserId,
            ticket.User.Name,
            ticket.QrCodeToken,
            ticket.Status,
            ticket.ClaimedAt,
            ticket.ExpiresAt,
            ticket.RedeemedAt,
            ticket.Promotion.DiscountPercent,
            ticket.Promotion.Scope,
            ParseTargetDishIds(ticket.Promotion.TargetDishIdsJson));

    private async Task ExpireDueTicketsAsync(CancellationToken ct)
        => await _ticketLifecycleService.ExpireDueTicketsAsync(ct);

    private async Task<DateTime?> GetUserCooldownUntilAsync(Guid userId, CancellationToken ct)
    {
        var expiredTickets = await _context.PromotionTickets
            .Where(t => t.UserId == userId && t.Status == PromotionTicketStatus.Expired)
            .OrderByDescending(t => t.ExpiresAt)
            .Select(t => t.ExpiresAt)
            .ToListAsync(ct);

        if (expiredTickets.Count < 3) return null;
        return expiredTickets[2].AddDays(30);
    }

    private async Task<int> GetUsersOnCooldownCountAsync(CancellationToken ct)
    {
        var userIds = await _context.PromotionTickets
            .Where(t => t.Status == PromotionTicketStatus.Expired)
            .Select(t => t.UserId)
            .Distinct()
            .ToListAsync(ct);

        var count = 0;
        foreach (var userId in userIds)
        {
            var cooldown = await GetUserCooldownUntilAsync(userId, ct);
            if (cooldown.HasValue && cooldown.Value > DateTime.UtcNow)
                count++;
        }

        return count;
    }
}
