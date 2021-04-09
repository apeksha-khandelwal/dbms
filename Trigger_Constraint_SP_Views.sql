
/*
drop TRIGGER PostTravelCovidTest 
Insert into covid values (2054,'2020-06-16','Positive','YES', 1027)
insert into [HealthPostTravel] Values(354,2054)
select * from [HealthPostTravel]

delete from HealthPostTravel where PostTravelID = 354
*/

	CREATE TRIGGER PostTravelCovidTest 
	ON HealthPostTravel 
	AFTER INSERT, UPDATE 
	AS 
	  BEGIN 
	  Print 'In trigger declare'
		  DECLARE @CovidTestID INT, 
				  @CovidResult VARCHAR(50), 
				  @PersonID    INT 

		  SELECT @CovidTestID = CovidTestID 
		  FROM   INSERTED

		  SELECT @CovidResult = CovidResult, 
				 @PersonID = PersonID 
		  FROM   Covid 
		  WHERE  CovidTestID = @CovidTestID 
				 AND CovidResult = 'Positive' 

		  IF @CovidResult IS NOT NULL 
			BEGIN 
				SELECT 'Positive alert! Execute TrackCoPassengerList(' + Cast(@PersonID as varchar(5)) +') to get the list of co-passengers to be notified.' as Recommended_Action
			END 
	END 
	GO 



/*
drop TRIGGER PreTravelCovidTest 
Insert into covid values (2054,'2020-06-16','Positive','YES', 1027)
insert into [HealthPreTravel] Values (354,98,'NO',2054)

delete from HealthPreTravel where PreTravelID = 354
*/

	CREATE TRIGGER PreTravelCovidTest 
	ON HealthPreTravel 
	AFTER INSERT, UPDATE 
	AS 
	  BEGIN 
		  DECLARE @CovidTestID INT, 
				  @CovidResult VARCHAR(50), 
				  @PersonID    INT 

		  SELECT @CovidTestID = CovidTestID 
		  FROM   inserted 

		  SELECT @CovidResult = CovidResult, 
				 @PersonID = PersonID 
		  FROM   Covid 
		  WHERE  CovidTestID = @CovidTestID 
				 AND CovidResult = 'Positive' 

		  IF @CovidResult IS NOT NULL 
		  BEGIN 
				SELECT 'Infected Patient found! Stop ' + Cast(@PersonID as varchar(5)) +' from onboarding.' as Recommended_Action
		  END 
	END
	GO


    
    --Stored Procedure
    CREATE PROCEDURE TrackCoPassengerList @PersonID INT
    AS
      BEGIN
          WITH EffectedFlights
               AS (SELECT F.FlightID     AS FlightID,
                          F.DateOfTravel AS TravelDate
                   FROM   PassengerOnFlight F
                          INNER JOIN Passenger P
                                  ON P.PassengerID = F.PassengerID
                   WHERE  P.PersonID = @PersonID
                )
          SELECT Per.PersonID,
                 EF.FlightID,
                 EF.TravelDate,
                 Per.FirstName + Per.LastName    AS FullName,
                 Per.Email,
                 Per.PhoneNumber,
                 addr.Street + ', ' + addr.City + ', ' + addr.State + ', ' +addr.ZipCode AS PersonAddress
          FROM   PERSON Per
                 INNER JOIN Passenger Pass
                         ON Pass.PersonID = Per.PersonID
                 INNER JOIN PassengerOnFlight POF
                         ON Pass.PassengerID = POF.PassengerID
                 INNER JOIN EffectedFlights EF
                         ON EF.FlightID = POF.FlightID
                            AND EF.TravelDate = POF.DateOfTravel
                INNER JOIN Address addr
                         ON addr.Addressid = Per.AddressID
				WHERE Per.PersonID != @PersonID
            UNION
            SELECT Per.PersonID, 
				 EF.FlightID,
				 EF.TravelDate,
				 Per.FirstName + Per.LastName    AS FullName, 
				 Per.Email, 
				 Per.PhoneNumber, 
				 addr.Street + ', ' + addr.City + ', ' + addr.State + ', ' +addr.ZipCode AS PersonAddress 
			FROM  EffectedFlights EF 
				INNER JOIN StaffOnFlight SOF 
						 ON EF.FlightID = SOF.FlightID and convert(date,EF.TravelDate) = convert(date,SOF.DateOfTravel)
				INNER JOIN Employee E 
						 ON E.EmployeeID = SOF.EmployeeID
				INNER JOIN PERSON Per 
						 on E.PersonID = Per.PersonID
				INNER JOIN Address addr 
						 ON addr.Addressid = Per.AddressID	
				WHERE Per.PersonID != @PersonID
      END
	GO

EXECUTE dbo.TrackCoPassengerList @PersonID=1025;


--drop procedure TrackCoPassengerList;

--Table-Level Check Constraints
CREATE FUNCTION AgeEligibilityCheck(@PID int)
RETURNS INT
BEGIN
   declare @CKC INT;
   declare @Age INT
   Select @AGE = Per.Age
      from Passenger Pass
	  inner join Person Per
		on Per.PersonID = Pass.PersonID
      where Pass.PassengerID = @PID;
	if @Age>=65 OR @Age<10
		Set @CKC = 1;
	else
		Set @CKC = 0;
   return @CKC;
END

ALTER TABLE PassengerOnFlight add CONSTRAINT ckPassengerAge CHECK (dbo.AgeEligibilityCheck (PassengerID) = 0);

/*
update Person set DateOfBirth = '1940-09-02' where PersonID = 1001
Insert into Passenger Values (8001,1001);
insert into [PassengerOnFlight] values
(8001,11,51,501,convert(datetime,'18-06-20 10:24:09 PM',5),'A21','YES')
delete from [PassengerOnFlight] where PassengerID=8001
delete from [Passenger] where PassengerID=8001
update Person set DateOfBirth = '1981-09-02' where PersonID = 1001
*/

--Views

CREATE VIEW VwFlightStatus AS
SELECT [FlightInformation].[FlightID] AS FlightID, 
       [FlightInformation].[Company] AS Company,
	   [FlightInformation].[DepartureTime],
	   [FlightInformation].[ArrivalTime],
	   [FlightStatus].[Status] AS FlightStatus,
	   ArrivalIata.[AirportName] AS Source,
	   DestinationIata.[AirportName] AS Destination
FROM  [FlightInformation] 
JOIN  [FlightStatus]
ON [FlightInformation].[FlightStatusID] = [FlightStatus].[FlightStatusID]
JOIN [Route] R
ON [FlightInformation].[RouteID] = R.[RouteID]
JOIN [Iata] ArrivalIata
ON ArrivalIata.[IATAcode]= R.[SourceIata]
JOIN [Iata] DestinationIata
ON DestinationIata.[IATAcode]= R.[DestinationIata]
GO

