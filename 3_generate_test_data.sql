USE MultitenantTaskManagement
GO

-- create test data procedure
CREATE PROCEDURE common.GenerateTestData
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @TenantId INT = 1
    WHILE @TenantId <= 10
    BEGIN
        DECLARE @TenantName NVARCHAR(100) = 'Tenant_' + CAST(@TenantId AS NVARCHAR(10))
        DECLARE @SchemaName NVARCHAR(128) = 'tenant_' + CAST(@TenantId AS NVARCHAR(10))

        -- check if tenant exists
        IF NOT EXISTS (SELECT 1 FROM common.Tenants WHERE TenantName = @TenantName)
        BEGIN
            -- create new tenant
            EXEC common.CreateTenantSchema @TenantName, @SchemaName

            DECLARE @UserId INT = 1
            DECLARE @ManagerId INT
            WHILE @UserId <= 100
            BEGIN
                -- set manager status and id
                DECLARE @IsManager BIT = CASE WHEN @UserId % 10 = 1 THEN 1 ELSE 0 END
                SET @ManagerId = CASE WHEN @IsManager = 0 THEN (@UserId - 1) / 10 * 10 + 1 ELSE NULL END

                -- create username
                DECLARE @Username NVARCHAR(50) = 'User_' + CAST(@TenantId AS NVARCHAR(10)) + '_' + CAST(@UserId AS NVARCHAR(10))

                -- add new user
                EXEC common.AddNewUser @TenantName, @Username, @IsManager, @ManagerId

                -- create tasks for user
                DECLARE @TaskId INT = 1
                WHILE @TaskId <= 1000
                BEGIN
                    DECLARE @Title NVARCHAR(200) = 'Task ' + CAST((@UserId - 1) * 1000 + @TaskId AS NVARCHAR(10))
                    DECLARE @Description NVARCHAR(MAX) = 'Description for task ' + CAST((@UserId - 1) * 1000 + @TaskId AS NVARCHAR(10))
                    DECLARE @Priority INT = @TaskId % 3 + 1
                    DECLARE @Status NVARCHAR(20) = CASE @TaskId % 4
                    WHEN 0 THEN 'Not Started'
                    WHEN 1 THEN 'In Progress'
                    WHEN 2 THEN 'Completed'
                    ELSE 'On Hold'
                    END

                    -- add new task
                    EXEC common.AddTask @SchemaName, @UserId, @UserId, @Title, @Description, @Priority, @Status

                    SET @TaskId = @TaskId + 1
                END

                SET @UserId = @UserId + 1
            END
        END
        ELSE
        BEGIN
            PRINT 'Tenant ' + @TenantName + ' already exists. Skipping.'
        END

        SET @TenantId = @TenantId + 1
    END
END
GO