-- Run the entire script in SSMS SQLCMD Mode. See README.md.
-- Original BACPAC schema only; no original data, logins, grants or file paths.
-- RefundRuleTB is inferred from C#; see the documented assumptions.
:on error exit
:setvar DatabaseName "TravelEaseDB"

USE [master];
GO
IF DB_ID(N'$(DatabaseName)') IS NULL
    EXEC(N'CREATE DATABASE [$(DatabaseName)] COLLATE SQL_Latin1_General_CP1_CI_AS;');
GO
USE [$(DatabaseName)];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Created TABLE (TableName sysname PRIMARY KEY);

    IF OBJECT_ID(N'dbo.BusSeatTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[BusSeatTB] (
        [vehicleID] [int] NOT NULL,
        [seatNumber] [varchar](15) NOT NULL,
        [seatStatus] [bit] NULL,
        [userID] [varchar](25) NULL
        );
        INSERT INTO @Created VALUES (N'BusSeatTB');
    END;

    IF OBJECT_ID(N'dbo.CompanyTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[CompanyTB] (
        [companyID] [int] NOT NULL,
        [compName] [varchar](25) NOT NULL,
        [bdRegID] [varchar](25) NOT NULL,
        [companyStatus] [bit] NULL,
        CONSTRAINT [PK_CompanyTB] PRIMARY KEY ([companyID])
        );
        INSERT INTO @Created VALUES (N'CompanyTB');
    END;

    IF OBJECT_ID(N'dbo.CompanyVehicleTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[CompanyVehicleTB] (
        [serial] [int] IDENTITY(1,1) NOT NULL,
        [companyID] [int] NOT NULL,
        [vehicleID] [int] NOT NULL,
        CONSTRAINT [PK_CompanyVehicleTB] PRIMARY KEY ([serial])
        );
        INSERT INTO @Created VALUES (N'CompanyVehicleTB');
    END;

    IF OBJECT_ID(N'dbo.DestinationTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[DestinationTB] (
        [destinationID] [int] IDENTITY(1,1) NOT NULL,
        [desFrom] [varchar](15) NOT NULL,
        [desTo] [varchar](15) NOT NULL,
        [vehicleTypeID] [int] NULL,
        CONSTRAINT [PK_DestinationTB] PRIMARY KEY ([destinationID])
        );
        INSERT INTO @Created VALUES (N'DestinationTB');
    END;

    IF OBJECT_ID(N'dbo.LaunchSeatTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[LaunchSeatTB] (
        [vehicleID] [int] NOT NULL,
        [seatNumber] [varchar](15) NOT NULL,
        [seatStatus] [bit] NULL,
        [userID] [varchar](25) NULL
        );
        INSERT INTO @Created VALUES (N'LaunchSeatTB');
    END;

    IF OBJECT_ID(N'dbo.LoginCredentialsTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[LoginCredentialsTB] (
        [userID] [varchar](25) NOT NULL,
        [userName] [varchar](50) NOT NULL,
        [userPassword] [varchar](255) NOT NULL,
        CONSTRAINT [PK_LoginCredentialsTB] PRIMARY KEY ([userID]),
        CONSTRAINT [UQ_LoginCredentialsTB_userName] UNIQUE ([userName])
        );
        INSERT INTO @Created VALUES (N'LoginCredentialsTB');
    END;

    IF OBJECT_ID(N'dbo.MAdminCompanyTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[MAdminCompanyTB] (
        [serial] [int] IDENTITY(1,1) NOT NULL,
        [companyID] [int] NOT NULL,
        [MAdminNumber] [int] NOT NULL,
        CONSTRAINT [PK_MAdminCompanyTB] PRIMARY KEY ([serial])
        );
        INSERT INTO @Created VALUES (N'MAdminCompanyTB');
    END;

    IF OBJECT_ID(N'dbo.ModularAdminTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[ModularAdminTB] (
        [MAdminNumber] [int] IDENTITY(1,1) NOT NULL,
        [userID] [varchar](25) NULL,
        CONSTRAINT [PK_ModularAdminTB] PRIMARY KEY ([MAdminNumber])
        );
        INSERT INTO @Created VALUES (N'ModularAdminTB');
    END;

    IF OBJECT_ID(N'dbo.PassengerPaymentTb', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[PassengerPaymentTb] (
        [serial] [int] IDENTITY(1,1) NOT NULL,
        [transactionID] [int] NOT NULL,
        [passengerNumber] [int] NOT NULL,
        CONSTRAINT [PK_PassengerPaymentTb] PRIMARY KEY ([serial])
        );
        INSERT INTO @Created VALUES (N'PassengerPaymentTb');
    END;

    IF OBJECT_ID(N'dbo.PassengerTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[PassengerTB] (
        [passengerNumber] [int] IDENTITY(1,1) NOT NULL,
        [userID] [varchar](25) NULL,
        CONSTRAINT [PK_PassengerTB] PRIMARY KEY ([passengerNumber])
        );
        INSERT INTO @Created VALUES (N'PassengerTB');
    END;

    IF OBJECT_ID(N'dbo.PaymentTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[PaymentTB] (
        [transactionID] [int] NOT NULL,
        [amount] [float](53) NOT NULL,
        [cardNumber] [int] NOT NULL,
        [cardType] [varchar](10) NOT NULL,
        [payDate] [date] NOT NULL,
        CONSTRAINT [PK_PaymentTB] PRIMARY KEY ([transactionID])
        );
        INSERT INTO @Created VALUES (N'PaymentTB');
    END;

    IF OBJECT_ID(N'dbo.PlaneSeatTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[PlaneSeatTB] (
        [vehicleID] [int] NOT NULL,
        [seatNumber] [varchar](15) NOT NULL,
        [seatStatus] [bit] NULL,
        [userID] [varchar](25) NULL
        );
        INSERT INTO @Created VALUES (N'PlaneSeatTB');
    END;

    IF OBJECT_ID(N'dbo.RefundTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[RefundTB] (
        [refundID] [int] IDENTITY(1,1) NOT NULL,
        [transactionID] [int] NOT NULL,
        [refundDate] [date] NOT NULL,
        CONSTRAINT [PK_RefundTB] PRIMARY KEY ([refundID])
        );
        INSERT INTO @Created VALUES (N'RefundTB');
    END;

    IF OBJECT_ID(N'dbo.SeatNumbersTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[SeatNumbersTB] (
        [ticketID] [int] NOT NULL,
        [seats] [varchar](20) NOT NULL,
        [vehicleID] [int] NOT NULL
        );
        INSERT INTO @Created VALUES (N'SeatNumbersTB');
    END;

    IF OBJECT_ID(N'dbo.TicketDestinationTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[TicketDestinationTB] (
        [serial] [int] IDENTITY(1,1) NOT NULL,
        [ticketID] [int] NULL,
        [destinationID] [int] NULL,
        CONSTRAINT [PK_TicketDestinationTB] PRIMARY KEY ([serial])
        );
        INSERT INTO @Created VALUES (N'TicketDestinationTB');
    END;

    IF OBJECT_ID(N'dbo.TicketTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[TicketTB] (
        [ticketID] [int] NOT NULL,
        [buyDate] [date] NOT NULL,
        [fare] [float](53) NOT NULL,
        [seatAmount] [int] NOT NULL,
        [vehicleID] [int] NOT NULL,
        [userID] [varchar](25) NOT NULL,
        [journeyDate] [date] NULL,
        CONSTRAINT [PK_TicketTB] PRIMARY KEY ([ticketID])
        );
        INSERT INTO @Created VALUES (N'TicketTB');
    END;

    IF OBJECT_ID(N'dbo.TrainSeatTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[TrainSeatTB] (
        [vehicleID] [int] NOT NULL,
        [seatNumber] [varchar](15) NOT NULL,
        [seatStatus] [bit] NULL,
        [userID] [varchar](25) NULL
        );
        INSERT INTO @Created VALUES (N'TrainSeatTB');
    END;

    IF OBJECT_ID(N'dbo.UserTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[UserTB] (
        [userID] [varchar](25) NOT NULL,
        [fName] [varchar](50) NOT NULL,
        [lName] [varchar](50) NOT NULL,
        [nid] [varchar](17) NOT NULL,
        [gender] [varchar](7) NOT NULL,
        [dob] [date] NOT NULL,
        [phone] [varchar](14) NOT NULL,
        [email] [varchar](25) NOT NULL,
        [residence] [varchar](100) NOT NULL,
        [userStatus] [smallint] NOT NULL,
        CONSTRAINT [PK_UserTB] PRIMARY KEY ([userID]),
        CONSTRAINT [CK_UserTB_1] CHECK ([dob]<getdate()),
        CONSTRAINT [CK_UserTB_2] CHECK ([email] like '%@%.%')
        );
        INSERT INTO @Created VALUES (N'UserTB');
    END;

    IF OBJECT_ID(N'dbo.VehicleTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[VehicleTB] (
        [vehicleID] [int] IDENTITY(1,1) NOT NULL,
        [vehicleName] [varchar](50) NOT NULL,
        [vehicleTypeID] [int] NULL,
        [BDRegistrationNumber] [varchar](50) NOT NULL,
        [MAdminID] [int] NULL,
        [availableSeats] [int] NULL,
        [vehicleStatus] [int] NULL,
        [destinationID] [int] NULL,
        CONSTRAINT [PK_VehicleTB] PRIMARY KEY ([vehicleID])
        );
        INSERT INTO @Created VALUES (N'VehicleTB');
    END;

    IF OBJECT_ID(N'dbo.VehicleTypeTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[VehicleTypeTB] (
        [vehicleTypeID] [int] IDENTITY(1,1) NOT NULL,
        [vehicleTypeName] [varchar](50) NOT NULL,
        [totalSeats] [int] NULL,
        CONSTRAINT [PK_VehicleTypeTB] PRIMARY KEY ([vehicleTypeID]),
        CONSTRAINT [UQ_VehicleTypeTB_vehicleTypeName] UNIQUE ([vehicleTypeName])
        );
        INSERT INTO @Created VALUES (N'VehicleTypeTB');
    END;

    IF OBJECT_ID(N'dbo.RefundRuleTB', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[RefundRuleTB] (
        [MAdminNumber] [int] NOT NULL,
        [refund_80_percent] [int] NOT NULL,
        [refund_60_percent] [int] NOT NULL,
        [refund_40_percent] [int] NOT NULL,
        [no_refund] [int] NOT NULL,
        CONSTRAINT [PK_RefundRuleTB] PRIMARY KEY ([MAdminNumber])
        );
        INSERT INTO @Created VALUES (N'RefundRuleTB');
    END;

    -- Add original relationships only to tables created by this execution.
    -- Existing tables and constraints are never rewritten.

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'RefundTB')
        ALTER TABLE [dbo].[RefundTB] WITH CHECK ADD CONSTRAINT [FK_RefundTB_transactionID]
            FOREIGN KEY ([transactionID]) REFERENCES [dbo].[PaymentTB] ([transactionID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'SeatNumbersTB')
        ALTER TABLE [dbo].[SeatNumbersTB] WITH CHECK ADD CONSTRAINT [FK_SeatNumbersTB_vehicleID]
            FOREIGN KEY ([vehicleID]) REFERENCES [dbo].[VehicleTB] ([vehicleID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'SeatNumbersTB')
        ALTER TABLE [dbo].[SeatNumbersTB] WITH CHECK ADD CONSTRAINT [FK_SeatNumbersTB_ticketID]
            FOREIGN KEY ([ticketID]) REFERENCES [dbo].[TicketTB] ([ticketID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'BusSeatTB')
        ALTER TABLE [dbo].[BusSeatTB] WITH CHECK ADD CONSTRAINT [FK_BusSeatTB_vehicleID]
            FOREIGN KEY ([vehicleID]) REFERENCES [dbo].[VehicleTB] ([vehicleID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'BusSeatTB')
        ALTER TABLE [dbo].[BusSeatTB] WITH CHECK ADD CONSTRAINT [FK_BusSeatTB_userID]
            FOREIGN KEY ([userID]) REFERENCES [dbo].[UserTB] ([userID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'TrainSeatTB')
        ALTER TABLE [dbo].[TrainSeatTB] WITH CHECK ADD CONSTRAINT [FK_TrainSeatTB_vehicleID]
            FOREIGN KEY ([vehicleID]) REFERENCES [dbo].[VehicleTB] ([vehicleID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'TrainSeatTB')
        ALTER TABLE [dbo].[TrainSeatTB] WITH CHECK ADD CONSTRAINT [FK_TrainSeatTB_userID]
            FOREIGN KEY ([userID]) REFERENCES [dbo].[UserTB] ([userID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'LaunchSeatTB')
        ALTER TABLE [dbo].[LaunchSeatTB] WITH CHECK ADD CONSTRAINT [FK_LaunchSeatTB_vehicleID]
            FOREIGN KEY ([vehicleID]) REFERENCES [dbo].[VehicleTB] ([vehicleID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'LaunchSeatTB')
        ALTER TABLE [dbo].[LaunchSeatTB] WITH CHECK ADD CONSTRAINT [FK_LaunchSeatTB_userID]
            FOREIGN KEY ([userID]) REFERENCES [dbo].[UserTB] ([userID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'PlaneSeatTB')
        ALTER TABLE [dbo].[PlaneSeatTB] WITH CHECK ADD CONSTRAINT [FK_PlaneSeatTB_vehicleID]
            FOREIGN KEY ([vehicleID]) REFERENCES [dbo].[VehicleTB] ([vehicleID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'PlaneSeatTB')
        ALTER TABLE [dbo].[PlaneSeatTB] WITH CHECK ADD CONSTRAINT [FK_PlaneSeatTB_userID]
            FOREIGN KEY ([userID]) REFERENCES [dbo].[UserTB] ([userID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'CompanyVehicleTB')
        ALTER TABLE [dbo].[CompanyVehicleTB] WITH CHECK ADD CONSTRAINT [FK_CompanyVehicleTB_companyID]
            FOREIGN KEY ([companyID]) REFERENCES [dbo].[CompanyTB] ([companyID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'CompanyVehicleTB')
        ALTER TABLE [dbo].[CompanyVehicleTB] WITH CHECK ADD CONSTRAINT [FK_CompanyVehicleTB_vehicleID]
            FOREIGN KEY ([vehicleID]) REFERENCES [dbo].[VehicleTB] ([vehicleID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'PassengerTB')
        ALTER TABLE [dbo].[PassengerTB] WITH CHECK ADD CONSTRAINT [FK_PassengerTB_userID]
            FOREIGN KEY ([userID]) REFERENCES [dbo].[UserTB] ([userID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'ModularAdminTB')
        ALTER TABLE [dbo].[ModularAdminTB] WITH CHECK ADD CONSTRAINT [FK_ModularAdminTB_userID]
            FOREIGN KEY ([userID]) REFERENCES [dbo].[UserTB] ([userID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'LoginCredentialsTB')
        ALTER TABLE [dbo].[LoginCredentialsTB] WITH CHECK ADD CONSTRAINT [FK_LoginCredentialsTB_userID]
            FOREIGN KEY ([userID]) REFERENCES [dbo].[UserTB] ([userID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'VehicleTB')
        ALTER TABLE [dbo].[VehicleTB] WITH CHECK ADD CONSTRAINT [FK_VehicleTB_destinationID]
            FOREIGN KEY ([destinationID]) REFERENCES [dbo].[DestinationTB] ([destinationID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'VehicleTB')
        ALTER TABLE [dbo].[VehicleTB] WITH CHECK ADD CONSTRAINT [FK_VehicleTB_vehicleTypeID]
            FOREIGN KEY ([vehicleTypeID]) REFERENCES [dbo].[VehicleTypeTB] ([vehicleTypeID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'VehicleTB')
        ALTER TABLE [dbo].[VehicleTB] WITH CHECK ADD CONSTRAINT [FK_VehicleTB_MAdminID]
            FOREIGN KEY ([MAdminID]) REFERENCES [dbo].[ModularAdminTB] ([MAdminNumber]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'TicketTB')
        ALTER TABLE [dbo].[TicketTB] WITH CHECK ADD CONSTRAINT [FK_TicketTB_vehicleID]
            FOREIGN KEY ([vehicleID]) REFERENCES [dbo].[VehicleTB] ([vehicleID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'TicketTB')
        ALTER TABLE [dbo].[TicketTB] WITH CHECK ADD CONSTRAINT [FK_TicketTB_userID]
            FOREIGN KEY ([userID]) REFERENCES [dbo].[UserTB] ([userID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'DestinationTB')
        ALTER TABLE [dbo].[DestinationTB] WITH CHECK ADD CONSTRAINT [FK_DestinationTB_vehicleTypeID]
            FOREIGN KEY ([vehicleTypeID]) REFERENCES [dbo].[VehicleTypeTB] ([vehicleTypeID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'TicketDestinationTB')
        ALTER TABLE [dbo].[TicketDestinationTB] WITH CHECK ADD CONSTRAINT [FK_TicketDestinationTB_ticketID]
            FOREIGN KEY ([ticketID]) REFERENCES [dbo].[TicketTB] ([ticketID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'TicketDestinationTB')
        ALTER TABLE [dbo].[TicketDestinationTB] WITH CHECK ADD CONSTRAINT [FK_TicketDestinationTB_destinationID]
            FOREIGN KEY ([destinationID]) REFERENCES [dbo].[DestinationTB] ([destinationID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'MAdminCompanyTB')
        ALTER TABLE [dbo].[MAdminCompanyTB] WITH CHECK ADD CONSTRAINT [FK_MAdminCompanyTB_companyID]
            FOREIGN KEY ([companyID]) REFERENCES [dbo].[CompanyTB] ([companyID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'MAdminCompanyTB')
        ALTER TABLE [dbo].[MAdminCompanyTB] WITH CHECK ADD CONSTRAINT [FK_MAdminCompanyTB_MAdminNumber]
            FOREIGN KEY ([MAdminNumber]) REFERENCES [dbo].[ModularAdminTB] ([MAdminNumber]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'PassengerPaymentTb')
        ALTER TABLE [dbo].[PassengerPaymentTb] WITH CHECK ADD CONSTRAINT [FK_PassengerPaymentTb_transactionID]
            FOREIGN KEY ([transactionID]) REFERENCES [dbo].[PaymentTB] ([transactionID]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'PassengerPaymentTb')
        ALTER TABLE [dbo].[PassengerPaymentTb] WITH CHECK ADD CONSTRAINT [FK_PassengerPaymentTb_passengerNumber]
            FOREIGN KEY ([passengerNumber]) REFERENCES [dbo].[PassengerTB] ([passengerNumber]);

    IF EXISTS (SELECT 1 FROM @Created WHERE TableName = N'RefundRuleTB')
        ALTER TABLE [dbo].[RefundRuleTB] WITH CHECK ADD CONSTRAINT [FK_RefundRuleTB_MAdminNumber]
            FOREIGN KEY ([MAdminNumber]) REFERENCES [dbo].[ModularAdminTB] ([MAdminNumber]);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
