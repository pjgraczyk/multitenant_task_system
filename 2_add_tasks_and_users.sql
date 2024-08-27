USE MultitenantTaskManagement
GO

-- add task procedure
CREATE PROCEDURE common.AddTask
    @SchemaName NVARCHAR(128),
    @CreatedBy INT,
    @AssignedTo INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @Priority INT,
    @Status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @SQL NVARCHAR(MAX) = N'
    DECLARE @Now DATETIME2 = CURRENT_TIMESTAMP
    DECLARE @TaskId INT

    -- insert new task
    INSERT INTO ' + QUOTENAME(@SchemaName) + '.Tasks
        (CreatedBy, AssignedTo, Title, Description, Priority, Status, CreatedAt, UpdatedAt)
    VALUES
        (@CreatedBy, @AssignedTo, @Title, @Description, @Priority, @Status, @Now, @Now)

    SET @TaskId = SCOPE_IDENTITY()

    -- log task creation
    INSERT INTO ' + QUOTENAME(@SchemaName) + '.TaskHistory
        (TaskId, ChangedBy, ChangeType, NewValue, ChangedAt)
    VALUES
        (@TaskId, @CreatedBy, ''Created'', @Title, @Now)'

    EXEC sp_executesql @SQL,
        N'@CreatedBy INT, @AssignedTo INT, @Title NVARCHAR(200), @Description NVARCHAR(MAX), @Priority INT, @Status NVARCHAR(20)',
        @CreatedBy, @AssignedTo, @Title, @Description, @Priority, @Status
END
GO

-- add new user procedure
CREATE PROCEDURE common.AddNewUser
    @TenantName NVARCHAR(100),
    @Username NVARCHAR(50),
    @IsManager BIT,
    @ManagerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @SchemaName NVARCHAR(128)
    DECLARE @SQL NVARCHAR(MAX)

    -- get tenant's schema name
    SELECT @SchemaName = SchemaName
    FROM common.Tenants
    WHERE TenantName = @TenantName

    IF @SchemaName IS NULL
    BEGIN
        THROW 50000, 'tenant not found', 1
        RETURN
    END

    SET @SQL = N'
    -- check for duplicate username
    IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@SchemaName) + '.Users WHERE Username = @Username)
    BEGIN
        THROW 50001, ''username already exists'', 1
        RETURN
    END

    -- validate manager
    IF @ManagerId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@SchemaName) + '.Users WHERE UserId = @ManagerId AND IsManager = 1)
    BEGIN
        THROW 50002, ''invalid manager id'', 1
        RETURN
    END

    -- add new user
    INSERT INTO ' + QUOTENAME(@SchemaName) + '.Users (Username, IsManager, ManagerId)
    VALUES (@Username, @IsManager, @ManagerId)'

    EXEC sp_executesql @SQL,
        N'@Username NVARCHAR(50), @IsManager BIT, @ManagerId INT',
        @Username, @IsManager, @ManagerId
END
GO