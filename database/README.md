# TravelEase SQL Server setup (Step 3)

These scripts preserve the existing application schema. No C# code is changed.
Execution is **unverified**: no usable local SQL Server instance or SQL command-line tools were found. Service enumeration was unavailable in the restricted environment. No software was installed. Compilation and application execution also remain unverified from Step 2.

## Evidence and scope

All 79 C# files were scanned for SQL, connections, table identifiers and data-reader column names, including dynamically selected seat tables. SQL is issued by 16 source files: `Admin.cs`, `ModularAdmin.cs`, `Passenger.cs`, `Vehicle.cs`; passenger forms `AvailableVehicle`, `BuyTicketAir`, `BuyTicketBus`, `BuyTicketLaunch`, `BuyTicketTrain`, `Payment`, `SearchTicket`; system-admin forms `RemoveUser`, `RequestedCom`, `RestrictVehicle`; and welcome forms `FormLogIn`, `FormRegistration`. Related models and refund UI were also inspected.

The original local `D:\University\C#\data\TravelEaseDB.bacpac` supplies authoritative schema metadata (`model.xml`) for 20 tables, 15 primary keys, 28 foreign keys, two unique constraints and two checks. Its table data, logins and permission grants are not copied into this repository. The project report was not needed because the database metadata provides actual definitions rather than a conceptual model.

The C# code references 16 distinct tables. Fifteen are in the backup; `RefundRuleTB` is missing there and is inferred as described below. The scripts therefore create **21 tables, 16 primary keys and 29 foreign keys**, preserving five additional tables from the original schema even though current C# SQL does not access them. Constraint names are made readable; table names, column names, types, nullability and identity behavior from the backup are preserved. New identities start at 1; historical identity counters are not imported.

## Setup in SQL Server Management Studio (SSMS)

1. Use a Windows computer with a running SQL Server Database Engine (Express or Developer is suitable) and SSMS. SSMS alone is not a database server. These scripts use SQL Server 2012+ syntax; a currently supported SQL Server version is recommended. This task did not install anything.
2. Connect in SSMS using **Database Engine**, server **`.\SQLEXPRESS`**, and **Windows Authentication** to match the current application. If your instance has another name, you can test the scripts there, but the unchanged application will still connect to `.\SQLEXPRESS`.
3. For an initial disposable test, open `schema.sql` with **File > Open > File**. Select **Query > SQLCMD Mode**. Change the `:setvar DatabaseName "TravelEaseDB"` line to `:setvar DatabaseName "TravelEaseDB_Step3_Test"`. Use only a simple database name containing letters, digits and underscores. The variable is a script setting, not user input.
4. Execute the **whole file** with F5. The account needs permission to create a database (if absent) and create tables/constraints in it. Verify the Messages pane has no errors. SQLCMD's `:on error exit` prevents later batches from running if database creation or selection fails.
5. Open `seed.sql`, enable **SQLCMD Mode** for that query window too, and use the **same DatabaseName**. Execute the whole file. The seed requires SELECT/INSERT and permission to use IDENTITY_INSERT on `VehicleTypeTB` (normally run setup as the database owner).
6. Run both scripts a second time. Existing rows should remain intact and seed counts should not increase. On a fresh test database, inspect the results using the queries below. Existing databases may contain additional rows or objects.
7. After reviewing the disposable result, repeat with both variables set to `TravelEaseDB` on `.\SQLEXPRESS` for application testing. If that database already contains useful data, back it up first and compare its structure with this script. This is a bootstrap script, not an automatic migration or schema repair tool.
8. After the .NET/Visual Studio build prerequisites from Step 2 are available, run the application. Register your own fictional test passenger using the UI and a password you choose locally. Search **Bus**, **Demo Origin** to **Demo Terminus**. The seed supplies no usable login accounts. Test company/modular-admin registration separately; the demo bus deliberately has no owner or company assignment.

Run these in a query window whose database dropdown is set to the test database:

```sql
SELECT DB_NAME() AS DatabaseName;
SELECT COUNT(*) AS Tables FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo'); -- 21
SELECT COUNT(*) AS PrimaryKeys FROM sys.key_constraints WHERE type = 'PK'; -- 16
SELECT COUNT(*) AS ForeignKeys FROM sys.foreign_keys; -- 29
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
SELECT vehicleTypeID, vehicleTypeName, totalSeats FROM dbo.VehicleTypeTB;
SELECT vehicleID, vehicleName, destinationID FROM dbo.VehicleTB;
SELECT COUNT(*) AS DemoSeats FROM dbo.BusSeatTB s
JOIN dbo.VehicleTB v ON v.vehicleID = s.vehicleID
WHERE v.BDRegistrationNumber = 'DEMO-BUS-001'; -- 38
SELECT ticketID, buyDate, journeyDate FROM dbo.TicketTB
WHERE userID = 'TE-DEMO-PASSENGER'; -- one historical example on a fresh setup
```

The disposable database is not automatically deleted. Keep or remove it manually after reviewing the test results; never remove your working database as part of rerunning these scripts.

## Rerun behavior and sample data

`schema.sql` creates the database only if absent, using the original case-insensitive `SQL_Latin1_General_CP1_CI_AS` collation. This matters because C# varies capitalization (`fname`/`fName`, `UserID`/`userID`, `username`/`userName`). Existing database collation is not changed. Tables, keys and checks are created only for missing tables; foreign keys are added only to tables created in that execution. Existing objects are skipped, not modified or verified for equivalence. Schema creation is transactional after the database has been created: a failure rolls back table/constraint work but may leave an empty new database. An incompatible existing table can cause a failure requiring manual review.

`seed.sql` uses a transaction, serializable isolation and existence checks; it never updates or deletes existing data. Conflicting reserved identifiers/type mappings cause an error and rollback. Seat status and ownership are not reset on rerun. Run setup while the application is closed. Repeating the seed after deliberately deleting demo rows will recreate missing sample rows; it is not a reset script.

On a fresh database the seed adds four transport types, one fictional passenger profile and passenger-role row, one fictional bus route, one bus with 38 available seats, and one historical ticket. No names or contact information come from the original data. No credentials, passwords, payment details, SQL logins or grants are seeded. `LoginCredentialsTB` stays empty. Types 1/2/3/4 and seat capacities 38/38/12/72 follow `Vehicle.setSeatPrams()`; the display names Bus/Train/Launch/Airplane are descriptive seed choices. The historical ticket avoids the existing empty-table `MAX(ticketID)` failure during initial testing; it does not fix that application bug. No current seat reservation is inferred from that historical ticket.

## Uncertain requirements and preserved limitations

- **RefundRuleTB is inferred, not recovered.** Its five column names are explicit in `ModularAdmin.cs`. All are `int NOT NULL` because the application sends integers. `MAdminNumber` is chosen as the primary key and foreign key to `ModularAdminTB`, based on the code's existence-check/insert/update pattern suggesting one rule per admin. The original key, nullability and any additional columns cannot be confirmed. UI labels indicate hour thresholds, but ordering, permitted ranges and boundary behavior are unknown. No range checks, defaults or fictional refund policies are invented.
- **No extra keys are imposed on the four seat tables or SeatNumbersTB.** The original database has none. `(vehicleID, seatNumber)` is a plausible seat key, but duplicate prevention is a future decision. Likewise role user IDs and company/admin links are not uniquely constrained beyond the recovered keys; the application sometimes assumes single rows where the database permits several.
- **Original defaults are absent.** In particular `CompanyTB.companyStatus` is nullable with no default. Registration passes an unused status parameter but omits the column in its INSERT, so a new company gets NULL and is absent from the pending list (`companyStatus = 0`). No default, trigger or code change is added to silently alter this behavior.
- **Destination type may be NULL.** `Vehicle.GetOrCreateDestinationID` omits `vehicleTypeID` on INSERT, although the search filters on it. Route lookup also ignores transport type. The seed supplies its type explicitly and uses unique fictional endpoint names. No inferred uniqueness or automatic type-filling trigger is added.
- **Seat reservation scope is incomplete.** Buy-ticket forms update by `seatNumber` without `vehicleID`; multiple vehicles can share a label. Seat rows have no journey date, so per-departure inventory cannot be modeled from the current schema. Cancellation deletes a ticket but does not restore seats. These remain application issues for later work.
- **Ticket/identity allocation is fragile.** The payment form casts `MAX(ticketID)` to int without handling an empty table; MAX-plus-one ID generation and `SELECT MAX(vehicleID)` also permit concurrency races. `TicketTB.ticketID`, `CompanyTB.companyID` and `PaymentTB.transactionID` remain non-identity, as in the original. `journeyDate` remains nullable although `Passenger.GetTicketInfo` casts it without a null check.
- **Five original tables are not used by current C# SQL:** `PaymentTB`, `PassengerPaymentTb`, `RefundTB`, `SeatNumbersTB`, `TicketDestinationTB`. Their definitions and relationships are preserved, but the app's ticket-purchase code does not write payment records, ticket-seat links or ticket-destination links. No ticket-to-payment foreign key is evidenced. `CompanyVehicleTB` is read for company vehicle types, but the vehicle insertion code does not populate it. No triggers are invented to populate these relationships.
- **Deletion behavior stays NO ACTION.** Populating `SeatNumbersTB` or `TicketDestinationTB` can prevent the application's direct ticket deletion until dependent rows are handled. No cascading deletes are introduced. `PaymentTB.cardNumber` remains the original `int`, and monetary values remain `float(53)`; their suitability is a future design question, not changed here.
- **Authentication is preserved.** The existing code stores/compares passwords directly, and the system administrator is hardcoded in `Admin.cs` rather than represented by an Admin table. No administrator table or credentials are created, and existing credential literals are not repeated in this documentation.

The original unique constraints are on `LoginCredentialsTB.userName` and `VehicleTypeTB.vehicleTypeName`. The recovered checks require `UserTB.dob < GETDATE()` and an email matching `%@%.%`. There is no evidence for extra uniqueness on NID, phone, registration numbers, routes, or for new date/fare/refund checks. Uncertain rules are deliberately not imposed.

## Connection strings: future configuration work only

There are 15 hardcoded connection-string occurrences in 14 C# files. They all target `Data Source=.\SQLEXPRESS;Initial Catalog=TravelEaseDB;Integrated Security=True` (spacing varies), using the Windows identity running the app, with no SQL password in the connection strings.

Locations: `Admin.cs:14`, `User.cs:21`, `Vehicle.cs:30`, `ModularAdmin.cs:412,489`; `PassengerDashboards/BuyTicketAir.cs:16`, `BuyTicketBus.cs:16`, `BuyTicketLaunch.cs:16`, `BuyTicketTrain.cs:17`, `SearchTicket.cs:17`; `System Admin/RemoveUser.cs:19`, `RequestedCom.cs:19`, `RestrictVehicle.cs:16`; `WelcomeModel/FormLogIn.cs:27`, `FormRegistration.cs:17`. Other database calls reuse inherited/singleton connection values.

In a later step, move the connection string into one named configuration entry (for example `ConnectionStrings:TravelEase` in local application configuration), allow an environment override, and have every connection consumer use it. Keep credentials out of source control; retain Windows authentication for local development where appropriate. Grant the runtime Windows identity only the database permissions it needs, separately from the privileged setup account. No configuration loading or C# refactoring is implemented in Step 3.

## Validation performed

Static review compared table/column definitions, types, nullability, identities, keys, checks, and foreign-key endpoints against the original BACPAC metadata and checked C# SQL table/column references (including dynamic seat-table selections). Seed values and insert order were checked against schema constraints. Rerun guards, rollback handling and preservation of existing objects/data were reviewed. This is not a SQL Server parser or execution test. Run the disposable validation above before relying on the scripts. No build, database execution, UI test, commit or push was performed.

## Tables and relationships

The schema script contains all column definitions. `?` below means nullable; `identity` means SQL Server generates the number. Foreign keys use NO ACTION (no cascading deletes or updates).

| Table | Columns (original SQL types) | Primary key | Foreign keys |
| --- | --- | --- | --- |
| `BusSeatTB` | `vehicleID` int, `seatNumber` varchar(15), `seatStatus` bit ?, `userID` varchar(25) ? | None in original | vehicleID -> VehicleTB(vehicleID); userID -> UserTB(userID) |
| `CompanyTB` | `companyID` int, `compName` varchar(25), `bdRegID` varchar(25), `companyStatus` bit ? | companyID | None |
| `CompanyVehicleTB` | `serial` int identity, `companyID` int, `vehicleID` int | serial | companyID -> CompanyTB(companyID); vehicleID -> VehicleTB(vehicleID) |
| `DestinationTB` | `destinationID` int identity, `desFrom` varchar(15), `desTo` varchar(15), `vehicleTypeID` int ? | destinationID | vehicleTypeID -> VehicleTypeTB(vehicleTypeID) |
| `LaunchSeatTB` | `vehicleID` int, `seatNumber` varchar(15), `seatStatus` bit ?, `userID` varchar(25) ? | None in original | vehicleID -> VehicleTB(vehicleID); userID -> UserTB(userID) |
| `LoginCredentialsTB` | `userID` varchar(25), `userName` varchar(50), `userPassword` varchar(255) | userID | userID -> UserTB(userID) |
| `MAdminCompanyTB` | `serial` int identity, `companyID` int, `MAdminNumber` int | serial | companyID -> CompanyTB(companyID); MAdminNumber -> ModularAdminTB(MAdminNumber) |
| `ModularAdminTB` | `MAdminNumber` int identity, `userID` varchar(25) ? | MAdminNumber | userID -> UserTB(userID) |
| `PassengerPaymentTb` | `serial` int identity, `transactionID` int, `passengerNumber` int | serial | transactionID -> PaymentTB(transactionID); passengerNumber -> PassengerTB(passengerNumber) |
| `PassengerTB` | `passengerNumber` int identity, `userID` varchar(25) ? | passengerNumber | userID -> UserTB(userID) |
| `PaymentTB` | `transactionID` int, `amount` float(53), `cardNumber` int, `cardType` varchar(10), `payDate` date | transactionID | None |
| `PlaneSeatTB` | `vehicleID` int, `seatNumber` varchar(15), `seatStatus` bit ?, `userID` varchar(25) ? | None in original | vehicleID -> VehicleTB(vehicleID); userID -> UserTB(userID) |
| `RefundTB` | `refundID` int identity, `transactionID` int, `refundDate` date | refundID | transactionID -> PaymentTB(transactionID) |
| `SeatNumbersTB` | `ticketID` int, `seats` varchar(20), `vehicleID` int | None in original | vehicleID -> VehicleTB(vehicleID); ticketID -> TicketTB(ticketID) |
| `TicketDestinationTB` | `serial` int identity, `ticketID` int ?, `destinationID` int ? | serial | ticketID -> TicketTB(ticketID); destinationID -> DestinationTB(destinationID) |
| `TicketTB` | `ticketID` int, `buyDate` date, `fare` float(53), `seatAmount` int, `vehicleID` int, `userID` varchar(25), `journeyDate` date ? | ticketID | vehicleID -> VehicleTB(vehicleID); userID -> UserTB(userID) |
| `TrainSeatTB` | `vehicleID` int, `seatNumber` varchar(15), `seatStatus` bit ?, `userID` varchar(25) ? | None in original | vehicleID -> VehicleTB(vehicleID); userID -> UserTB(userID) |
| `UserTB` | `userID` varchar(25), `fName` varchar(50), `lName` varchar(50), `nid` varchar(17), `gender` varchar(7), `dob` date, `phone` varchar(14), `email` varchar(25), `residence` varchar(100), `userStatus` smallint | userID | None |
| `VehicleTB` | `vehicleID` int identity, `vehicleName` varchar(50), `vehicleTypeID` int ?, `BDRegistrationNumber` varchar(50), `MAdminID` int ?, `availableSeats` int ?, `vehicleStatus` int ?, `destinationID` int ? | vehicleID | destinationID -> DestinationTB(destinationID); vehicleTypeID -> VehicleTypeTB(vehicleTypeID); MAdminID -> ModularAdminTB(MAdminNumber) |
| `VehicleTypeTB` | `vehicleTypeID` int identity, `vehicleTypeName` varchar(50), `totalSeats` int ? | vehicleTypeID | None |
| `RefundRuleTB` | `MAdminNumber` int, `refund_80_percent` int, `refund_60_percent` int, `refund_40_percent` int, `no_refund` int | MAdminNumber | MAdminNumber -> ModularAdminTB(MAdminNumber) |
