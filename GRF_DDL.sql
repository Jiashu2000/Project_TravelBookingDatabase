/*
 * 
 * IMT 563 Project Graph Model DDL
 * Team 8
 * 
*/

USE QICC

CREATE SCHEMA GRF

-- Create Node Table

DROP TABLE GRF.Airport

CREATE TABLE GRF.Airport (
    AirportID INT NOT NULL PRIMARY KEY,
    AirportName VARCHAR(100) NOT NULL,
    AirportCityID INT NOT NULL,
    IATA VARCHAR(10)
) AS NODE;




INSERT INTO GRF.Airport
    SELECT
        a.AirportID AS AirportID,
        a.AirportName AS AirportName,
        a.AirportCityID AS AirportCityID,
        a.IATA AS IATA
    FROM
        TBL.Airport a




-- Create Edge Table

DROP TABLE GRF.Route

CREATE TABLE GRF.Route (
    RouteID INT NOT NULL,
    AirlineID INT NOT NULL,
    OriginAirportID INT NOT NULL,
    DestinationAirportID INT NOT NULL,
    Stops INT NOT NULL, 
    AirCraftID INT NOT NULL 
) AS EDGE;


INSERT INTO GRF.Route ($From_id, $to_id, RouteID, AirlineID, OriginAirportID, 
DestinationAirportID, Stops, AirCraftID) 
SELECT 
    Origin.$node_id AS FromNode, 
    Destination.$node_id AS ToNode,
    Route.RouteID,
    Route.AirlineID,
    Route.OriginAirportID,
    Route.DestinationAirportID,
    Route.Stops,
    Route.AirCraftID
FROM TBL.Route AS Route
	JOIN GRF.Airport AS Origin
		ON Origin.AirportID = Route.OriginAirportID
	JOIN GRF.Airport AS Destination
		ON Destination.AirportID = Route.DestinationAirportID


-- TESTING
/*
 * Airport info 
 */    
SELECT JSON_VALUE ($node_id, '$.id') AS id,
		AirportName
FROM GRF.Airport


/*
 * Direct Routes from Airport A to Airport B
 */
SELECT
    Route.RouteID,
    Route.AirlineID,
    Route.Stops
FROM
    GRF.Route AS Route,
    GRF.Airport AS Origin,
    GRF.Airport AS Destination
WHERE
    MATCH(Origin - (Route) -> Destination)
AND
    Origin.AirportName = 'Seattle Tacoma International Airport'
AND
    Destination.AirportName = 'John F Kennedy International Airport'


SELECT
    Route.RouteID,
    Route.AirlineID,
    Route.Stops
FROM
    GRF.Route AS Route,
    GRF.Airport AS Origin,
    GRF.Airport AS Destination
WHERE
    MATCH(Origin - (Route) -> Destination)
AND
    Origin.AirportName = 'Seattle Tacoma International Airport'
AND
    Destination.AirportName = 'Beijing Capital International Airport'


/*
 * Find Path from Airport A to Airport B within 2 Routes
 */

DROP FUNCTION GRF.FindPath

CREATE FUNCTION GRF.FindPath
(
@OriginAirport VARCHAR(100),
@DestinationAirport VARCHAR(100)
) 
RETURNS TABLE
AS
RETURN (
	SELECT
    	Origin.AirportName AS Origin,
		Destination.AirportName AS Destination,
		Route.Stops AS Transit,
		CONCAT(Route.RouteID, '') AS RoutePath,
		CONCAT(Route.AirlineID, '') AS AirlinePath,
		CONCAT(Origin.AirportName , ' -> ', Destination.AirportName) AS AirportPath
	FROM
    	GRF.Route AS Route,
    	GRF.Airport AS Origin,
    	GRF.Airport AS Destination
	WHERE
    	MATCH(Origin - (Route) -> Destination)
	AND
    	Origin.AirportName = @OriginAirport
	AND
    	Destination.AirportName = @DestinationAirport
    UNION ALL
	SELECT DISTINCT 
		a1.AirportName AS Origin,
		a3.AirportName AS Destination,
		r1.Stops + r2.Stops + 1 AS Transit,
		CONCAT(r1.RouteID , ' -> ', r2.RouteID) AS RoutePath,
		CONCAT(r1.AirlineID , ' -> ', r2.AirlineID) AS AirlinePath,
		CONCAT(a1.AirportName , ' -> ', a2.AirportName , ' -> ', a3.AirportName) AS AirportPath
	FROM 
		GRF.Airport AS a1, 
		GRF.Route AS r1,
		GRF.Airport AS a2, 
		GRF.Route AS r2,
		GRF.Airport AS a3
	WHERE MATCH (a1 -(r1)->a2-(r2)->a3)
	AND a1.AirportName = @OriginAirport
	AND a3.AirportName = @DestinationAirport 
	AND r1.Stops + r2.Stops <= 2
	AND a2.AirportName != a1.AirportName
	AND a3.AirportName != a2.AirportName
	AND a1.AirportName != a3.AirportName 
)

SELECT 	Transit, RoutePath, AirlinePath, AirportPath FROM GRF.FindPath('Seattle Tacoma International Airport', 'Beijing Capital International Airport')

SELECT Transit, RoutePath, AirlinePath, AirportPath FROM GRF.FindPath('Seattle Tacoma International Airport', 'John F Kennedy International Airport')

SELECT Transit, RoutePath, AirlinePath, AirportPath FROM GRF.FindPath('Seattle Tacoma International Airport', 'Chengdu Shuangliu International Airport')