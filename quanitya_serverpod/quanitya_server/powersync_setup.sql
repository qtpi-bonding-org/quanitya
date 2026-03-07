--
-- PowerSync Setup: Create replication role
--
-- This role is used by PowerSync to read the PostgreSQL replication stream.
-- REPLICATION privilege: Allows reading the Write-Ahead Log (WAL) for logical replication
-- BYPASSRLS privilege: Allows bypassing row-level security policies to read all data
-- LOGIN privilege: Allows the role to connect to the database
--
CREATE ROLE powersync_role WITH 
  REPLICATION 
  BYPASSRLS 
  LOGIN 
  PASSWORD :'powersync_password';  -- Pass via: psql -v powersync_password='your_password'

--
-- PowerSync Setup: Grant SELECT permissions
--
-- Grant SELECT on all existing tables in the public schema to powersync_role.
-- This allows PowerSync to read current data from all tables.
--
GRANT SELECT ON ALL TABLES IN SCHEMA public TO powersync_role;

--
-- Grant SELECT on all future tables in the public schema to powersync_role.
-- This ensures that any tables created after this migration will automatically
-- be readable by PowerSync without requiring additional GRANT statements.
--
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT ON TABLES TO powersync_role;

--
-- Grant database and schema permissions to powersync_role
--
GRANT CONNECT ON DATABASE quanitya TO powersync_role;
GRANT USAGE ON SCHEMA public TO powersync_role;
GRANT CREATE ON DATABASE quanitya TO powersync_role;
GRANT CREATE ON SCHEMA public TO powersync_role;

--
-- PowerSync Setup: Create publication
--
-- A publication defines which tables are replicated through logical replication.
-- PowerSync subscribes to this publication to receive real-time updates.
--
-- FOR ALL TABLES: This publication includes all tables in the database.
-- 
-- PERFORMANCE WARNING: In production environments with many tables or high write
-- volume, consider creating a publication for specific tables only:
--   CREATE PUBLICATION powersync FOR TABLE table1, table2, table3;
-- This reduces replication overhead and improves performance.
--
CREATE PUBLICATION powersync FOR ALL TABLES;