CREATE OR REPLACE FUNCTION audit_table(
	connname VARCHAR,
	conn_data VARCHAR,
    name_schema VARCHAR,
    name_table VARCHAR
)
	RETURNS VARCHAR
	AS $func$
BEGIN
	CREATE SCHEMA IF NOT EXISTS name_schema;
	RAISE NOTICE 'Schema % created - or skipped', name_schema;
	RAISE NOTICE 'audit_table_copy % ', (SELECT audit_table_copy(connname, name_schema, name_table));
	RAISE NOTICE 'audit_table_triggers % ', (SELECT audit_table_triggers(conn_data, name_schema, name_table));
	RETURN 'Audit Table done';
END
$func$
LANGUAGE plpgsql;