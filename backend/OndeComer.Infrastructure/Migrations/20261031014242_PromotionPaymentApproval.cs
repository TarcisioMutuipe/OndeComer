using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OndeComer.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class PromotionPaymentApproval : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "ChargeEnabled",
                table: "PromotionSettings",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<decimal>(
                name: "PaymentAmount",
                table: "Promotions",
                type: "numeric(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PaymentApprovedAt",
                table: "Promotions",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaymentReceiptPhoneNumber",
                table: "Promotions",
                type: "character varying(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "RequiresPayment",
                table: "Promotions",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ChargeEnabled",
                table: "PromotionSettings");

            migrationBuilder.DropColumn(
                name: "PaymentAmount",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "PaymentApprovedAt",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "PaymentReceiptPhoneNumber",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "RequiresPayment",
                table: "Promotions");
        }
    }
}
