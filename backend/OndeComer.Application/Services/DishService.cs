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

    public DishService(IUnitOfWork uow) => _uow = uow;

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
            ImageUrl = request.ImageUrl,
            AvailabilityStart = request.AvailabilityStart,
            AvailabilityEnd = request.AvailabilityEnd,
        };

        await _uow.Dishes.AddAsync(dish, ct);
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
        if (request.ImageUrl is not null) dish.ImageUrl = request.ImageUrl;
        if (request.AvailabilityStart.HasValue) dish.AvailabilityStart = request.AvailabilityStart.Value;
        if (request.AvailabilityEnd.HasValue) dish.AvailabilityEnd = request.AvailabilityEnd.Value;
        if (request.IsActive.HasValue) dish.IsActive = request.IsActive.Value;
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

        _uow.Dishes.Delete(dish);
        await _uow.CommitAsync(ct);
    }

    public async Task<IEnumerable<DishDto>> GetByRestaurantAsync(Guid restaurantId, bool onlyAvailable = false, CancellationToken ct = default)
    {
        var dishes = await _uow.Dishes.GetByRestaurantIdAsync(restaurantId, onlyAvailable, ct);
        return dishes.Select(ToDto);
    }

    public async Task<DishDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var d = await _uow.Dishes.GetByIdAsync(id, ct);
        return d is null ? null : ToDto(d);
    }

    private static DishDto ToDto(Dish d) => new(
        d.Id, d.RestaurantId, d.Name, d.Description, d.Price,
        d.Category, d.ImageUrl, d.AvailabilityStart, d.AvailabilityEnd,
        d.IsActive, d.RatingAverage, d.RatingCount, d.CreatedAt, d.UpdatedAt
    );
}
