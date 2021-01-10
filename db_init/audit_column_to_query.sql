CREATE OR REPLACE FUNCTION audit_column_to_query(
	column_name information_schema.columns.column_name%TYPE,
	data_type information_schema.columns.data_type%TYPE,
	character_maximum_length information_schema.columns.character_maximum_length%TYPE,
	udt_name information_schema.columns.udt_name%TYPE
)
	RETURNS VARCHAR
	AS $func$
BEGIN
	IF data_type = 'USER-DEFINED' THEN
		RETURN CONCAT(' "', column_name, '" VARCHAR ');
	END IF;

	IF udt_name = 'varchar' AND character_maximum_length IS NOT NULL THEN
		RETURN CONCAT(column_name, '" VARCHAR(', character_maximum_length ,') ');
	END IF;

	RETURN CONCAT(' "', column_name, '" ', udt_name, ' ');
END
$func$
LANGUAGE plpgsql;