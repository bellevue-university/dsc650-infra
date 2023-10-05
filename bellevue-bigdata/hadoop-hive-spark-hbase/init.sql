CREATE DATABASE "hivemetastoredb";

CREATE user pguser WITH ENCRYPTED PASSWORD '123456';
CREATE DATABASE pgdata ENCODING UTF8 TEMPLATE template1;
-- unable to create schema under pgdata,if exec following sqls,a schema will be added to postgres database 
-- CREATE SCHEMA pguser_public;
-- SET search_path = pguser_public;
GRANT ALL PRIVILEGES ON DATABASE pgdata TO pguser;