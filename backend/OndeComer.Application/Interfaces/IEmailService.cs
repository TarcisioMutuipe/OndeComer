namespace OndeComer.Application.Interfaces;

public interface IEmailService
{
    Task SendEmailConfirmationAsync(string toEmail, string userName, string confirmationToken, CancellationToken ct = default);
    Task SendPasswordResetAsync(string toEmail, string userName, string resetToken, CancellationToken ct = default);
    Task SendWelcomeAsync(string toEmail, string userName, CancellationToken ct = default);
}
