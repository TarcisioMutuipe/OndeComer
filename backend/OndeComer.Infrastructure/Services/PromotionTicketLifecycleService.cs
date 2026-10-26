using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using OndeComer.Application.DTOs.Notification;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Services;

public class PromotionTicketLifecycleService : IPromotionTicketLifecycleService
{
    private const string ExpiredReason = "Ticket expirou dentro da janela de consumo.";
    private static readonly TimeSpan ReminderWindow = TimeSpan.FromHours(24);

    private readonly AppDbContext _context;
    private readonly INotificationService _notificationService;
    private readonly ILogger<PromotionTicketLifecycleService> _logger;

    public PromotionTicketLifecycleService(
        AppDbContext context,
        INotificationService notificationService,
        ILogger<PromotionTicketLifecycleService> logger)
    {
        _context = context;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task ExpireDueTicketsAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var expiredTickets = await _context.PromotionTickets
            .Where(t => t.Status == PromotionTicketStatus.Claimed && t.ExpiresAt <= now)
            .ToListAsync(ct);

        if (expiredTickets.Count == 0) return;

        foreach (var ticket in expiredTickets)
        {
            ticket.Status = PromotionTicketStatus.Expired;
            ticket.ExpirationReason ??= ExpiredReason;
        }

        await _context.SaveChangesAsync(ct);
    }

    public async Task SendExpiringSoonRemindersAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var until = now.Add(ReminderWindow);

        var candidateTickets = await _context.PromotionTickets
            .Include(t => t.Promotion)
            .Where(t => t.Status == PromotionTicketStatus.Claimed
                && t.ExpiresAt > now
                && t.ExpiresAt <= until
                && t.ReminderSentAt == null)
            .OrderBy(t => t.ExpiresAt)
            .ToListAsync(ct);

        if (candidateTickets.Count == 0) return;

        var userIds = candidateTickets.Select(t => t.UserId).Distinct().ToList();
        var preferences = await _context.NotificationPreferences
            .AsNoTracking()
            .Where(p => userIds.Contains(p.UserId))
            .Select(p => new { p.UserId, p.PromotionActive })
            .ToListAsync(ct);

        var preferenceMap = preferences.ToDictionary(p => p.UserId, p => p.PromotionActive);
        var ticketsToMark = new List<PromotionTicket>();

        foreach (var ticket in candidateTickets)
        {
            if (preferenceMap.TryGetValue(ticket.UserId, out var promotionActive) && !promotionActive)
            {
                continue;
            }

            var countdown = FormatCountdown(ticket.ExpiresAt - now);
            try
            {
                var sent = await _notificationService.SendPushToUserAsync(
                    ticket.UserId,
                    new PushNotificationDto(
                        "Seu ticket está perto de vencer",
                        $"{ticket.Promotion.Title} expira em {countdown}. Abra o app e consuma antes de perder a validade.",
                        "/tickets",
                        new Dictionary<string, string>
                        {
                            ["ticketId"] = ticket.Id.ToString(),
                            ["promotionId"] = ticket.PromotionId.ToString(),
                            ["type"] = "promotion_ticket_expiring_soon"
                        }),
                    ct);

                if (sent)
                {
                    ticketsToMark.Add(ticket);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send expiring reminder for ticket {TicketId}", ticket.Id);
            }
        }

        if (ticketsToMark.Count == 0) return;

        var ids = ticketsToMark.Select(t => t.Id).Distinct().ToList();
        var ticketsToUpdate = await _context.PromotionTickets
            .Where(t => ids.Contains(t.Id))
            .ToListAsync(ct);

        foreach (var ticket in ticketsToUpdate)
        {
            ticket.ReminderSentAt ??= now;
        }

        await _context.SaveChangesAsync(ct);
    }

    private static string FormatCountdown(TimeSpan remaining)
    {
        if (remaining.TotalDays >= 1)
        {
            var days = Math.Ceiling(remaining.TotalDays);
            return $"{days:0} dia(s)";
        }

        if (remaining.TotalHours >= 1)
        {
            var hours = Math.Ceiling(remaining.TotalHours);
            return $"{hours:0} hora(s)";
        }

        var minutes = Math.Max(1, (int)Math.Ceiling(remaining.TotalMinutes));
        return $"{minutes} min";
    }
}
