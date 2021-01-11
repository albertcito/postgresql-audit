CREATE OR REPLACE FUNCTION audit_db(
	connname VARCHAR,
	conn_data VARCHAR
)
	RETURNS VARCHAR
	AS $func$
	DECLARE record RECORD;
BEGIN
	FOR record IN (
		SELECT schema_name FROM information_schema.schemata
 		WHERE schema_name !~ '^pg_' AND schema_name <> 'information_schema'
	) LOOP
		RAISE NOTICE '---------------- audit_schema: % ------------------------', record.schema_name;
		RAISE NOTICE '%', (SELECT audit_schema(
			connname, conn_data, CAST(record.schema_name AS VARCHAR)
		));
	END LOOP;
	RETURN 'Audit Schema done';
END
$func$
LANGUAGE plpgsql;