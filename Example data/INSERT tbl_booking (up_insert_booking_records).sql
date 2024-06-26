--------------------------------------------------------------------------------------------------
--- PROCEDURE DEFINITION
--- up_insert_booking_records
--------------------------------------------------------------------------------------------------
-- This procedure is used to generate booking records.
-- It randomly selects a customer and a package, and assigns a random discount percentage.
-- Then it calculates the discount amount and  booking price.
-- Then it inserts a booking record into the tbl_booking table with the retrieved details.
--
-- Example Usage:
-- EXEC up_insert_booking_records
--
-- Result of the action
-- Procedure adds booking records
--------------------------------------------------------------------------------------------------


USE [TRAVEL_AGENCY]
GO


CREATE OR ALTER PROCEDURE up_insert_booking_records
AS
BEGIN
    DECLARE @Discount TABLE (Discount FLOAT);
    INSERT INTO @Discount (Discount) VALUES (0.0), (0.0), (0.0), (0.0), (0.0), (0.0), (0.0), (0.0), (0.0), (0.0), (0.0), (0.0), (0.02), (0.03), (0.05), (0.07), (0.1), (0.12), (0.15), (0.18);

    DECLARE @CustId INT;
    DECLARE @PackageId INT;
    DECLARE @DiscountPercent FLOAT;
    DECLARE @packPrice DECIMAL(10, 2)
    DECLARE @bookDiscountAmnt DECIMAL(10, 2)
    DECLARE @bookPrice DECIMAL(10, 2)

    DECLARE @CustomerCount INT;
    SELECT @CustomerCount = COUNT(*) FROM tbl_customer;

    DECLARE @Counter INT = 1;

    WHILE @Counter <= @CustomerCount
    BEGIN
        SELECT @CustId = custId FROM tbl_customer ORDER BY custId OFFSET (@Counter - 1) ROWS FETCH NEXT 1 ROW ONLY;

        SELECT TOP 1 @DiscountPercent = Discount
        FROM @Discount
        ORDER BY NEWID();

		SET @PackageId = ROUND(RAND() * (4031 - 3817) + 3817, 0);

		IF @CustId IS NOT NULL AND @PackageId IS NOT NULL AND EXISTS (SELECT 1 FROM tbl_package WHERE packId = @PackageId)
		BEGIN
			SELECT @packPrice = packPrice
			FROM tbl_package
			WHERE packId = @PackageId;

			SET @bookDiscountAmnt = @packPrice * @DiscountPercent;

			SET @bookPrice = @packPrice - @bookDiscountAmnt;

            INSERT INTO tbl_booking(bookCustId, bookPackageId, bookDiscountPercent, bookPrice, bookDiscountAmnt)
            VALUES (@CustId, @PackageId, @DiscountPercent, @bookPrice,  @bookDiscountAmnt);
			
			SET @Counter = @Counter + 1;
		END
    END
END;

-----------------------------------------------------------------------------------------------

EXEC up_insert_booking_records

-----------------------------------------------------------------------------------------------
USE TRAVEL_AGENCY
GO
select count(*) from tbl_booking