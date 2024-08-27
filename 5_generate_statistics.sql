USE MultitenantTaskManagement
GO

-- get user tasks
CREATE PROCEDURE common.GetUserTasks
    @SchemaName NVARCHAR(128),
    @UserId INT
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '
    SELECT t.*
    FROM ' + @SchemaName + '.Tasks t
    LEFT JOIN ' + @SchemaName + '.TaskSharing ts ON t.TaskId = ts.TaskId
    WHERE t.AssignedTo = @UserId OR ts.SharedWith = @UserId
    ORDER BY t.CreatedAt DESC'

    EXEC sp_executesql @SQL, N'@UserId INT', @UserId
END
GO

-- get task statistics for manager
CREATE PROCEDURE common.GetTaskStatistics
    @SchemaName NVARCHAR(128),
    @ManagerId INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '
    SELECT
    u.UserId, u.Username,
    YEAR(t.CreatedAt) AS Year,
    MONTH(t.CreatedAt) AS Month,
    t.Status, COUNT(*) AS TaskCount
    FROM ' + @SchemaName + '.Tasks t
    JOIN ' + @SchemaName + '.Users u ON t.AssignedTo = u.UserId
    WHERE u.ManagerId = @ManagerId
      AND t.CreatedAt BETWEEN @StartDate AND @EndDate
    GROUP BY u.UserId, u.Username, YEAR(t.CreatedAt), MONTH(t.CreatedAt), t.Status
    ORDER BY u.Username, Year, Month, t.Status'

    EXEC sp_executesql @SQL, N'@ManagerId INT, @StartDate DATE, @EndDate DATE',
        @ManagerId, @StartDate, @EndDate
END
GO

-- get aggregate task statistics
CREATE PROCEDURE common.GetAggregateTaskStatistics
    @TenantName NVARCHAR(100),
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    DECLARE @SchemaName NVARCHAR(128)
    SELECT @SchemaName = SchemaName FROM common.Tenants WHERE TenantName = @TenantName

    IF @SchemaName IS NULL
    BEGIN
        PRINT 'Tenant not found'
        RETURN
    END

    DECLARE @SQL NVARCHAR(MAX) = '
    WITH TaskCounts AS (
        SELECT
            u.UserId, u.Username,
            YEAR(t.CreatedAt) AS Year,
            MONTH(t.CreatedAt) AS Month,
            t.Status, COUNT(*) AS TaskCount
        FROM ' + @SchemaName + '.Tasks t
        JOIN ' + @SchemaName + '.Users u ON t.AssignedTo = u.UserId
        WHERE t.CreatedAt BETWEEN @StartDate AND @EndDate
        GROUP BY u.UserId, u.Username, YEAR(t.CreatedAt), MONTH(t.CreatedAt), t.Status
    )
    SELECT *
    FROM TaskCounts
    PIVOT (
        SUM(TaskCount)
        FOR Status IN ([Not Started], [In Progress], [Completed], [On Hold], [Deleted])
    ) AS PivotTable
    ORDER BY Username, Year, Month'

    EXEC sp_executesql @SQL, N'@StartDate DATE, @EndDate DATE', @StartDate, @EndDate
END
GO