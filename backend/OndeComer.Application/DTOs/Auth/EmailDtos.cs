namespace OndeComer.Application.DTOs.Auth;

public record SendConfirmationRequest(string Email);
public record ForgotPasswordRequest(string Email);
public record ResetPasswordRequest(string Email, string Token, string NewPassword);
