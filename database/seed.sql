-- Fictional development data only. No login credentials or payment details.
-- Run the entire script after schema.sql in SSMS SQLCMD Mode.
:on error exit
:setvar DatabaseName "TravelEaseDB"

USE [$(DatabaseName)];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

DECLARE @IdentityInsertOn bit = 0;
BEGIN TRY
    BEGIN TRANSACTION;

    -- IDs are fixed by Vehicle.setSeatPrams(), not arbitrary sample values.
    DECLARE @Types TABLE (id int, name varchar(50), seats int);
    INSERT INTO @Types VALUES
        (1, 'Bus', 38), (2, 'Train', 38), (3, 'Launch', 12), (4, 'Airplane', 72);
    IF EXISTS (
        SELECT 1 FROM dbo.VehicleTypeTB v JOIN @Types t
            ON v.vehicleTypeID = t.id OR v.vehicleTypeName = t.name
        WHERE v.vehicleTypeID <> t.id OR v.vehicleTypeName <> t.name
            OR v.totalSeats IS NULL OR v.totalSeats <> t.seats
    )
        THROW 51000, 'Vehicle type data conflicts with the seed. Review existing mappings; nothing will be overwritten.', 1;

    SET IDENTITY_INSERT dbo.VehicleTypeTB ON;
    SET @IdentityInsertOn = 1;
    INSERT INTO dbo.VehicleTypeTB (vehicleTypeID, vehicleTypeName, totalSeats)
        SELECT t.id, t.name, t.seats FROM @Types t
        WHERE NOT EXISTS (SELECT 1 FROM dbo.VehicleTypeTB v WHERE v.vehicleTypeID = t.id);
    SET IDENTITY_INSERT dbo.VehicleTypeTB OFF;
    SET @IdentityInsertOn = 0;

    -- Deliberately not a login account: LoginCredentialsTB remains untouched.
    IF EXISTS (SELECT 1 FROM dbo.UserTB WHERE userID = 'TE-DEMO-PASSENGER'
        AND (fName <> 'Sample' OR lName <> 'Passenger' OR email <> 'demo@example.invalid'))
        THROW 51001, 'The reserved demo user ID is already in use. Seed aborted.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.UserTB WHERE userID = 'TE-DEMO-PASSENGER')
        INSERT INTO dbo.UserTB
            (userID, fName, lName, nid, gender, dob, phone, email, residence, userStatus)
        VALUES ('TE-DEMO-PASSENGER', 'Sample', 'Passenger', 'DEMO-NID-0001', 'Other',
            '19900101', '00000000000', 'demo@example.invalid', 'Fictional Test Town', 1);
    IF NOT EXISTS (SELECT 1 FROM dbo.PassengerTB WHERE userID = 'TE-DEMO-PASSENGER')
        INSERT INTO dbo.PassengerTB (userID) VALUES ('TE-DEMO-PASSENGER');

    IF NOT EXISTS (SELECT 1 FROM dbo.DestinationTB
        WHERE desFrom = 'Demo Origin' AND desTo = 'Demo Terminus' AND vehicleTypeID = 1)
        INSERT INTO dbo.DestinationTB (desFrom, desTo, vehicleTypeID)
            VALUES ('Demo Origin', 'Demo Terminus', 1);
    IF (SELECT COUNT(*) FROM dbo.DestinationTB
        WHERE desFrom = 'Demo Origin' AND desTo = 'Demo Terminus') <> 1
        THROW 51002, 'The demo route is ambiguous. Seed aborted.', 1;
    DECLARE @DestinationID int = (SELECT destinationID FROM dbo.DestinationTB
        WHERE desFrom = 'Demo Origin' AND desTo = 'Demo Terminus' AND vehicleTypeID = 1);

    IF EXISTS (SELECT 1 FROM dbo.VehicleTB WHERE BDRegistrationNumber = 'DEMO-BUS-001'
        AND (vehicleName <> 'Demo Bus' OR vehicleTypeID IS NULL OR vehicleTypeID <> 1
            OR destinationID IS NULL OR destinationID <> @DestinationID))
        THROW 51003, 'The demo vehicle registration is already in use. Seed aborted.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.VehicleTB WHERE BDRegistrationNumber = 'DEMO-BUS-001')
        INSERT INTO dbo.VehicleTB
            (vehicleName, vehicleTypeID, BDRegistrationNumber, MAdminID,
             availableSeats, vehicleStatus, destinationID)
        VALUES ('Demo Bus', 1, 'DEMO-BUS-001', NULL, 38, 1, @DestinationID);
    IF (SELECT COUNT(*) FROM dbo.VehicleTB WHERE BDRegistrationNumber = 'DEMO-BUS-001') <> 1
        THROW 51004, 'Duplicate demo vehicle registrations found. Seed aborted.', 1;
    DECLARE @VehicleID int = (SELECT vehicleID FROM dbo.VehicleTB
        WHERE BDRegistrationNumber = 'DEMO-BUS-001');

    DECLARE @Seat int = 1;
    WHILE @Seat <= 38
    BEGIN
        DECLARE @SeatNumber varchar(15) = 'BS-' + RIGHT('00' + CAST(@Seat AS varchar(2)), 2);
        IF NOT EXISTS (SELECT 1 FROM dbo.BusSeatTB
            WHERE vehicleID = @VehicleID AND seatNumber = @SeatNumber)
            INSERT INTO dbo.BusSeatTB (vehicleID, seatNumber, seatStatus, userID)
                VALUES (@VehicleID, @SeatNumber, 1, NULL);
        -- Existing seat assignments and status are preserved on rerun.
        SET @Seat += 1;
    END;

    -- Historical example, not a current reservation. The application currently
    -- casts MAX(ticketID) directly to int and cannot purchase the first ticket
    -- when TicketTB is empty. This sample permits testing; it is not a code fix.
    IF NOT EXISTS (SELECT 1 FROM dbo.TicketTB
        WHERE userID = 'TE-DEMO-PASSENGER' AND vehicleID = @VehicleID AND buyDate = '20200101')
    BEGIN
        DECLARE @TicketID int = (SELECT ISNULL(MAX(ticketID), 0) + 1 FROM dbo.TicketTB);
        INSERT INTO dbo.TicketTB (ticketID, buyDate, fare, seatAmount, vehicleID, userID, journeyDate)
            VALUES (@TicketID, '20200101', 100, 1, @VehicleID, 'TE-DEMO-PASSENGER', '20200102');
    END;

    COMMIT TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF @IdentityInsertOn = 1 SET IDENTITY_INSERT dbo.VehicleTypeTB OFF;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH;
GO
