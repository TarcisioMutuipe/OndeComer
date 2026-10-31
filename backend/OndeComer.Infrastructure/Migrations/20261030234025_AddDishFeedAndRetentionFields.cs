using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OndeComer.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDishFeedAndRetentionFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "DeactivatedAt",
                table: "Dishes",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ShowInFeed",
                table: "Dishes",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<string>(
                name: "Subcategory",
                table: "Dishes",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

                migrationBuilder.Sql("""
                     UPDATE "Dishes"
                     SET "DeactivatedAt" = "UpdatedAt"
                     WHERE "IsActive" = FALSE;

                     UPDATE "Dishes"
                     SET "ShowInFeed" = FALSE
                     WHERE LOWER("Category") LIKE '%bebid%'
                         OR LOWER("Category") LIKE '%vinho%'
                         OR LOWER("Category") LIKE '%drink%';
                     """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeactivatedAt",
                table: "Dishes");

            migrationBuilder.DropColumn(
                name: "ShowInFeed",
                table: "Dishes");

            migrationBuilder.DropColumn(
                name: "Subcategory",
                table: "Dishes");
        }
    }
}
