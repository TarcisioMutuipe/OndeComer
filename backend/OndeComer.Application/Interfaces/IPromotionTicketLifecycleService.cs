namespace OndeComer.Application.Interfaces;

public interface IPromotionTicketLifecycleService
{
    Task ExpireDueTicketsAsync(CancellationToken ct = default);
    Task SendExpiringSoonRemindersAsync(CancellationToken ct = default);
}
