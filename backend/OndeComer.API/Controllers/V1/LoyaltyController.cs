using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Loyalty;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/loyalty")]
[Authorize]
public class LoyaltyController : ControllerBase
{
    private readonly ILoyaltyService _loyaltyService;

    public LoyaltyController(ILoyaltyService loyaltyService)
    {
        _loyaltyService = loyaltyService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    /// <summary>
    /// Retorna overview de fidelidade do usuário: pontos, badges, histórico.
    /// </summary>
    [HttpGet("me")]
    public async Task<ActionResult<LoyaltyOverviewResponse>> GetMyLoyalty()
    {
        var userId = GetCurrentUserId();
        var result = await _loyaltyService.GetUserLoyaltyAsync(userId);
        return Ok(result);
    }

    /// <summary>
    /// Lista campanhas ativas (opcionalmente filtradas por restaurante).
    /// </summary>
    [HttpGet("campaigns")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<CampaignDto>>> GetCampaigns([FromQuery] Guid? restaurantId)
    {
        var result = await _loyaltyService.GetActiveCampaignsAsync(restaurantId);
        return Ok(result);
    }

    /// <summary>
    /// Cria uma campanha de fidelidade (owner).
    /// </summary>
    [HttpPost("campaigns")]
    public async Task<ActionResult<CampaignDto>> CreateCampaign([FromBody] CreateCampaignRequest request)
    {
        var result = await _loyaltyService.CreateCampaignAsync(request);
        return Created($"api/v1/loyalty/campaigns/{result.Id}", result);
    }

    /// <summary>
    /// Atualiza uma campanha existente.
    /// </summary>
    [HttpPut("campaigns/{campaignId:guid}")]
    public async Task<ActionResult<CampaignDto>> UpdateCampaign(Guid campaignId, [FromBody] UpdateCampaignRequest request)
    {
        var result = await _loyaltyService.UpdateCampaignAsync(campaignId, request);
        return Ok(result);
    }
}
