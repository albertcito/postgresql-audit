CREATE OR REPLACE FUNCTION audit_schema(
	connname VARCHAR,
	conn_data VARCHAR,
    name_schema VARCHAR
)
	RETURNS VARCHAR
	AS $func$
	DECLARE record RECORD;
BEGIN
	FOR record IN (
		SELECT tables.table_name FROM information_schema.tables WHERE table_schema = name_schema
	) LOOP
		RAISE NOTICE '---------------- audit_table: % ------------------------', record.table_name;
		RAISE NOTICE '%', (SELECT audit_table(
			connname, conn_data, name_schema, CAST(record.table_name AS VARCHAR)
		));
	END LOOP;
	RETURN 'audit_schema done';
END
$func$
LANGUAGE plpgsql;