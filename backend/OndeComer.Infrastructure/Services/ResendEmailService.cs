using System.Net.Http.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using OndeComer.Application.Interfaces;

namespace OndeComer.Infrastructure.Services;

public class ResendEmailService : IEmailService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<ResendEmailService> _logger;
    private readonly string _apiKey;
    private readonly string _fromEmail;
    private readonly string _baseUrl;

    public ResendEmailService(
        IHttpClientFactory httpClientFactory,
        ILogger<ResendEmailService> logger,
        IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
        _apiKey = configuration["Email:ResendApiKey"] ?? "";
        _fromEmail = configuration["Email:FromAddress"] ?? "noreply@ondecomer.com";
        _baseUrl = configuration["Email:BaseUrl"] ?? "http://localhost:5000";
    }

    public async Task SendEmailConfirmationAsync(string toEmail, string userName, string confirmationToken, CancellationToken ct = default)
    {
        var confirmUrl = $"{_baseUrl}/api/v1/auth/confirm-email?token={Uri.EscapeDataString(confirmationToken)}&email={Uri.EscapeDataString(toEmail)}";

        var html = $"""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: #E65100;">Onde Comer em Salvador</h2>
                <p>Olá, <strong>{userName}</strong>!</p>
                <p>Obrigado por se cadastrar. Para confirmar seu e-mail, clique no botão abaixo:</p>
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{confirmUrl}"
                       style="background-color: #E65100; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-size: 16px;">
                        Confirmar E-mail
                    </a>
                </div>
                <p style="color: #666; font-size: 12px;">Se você não se cadastrou, ignore este e-mail.</p>
                <p style="color: #666; font-size: 12px;">O link expira em 24 horas.</p>
            </div>
            """;

        await SendAsync(toEmail, "Confirme seu e-mail - Onde Comer em Salvador", html, ct);
    }

    public async Task SendPasswordResetAsync(string toEmail, string userName, string resetToken, CancellationToken ct = default)
    {
        var resetUrl = $"{_baseUrl}/api/v1/auth/reset-password?token={Uri.EscapeDataString(resetToken)}&email={Uri.EscapeDataString(toEmail)}";

        var html = $"""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: #E65100;">Onde Comer em Salvador</h2>
                <p>Olá, <strong>{userName}</strong>!</p>
                <p>Recebemos uma solicitação de redefinição de senha. Clique abaixo para criar uma nova:</p>
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{resetUrl}"
                       style="background-color: #E65100; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-size: 16px;">
                        Redefinir Senha
                    </a>
                </div>
                <p style="color: #666; font-size: 12px;">Se não foi você, ignore este e-mail. O link expira em 1 hora.</p>
            </div>
            """;

        await SendAsync(toEmail, "Redefinir senha - Onde Comer em Salvador", html, ct);
    }

    public async Task SendWelcomeAsync(string toEmail, string userName, CancellationToken ct = default)
    {
        var html = $"""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: #E65100;">Bem-vindo(a) ao Onde Comer em Salvador! 🎉</h2>
                <p>Olá, <strong>{userName}</strong>!</p>
                <p>Seu e-mail foi confirmado com sucesso. Agora você pode:</p>
                <ul>
                    <li>Descobrir os melhores restaurantes de Salvador</li>
                    <li>Avaliar e comentar pratos</li>
                    <li>Aproveitar promoções exclusivas</li>
                    <li>Criar listas de desejos</li>
                </ul>
                <p>Bom apetite! 🍽️</p>
            </div>
            """;

        await SendAsync(toEmail, "Bem-vindo(a) ao Onde Comer em Salvador!", html, ct);
    }

    private async Task SendAsync(string to, string subject, string htmlBody, CancellationToken ct)
    {
        if (string.IsNullOrEmpty(_apiKey))
        {
            _logger.LogWarning("[Email] Resend API key não configurada. Email para {To} com assunto '{Subject}' não enviado (modo dev).", to, subject);
            return;
        }

        try
        {
            var client = _httpClientFactory.CreateClient("Resend");
            client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _apiKey);

            var payload = new
            {
                from = _fromEmail,
                to = new[] { to },
                subject,
                html = htmlBody
            };

            var response = await client.PostAsJsonAsync("https://api.resend.com/emails", payload, ct);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("[Email] Enviado com sucesso para {To}: {Subject}", to, subject);
            }
            else
            {
                var body = await response.Content.ReadAsStringAsync(ct);
                _logger.LogError("[Email] Falha ao enviar para {To}: {StatusCode} - {Body}", to, response.StatusCode, body);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[Email] Exceção ao enviar email para {To}", to);
        }
    }
}
