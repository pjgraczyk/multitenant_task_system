USE MultitenantTaskManagement
GO

-- update task and record history
CREATE PROCEDURE common.UpdateTask
    @SchemaName NVARCHAR(128),
    @TaskId INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @Priority INT,
    @Status NVARCHAR(20),
    @AssignedTo INT,
    @UpdatedBy INT
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX)

    -- get current task values
    SET @SQL = '
    DECLARE @OldTitle NVARCHAR(200), @OldDescription NVARCHAR(MAX),
            @OldPriority INT, @OldStatus NVARCHAR(20), @OldAssignedTo INT

    SELECT @OldTitle = Title, @OldDescription = Description,
           @OldPriority = Priority, @OldStatus = Status, @OldAssignedTo = AssignedTo
    FROM ' + @SchemaName + '.Tasks
    WHERE TaskId = @TaskId

    -- update task
    UPDATE ' + @SchemaName + '.Tasks
    SET Title = @Title,
        Description = @Description,
        Priority = @Priority,
        Status = @Status,
        AssignedTo = @AssignedTo,
        UpdatedAt = GETDATE()
    WHERE TaskId = @TaskId

    -- record changes in task history
    INSERT INTO ' + @SchemaName + '.TaskHistory (TaskId, ChangedBy, ChangeType, OldValue, NewValue, ChangedAt)
    VALUES
        (@TaskId, @UpdatedBy, ''Title'', @OldTitle, @Title, GETDATE()),
        (@TaskId, @UpdatedBy, ''Description'', @OldDescription, @Description, GETDATE()),
        (@TaskId, @UpdatedBy, ''Priority'', CAST(@OldPriority AS NVARCHAR(10)), CAST(@Priority AS NVARCHAR(10)), GETDATE()),
        (@TaskId, @UpdatedBy, ''Status'', @OldStatus, @Status, GETDATE()),
        (@TaskId, @UpdatedBy, ''AssignedTo'', CAST(@OldAssignedTo AS NVARCHAR(10)), CAST(@AssignedTo AS NVARCHAR(10)), GETDATE())
    '

    EXEC sp_executesql @SQL,
        N'@TaskId INT, @Title NVARCHAR(200), @Description NVARCHAR(MAX),
          @Priority INT, @Status NVARCHAR(20), @AssignedTo INT, @UpdatedBy INT',
        @TaskId, @Title, @Description, @Priority, @Status, @AssignedTo, @UpdatedBy

    PRINT 'Task updated and history recorded.'
END
GO