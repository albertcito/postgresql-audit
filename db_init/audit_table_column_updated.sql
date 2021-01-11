CREATE OR REPLACE FUNCTION audit_table_column_updated(
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
	DECLARE modified_column BOOLEAN;
	DECLARE total_modified_columns INT = 0;
	DECLARE are_same_columns BOOLEAN;
BEGIN
	audit_get_column_query = FORMAT(
		'SELECT * FROM public.audit_get_table_columns(''%s'', ''%s'')',
		name_schema, name_table
	);
	RAISE NOTICE 'Get remote columns: %', audit_get_column_query;
	FOR local_record IN (SELECT * FROM audit_get_table_columns(name_schema, name_table)) LOOP
		modified_column = false;
		FOR audit_record IN (SELECT * FROM dblink(connname, audit_get_column_query) AS remote(
			column_name VARCHAR,
			data_type VARCHAR,
			character_maximum_length  INT,
			numeric_precision  INT,
			datetime_precision  INT,
			udt_name VARCHAR
		)) LOOP
			IF local_record.column_name = audit_record.column_name THEN
				are_same_columns = local_record.column_name = audit_record.column_name AND
					(
						local_record.data_type = 'USER-DEFINED' OR
						local_record.data_type = audit_record.data_type
					) AND
					(
						local_record.data_type = 'USER-DEFINED' OR
						local_record.udt_name = audit_record.udt_name
					) AND
					coalesce(local_record.character_maximum_length, -1) = coalesce(audit_record.character_maximum_length, -1) AND
					coalesce(local_record.numeric_precision, -1) = coalesce(audit_record.numeric_precision, -1) AND
					coalesce(local_record.datetime_precision, -1) = coalesce(audit_record.datetime_precision, -1);
				IF are_same_columns IS FALSE THEN
					modified_column = true;
				END IF;
				EXIT; -- break from the loop
			END IF;
		END LOOP;
		IF modified_column = true THEN
			total_modified_columns = total_modified_columns + 1;
			audit_alter_table_query = CONCAT(audit_alter_table_query, ' ALTER COLUMN ', audit_column_to_query(
				local_record.column_name,
				local_record.data_type,
				local_record.character_maximum_length,
				local_record.udt_name,
				'TYPE'
			), ', ');
		END IF;
	END LOOP;

	IF total_modified_columns > 0 THEN
		audit_alter_table_query = RTRIM(audit_alter_table_query, ', ');
		RAISE NOTICE 'Executing: %', audit_alter_table_query;
		RAISE NOTICE 'Executed: %', (SELECT dblink_exec(connname, audit_alter_table_query));
	END IF;

	RETURN CONCAT(total_modified_columns, ' columns were updated');
END
$func$
LANGUAGE plpgsql;