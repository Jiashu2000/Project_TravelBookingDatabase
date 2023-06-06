/*
 * 
 * IMT 563 Project Relational Model Table DDL
 * Team 8
 * 
*/

USE QICC

CREATE SCHEMA TBL

-- Load Table In TBL

/*
 * Airline Table
 * Purpose: Store basic information about airlines
 * Clustered Index: AirlineID
 * Non-clustered Index: AirlineName; IATA
 * Unique Constraint: AirlineName
 * 
*/

DROP TABLE TBL.Airline

CREATE TABLE TBL.Airline (
	AirlineID INT IDENTITY(1, 1),
    AirlineName VARCHAR(150) NOT NULL,
    Alias VARCHAR(50),
    IATA VARCHAR(30),
    ICAO VARCHAR(30),
    Active TINYINT NOT NULL,
    TS DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Airline PRIMARY KEY CLUSTERED (AirlineID),
    CONSTRAINT IX_Airline_Name UNIQUE (AirlineName),
    INDEX IX_Airline_IATA NONCLUSTERED (IATA)
);



/*
 * Country Table
 * Purpose: Store basic information about countries where airports located in
 * Clustered Index: CountryID
 * Non-clustered Index: CountryName
 * Unique Constraint: CountryName
*/

DROP TABLE TBL.Country

CREATE TABLE TBL.Country (
	CountryID INT IDENTITY(1, 1),
    CountryName VARCHAR(50) NOT NULL,
    IsoCode VARCHAR(20),
    TS DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Country PRIMARY KEY CLUSTERED (CountryID),
    CONSTRAINT IX_Country_Name UNIQUE (CountryName)
);



/*
 * City Table
 * Purpose: Store basic information about cities where airports located in
 * Relationship: 
 *          FK1: Country(CountryID); One (Country) - Many (City)
 * Clustered Index: CityID
 * Non-clustered Index: CountryID; CityName
*/

DROP TABLE TBL.City

CREATE TABLE TBL.City (
	CityID INT IDENTITY(1, 1),
    CityName VARCHAR(100) NOT NULL,
    CountryID INT NOT NULL FOREIGN KEY REFERENCES TBL.Country(CountryID),
    TS DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_City PRIMARY KEY CLUSTERED (CityID),
    INDEX IX_City_Country NONCLUSTERED (CountryID),
    INDEX IX_City_Name NONCLUSTERED (CityName)
);



/*
 * Plane Table
 * Purpose: Store basic information about airplanes
 * Clustered Index: PlaneID
 * Non-clustered Index: IATA
*/

DROP TABLE TBL.Plane

CREATE TABLE TBL.Plane (
	PlaneID INT IDENTITY(1, 1),
    PlaneName VARCHAR(100) NOT NULL,
    IATA VARCHAR(30),
    ICAO VARCHAR(30),
    TS DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Plane PRIMARY KEY CLUSTERED (PlaneID),
    INDEX IX_Plane_IATA NONCLUSTERED (IATA)
);

SELECT  * FROM TBL.Plane



/*
 * Airport Table
 * Purpose: Store basic information about airports
 * Relationship: 
 *          FK1: City(CityID); One (City) - Many (Airport)
 * Clustered Index: AirportID
 * Non-clustered Index: AirportCityID; AirportName; IATA
*/

DROP TABLE TBL.Airport

CREATE TABLE TBL.Airport (
	AirportID INT IDENTITY(1, 1),
    AirportName VARCHAR(100) NOT NULL,
    AirportCityID INT NOT NULL FOREIGN KEY REFERENCES TBL.City(CityID),
    IATA VARCHAR(10),
    ICAO VARCHAR(10),
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    Altitude FLOAT NOT NULL,
    TS DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Airport PRIMARY KEY CLUSTERED (AirportID),
    INDEX IX_Airport_City NONCLUSTERED (AirportCityID),
    INDEX IX_Airport_Name NONCLUSTERED (AirportName),
    INDEX IX_Airport_IATA NONCLUSTERED (IATA)
);



/*
 * Route Table
 * Purpose: Store basic information about flight routes
 * Relationship: 
 *          FK1: Airline(AirlineID); One (Airline) - Many (Route)
 *          FK2: Airport(AirportID); One (OriginAirport) - Many (Route)
 *          FK3: Airport(AirportID); One (DestinationAirport) - Many (Route)
 *          FK4: Plane(PlaneID); One (PlaneID) - Many (Route)
 * Clustered Index: RouteID
 * Non-clustered Index: DestinationAirportID; OriginAirportID; 
 * 						(OriginAirportID, DestinationAirportID)
*/

DROP TABLE TBL.Route

CREATE TABLE TBL.Route (
	RouteID INT IDENTITY(1, 1),
    AirlineID INT NOT NULL FOREIGN KEY REFERENCES TBL.Airline(AirlineID),
    OriginAirportID INT NOT NULL FOREIGN KEY REFERENCES TBL.Airport(AirportID),
    DestinationAirportID INT NOT NULL FOREIGN KEY REFERENCES TBL.Airport(AirportID),
    Stops INT NOT NULL,
    AirCraftID INT NOT NULL FOREIGN KEY REFERENCES TBL.Plane(PlaneID),
    TS DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Route PRIMARY KEY CLUSTERED (RouteID),
    INDEX IX_Route_Destination NONCLUSTERED (DestinationAirportID),
    INDEX IX_Route_Origin NONCLUSTERED (OriginAirportID),
    INDEX IX_Route_OriginDest NONCLUSTERED (OriginAirportID, DestinationAirportID)
);



/*
 * TravelType Table
 * Purpose: Store basic information about types of travel.
 * Encoding: 
 *          0 represents Personal Travel
 *          1 represents Business Travel
 * 
*/

DROP TABLE TBL.TravelType

CREATE TABLE TBL.TravelType (
	TravelTypeID INT PRIMARY KEY,
    TravelTypeName VARCHAR(20) NOT NULL
);

INSERT INTO TBL.TravelType
VALUES 
    (0, 'Personal Travel'),
    (1, 'Business Travel')



/*
 * CabinClassType Table
 * Purpose: Store basic information about types of cabin class.
 * Encoding: 
 *          0 represents Economy
 *          1 represents Premium Economy
 *          2 represents Business
 * 
*/

DROP TABLE TBL.CabinClass

CREATE TABLE TBL.CabinClass (
	CabinClassID INT PRIMARY KEY,
    CabinClassName VARCHAR(20) NOT NULL
);

INSERT INTO TBL.CabinClass
VALUES 
    (0, 'Economy'),
    (1, 'Premium Economy'),
    (2, 'Business')



/*
 * User Table
 * Purpose: Store basic information about users
 * Clustered Index: UserID
 * Non-clustered Index: (FirstName, LastName);
*/

DROP TABLE TBL.[User]

CREATE TABLE TBL.[User] (
	UserID INT IDENTITY(1, 1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Age INT NOT NULL,
    TS DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_User PRIMARY KEY CLUSTERED (UserID),
    INDEX IX_User_Name NONCLUSTERED (FirstName, LastName)
);

SELECT * FROM TBL.[USER]



/*
 * Flight Table
 * Purpose: Store basic information about flights.
 * Relationship: 
 *          FK1: [User](UserID); One (User) - Many (Fight)
 *          FK2: Route(RouteID); One (Route) - Many (Fight)
 *          FK3: TravelType(TravelTypeID); One (TravelType) - Many (Fight)
 *          FK4: CabinClass(CabinClassID); One (CabinClass) - Many (Fight)
 * Note: ArrivalDelay & DepartureDelay are delay in minutes.
 * Clustered Index: FlightID
 * Non-clustered Index: UserID; (AirlineIATA, FlightNumber)
 * 
*/

DROP TABLE TBL.Flight

CREATE TABLE TBL.Flight (
	FlightID INT IDENTITY(1, 1),
    UserID INT NOT NULL FOREIGN KEY REFERENCES TBL.[User](UserID),
    RouteID INT NOT NULL FOREIGN KEY REFERENCES TBL.Route(RouteID),
    FlightNumber INT NOT NULL,
	FlightDate DATETIME NOT NULL,
    TravelTypeID INT NOT NULL FOREIGN KEY REFERENCES TBL.TravelType(TravelTypeID),
    CabinClassID INT NOT NULL FOREIGN KEY REFERENCES TBL.CabinClass(CabinClassID),
    ScheduledDepTime INT NOT NULL,
	ActualDepTime INT NOT NULL, 
	DepDelay INT NOT NULL,
    ScheduledArrTime INT NOT NULL,
    ActualArrTime INT NOT NULL,
    ArrDelay INT NOT NULL, 
    Cancelled INT NOT NULL,
    AirTime INT NOT NULL,
    Distance INT NOT NULL,
    TS DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Flight PRIMARY KEY CLUSTERED (FlightID),
    INDEX IX_Flight_User NONCLUSTERED (UserID),
    INDEX IX_Flight_FlightNumber NONCLUSTERED (FlightNumber)
);



/*
 * Rating Table
 * Purpose: Store basic information about flight ratings from users.
 * Relationship: 
 *          FK1: Flight(FlightID); One (Flight) - Many (Rating)
 * Note: From WifiService to Cleanlines are rating subcategories. 
 *       All rating range from 0 to 5.
 * Satisfaction Encoding: 
 *          0 represents Neutral or Dissatisfied
 *          1 represents Satisfied
 * Clustered Index: RatingID
 * Non-clustered Index: FlightID;
 * 
*/

DROP TABLE TBL.Rating

CREATE TABLE TBL.Rating (
	RatingID INT IDENTITY(1, 1),
    FlightID INT NOT NULL FOREIGN KEY REFERENCES TBL.Flight(FlightID),
    WifiService INT NOT NULL,
    DepArrTimeConvenience INT NOT NULL,
    EaseofOnlineBooking INT NOT NULL,
    GateLocation INT NOT NULL,
    FoodDrink INT NOT NULL, 
    EaseofOnlineBoarding INT NOT NULL,
    SeatComfort INT NOT NULL,
    InflightEntertainment INT NOT NULL,
    OnboardService INT NOT NULL,
    LegroomService INT NOT NULL,
    BaggageHandling INT NOT NULL,
    CheckinService INT NOT NULL,
    InflightService INT NOT NULL,
    Cleanliness INT NOT NULL,
    Satisfaction INT NOT NULL,
    TS DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Rating PRIMARY KEY CLUSTERED (RatingID),
    CONSTRAINT IX_Rating_FlightID UNIQUE (FlightID)
);


-- Test if data successfully loaded into the TBL.Rating table
SELECT * FROM TBL.Rating 


DBCC CHECKIDENT ('FLIGHT', RESEED, 0)

