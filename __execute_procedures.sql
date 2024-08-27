USE MultitenantTaskManagement
GO

EXEC common.GenerateTestData
EXEC common.GetTaskStatistics 'tenant_1', 1, '2022-01-01', '2026-12-31'
EXEC common.GetAggregateTaskStatistics 'tenant_1', '2022-01-01', '2026-12-31'
-- The data should be visible only to the manager and the person who created?
EXEC common.GetUserTasks 'tenant_1', 5
-- Only manager should probably have right to assign tasks to someone else
EXEC common.AddTask 'tenant_1', 1, 2, 'Test Task', 'This is a test task', 1, 'Not Started'
-- Should only managers delete tasks?
EXEC common.DeleteTask 1, 1, 'tenant_1'
-- Task deletion should remain in database but be invisible to user, for API it should return only one table
EXEC common.GetTaskInfoAndHistory 'tenant_1', 10
-- More validation for the Status Names and if the user can update task (user should be argument in this procedure)
EXEC common.UpdateTask 'Tenant_1', 10, 'Hello World!', 'This is updated task!', 2, 'In Progress', 1, 1
-- There should be check for unified name schema for given tenant the tenant (if duplicate then ex. _1...)
EXEC common.AddNewUser 'tenant_1', 'pjgraczyk', 0, 1
-- Add Check for if tenant exists, but it's only fetch so at maximum it can be an error not privilege violation
EXEC common.GetAllTenantUsers 'tenant_1'