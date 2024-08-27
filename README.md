# Multitenant Task Management
A SQL Server-based multitenant system for task management using a single database with multiple schemas.

# Requirements
- MS SQL Server 2019+
- SQL IDE of choice

# Deploying
- Uncomment the portion (lines 1-3) of [1_create_database_and_schema.sql](1_create_database_and_schema.sql) to create a database
- Run each file:
  1. [1_create_database_and_schema.sql](1_create_database_and_schema.sql)
  1. [2_add_tasks_and_users.sql](2_add_tasks_and_users.sql)
  1. [3_generate_test_data.sql](3_generate_test_data.sql)
  1. [4_manipulate_tasks_delete_update.sql](4_manipulate_tasks_delete_update.sql)
  1. [5_generate_statistics.sql](5_generate_statistics.sql)
  1. [6_get_tasks_info.sql](6_get_tasks_info.sql)
  1. [7_get_all_tenant_users.sql](7_get_all_tenant_users.sql)
  1. [8_update_tasks.sql](8_update_tasks.sql)

# Usage
- Using the [__execute_procedures.sql](__execute_procedures.sql) file please generate test data (if needed) \
and use procedures to modify data and fetch statistics
- I have strategically removed __drop_database file (for repeating the test) for the sake of "safety" of the users deploying \
however the procedures/schemas/tables/databases can **of course** be deleted by IDE or by SQL query.

# Shortcomings
Given the time to create this database there are a couple shortcomings:
- There aren't as many checks for data integrity (**CONSTRAINTS**)
- There aren't as many error flags as should be to check if tenants/users/tasks/etc. exist
- The procedures lack proper history check structure (OLD -> NEW is a row for a given col)
- Some procedures lack privilege management