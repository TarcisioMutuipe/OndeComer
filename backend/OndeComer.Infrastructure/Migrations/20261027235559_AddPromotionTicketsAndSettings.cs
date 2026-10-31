using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace OndeComer.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPromotionTicketsAndSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ClaimEndsAt",
                table: "Promotions",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AddColumn<DateTime>(
                name: "ClaimStartsAt",
                table: "Promotions",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AddColumn<string>(
                name: "PixKey",
                table: "Promotions",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RemainingTickets",
                table: "Promotions",
                type: "integer",
                nullable: false,
                defaultValue: 10);

            migrationBuilder.AddColumn<string>(
                name: "Scope",
                table: "Promotions",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "TargetDishIdsJson",
                table: "Promotions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TicketValidityDays",
                table: "Promotions",
                type: "integer",
                nullable: false,
                defaultValue: 7);

            migrationBuilder.AddColumn<int>(
                name: "TotalTickets",
                table: "Promotions",
                type: "integer",
                nullable: false,
                defaultValue: 10);

            migrationBuilder.CreateTable(
                name: "PromotionSettings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    BatchPrice = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    TicketsPerBatch = table.Column<int>(type: "integer", nullable: false),
                    TicketValidityDays = table.Column<int>(type: "integer", nullable: false),
                    ClaimWindowDays = table.Column<int>(type: "integer", nullable: false),
                    PixKey = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    ReceiptPhoneNumber = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PromotionSettings", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "PromotionTickets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PromotionId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    QrCodeToken = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    ClaimedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    RedeemedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ExpirationReason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    ReminderSentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PromotionTickets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PromotionTickets_Promotions_PromotionId",
                        column: x => x.PromotionId,
                        principalTable: "Promotions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PromotionTickets_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PromotionTickets_PromotionId",
                table: "PromotionTickets",
                column: "PromotionId");

            migrationBuilder.CreateIndex(
                name: "IX_PromotionTickets_QrCodeToken",
                table: "PromotionTickets",
                column: "QrCodeToken",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PromotionTickets_UserId",
                table: "PromotionTickets",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PromotionSettings");

            migrationBuilder.DropTable(
                name: "PromotionTickets");

            migrationBuilder.DropColumn(
                name: "ClaimEndsAt",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "ClaimStartsAt",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "PixKey",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "RemainingTickets",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "Scope",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "TargetDishIdsJson",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "TicketValidityDays",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "TotalTickets",
                table: "Promotions");
        }
    }
}
