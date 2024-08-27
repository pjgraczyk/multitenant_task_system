-- -- create new database
-- CREATE DATABASE MultitenantTaskManagement
-- GO

-- use the new database
USE MultitenantTaskManagement
GO

-- create common area for shared info
CREATE SCHEMA common
GO

-- table to track customers (tenants)
CREATE TABLE common.Tenants (
    TenantId INT IDENTITY(1,1) PRIMARY KEY,
    TenantName NVARCHAR(100) NOT NULL,
    SchemaName NVARCHAR(128) NOT NULL
)
GO

-- helper function to set up new customer area
CREATE PROCEDURE common.CreateTenantSchema
    @TenantName NVARCHAR(100),
    @SchemaName NVARCHAR(128)
AS
BEGIN
    -- add new customer to list
    INSERT INTO common.Tenants (TenantName, SchemaName)
    VALUES (@TenantName, @SchemaName)

    -- create separate area for customer data
    DECLARE @SQL NVARCHAR(MAX) = N'CREATE SCHEMA ' + QUOTENAME(@SchemaName)
    EXEC sp_executesql @SQL

    -- create tables for customer
    SET @SQL = N'
    -- users table
    CREATE TABLE ' + QUOTENAME(@SchemaName) + '.Users (
        UserId INT IDENTITY(1,1) PRIMARY KEY,
        Username NVARCHAR(50) NOT NULL,
        IsManager BIT NOT NULL,
        ManagerId INT NULL
    )

    -- tasks table
    CREATE TABLE ' + QUOTENAME(@SchemaName) + '.Tasks (
        TaskId INT IDENTITY(1,1) PRIMARY KEY,
        CreatedBy INT NOT NULL,
        AssignedTo INT NOT NULL,
        Title NVARCHAR(200) NOT NULL,
        Description NVARCHAR(MAX),
        Priority INT NOT NULL,
        Status NVARCHAR(20) NOT NULL,
        CreatedAt DATETIME2 NOT NULL,
        UpdatedAt DATETIME2 NOT NULL
    )

    -- task history table
    CREATE TABLE ' + QUOTENAME(@SchemaName) + '.TaskHistory (
        HistoryId INT IDENTITY(1,1) PRIMARY KEY,
        TaskId INT NOT NULL,
        ChangedBy INT NOT NULL,
        ChangeType NVARCHAR(20) NOT NULL,
        OldValue NVARCHAR(MAX),
        NewValue NVARCHAR(MAX),
        ChangedAt DATETIME2 NOT NULL
    )

    -- task sharing table
    CREATE TABLE ' + QUOTENAME(@SchemaName) + '.TaskSharing (
        SharingId INT IDENTITY(1,1) PRIMARY KEY,
        TaskId INT NOT NULL,
        SharedWith INT NOT NULL,
        SharedBy INT NOT NULL,
        SharedAt DATETIME2 NOT NULL
    )'
    EXEC sp_executesql @SQL
END
GO