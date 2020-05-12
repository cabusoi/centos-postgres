CREATE EXTENSION tds_fdw;
CREATE SCHEMA import_schema;
CREATE SERVER sql01 FOREIGN DATA WRAPPER tds_fdw OPTIONS (servername 'mssql', database 'master', msg_handler 'notice');
CREATE USER MAPPING FOR postgres SERVER sql01 OPTIONS (username 'sa', password 'P4ssw0rD');
IMPORT FOREIGN SCHEMA msschema01 FROM SERVER sql01 INTO import_schema OPTIONS (import_default 'true');
NOTICE:  DB-Library notice: Msg #: 5701, Msg state: 2, Msg: Changed database context to 'master'., Server: 
