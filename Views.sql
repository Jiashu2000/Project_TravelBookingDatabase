/*
 * 
 * IMT 563 Project DDL
 * Team 8
 * 
*/

USE QICC

/*
 * View on Route Info
 */

DROP VIEW TBL.VW_RouteInfo

CREATE VIEW TBL.VW_RouteInfo
AS
SELECT
	r.RouteID,
	al.AirlineName,
	al.IATA AS AirlineIATA,
	ap1.AirportName AS OriginAirport,
	ap1.IATA AS OriginIATA,
	c1.CityName AS OriginCity,
	cy1.CountryName AS OriginCountry,
	ap2.AirportName AS DestinationAirport,
	ap2.IATA AS DestinationIATA,
	c2.CityName AS DestinationCity,
	cy2.CountryName AS DestinationCountry
FROM
	TBL.Route r
JOIN
	TBL.Airport ap1
ON
	r.OriginAirportID = ap1.AirportID 
JOIN
	TBL.Airport ap2
ON
	r.DestinationAirportID = ap2.AirportID  
JOIN
	TBL.Airline al
ON
	r.AirlineID = al.AirlineID 
JOIN
	TBL.City c1
ON
	ap1.AirportCityID = c1.CityID 
JOIN
	TBL.City c2
ON
	ap2.AirportCityID = c2.CityID 
JOIN
	TBL.Country cy1
ON
	c1.CountryID = cy1.CountryID 
JOIN
	TBL.Country cy2
ON
	c2.CountryID = cy2.CountryID 

SELECT * FROM TBL.VW_RouteInfo