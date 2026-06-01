using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using OndeComer.Application.DTOs.Moderation;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Infrastructure.Data;
using System.Text.Json;

namespace OndeComer.Infrastructure.Services;

public class ModerationService : IModerationService
{
    private readonly AppDbContext _context;
    private readonly ILogger<ModerationService> _logger;
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    // Thresholds
    private const double HighConfidenceThreshold = 0.85;
    private const double MediumConfidenceThreshold = 0.50;

    // Built-in offensive word list (Portuguese + English basics)
    private static readonly HashSet<string> OffensiveWords = new(StringComparer.OrdinalIgnoreCase)
    {
        // Portuguese offensive terms
        "porra", "caralho", "merda", "fdp", "puta", "desgraça",
        "vagabunda", "arrombado", "viado", "corno", "otário",
        "imbecil", "idiota", "lixo humano", "racista", "nazista",
        // English offensive terms
        "fuck", "shit", "asshole", "bitch", "bastard", "damn",
        "nigger", "faggot", "retard", "slut", "whore",
        // Spam indicators
        "ganhe dinheiro", "clique aqui", "promoção imperdível",
        "viagra", "casino", "apostas online"
    };

    private static readonly HashSet<string> HateSpeechPatterns = new(StringComparer.OrdinalIgnoreCase)
    {
        "racista", "nazista", "supremacia", "matar", "morte a",
        "exterminar", "holocausto", "ódio racial", "inferioridade racial"
    };

    public ModerationService(
        AppDbContext context,
        ILogger<ModerationService> logger,
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory)
    {
        _context = context;
        _logger = logger;
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    public async Task<ModerationResult> ScanTextAsync(ScanTextRequest request)
    {
        // Try external service first (Azure Content Moderator)
        var externalEndpoint = _configuration["Moderation:TextEndpoint"];
        var apiKey = _configuration["Moderation:ApiKey"];

        ModerationResult result;

        if (!string.IsNullOrEmpty(externalEndpoint) && !string.IsNullOrEmpty(apiKey))
        {
            result = await ScanTextExternalAsync(request.Text, externalEndpoint, apiKey);
        }
        else
        {
            // Fallback: built-in keyword analysis
            result = AnalyzeTextLocally(request.Text);
        }

        // Log the result
        var log = new ModerationLog
        {
            ContentType = "text",
            EntityType = request.EntityType,
            EntityId = request.EntityId,
            UserId = request.UserId,
            Result = result.Result,
            ConfidenceScore = result.ConfidenceScore,
            Categories = JsonSerializer.Serialize(result.DetectedCategories),
            OriginalContent = request.Text.Length > 500 ? request.Text[..500] : request.Text,
            Reason = result.Reason,
            ReviewedByHuman = false
        };

        _context.ModerationLogs.Add(log);
        await _context.SaveChangesAsync();

        _logger.LogInformation(
            "Text moderation: {Result} (confidence: {Score:F2}) for {EntityType} by user {UserId}",
            result.Result, result.ConfidenceScore, request.EntityType, request.UserId);

        return result;
    }

    public async Task<ModerationResult> ScanImageAsync(ScanImageRequest request)
    {
        var externalEndpoint = _configuration["Moderation:ImageEndpoint"];
        var apiKey = _configuration["Moderation:ApiKey"];

        ModerationResult result;

        if (!string.IsNullOrEmpty(externalEndpoint) && !string.IsNullOrEmpty(apiKey))
        {
            result = await ScanImageExternalAsync(request.ImageUrl, externalEndpoint, apiKey);
        }
        else
        {
            // Without external API, approve images with a note
            result = new ModerationResult("approved", 0.1, Array.Empty<string>(), "No image moderation API configured");
        }

        var log = new ModerationLog
        {
            ContentType = "image",
            EntityType = request.EntityType,
            EntityId = request.EntityId,
            UserId = request.UserId,
            Result = result.Result,
            ConfidenceScore = result.ConfidenceScore,
            Categories = JsonSerializer.Serialize(result.DetectedCategories),
            OriginalContent = request.ImageUrl,
            Reason = result.Reason,
            ReviewedByHuman = false
        };

        _context.ModerationLogs.Add(log);
        await _context.SaveChangesAsync();

        _logger.LogInformation(
            "Image moderation: {Result} (confidence: {Score:F2}) for {EntityType}",
            result.Result, result.ConfidenceScore, request.EntityType);

        return result;
    }

    public async Task<IEnumerable<ModerationLogDto>> GetLogsAsync(string? result = null, string? entityType = null, int page = 1, int pageSize = 20)
    {
        var query = _context.ModerationLogs.AsQueryable();

        if (!string.IsNullOrEmpty(result))
            query = query.Where(l => l.Result == result);
        if (!string.IsNullOrEmpty(entityType))
            query = query.Where(l => l.EntityType == entityType);

        var logs = await query
            .OrderByDescending(l => l.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return logs.Select(l => new ModerationLogDto(
            l.Id, l.ContentType, l.EntityType, l.EntityId, l.UserId,
            l.Result, l.ConfidenceScore, l.Categories, l.Reason,
            l.ReviewedByHuman, l.CreatedAt
        ));
    }

    public async Task<ModerationLogDto> ReviewLogAsync(Guid logId, Guid reviewerUserId, string decision)
    {
        var log = await _context.ModerationLogs.FindAsync(logId)
            ?? throw new Application.Common.Exceptions.NotFoundException("Log de moderação não encontrado.");

        log.ReviewedByHuman = true;
        log.ReviewedByUserId = reviewerUserId;
        log.ReviewedAt = DateTime.UtcNow;
        log.Result = decision == "approve" ? "approved" : "blocked";

        await _context.SaveChangesAsync();

        return new ModerationLogDto(
            log.Id, log.ContentType, log.EntityType, log.EntityId, log.UserId,
            log.Result, log.ConfidenceScore, log.Categories, log.Reason,
            log.ReviewedByHuman, log.CreatedAt
        );
    }

    #region Private Methods

    private ModerationResult AnalyzeTextLocally(string text)
    {
        var detectedCategories = new List<string>();
        var lowerText = text.ToLowerInvariant();
        double maxScore = 0;

        // Check hate speech (highest severity)
        foreach (var pattern in HateSpeechPatterns)
        {
            if (lowerText.Contains(pattern, StringComparison.OrdinalIgnoreCase))
            {
                detectedCategories.Add("hate_speech");
                maxScore = Math.Max(maxScore, 0.95);
                break;
            }
        }

        // Check offensive words
        int offensiveCount = 0;
        foreach (var word in OffensiveWords)
        {
            if (lowerText.Contains(word, StringComparison.OrdinalIgnoreCase))
            {
                offensiveCount++;
                if (!detectedCategories.Contains("profanity"))
                    detectedCategories.Add("profanity");
            }
        }

        if (offensiveCount > 0)
        {
            var offensiveScore = Math.Min(0.5 + (offensiveCount * 0.15), 0.95);
            maxScore = Math.Max(maxScore, offensiveScore);
        }

        // Check for ALL CAPS (shouting)
        var words = text.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var capsRatio = words.Length > 3
            ? (double)words.Count(w => w.Length > 2 && w == w.ToUpper()) / words.Length
            : 0;
        if (capsRatio > 0.6)
        {
            detectedCategories.Add("aggressive_tone");
            maxScore = Math.Max(maxScore, 0.4);
        }

        // Determine result based on confidence threshold
        string resultStr;
        if (maxScore >= HighConfidenceThreshold)
            resultStr = "blocked";
        else if (maxScore >= MediumConfidenceThreshold)
            resultStr = "flagged";
        else
            resultStr = "approved";

        var reason = detectedCategories.Count > 0
            ? $"Detected: {string.Join(", ", detectedCategories)}"
            : null;

        return new ModerationResult(resultStr, maxScore, detectedCategories.ToArray(), reason);
    }

    private async Task<ModerationResult> ScanTextExternalAsync(string text, string endpoint, string apiKey)
    {
        try
        {
            var client = _httpClientFactory.CreateClient("Moderation");
            client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", apiKey);

            var response = await client.PostAsync(
                $"{endpoint}/contentmoderator/moderate/v1.0/ProcessText/Screen?classify=true",
                new StringContent(text, System.Text.Encoding.UTF8, "text/plain"));

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("External text moderation failed with status {Status}. Falling back to local.", response.StatusCode);
                return AnalyzeTextLocally(text);
            }

            var json = await response.Content.ReadAsStringAsync();
            var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var categories = new List<string>();
            double score = 0;

            if (root.TryGetProperty("Classification", out var classification))
            {
                if (classification.TryGetProperty("Category1", out var cat1) &&
                    cat1.GetProperty("Score").GetDouble() > 0.5)
                {
                    categories.Add("sexually_explicit");
                    score = Math.Max(score, cat1.GetProperty("Score").GetDouble());
                }
                if (classification.TryGetProperty("Category2", out var cat2) &&
                    cat2.GetProperty("Score").GetDouble() > 0.5)
                {
                    categories.Add("sexually_suggestive");
                    score = Math.Max(score, cat2.GetProperty("Score").GetDouble());
                }
                if (classification.TryGetProperty("Category3", out var cat3) &&
                    cat3.GetProperty("Score").GetDouble() > 0.5)
                {
                    categories.Add("offensive");
                    score = Math.Max(score, cat3.GetProperty("Score").GetDouble());
                }
            }

            if (root.TryGetProperty("Terms", out var terms) && terms.GetArrayLength() > 0)
            {
                categories.Add("profanity");
                score = Math.Max(score, 0.7);
            }

            string result = score >= HighConfidenceThreshold ? "blocked"
                : score >= MediumConfidenceThreshold ? "flagged"
                : "approved";

            return new ModerationResult(result, score, categories.ToArray(),
                categories.Count > 0 ? $"Detected: {string.Join(", ", categories)}" : null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "External text moderation error, falling back to local analysis");
            return AnalyzeTextLocally(text);
        }
    }

    private async Task<ModerationResult> ScanImageExternalAsync(string imageUrl, string endpoint, string apiKey)
    {
        try
        {
            var client = _httpClientFactory.CreateClient("Moderation");
            client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", apiKey);

            var content = new StringContent(
                JsonSerializer.Serialize(new { DataRepresentation = "URL", Value = imageUrl }),
                System.Text.Encoding.UTF8, "application/json");

            var response = await client.PostAsync(
                $"{endpoint}/contentmoderator/moderate/v1.0/ProcessImage/Evaluate", content);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("External image moderation failed: {Status}", response.StatusCode);
                return new ModerationResult("flagged", 0.5, new[] { "api_unavailable" }, "Image API unavailable, flagged for human review");
            }

            var json = await response.Content.ReadAsStringAsync();
            var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var categories = new List<string>();
            double score = 0;

            if (root.TryGetProperty("IsImageAdultClassified", out var adult) && adult.GetBoolean())
            {
                categories.Add("adult");
                score = root.TryGetProperty("AdultClassificationScore", out var adultScore)
                    ? adultScore.GetDouble() : 0.9;
            }

            if (root.TryGetProperty("IsImageRacyClassified", out var racy) && racy.GetBoolean())
            {
                categories.Add("racy");
                var racyScore = root.TryGetProperty("RacyClassificationScore", out var rs)
                    ? rs.GetDouble() : 0.7;
                score = Math.Max(score, racyScore);
            }

            string result = score >= HighConfidenceThreshold ? "blocked"
                : score >= MediumConfidenceThreshold ? "flagged"
                : "approved";

            return new ModerationResult(result, score, categories.ToArray(),
                categories.Count > 0 ? $"Detected: {string.Join(", ", categories)}" : null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "External image moderation error");
            return new ModerationResult("flagged", 0.5, new[] { "error" }, "Moderation service unavailable, flagged for review");
        }
    }

    #endregion
}
