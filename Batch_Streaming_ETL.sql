/*
 * 
 * IMT 563 Project ETL
 * Team 8
 * 
*/


USE QICC


/*
 * Batch Incremental ETL
 * Stored Procedures
 */

/*
 * Stored procedure to load data from SRC.City to TBL.City
*/

DROP PROCEDURE LoadCity

CREATE PROCEDURE LoadCity
@LastLoadTime DATETIME
AS
BEGIN
	MERGE TBL.City AS tar
	USING (SELECT
				sc.CityName, 
				tc.CountryID 
			FROM SRC.City sc
			JOIN TBL.Country tc
			ON sc.CountryName = tc.CountryName
			WHERE sc.TS > @LastLoadTime
		) AS src
	ON tar.CityName = src.CityName
	
	WHEN NOT MATCHED THEN
		INSERT (CityName, CountryID)
		VALUES (src.CityName, src.CountryID);
END

EXEC LoadCity '2023-05-25 00:00:00.000'


-- Test if data successfully loaded into the TBL.City table
SELECT * FROM TBL.City


/*
 * Stored procedure to load data from SRC.Airport to TBL.Airport
*/
DROP PROCEDURE LoadAirport

CREATE PROCEDURE LoadAirport
@LastLoadTime DATETIME
AS
BEGIN
	MERGE TBL.Airport AS tar
	USING (SELECT
				tc.CityName, 
				tc.CityID,
				sa.AirportName,
				sa.IATA,
				sa.ICAO,
				sa.Latitude,
				sa.Longitude,
				sa.Altitude 
			FROM SRC.Airport sa
			JOIN TBL.City tc
			ON sa.AirportCityName = tc.CityName
			JOIN TBL.Country tcy
			ON sa.AirportCountryName = tcy.CountryName 
			AND tc.CountryID = tcy.CountryID 
			WHERE sa.TS > @LastLoadTime
		) AS src
	ON tar.AirportName = src.AirportName
	
	WHEN NOT MATCHED THEN
		INSERT (AirportName, AirportCityID, IATA, ICAO, 
				Latitude, Longitude, Altitude)
		VALUES (src.AirportName, src.CityID, src.IATA, src.ICAO,
				src.Latitude, src.Longitude, src.Altitude);
END

EXEC LoadAirport '2023-05-25 00:00:00.000'


-- Test if data successfully loaded into the TBL.Airport table
SELECT COUNT(*) FROM TBL.Airport


/*
 * Stored procedure to load data from SRC.Route to TBL.Route
*/
DROP PROCEDURE LoadRoute

CREATE PROCEDURE LoadRoute
@LastLoadTime DATETIME
AS
BEGIN
	MERGE TBL.Route AS tar
	USING (SELECT
				tal.AirlineID,
				tap1.AirportID AS 'OriginAirportID',
				tap2.AirportID AS 'DestinationAirportID',
				sr.Stops,
				tp.PlaneID 
			FROM SRC.Route sr
			JOIN TBL.Airline tal
			ON sr.AirlineIATA = tal.IATA 
			JOIN TBL.Airport tap1
			ON sr.OriginAirportIATA = tap1.IATA 
			JOIN TBL.Airport tap2
			ON sr.DestinationAirportIATA = tap2.IATA 
			JOIN TBL.Plane tp
			ON sr.AirCraftIATA = tp.IATA 
			WHERE sr.TS > @LastLoadTime
		) AS src
	ON tar.AirlineID = src.AirlineID
    AND tar.OriginAirportID = src.OriginAirportID
	AND tar.DestinationAirportID = src.DestinationAirportID
	
	WHEN NOT MATCHED THEN
		INSERT (AirlineID, OriginAirportID, DestinationAirportID, Stops, AirCraftID)
		VALUES (src.AirlineID, src.OriginAirportID, src.DestinationAirportID,
				src.Stops, src.PlaneID);
END

EXEC LoadRoute '2023-05-25 00:00:00.000'


-- Test if data successfully loaded into the TBL.Route table
SELECT COUNT(*) FROM TBL.Route


/*
 * Stored procedure to load data from SRC.Flight to TBL.Flight
*/
DROP PROCEDURE LoadFlight

CREATE PROCEDURE LoadFlight
@LastLoadTime DATETIME
AS
BEGIN
	MERGE TBL.Flight AS tar
	USING (SELECT
				sf.UserID,
				tr.RouteID,
				sf.FlightNumber,
				sf.FlightDate,
				sf.TravelTypeID,
				sf.CabinClassID,
				sf.ScheduledDepTime,
				sf.ActualDepTime, 
				sf.DepDelay,
				sf.ScheduledArrTime,
				sf.ActualArrTime,
				sf.ArrDelay, 
    			sf.Cancelled,
    			sf.AirTime,
    			sf.Distance 
			FROM SRC.Flight sf
			JOIN TBL.Airport tap1
			ON sf.OriginAirport = tap1.IATA 
			JOIN TBL.Airport tap2
			ON sf.DestinationAirport = tap2.IATA 
			JOIN TBL.Airline ta
			ON sf.CarrierIATA = ta.IATA 
			JOIN TBL.Route tr
			ON tap1.AirportID = tr.OriginAirportID
			AND tap2.AirportID = tr.DestinationAirportID
			AND ta.AirlineID = tr.AirlineID 
			JOIN TBL.[User] tu
			ON sf.UserID = tu.UserID 
			JOIN TBL.TravelType tt
			ON sf.TravelTypeID = tt.TravelTypeID 
			JOIN TBL.CabinClass tc
			ON sf.CabinClassID = tc.CabinClassID 
			WHERE sf.TS > @LastLoadTime
		) AS src
	ON tar.UserID = src.UserID
    AND tar.FlightNumber = src.FlightNumber
	AND tar.FlightDate = src.FlightDate
	
	WHEN NOT MATCHED THEN
		INSERT (UserID, RouteID, FlightNumber, FlightDate, TravelTypeID,
		CabinClassID, ScheduledDepTime, ActualDepTime, DepDelay, ScheduledArrTime,
		ActualArrTime, ArrDelay, Cancelled, AirTime, Distance)
		VALUES (src.UserID,
				src.RouteID,
				src.FlightNumber,
				src.FlightDate,
				src.TravelTypeID,
				src.CabinClassID,
				src.ScheduledDepTime,
				src.ActualDepTime, 
				src.DepDelay,
				src.ScheduledArrTime,
				src.ActualArrTime,
				src.ArrDelay, 
    			src.Cancelled,
    			src.AirTime,
    			src.Distance );
END

EXEC LoadFlight '2023-05-25 00:00:00.000'


-- Test if data successfully loaded into the TBL.Flight table
SELECT COUNT(*) FROM TBL.Flight


/*
 * Streaming ETL
 * Trigger on Flight Insert
 */


DROP TRIGGER SRC.TGR_SRC_Flight

CREATE TRIGGER SRC.TGR_SRC_Flight ON SRC.Flight
FOR INSERT
AS
BEGIN
	BEGIN TRY
		INSERT INTO TBL.Flight
			(UserID, RouteID, FlightNumber, 
			FlightDate, TravelTypeID, CabinClassID, 
			ScheduledDepTime, ActualDepTime, DepDelay, 
			ScheduledArrTime, ActualArrTime, ArrDelay, 
			Cancelled, AirTime, Distance)
		SELECT
			i.UserID,
			ri.RouteID,
			i.FlightNumber,
			i.FlightDate,
			i.TravelTypeID,
			i.CabinClassID,
			i.ScheduledDepTime,
			i.ActualDepTime, 
			i.DepDelay, 
			i.ScheduledArrTime, 
			i.ActualArrTime, 
			i.ArrDelay, 
			i.Cancelled, 
			i.AirTime, 
			i.Distance		
		FROM
			INSERTED i
		JOIN
			TBL.VW_RouteInfo ri
		ON
			i.OriginAirport = ri.OriginIATA
		AND
			i.DestinationAirport = ri.DestinationIATA
		AND
			i.CarrierIATA = ri.AirlineIATA
	END TRY
	BEGIN CATCH
		SELECT 'Failed to Load to TBL.Flight.'
	END CATCH
END

-- Testing

SELECT *
FROM SRC.Flight
WHERE UserID = 20

SELECT *
FROM TBL.Flight
WHERE UserID = 20

INSERT INTO SRC.Flight
(UserID, CarrierIATA, FlightNumber,FlightDate,
    OriginAirport, OriginCityName, DestinationAirport,
	DestinationCityName, ScheduledDepTime, ActualDepTime, 
	DepDelay, ScheduledArrTime, ActualArrTime, ArrDelay, 
    Cancelled, AirTime, Distance, TravelTypeID, CabinClassID)
VALUES (20, 'AA', 2817, '2023-05-20 00:00:00.000', 'DCA', 'Washington', 'DFW', 'Dallas-Fort Worth', 
1520, 1524, 4, 1841, 1838, -3, 0, 91, 740, 0, 1)


DELETE FROM SRC.FLIGHT
WHERE UserID = 20 AND FlightNumber = 2817

DELETE FROM TBL.FLIGHT
WHERE UserID = 20 AND FlightNumber = 2817
