using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OndeComer.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddEventsAndReservations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "AllowsReservations",
                table: "Restaurants",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "EventSpaceCapacity",
                table: "Restaurants",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "HasEventSpace",
                table: "Restaurants",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "TablesAvailableForReservation",
                table: "Restaurants",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TotalTables",
                table: "Restaurants",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "CityEvents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    ImageUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    YouTubeVideoUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    LocationOrAddress = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    EventDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RestaurantId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    LikesCount = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    DislikesCount = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CityEvents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CityEvents_Restaurants_RestaurantId",
                        column: x => x.RestaurantId,
                        principalTable: "Restaurants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_CityEvents_Users_CreatedByUserId",
                        column: x => x.CreatedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "RestaurantReservations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    RestaurantId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CustomerName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    CustomerPhone = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    ReservationDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    TimeSlot = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    PartySize = table.Column<int>(type: "integer", nullable: false),
                    ToleranceMinutes = table.Column<int>(type: "integer", nullable: false, defaultValue: 15),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    CancellationReason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    StatusUpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RestaurantReservations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RestaurantReservations_Restaurants_RestaurantId",
                        column: x => x.RestaurantId,
                        principalTable: "Restaurants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_RestaurantReservations_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CityEventReactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CityEventId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsLike = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CityEventReactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CityEventReactions_CityEvents_CityEventId",
                        column: x => x.CityEventId,
                        principalTable: "CityEvents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CityEventReactions_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CityEventReactions_Event_User",
                table: "CityEventReactions",
                columns: new[] { "CityEventId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CityEventReactions_UserId",
                table: "CityEventReactions",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_CityEvents_CreatedAt",
                table: "CityEvents",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_CityEvents_CreatedByUserId",
                table: "CityEvents",
                column: "CreatedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_CityEvents_IsActive",
                table: "CityEvents",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_CityEvents_RestaurantId",
                table: "CityEvents",
                column: "RestaurantId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_Restaurant_Date",
                table: "RestaurantReservations",
                columns: new[] { "RestaurantId", "ReservationDate" });

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_UserId",
                table: "RestaurantReservations",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CityEventReactions");

            migrationBuilder.DropTable(
                name: "RestaurantReservations");

            migrationBuilder.DropTable(
                name: "CityEvents");

            migrationBuilder.DropColumn(
                name: "AllowsReservations",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "EventSpaceCapacity",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "HasEventSpace",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "TablesAvailableForReservation",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "TotalTables",
                table: "Restaurants");
        }
    }
}
