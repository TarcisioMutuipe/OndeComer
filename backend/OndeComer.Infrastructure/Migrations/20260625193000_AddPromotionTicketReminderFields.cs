using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OndeComer.Infrastructure.Migrations
{
    public partial class AddPromotionTicketReminderFields : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ExpirationReason",
                table: "PromotionTickets",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReminderSentAt",
                table: "PromotionTickets",
                type: "timestamp with time zone",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ExpirationReason",
                table: "PromotionTickets");

            migrationBuilder.DropColumn(
                name: "ReminderSentAt",
                table: "PromotionTickets");
        }
    }
}
