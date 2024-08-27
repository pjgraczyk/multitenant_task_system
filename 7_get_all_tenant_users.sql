USE MultitenantTaskManagement
GO

-- get all users for a tenant
CREATE PROCEDURE common.GetAllTenantUsers
    @TenantName NVARCHAR(100)
AS
BEGIN
    DECLARE @SchemaName NVARCHAR(128)

    -- get schema name for the tenant
    SELECT @SchemaName = SchemaName
    FROM common.Tenants
    WHERE TenantName = @TenantName

    IF @SchemaName IS NULL
    BEGIN
        PRINT 'Tenant not found'
        RETURN
    END

    -- get users for the tenant
    DECLARE @SQL NVARCHAR(MAX) = '
    SELECT
        u.UserId,
        u.Username,
        u.IsManager,
        m.Username AS ManagerName,
        (SELECT COUNT(*) FROM ' + @SchemaName + '.Tasks t WHERE t.AssignedTo = u.UserId) AS AssignedTasksCount,
        (SELECT COUNT(*) FROM ' + @SchemaName + '.Tasks t WHERE t.CreatedBy = u.UserId) AS CreatedTasksCount
    FROM ' + @SchemaName + '.Users u
    LEFT JOIN ' + @SchemaName + '.Users m ON u.ManagerId = m.UserId
    ORDER BY u.Username'

    EXEC sp_executesql @SQL
END
GO