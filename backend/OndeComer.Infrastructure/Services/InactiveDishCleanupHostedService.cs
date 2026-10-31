using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OndeComer.Application.Interfaces;

namespace OndeComer.Infrastructure.Services;

public class InactiveDishCleanupHostedService : BackgroundService
{
    private static readonly TimeSpan PollInterval = TimeSpan.FromHours(6);
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<InactiveDishCleanupHostedService> _logger;

    public InactiveDishCleanupHostedService(
        IServiceScopeFactory scopeFactory,
        ILogger<InactiveDishCleanupHostedService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await RunCycleAsync(stoppingToken);

        using var timer = new PeriodicTimer(PollInterval);
        while (await timer.WaitForNextTickAsync(stoppingToken))
            await RunCycleAsync(stoppingToken);
    }

    private async Task RunCycleAsync(CancellationToken ct)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var dishes = scope.ServiceProvider.GetRequiredService<IDishService>();
            var deletedCount = await dishes.DeleteExpiredInactiveAsync(ct);
            if (deletedCount > 0)
                _logger.LogInformation("Pratos inativos expirados removidos: {Count}", deletedCount);
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested)
        {
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao remover pratos inativos expirados.");
        }
    }
}
