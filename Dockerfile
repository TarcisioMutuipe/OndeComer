FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY backend/OndeComer.Domain/OndeComer.Domain.csproj backend/OndeComer.Domain/
COPY backend/OndeComer.Application/OndeComer.Application.csproj backend/OndeComer.Application/
COPY backend/OndeComer.Infrastructure/OndeComer.Infrastructure.csproj backend/OndeComer.Infrastructure/
COPY backend/OndeComer.API/OndeComer.API.csproj backend/OndeComer.API/
RUN dotnet restore backend/OndeComer.API/OndeComer.API.csproj

COPY backend/ backend/
WORKDIR /src/backend/OndeComer.API
RUN dotnet publish OndeComer.API.csproj --configuration Release --output /app/publish --no-restore /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 10000
ENTRYPOINT ["sh", "-c", "dotnet OndeComer.API.dll --urls http://0.0.0.0:${PORT:-10000}"]
