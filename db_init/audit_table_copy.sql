CREATE OR REPLACE FUNCTION audit_table_copy(
	connname VARCHAR,
    name_schema VARCHAR,
    name_table VARCHAR
)
	RETURNS VARCHAR
	AS $func$
	DECLARE record RECORD;
	DECLARE new_table VARCHAR = CONCAT('"', name_schema, '"."', name_table, '"');
	DECLARE table_to_create VARCHAR = CONCAT('CREATE TABLE IF NOT EXISTS ', new_table, '(');
BEGIN
	table_to_create = CONCAT(table_to_create, ' "_audit_id" SERIAL PRIMARY KEY,');
	table_to_create = CONCAT(table_to_create, ' "_audit_type" VARCHAR,');
	table_to_create = CONCAT(table_to_create, ' "_audit_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,');
	FOR record IN (SELECT * FROM audit_get_table_columns(name_schema, name_table)) LOOP
		IF record.data_type = 'USER-DEFINED' THEN
			table_to_create = CONCAT(table_to_create, ' "', record.column_name, '" VARCHAR,');
		ELSE
			IF record.udt_name = 'varchar' AND record.character_maximum_length IS NOT NULL THEN
				table_to_create = CONCAT(
					table_to_create, ' "', record.column_name, '" VARCHAR(', record.character_maximum_length ,'),'
				);
			ELSE
				table_to_create = CONCAT(
					table_to_create, ' "', record.column_name, '" ', record.udt_name, ','
				);
			END IF;
		END IF;
    END LOOP;
	table_to_create = RTRIM(table_to_create, ',');
	table_to_create = CONCAT(table_to_create, ' );');
	RAISE NOTICE 'Executed %',  table_to_create;
	RETURN CONCAT(
		new_table,
		' was created if it does not existed. ',
		(SELECT dblink_exec(connname, table_to_create))
	);
END
$func$
LANGUAGE plpgsql;