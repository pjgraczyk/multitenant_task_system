USE MultitenantTaskManagement
GO

-- delete task procedure
CREATE PROCEDURE common.DeleteTask
    @TaskId INT,
    @UserId INT,
    @TenantSchemaName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @IsManager BIT
    DECLARE @AssignedTo INT
    DECLARE @CreatedBy INT

    -- check if user is manager
    SET @SQL = 'SELECT @IsManager = IsManager FROM ' + @TenantSchemaName + '.Users WHERE UserId = @UserId'
    EXEC sp_executesql @SQL, N'@UserId INT, @IsManager BIT OUTPUT', @UserId, @IsManager OUTPUT

    -- get task details
    SET @SQL = 'SELECT @AssignedTo = AssignedTo, @CreatedBy = CreatedBy FROM ' + @TenantSchemaName + '.Tasks WHERE TaskId = @TaskId'
    EXEC sp_executesql @SQL, N'@TaskId INT, @AssignedTo INT OUTPUT, @CreatedBy INT OUTPUT', @TaskId, @AssignedTo OUTPUT, @CreatedBy OUTPUT

    -- delete or mark task as deleted
    IF @IsManager = 1 OR @CreatedBy = @UserId
    BEGIN
        -- delete task and related records
        SET @SQL = '
        DELETE FROM ' + @TenantSchemaName + '.TaskHistory WHERE TaskId = @TaskId
        DELETE FROM ' + @TenantSchemaName + '.TaskSharing WHERE TaskId = @TaskId
        DELETE FROM ' + @TenantSchemaName + '.Tasks WHERE TaskId = @TaskId'
        EXEC sp_executesql @SQL, N'@TaskId INT', @TaskId

        PRINT 'Task deleted'
    END
    ELSE IF @AssignedTo = @UserId
    BEGIN
        -- mark task as deleted
        SET @SQL = '
        UPDATE ' + @TenantSchemaName + '.Tasks
        SET Status = ''Deleted'', UpdatedAt = GETDATE()
        WHERE TaskId = @TaskId

        INSERT INTO ' + @TenantSchemaName + '.TaskHistory (TaskId, ChangedBy, ChangeType, OldValue, NewValue, ChangedAt)
        VALUES (@TaskId, @UserId, ''StatusChange'', ''Active'', ''Deleted'', GETDATE())'
        EXEC sp_executesql @SQL, N'@TaskId INT, @UserId INT', @TaskId, @UserId

        PRINT 'Task marked as deleted'
    END
    ELSE
    BEGIN
        PRINT 'No permission to delete this task'
    END
END
GO