USE MultitenantTaskManagement
GO

-- get task info and history
CREATE PROCEDURE common.GetTaskInfoAndHistory
    @SchemaName NVARCHAR(100),
    @TaskId INT
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX)

    SET @SQL = '
    -- get task info
    SELECT
        t.TaskId, t.Title, t.Description, t.Priority, t.Status,
        t.CreatedAt, t.UpdatedAt,
        creator.Username AS CreatedByUser,
        assignee.Username AS AssignedToUser
    FROM ' + @SchemaName + '.Tasks t
    JOIN ' + @SchemaName + '.Users creator ON t.CreatedBy = creator.UserId
    JOIN ' + @SchemaName + '.Users assignee ON t.AssignedTo = assignee.UserId
    WHERE t.TaskId = @TaskId;

    -- get task history
    SELECT
        th.HistoryId, th.ChangeType, th.OldValue, th.NewValue,
        th.ChangedAt, u.Username AS ChangedByUser
    FROM ' + @SchemaName + '.TaskHistory th
    JOIN ' + @SchemaName + '.Users u ON th.ChangedBy = u.UserId
    WHERE th.TaskId = @TaskId
    ORDER BY th.ChangedAt DESC;

    -- get task sharing info
    SELECT
        ts.SharingId,
        sharedWith.Username AS SharedWithUser,
        sharedBy.Username AS SharedByUser,
        ts.SharedAt
    FROM ' + @SchemaName + '.TaskSharing ts
    JOIN ' + @SchemaName + '.Users sharedWith ON ts.SharedWith = sharedWith.UserId
    JOIN ' + @SchemaName + '.Users sharedBy ON ts.SharedBy = sharedBy.UserId
    WHERE ts.TaskId = @TaskId
    ORDER BY ts.SharedAt DESC;'

    EXEC sp_executesql @SQL, N'@TaskId INT', @TaskId
END
GO