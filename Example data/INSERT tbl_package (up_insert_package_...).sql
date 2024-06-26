--------------------------------------------------------------------------------------------------
--- PROCEDURE DEFINITION
--- up_insert_package_flight_records
--------------------------------------------------------------------------------------------------
-- This procedure is used to generate package records with flight details.
-- It randomly selects a city and fetches outbound and return flight IDs for that city.
-- It also fetches a representative ID and hotel ID for the selected city.
-- Then, it calculates the duration of the trip, price, and start/end dates based on the selected flights, hotel, and city details.
-- Finally, it inserts a package record into the tbl_package table with the retrieved details.
--
-- Example Usage:
-- EXEC up_insert_package_flight_records
--
-- Result of the action
-- Procedure adds package records with flight details
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
--- PROCEDURE DEFINITION
--- up_insert_package_bus_records
--------------------------------------------------------------------------------------------------
-- This procedure is used to generate package records with bus route details.
-- It randomly selects a city and fetches outbound and return bus route IDs for that city.
-- It also fetches a representative ID and hotel ID for the selected city.
-- Then, it calculates the duration of the trip, price, and start/end dates based on the selected bus route, hotel, and city details.
-- Finally, it inserts a package record into the tbl_package table with the retrieved details.
--
-- Example Usage:
-- EXEC up_insert_package_bus_records
--
-- Result of the action
-- Procedure adds package records with bus route details
--------------------------------------------------------------------------------------------------

USE TRAVEL_AGENCY
GO

CREATE OR ALTER PROCEDURE up_insert_package_flight_records
AS
BEGIN
    DECLARE @CityId INT;
    DECLARE @CityName VARCHAR(50);
    DECLARE @OutboundFlightId INT;
    DECLARE @ReturnFlightId INT;
    DECLARE @RepId INT;
    DECLARE @HotelId INT;
    DECLARE @RandomIndex INT;
    DECLARE @Duration TINYINT;
    DECLARE @StartDate DATE;
    DECLARE @EndDate DATE;
    DECLARE @Price FLOAT;

    SET @RandomIndex = ROUND(RAND() * (441 - 1) + 1, 0);
    SELECT @CityId = cityId, @CityName = cityName 
	FROM tbl_city 
	WHERE cityId = @RandomIndex;

    SELECT TOP 1 @OutboundFlightId = fliId FROM tbl_flight WHERE fliEndCityId = @CityId ORDER BY NEWID();

    SELECT TOP 1 @ReturnFlightId = fliId
		FROM tbl_flight WHERE fliStartCityId = (SELECT fliEndCityId FROM tbl_flight WHERE fliId = @OutboundFlightId) AND 
		fliEndCityId = (SELECT fliStartCityId FROM tbl_flight WHERE fliId = @OutboundFlightId) AND 
		fliStartTime > (SELECT fliEndTime FROM tbl_flight WHERE fliId = @OutboundFlightId) AND
		DATEDIFF(DAY, (SELECT fliEndTime FROM tbl_flight WHERE fliId = @OutboundFlightId), fliStartTime) < 30 AND
		DATEDIFF(DAY, (SELECT fliEndTime FROM tbl_flight WHERE fliId = @OutboundFlightId), fliStartTime) > 3
		ORDER BY NEWID();
		
    SELECT TOP 1 @RepId = repId FROM tbl_representative WHERE repCityId = @CityId ORDER BY NEWID();

    SELECT TOP 1 @HotelId = hotId FROM tbl_hotel WHERE hotAddrId IN (SELECT addrId FROM tbl_address WHERE addrCityId = @CityId) ORDER BY NEWID();

	IF @OutboundFlightId IS NULL OR @RepId IS NULL OR @HotelId IS NULL OR @ReturnFlightId IS NULL
	BEGIN
		RETURN;
	END
	ELSE
	BEGIN
		 SELECT @StartDate = fliEndTime FROM tbl_flight WHERE fliId = @OutboundFlightId;
		 SELECT @EndDate = fliStartTime FROM tbl_flight WHERE fliId = @ReturnFlightId;
		 SELECT @Duration = DATEDIFF(DAY, @StartDate, @EndDate) + 1
		 SELECT @Price = 
        (
            (SELECT hotPricePerNight FROM tbl_hotel WHERE hotId = @HotelId) * @Duration +
            ISNULL((SELECT fliPrice FROM tbl_flight WHERE fliId = @OutboundFlightId), 0) +
            ISNULL((SELECT fliPrice FROM tbl_flight WHERE fliId = @ReturnFlightId), 0) +
            ISNULL((SELECT busRoutePrice FROM tbl_busroute WHERE busRouteId = @OutboundFlightId), 0) +
            ISNULL((SELECT busRoutePrice FROM tbl_busroute WHERE busRouteId = @ReturnFlightId), 0)
        ) * 1.15

		INSERT INTO tbl_package(packTitle, packDescription, packCityId, packHotId, packDuration, packPrice, packStartDate, packEndDate, packOutboundFlightId, packReturnFlightId, packRepId)
		VALUES ('Unforgettable trip to ' + @CityName, NULL, @CityId, @HotelId, @Duration, @Price, @StartDate, @EndDate, @OutboundFlightId, @ReturnFlightId, @RepId);
	END
END;

/*--------------------------------------------------------------------------------------------------------*/

CREATE OR ALTER PROCEDURE up_insert_package_bus_records
AS
BEGIN
    DECLARE @CityId INT;
    DECLARE @CityName VARCHAR(50);
    DECLARE @OutboundBusRouteId INT;
    DECLARE @ReturnBusRouteId INT;
    DECLARE @EndDate DATE;
    DECLARE @RepId INT;
    DECLARE @HotelId INT;
    DECLARE @Duration TINYINT;
    DECLARE @RandomIndex INT;
    DECLARE @StartDate DATE;
    DECLARE @Price FLOAT;

    SET @RandomIndex = ROUND(RAND() * (441 - 1) + 1, 0);
    SELECT @CityId = cityId, @CityName = cityName 
	FROM tbl_city 
	WHERE cityId = @RandomIndex;

    SELECT TOP 1 @OutboundBusRouteId = busRouteId FROM tbl_busroute WHERE busRouteEndCityId = @CityId ORDER BY NEWID();
	
    SELECT TOP 1 @ReturnBusRouteId = busRouteId, @EndDate = busRouteEndTime 
		FROM tbl_busroute WHERE busRouteStartCityId = (SELECT busRouteEndCityId FROM tbl_busroute WHERE busRouteId = @OutboundBusRouteId) AND 
		busRouteEndCityId = (SELECT busRouteStartCityId FROM tbl_busroute WHERE busRouteId = @OutboundBusRouteId) AND 
		busRouteStartTime > (SELECT busRouteEndTime FROM tbl_busroute WHERE busRouteId = @OutboundBusRouteId) AND
		DATEDIFF(DAY, (SELECT busRouteEndTime FROM tbl_busroute WHERE busRouteId = @OutboundBusRouteId), busRouteStartTime) < 30 AND
		DATEDIFF(DAY, (SELECT busRouteEndTime  FROM tbl_busroute WHERE busRouteId = @OutboundBusRouteId), busRouteStartTime) > 3
		ORDER BY NEWID();
		
    SELECT TOP 1 @RepId = repId FROM tbl_representative WHERE repCityId = @CityId ORDER BY NEWID();

    SELECT TOP 1 @HotelId = hotId FROM tbl_hotel WHERE hotAddrId IN (SELECT addrId FROM tbl_address WHERE addrCityId = @CityId) ORDER BY NEWID();

	IF @OutboundBusRouteId IS NULL OR @RepId IS NULL OR @HotelId IS NULL OR @ReturnBusRouteId IS NULL
	BEGIN
		RETURN;
	END
	ELSE
	BEGIN
		 SELECT @StartDate = busRouteEndTime FROM tbl_busroute WHERE busRouteId = @OutboundBusRouteId;
		 SELECT @EndDate = busRouteStartTime FROM tbl_busroute WHERE busRouteId = @ReturnBusRouteId;
		 SELECT @Duration = DATEDIFF(DAY, @StartDate, @EndDate) + 1
		 SELECT @Price = 
        (
            (SELECT hotPricePerNight FROM tbl_hotel WHERE hotId = @HotelId) * @Duration +
            ISNULL((SELECT fliPrice FROM tbl_flight WHERE fliId = @OutboundBusRouteId), 0) +
            ISNULL((SELECT fliPrice FROM tbl_flight WHERE fliId = @ReturnBusRouteId), 0) +
            ISNULL((SELECT busRoutePrice FROM tbl_busroute WHERE busRouteId = @OutboundBusRouteId), 0) +
            ISNULL((SELECT busRoutePrice FROM tbl_busroute WHERE busRouteId = @ReturnBusRouteId), 0)
        ) * 1.15

		INSERT INTO tbl_package (packTitle, packDescription, packCityId, packHotId, packDuration, packPrice, packStartDate, packEndDate, packOutboundBusRouteId, packReturnBusRouteId, packRepId)
		VALUES ('Unforgettable trip to ' + @CityName, NULL, @CityId, @HotelId, @Duration, @Price, @StartDate, @EndDate, @OutboundBusRouteId, @ReturnBusRouteId, @RepId);
	END
END;

/*--------------------------------------------------------------------------------------------------------*/

DECLARE @Counter INT = 0

WHILE @Counter < 500
BEGIN
    EXEC up_insert_package_bus_records
    EXEC up_insert_package_flight_records
    SET @Counter = @Counter + 1
END

/*--------------------------------------------------------------------------------------------------------*/
USE TRAVEL_AGENCY
GO
select count(*) from tbl_package