/*
 * 
 * IMT 563 Project Data Mart
 * Team 8
 * 
*/

USE QICC

CREATE SCHEMA DM

-- 1.Average rating of airline services
DROP TABLE IF EXISTS DM.Airline_Rating

CREATE TABLE DM.Airline_Rating(
	AirlineName VARCHAR(150) NOT NULL,
	IATA VARCHAR(10) NOT NULL,
	BaggageHandling FLOAT NOT NULL,
	CheckinService FLOAT NOT NULL,
	Cleanliness FLOAT NOT NULL,
	DepArrTimeConvenience FLOAT NOT NULL,
	EaseofOnlineBoarding FLOAT NOT NULL,
	EaseofOnlineBooking FLOAT NOT NULL,
	FoodDrink FLOAT NOT NULL,
	GateLocation FLOAT NOT NULL,
	InflightEntertainment FLOAT NOT NULL,
	InflightService FLOAT NOT NULL,
	LegroomService FLOAT NOT NULL,
	OnboardService FLOAT NOT NULL,
	Satisfaction FLOAT NOT NULL,
	SeatComfort FLOAT NOT NULL,
	WifiService FLOAT NOT NULL
)

INSERT INTO DM.Airline_Rating
SELECT
	a.AirlineName,
	a.IATA,
	ROUND(AVG(CAST(r.BaggageHandling AS FLOAT)), 2) AS BaggageHandling,
	ROUND(AVG(CAST(r.CheckinService AS FLOAT)), 2) AS CheckinService,
	ROUND(AVG(CAST(r.Cleanliness AS FLOAT)), 2) AS Cleanliness,
	ROUND(AVG(CAST(r.DepArrTimeConvenience AS FLOAT)), 2) AS DepArrTimeConvenience,
	ROUND(AVG(CAST(r.EaseofOnlineBoarding AS FLOAT)), 2) AS EaseofOnlineBoarding,
	ROUND(AVG(CAST(r.EaseofOnlineBooking AS FLOAT)), 2) AS EaseofOnlineBooking,
	ROUND(AVG(CAST(r.FoodDrink AS FLOAT)), 2) AS FoodDrink,
	ROUND(AVG(CAST(r.GateLocation AS FLOAT)), 2) AS GateLocation,
	ROUND(AVG(CAST(r.InflightEntertainment AS FLOAT)), 2) AS InflightEntertainment,
	ROUND(AVG(CAST(r.InflightService AS FLOAT)), 2) AS InflightService,
	ROUND(AVG(CAST(r.LegroomService AS FLOAT)), 2) AS LegroomService,
	ROUND(AVG(CAST(r.OnboardService AS FLOAT)), 2) AS OnboardService,
	ROUND(AVG(CAST(r.Satisfaction AS FLOAT)), 2) AS Satisfaction,
	ROUND(AVG(CAST(r.SeatComfort AS FLOAT)), 2) AS SeatComfort,
	ROUND(AVG(CAST(r.WifiService AS FLOAT)), 2) AS WifiService
FROM TBL.Flight f
JOIN TBL.Rating r
ON f.FlightID = r.FlightID
JOIN TBL.[Route] tr
ON f.RouteID = tr.RouteID
JOIN TBL.Airline a
ON tr.AirlineID = a.AirlineID
GROUP BY
	a.AirlineName,
	a.IATA

SELECT * FROM DM.Airline_Rating

-- 2.Average departure and arrival delay by airport
DROP TABLE IF EXISTS DM.Airport_AvgDepArrDelays

CREATE TABLE DM.Airport_AvgDepArrDelays(
    AirportID INT NOT NULL,
    AirportName VARCHAR(100) NOT NULL,
    AverageDepDelay FLOAT NOT NULL,
    AverageArrDelay FLOAT NOT NULL
)

INSERT INTO DM.Airport_AvgDepArrDelays
SELECT
    a.AirportID,
    a.AirportName,
    AVG(f.DepDelay) AS AverageDepDelay,
    AVG(f.ArrDelay) AS AverageArrDelay
FROM
    QICC.TBL.Flight AS f
JOIN
    QICC.TBL.Route AS r
ON
    f.RouteID = r.RouteID
JOIN
    QICC.TBL.Airport AS a
ON
    r.OriginAirportID = a.AirportID OR r.DestinationAirportID = a.AirportID
GROUP BY
    a.AirportID,
    a.AirportName

SELECT * FROM DM.Airport_AvgDepArrDelays

-- 3.Airport busyness by quarter
DROP TABLE IF EXISTS DM.Airport_BusiestAirportsByQuarter

CREATE TABLE DM.Airport_BusiestAirportsByQuarter(
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    AirportID INT NOT NULL,
    AirportName VARCHAR(100) NOT NULL,
    TotalFlights INT NOT NULL
)

INSERT INTO DM.Airport_BusiestAirportsByQuarter
SELECT
    DATEPART(yy, f.FlightDate) AS Year,
    DATEPART(qq, f.FlightDate) AS Quarter,
    a.AirportID,
    a.AirportName,
    COUNT(f.FlightID) AS TotalFlights
FROM
    QICC.TBL.Flight AS f
JOIN
    QICC.TBL.Route AS r
ON
    f.RouteID = r.RouteID
JOIN
    QICC.TBL.Airport AS a
ON
    r.OriginAirportID = a.AirportID OR r.DestinationAirportID = a.AirportID
GROUP BY
    DATEPART(yy, f.FlightDate),
    DATEPART(qq, f.FlightDate),
    a.AirportID,
    a.AirportName
ORDER BY
    TotalFlights DESC

SELECT * FROM DM.Airport_BusiestAirportsByQuarter
ORDER BY TotalFlights DESC

-- 4.Top travel destination by quarter
DROP TABLE IF EXISTS DM.Passenger_TopTravelDestinationByQuarter

CREATE TABLE DM.Passenger_TopTravelDestinationByQuarter (
    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    DestinationCityName VARCHAR(150) NOT NULL,
    DestinationCountryName VARCHAR(150) NOT NULL,
    TravelCounts INT NOT NULL,
    [Rank] INT NOT NULL
)

INSERT INTO DM.Passenger_TopTravelDestinationByQuarter
SELECT
    DATEPART(YY, f.FlightDate) AS [Year],
    DATEPART(QQ, f.FlightDate) AS [Quarter],
    c.CityName AS DestinationCityName,
    tc.CountryName AS DestinationCountryName,
    COUNT(*) AS TravelCounts,
    RANK() OVER (
        PARTITION BY
            DATEPART(YY, f.FlightDate),
            DATEPART(QQ, f.FlightDate)
        ORDER BY COUNT(*) DESC
    ) AS [Rank]
FROM tbl.Flight f
JOIN tbl.[Route] r ON f.RouteID = r.RouteID
JOIN tbl.Airport a1 ON r.DestinationAirportID = a1.AirportID
JOIN tbl.City c ON a1.AirportCityID = c.CityID
JOIN tbl.Country tc ON c.CountryID = tc.CountryID
GROUP BY
    DATEPART(YY, f.FlightDate),
    DATEPART(QQ, f.FlightDate),
    c.CityName,
    tc.CountryName

SELECT * FROM DM.Passenger_TopTravelDestinationByQuarter

-- 5.Travel type by route
DROP TABLE IF EXISTS DM.Passenger_TravelTypeByRoute

CREATE TABLE DM.Passenger_TravelTypeByRoute (
    RouteID INT NOT NULL,
    DepAirportName VARCHAR(150) NOT NULL,
    DepAirportIATA VARCHAR(10) NOT NULL,
    DestAirportName VARCHAR(150) NOT NULL,
    DestAirportIATA VARCHAR(10) NOT NULL,
    BusinessTravelPct FLOAT NOT NULL,
    PersonalTravelPct FLOAT NOT NULL
)

INSERT INTO DM.Passenger_TravelTypeByRoute
SELECT
    r.RouteID,
    a1.AirportName AS DepAirportName,
    a1.IATA AS DepAirportIATA,
    a2.AirportName AS DestAirportName,
    a2.IATA AS DestAirportIATA,
    ROUND(CAST(SUM(f.TravelTypeID) AS FLOAT) / COUNT(*) * 100, 2) AS BusinessTravelPct,
    ROUND(CAST((COUNT(*) - SUM(f.TravelTypeID)) AS FLOAT) / COUNT(*) * 100, 2) AS PersonalTravelPct
FROM tbl.Flight f
JOIN tbl.TravelType tt ON f.TravelTypeID = tt.TravelTypeID
JOIN tbl.[Route] r ON r.RouteID = f.RouteID
JOIN tbl.Airport a1 ON r.OriginAirportID = a1.AirportID
JOIN tbl.Airport a2 ON r.DestinationAirportID = a2.AirportID
GROUP BY
    r.RouteID,
    a1.AirportName,
    a1.IATA,
    a2.AirportName,
    a2.IATA

SELECT * FROM DM.Passenger_TravelTypeByRoute

-- 6.Airline Cancellation Rate By Quarter
DROP TABLE IF EXISTS DM.Airline_CancellationByQuarter

CREATE TABLE DM.Airline_CancellationByQuarter (
	[Year] INT NOT NULL,
	[Quarter] INT NOT NULL, 
	AirportName VARCHAR(150) NOT NULL, 
	IATA VARCHAR(10) NOT NULL, 
	CancellationRate FLOAT NOT NULL, 
	AirportCancellationRank INT NOT NULL
)

INSERT INTO DM.Airline_CancellationByQuarter
SELECT DATEPART(YY, F.FlightDate) AS [Year],
	   DATEPART(QQ, F.FlightDate) AS [Quarter],
	   A.AirlineName,
	   A.IATA,
	   ROUND((CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) 
	   									 FROM tbl.Flight 
	   									 WHERE DATEPART(yy, FlightDate) = DATEPART(yy, f.FlightDate) 
	   									 	AND DATEPART(qq, FlightDate) = DATEPART(qq, f.FlightDate))) * 100, 2) AS CancellationRate,
	   RANK() OVER (PARTITION BY DATEPART(yy, f.FlightDate), DATEPART(qq, f.FlightDate) ORDER BY COUNT(*) DESC) AS AirlineCancellationRank
FROM TBL.Flight AS F
JOIN TBL.[Route] R 
	ON F.RouteID = R.RouteID
JOIN TBL.Airline A
	ON R.AirlineID = A.AirlineID
WHERE F.Cancelled = 1
GROUP BY DATEPART(YY, F.FlightDate), DATEPART(QQ, F.FlightDate), A.AirlineName, A.IATA

SELECT * FROM DM.Airline_CancellationByQuarter

-- 7.On Time Performance By Route
DROP TABLE IF EXISTS DM.Route_OnTimePerformance

CREATE TABLE DM.Route_OnTimePerformance (
	RouteID INT NOT NULL,
	OriginAirportID INT NOT NULL,
	OriginAirportName VARCHAR(150) NOT NULL,
	DestinationAirportID INT NOT NULL,
	DestinationAirportName VARCHAR(150) NOT NULL,
	OnTimePercentage FLOAT NOT NULL,
	RouteOnTimeRank INT NOT NULL
)

INSERT INTO DM.Route_OnTimePerformance
SELECT R.RouteID,
       R.OriginAirportID,
       A1.AirportName AS OriginAirportName,
       R.DestinationAirportID,
       A2.AirportName AS DestinationAirportName,
       ROUND((CAST(SUM(CASE WHEN F.DepDelay <= 0 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)) * 100, 2) AS OnTimePercentage,
       RANK() OVER (PARTITION BY R.OriginAirportID, R.DestinationAirportID 
                    ORDER BY ROUND((CAST(SUM(CASE WHEN F.DepDelay <= 0 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)) * 100, 2) DESC
                   ) AS RouteOnTimeRank
FROM TBL.Flight AS F
JOIN TBL.[Route] AS R 
	ON F.RouteID = R.RouteID
JOIN TBL.Airport AS A1 
	ON R.OriginAirportID = A1.AirportID
JOIN TBL.Airport AS A2 
	ON R.DestinationAirportID = A2.AirportID
GROUP BY R.RouteID, R.OriginAirportID, A1.AirportName, R.DestinationAirportID, A2.AirportName

SELECT * FROM DM.Route_OnTimePerformance

-- 8.Number of New Customers by Quarter
DROP TABLE IF EXISTS DM.Airline_NewCustomersByQuarter

CREATE TABLE DM.Airline_NewCustomersByQuarter (
	AirlineName VARCHAR(150) NOT NULL, 
	IATA VARCHAR(10) NOT NULL, 
	[Year] INT NOT NULL,
	[Quarter] INT NOT NULL, 
	NewCustomer INT
)

INSERT INTO DM.Airline_NewCustomersByQuarter
SELECT FF.AirlineName,
       FF.IATA,
       DATEPART(YEAR, FF.FirstFlightDate) AS [Year],
       DATEPART(QUARTER, FF.FirstFlightDate) AS [Quarter],
       COUNT(FF.UserID) AS NewCustomer
FROM (
    SELECT A.AirlineName,
           A.IATA,   
           F.UserID, 
           MIN(F.FlightDate) AS FirstFlightDate
    FROM TBL.Flight AS F
    JOIN TBL.[Route] AS R 
        ON F.RouteID = R.RouteID
    JOIN TBL.Airline AS A
        ON R.AirlineID = A.AirlineID
    GROUP BY A.AirlineName, A.IATA, F.UserID
) AS FF
GROUP BY FF.AirlineName, FF.IATA, DATEPART(YEAR, FF.FirstFlightDate), DATEPART(QUARTER, FF.FirstFlightDate)

SELECT * 
FROM DM.Airline_NewCustomersByQuarter
ORDER BY AirlineName, IATA, [Year], [Quarter]

-- 9.Number of Returning Customers by Quarter
DROP TABLE IF EXISTS DM.Airline_ReturningCustomersByQuarter

CREATE TABLE DM.Airline_ReturningCustomersByQuarter (
	AirlineName VARCHAR(150) NOT NULL, 
	IATA VARCHAR(10) NOT NULL, 
	[Year] INT NOT NULL,
	[Quarter] INT NOT NULL, 
	ReturingCustomer INT
)

INSERT INTO DM.Airline_ReturningCustomersByQuarter
SELECT FF.AirlineName,
       FF.IATA,
       DATEPART(YEAR, F.FlightDate) AS [Year],
       DATEPART(QUARTER, F.FlightDate) AS [Quarter],
       COUNT(FF.UserID) AS ReturningCustomer
FROM (
    SELECT A.AirlineName,
           A.IATA,   
           F.UserID, 
           MIN(F.FlightDate) AS FirstFlightDate
    FROM TBL.Flight AS F
    JOIN TBL.[Route] AS R 
        ON F.RouteID = R.RouteID
    JOIN TBL.Airline AS A
        ON R.AirlineID = A.AirlineID
    GROUP BY A.AirlineName, A.IATA, F.UserID
) AS FF
JOIN TBL.Flight AS F
	ON FF.UserID = F.UserID
WHERE FF.FirstFlightDate != F.FlightDate
GROUP BY FF.AirlineName, FF.IATA, DATEPART(YEAR, F.FlightDate), DATEPART(QUARTER, F.FlightDate)

SELECT * 
FROM DM.Airline_ReturningCustomersByQuarter
ORDER BY AirlineName, IATA, [Year], [Quarter]

-- 10.Quick view of all flights from all airlines
DROP TABLE IF EXISTS DM.Airline_RoutesDetails

CREATE TABLE DM.Airline_RoutesDetails (
    RouteID INT NOT NULL,
    AirlineID INT NOT NULL,
    AirlineName VARCHAR(150) NOT NULL,
    OriginAirportID INT NOT NULL,
    OriginAirportName VARCHAR(150) NOT NULL,
    OriginCityName VARCHAR(150) NOT NULL,
    DestinationAirportID INT NOT NULL,
    DestinationAirportName VARCHAR(150) NOT NULL,
    DestinationCityName VARCHAR(150) NOT NULL,
    Stops INT NOT NULL,
    AirCraftID INT NOT NULL
)

INSERT INTO DM.Airline_RoutesDetails
SELECT
    RouteID,
    r.AirlineID,
    ta.AirlineName,
    r.OriginAirportID,
    a1.AirportName AS OriginAirportName,
    c1.CityName AS OriginCityName,
    r.DestinationAirportID,
    a2.AirportName AS DestinationAirportName,
    c2.CityName AS DestinationCityName,
    r.Stops,
    r.AirCraftID
FROM tbl.[Route] r
JOIN tbl.Airport a1 ON a1.AirportID = r.OriginAirportID
JOIN tbl.Airport a2 ON a2.AirportID = r.OriginAirportID
JOIN tbl.City c1 ON a1.AirportCityID = c1.CityID
JOIN tbl.City c2 ON a2.AirportCityID = c2.CityID
JOIN tbl.Airline ta ON r.AirlineID = ta.AirlineID

SELECT * FROM DM.Airline_RoutesDetails

-- 11.Most popular aircraft in each quarter
DROP TABLE IF EXISTS DM.Plane_PopularPlaneByQuarter

CREATE TABLE DM.Plane_PopularPlaneByQuarter (
    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    PlaneName VARCHAR(150) NOT NULL,
    ICAO VARCHAR(10) NOT NULL,
    PlaneCounts INT NOT NULL,
    PlaneRank INT NOT NULL
)

INSERT INTO DM.Plane_PopularPlaneByQuarter
SELECT
    DATEPART(YY, FlightDate) AS [Year],
    DATEPART(QQ, FlightDate) AS [Quarter],
    p.PlaneName,
    p.ICAO,
    COUNT(*) AS PlaneCounts,
    RANK() OVER (
        PARTITION BY
            DATEPART(YY, FlightDate),
            DATEPART(QQ, FlightDate)
        ORDER BY COUNT(*) DESC
    ) AS PlaneRank
FROM tbl.Flight f
JOIN tbl.[Route] r ON f.RouteID = r.RouteID
JOIN tbl.Plane p ON r.AirCraftID = p.PlaneID
GROUP BY
    DATEPART(YY, FlightDate),
    DATEPART(QQ, FlightDate),
    p.PlaneName,
    p.ICAO
ORDER BY
    [Year] DESC,
    [Quarter] DESC

SELECT * FROM DM.Plane_PopularPlaneByQuarter

-- 12.Delays by departure airport in each month
DROP TABLE IF EXISTS DM.Airport_DelayByMonth

CREATE TABLE DM.Airport_DelayByMonth (
    [Year] INT NOT NULL,
    [Month] INT NOT NULL,
    AirportName VARCHAR(150) NOT NULL,
    IATA VARCHAR(10) NOT NULL,
    AvgDepDelay FLOAT NOT NULL,
    AirportDelayRank INT NOT NULL
)

INSERT INTO DM.Airport_DelayByMonth
SELECT
    DATEPART(YY, f.FlightDate) AS [Year],
    DATEPART(MM, f.FlightDate) AS [Month],
    a.AirportName,
    a.IATA,
    ROUND(AVG(CAST(DepDelay AS FLOAT)), 2) AS AvgDepDelay,
    RANK() OVER (
        PARTITION BY
            DATEPART(YY, f.FlightDate),
            DATEPART(MM, f.FlightDate)
        ORDER BY AVG(DepDelay) DESC
    ) AS AirportDelayRank
FROM tbl.Flight f
JOIN tbl.[Route] r ON f.RouteID = r.RouteID
JOIN tbl.Airport a ON r.OriginAirportID = a.AirportID
GROUP BY
    DATEPART(YY, f.FlightDate),
    DATEPART(MM, f.FlightDate),
    a.AirportName,
    a.IATA
ORDER BY
    [Year] DESC,
    [Month] DESC

SELECT * FROM DM.Airport_DelayByMonth

-- Routes_From_Seattle --

DROP TABLE IF EXISTS DM.Routes_From_Seattle

CREATE TABLE DM.Routes_From_Seattle (
    RouteID INT NOT NULL,
    AirlineID INT NOT NULL,
    AirlineName VARCHAR(150) NOT NULL,
    OriginAirportID INT NOT NULL,
    OriginAirportName VARCHAR(150) NOT NULL,
    OriginCityName VARCHAR(150) NOT NULL,
    DestinationAirportID INT NOT NULL,
    DestinationAirportName VARCHAR(150) NOT NULL,
    DestinationCityName VARCHAR(150) NOT NULL,
    Stops INT NOT NULL,
    AirCraftID INT NOT NULL
)

INSERT INTO DM.Routes_From_Seattle
SELECT
    RouteID,
    r.AirlineID,
    ta.AirlineName,
    r.OriginAirportID,
    a1.AirportName AS OriginAirportName,
    c1.CityName AS OriginCityName,
    r.DestinationAirportID,
    a2.AirportName AS DestinationAirportName,
    c2.CityName AS DestinationCityName,
    r.Stops,
    r.AirCraftID
FROM tbl.[Route] r
JOIN tbl.Airport a1 ON a1.AirportID = r.OriginAirportID
JOIN tbl.Airport a2 ON a2.AirportID = r.DestinationAirportID
JOIN tbl.City c1 ON a1.AirportCityID = c1.CityID
JOIN tbl.City c2 ON a2.AirportCityID = c2.CityID
JOIN tbl.Airline ta ON r.AirlineID = ta.AirlineID
WHERE a1.AirportName = 'Seattle Tacoma International Airport'

SELECT * FROM DM.Routes_From_Seattle