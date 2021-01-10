CREATE OR REPLACE FUNCTION audit_table_column_added(
	connname VARCHAR,
	name_schema VARCHAR,
    name_table VARCHAR
)
	RETURNS VARCHAR
	AS $func$
	DECLARE audit_record RECORD;
	DECLARE local_record RECORD;
	DECLARE audit_get_column_query VARCHAR;
	DECLARE audit_alter_table_query VARCHAR = CONCAT('ALTER TABLE "', name_schema, '"."', name_table ,'" ');
	DECLARE exist_record BOOLEAN;
	DECLARE total_new_columns INT = 0;
BEGIN
	--
	audit_get_column_query = FORMAT(
		'SELECT * FROM public.audit_get_table_columns(''%s'', ''%s'')',
		name_schema, name_table
	);
	RAISE NOTICE 'remote query: %', audit_get_column_query;
	FOR local_record IN (SELECT * FROM audit_get_table_columns(name_schema, name_table)) LOOP
		exist_record = false;
		FOR audit_record IN (SELECT * FROM dblink(connname, audit_get_column_query) AS remote(
			column_name VARCHAR,
			data_type VARCHAR,
			character_maximum_length  INT,
			numeric_precision  INT,
			datetime_precision  INT,
			udt_name  VARCHAR
		)) LOOP
			IF local_record.column_name = audit_record.column_name THEN
				exist_record = true;
			 	EXIT; -- break from the loop
			END IF;
		END LOOP;
		IF exist_record = false THEN
			total_new_columns = total_new_columns + 1;
			audit_alter_table_query = CONCAT(audit_alter_table_query, ' ADD COLUMN ', audit_column_to_query(
				local_record.column_name,
				local_record.data_type,
				local_record.character_maximum_length,
				local_record.udt_name
			), ', ');
			RAISE NOTICE 'column does not exist %', local_record.column_name;
		END IF;
	END LOOP;

	IF total_new_columns > 0 THEN
		audit_alter_table_query = RTRIM(audit_alter_table_query, ', ');
		RAISE NOTICE 'Executed: %', (SELECT dblink_exec(connname, audit_alter_table_query));
	END IF;

	RETURN CONCAT('It was inserted ',total_new_columns, ' new columns');
END
$func$
LANGUAGE plpgsql;