-- schema.sql
-- Run this in SSMS against your PoliceAssetTracker database.
-- Creates core tables, the django_app login/user, and a starter row-level
-- security policy so officers only see their own precinct's assets.

USE PoliceAssetTracker;
GO

------------------------------------------------------------
-- 1. App login (skip if you already created this earlier)
------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'django_app')
BEGIN
    CREATE LOGIN django_app WITH PASSWORD = 'CHANGE_ME_STRONG_PASSWORD!';
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'django_app')
BEGIN
    CREATE USER django_app FOR LOGIN django_app;
    ALTER ROLE db_datareader ADD MEMBER django_app;
    ALTER ROLE db_datawriter ADD MEMBER django_app;
END
GO

------------------------------------------------------------
-- 2. Core tables
------------------------------------------------------------
CREATE TABLE Precincts (
    PrecinctId      INT IDENTITY PRIMARY KEY,
    Name            NVARCHAR(100) NOT NULL,
    Code            NVARCHAR(10)  NOT NULL UNIQUE
);
GO

CREATE TABLE Officers (
    OfficerId       INT IDENTITY PRIMARY KEY,
    BadgeNumber     NVARCHAR(20)  NOT NULL UNIQUE,
    FirstName       NVARCHAR(50)  NOT NULL,
    LastName        NVARCHAR(50)  NOT NULL,
    PrecinctId      INT NOT NULL REFERENCES Precincts(PrecinctId),
    -- Maps this officer row to a SQL Server login/DB user for RLS
    DbUserName      NVARCHAR(128) NOT NULL,
    IsActive        BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE Assets (
    AssetId         INT IDENTITY PRIMARY KEY,
    AssetTag        NVARCHAR(30)  NOT NULL UNIQUE,
    Description     NVARCHAR(200) NOT NULL,
    Category        NVARCHAR(50)  NOT NULL,   -- e.g. Radio, Vehicle, Firearm, Laptop
    PrecinctId      INT NOT NULL REFERENCES Precincts(PrecinctId),
    Status          NVARCHAR(20)  NOT NULL DEFAULT 'Available', -- Available/Checked Out/Maintenance/Retired
    PurchaseDate    DATE NULL,
    LastMaintained  DATE NULL
);
GO

CREATE TABLE Checkouts (
    CheckoutId      INT IDENTITY PRIMARY KEY,
    AssetId         INT NOT NULL REFERENCES Assets(AssetId),
    OfficerId       INT NOT NULL REFERENCES Officers(OfficerId),
    CheckedOutAt    DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ReturnedAt      DATETIME2 NULL,
    Notes           NVARCHAR(500) NULL
);
GO

CREATE TABLE MaintenanceLogs (
    MaintenanceId   INT IDENTITY PRIMARY KEY,
    AssetId         INT NOT NULL REFERENCES Assets(AssetId),
    PerformedAt     DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    PerformedBy     NVARCHAR(100) NOT NULL,
    Description     NVARCHAR(500) NOT NULL,
    NextDueDate     DATE NULL
);
GO

------------------------------------------------------------
-- 3. Row-Level Security: officers only see their own precinct's assets
------------------------------------------------------------
CREATE SCHEMA Security;
GO

CREATE FUNCTION Security.fn_PrecinctAccessPredicate(@PrecinctId INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS AccessResult
WHERE @PrecinctId = (
    SELECT o.PrecinctId
    FROM dbo.Officers o
    WHERE o.DbUserName = USER_NAME()
)
OR IS_MEMBER('db_owner') = 1;  -- admins/DBA bypass the filter
GO

CREATE SECURITY POLICY Security.PrecinctFilter
ADD FILTER PREDICATE Security.fn_PrecinctAccessPredicate(PrecinctId) ON dbo.Assets,
ADD BLOCK PREDICATE Security.fn_PrecinctAccessPredicate(PrecinctId) ON dbo.Assets AFTER INSERT
WITH (STATE = ON);
GO

------------------------------------------------------------
-- 4. Sample seed data (optional — comment out if not needed)
------------------------------------------------------------
INSERT INTO Precincts (Name, Code) VALUES
    ('Downtown Precinct', 'DT01'),
    ('North Precinct', 'NP02');
GO
