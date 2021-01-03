CREATE OR REPLACE FUNCTION audit_get_table_columns(
    name_schema varchar,
    name_table varchar
)
	RETURNS TABLE (
      column_name information_schema.columns.column_name%TYPE,
	  data_type information_schema.columns.data_type%TYPE,
	  character_maximum_length information_schema.columns.character_maximum_length%TYPE,
	  numeric_precision information_schema.columns.numeric_precision%TYPE,
	  datetime_precision information_schema.columns.datetime_precision%TYPE,
      udt_name information_schema.columns.udt_name%TYPE
	)
	AS $func$
	DECLARE total_columns INTEGER;
BEGIN
	CREATE TEMP TABLE temp_table AS SELECT
	    columns.column_name,
        columns.data_type,
        columns.character_maximum_length,
        columns.numeric_precision,
        columns.datetime_precision,
        columns.udt_name
    FROM
        information_schema.columns
    WHERE
        columns.table_schema = name_schema
        AND columns.table_name = name_table
    ORDER BY
        ordinal_position ASC;
	SELECT count(temp_table.column_name) INTO total_columns FROM temp_table;
	IF total_columns = 0  THEN
		DROP TABLE IF EXISTS temp_table;
		RAISE EXCEPTION 'The %.% does not exists or has zero columns', name_schema, name_table
		USING ERRCODE='AUTZC';
	END IF;

	RETURN QUERY SELECT * FROM temp_table;
	DROP TABLE IF EXISTS temp_table;
END
$func$
LANGUAGE plpgsql;