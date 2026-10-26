using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OndeComer.Application.Interfaces;

namespace OndeComer.Infrastructure.Services;

public class PromotionTicketReminderHostedService : BackgroundService
{
    private static readonly TimeSpan PollInterval = TimeSpan.FromMinutes(15);
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<PromotionTicketReminderHostedService> _logger;

    public PromotionTicketReminderHostedService(
        IServiceScopeFactory scopeFactory,
        ILogger<PromotionTicketReminderHostedService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await RunCycleAsync(stoppingToken);

        using var timer = new PeriodicTimer(PollInterval);
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            await RunCycleAsync(stoppingToken);
        }
    }

    private async Task RunCycleAsync(CancellationToken ct)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var lifecycle = scope.ServiceProvider.GetRequiredService<IPromotionTicketLifecycleService>();
            await lifecycle.ExpireDueTicketsAsync(ct);
            await lifecycle.SendExpiringSoonRemindersAsync(ct);
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested)
        {
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao processar ciclo de tickets de promoção.");
        }
    }
}
