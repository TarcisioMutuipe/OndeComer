using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Dish;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Domain.Interfaces;

namespace OndeComer.Application.Services;

public class DishService : IDishService
{
    private readonly IUnitOfWork _uow;
    private readonly IImageService _imageService;

    public DishService(IUnitOfWork uow, IImageService imageService)
    {
        _uow = uow;
        _imageService = imageService;
    }

    public async Task<DishDto> CreateAsync(Guid restaurantId, Guid requesterId, CreateDishRequest request, CancellationToken ct = default)
    {
        var restaurant = await _uow.Restaurants.GetByIdAsync(restaurantId, ct)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        var requester = await _uow.Users.GetByIdAsync(requesterId, ct);
        if (requester?.ProfileType != ProfileType.Admin && restaurant.OwnerUserId != requesterId)
            throw new ForbiddenException("Você não tem permissão para adicionar pratos a este restaurante.");

        if (await _uow.Dishes.ExistsByNameAsync(restaurantId, request.Name, null, ct))
            throw new ConflictException($"Já existe um prato chamado '{request.Name}' neste restaurante.");

        var dish = new Dish
        {
            RestaurantId = restaurantId,
            Name = request.Name,
            Description = request.Description,
            Price = request.Price,
            Category = request.Category,
            Subcategory = request.Subcategory,
            ImageUrl = request.ImageUrl,
            ShowInFeed = request.ShowInFeed && !IsMenuOnlySection(request.Category),
            AvailabilityStart = request.AvailabilityStart,
            AvailabilityEnd = request.AvailabilityEnd,
        };

        await _uow.Dishes.AddAsync(dish, ct);
        await _imageService.AssociateDishImageAsync(dish.Id, dish.ImageUrl, ct);
        await _uow.CommitAsync(ct);
        return ToDto(dish);
    }

    public async Task<DishDto> UpdateAsync(Guid dishId, Guid requesterId, UpdateDishRequest request, CancellationToken ct = default)
    {
        var dish = await _uow.Dishes.GetByIdAsync(dishId, ct)
            ?? throw new NotFoundException("Prato não encontrado.");

        var restaurant = await _uow.Restaurants.GetByIdAsync(dish.RestaurantId, ct)!;
        var requester = await _uow.Users.GetByIdAsync(requesterId, ct);
        if (requester?.ProfileType != ProfileType.Admin && restaurant?.OwnerUserId != requesterId)
            throw new ForbiddenException("Você não tem permissão para editar este prato.");

        if (request.Name is not null)
        {
            if (await _uow.Dishes.ExistsByNameAsync(dish.RestaurantId, request.Name, dishId, ct))
                throw new ConflictException($"Já existe um prato chamado '{request.Name}' neste restaurante.");
            dish.Name = request.Name;
        }
        if (request.Description is not null) dish.Description = request.Description;
        if (request.Price.HasValue) dish.Price = request.Price.Value;
        if (request.Category is not null) dish.Category = request.Category;
        if (request.Subcategory is not null) dish.Subcategory = request.Subcategory;
        if (request.ImageUrl is not null) dish.ImageUrl = request.ImageUrl;
        if (request.ShowInFeed.HasValue) dish.ShowInFeed = request.ShowInFeed.Value;
        if (request.AvailabilityStart.HasValue) dish.AvailabilityStart = request.AvailabilityStart.Value;
        if (request.AvailabilityEnd.HasValue) dish.AvailabilityEnd = request.AvailabilityEnd.Value;
        if (IsMenuOnlySection(dish.Category)) dish.ShowInFeed = false;
        if (request.IsActive.HasValue)
        {
            if (request.IsActive.Value)
            {
                dish.DeactivatedAt = null;
            }
            else if (dish.IsActive)
            {
                dish.DeactivatedAt = DateTime.UtcNow;
            }
            dish.IsActive = request.IsActive.Value;
        }
        dish.UpdatedAt = DateTime.UtcNow;

        _uow.Dishes.Update(dish);
        await _uow.CommitAsync(ct);
        return ToDto(dish);
    }

    public async Task DeleteAsync(Guid dishId, Guid requesterId, CancellationToken ct = default)
    {
        var dish = await _uow.Dishes.GetByIdAsync(dishId, ct)
            ?? throw new NotFoundException("Prato não encontrado.");

        var restaurant = await _uow.Restaurants.GetByIdAsync(dish.RestaurantId, ct);
        var requester = await _uow.Users.GetByIdAsync(requesterId, ct);
        if (requester?.ProfileType != ProfileType.Admin && restaurant?.OwnerUserId != requesterId)
            throw new ForbiddenException("Você não tem permissão para excluir este prato.");

        var imagePaths = await _imageService.PrepareDishImagesForDeletionAsync(
            dish.Id, dish.ImageUrl, ct);
        await _uow.Dishes.RemoveDishReferencesFromPromotionsAsync([dish.Id], ct);
        _uow.Dishes.Delete(dish);
        await _uow.CommitAsync(ct);
        _imageService.DeleteStoredImages(imagePaths);
    }

    public async Task<IEnumerable<DishDto>> GetByRestaurantAsync(Guid restaurantId, bool onlyAvailable = false, CancellationToken ct = default)
    {
        var dishes = await _uow.Dishes.GetByRestaurantIdAsync(restaurantId, onlyAvailable, ct);
        return dishes.Select(ToDto);
    }

    public async Task<IEnumerable<DishFeedDto>> GetFeedAsync(int page, int pageSize, CancellationToken ct = default)
    {
        var dishes = await _uow.Dishes.GetFeedAsync(page, pageSize, DateTime.UtcNow, ct);
        return dishes.Select(d => new DishFeedDto(
            d.Id, d.RestaurantId, d.Name, d.Description, d.Price, d.Category,
            d.Subcategory, d.ImageUrl, d.CreatedAt, d.Restaurant.Name, d.Restaurant.LogoUrl));
    }

    public async Task<int> DeleteExpiredInactiveAsync(CancellationToken ct = default)
    {
        var cutoff = DateTime.UtcNow.AddDays(-7);
        var expiredDishes = (await _uow.Dishes.GetInactiveBeforeAsync(cutoff, ct)).ToList();
        if (expiredDishes.Count == 0) return 0;

        var dishIds = expiredDishes.Select(d => d.Id).ToArray();
        await _uow.Dishes.RemoveDishReferencesFromPromotionsAsync(dishIds, ct);
        var imagePaths = new List<string>();
        foreach (var dish in expiredDishes)
        {
            imagePaths.AddRange(await _imageService.PrepareDishImagesForDeletionAsync(
                dish.Id, dish.ImageUrl, ct));
            _uow.Dishes.Delete(dish);
        }

        await _uow.CommitAsync(ct);
        _imageService.DeleteStoredImages(imagePaths);
        return expiredDishes.Count;
    }

    public async Task<DishDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var d = await _uow.Dishes.GetByIdAsync(id, ct);
        return d is null ? null : ToDto(d);
    }

    private static DishDto ToDto(Dish d) => new(
        d.Id, d.RestaurantId, d.Name, d.Description, d.Price,
        d.Category, d.Subcategory, d.ImageUrl, d.ShowInFeed,
        d.AvailabilityStart, d.AvailabilityEnd, d.IsActive, d.DeactivatedAt,
        d.RatingAverage, d.RatingCount, d.CreatedAt, d.UpdatedAt
    );

    private static bool IsMenuOnlySection(string category)
    {
        var section = category.Trim().ToLowerInvariant();
        return section.Contains("bebid") || section.Contains("vinho") || section.Contains("drink");
    }
}
