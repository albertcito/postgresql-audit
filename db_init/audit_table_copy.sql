/**
 * - Add extra columns
 * - make it work: EXECUTE table_to_create; (line 24)
 *
 **/
CREATE OR REPLACE FUNCTION audit_table_copy(
	destiny_name_db VARCHAR,
    name_schema VARCHAR,
    name_table VARCHAR
)
	RETURNS VARCHAR
	AS $func$
	DECLARE rec RECORD;
	DECLARE new_table VARCHAR = CONCAT('"', destiny_name_db,'"."', name_schema, '"."', name_table, '"');
	DECLARE table_to_create VARCHAR = CONCAT('CREATE TABLE IF NOT EXISTS ', new_table, '(');
BEGIN
	FOR rec IN (SELECT * FROM audit_get_table_columns(name_schema, name_table)) LOOP
        RAISE INFO '%', rec;
			table_to_create = CONCAT(table_to_create, ' "', rec.column_name, '" ', rec.udt_name, ',');
    END LOOP;
	table_to_create = RTRIM(table_to_create, ',');
	table_to_create = CONCAT(table_to_create, ' );');
	RAISE NOTICE '%',  table_to_create;
	-- EXECUTE table_to_create;
	RETURN CONCAT(new_table, ' was created if it does not existed');
END
$func$
LANGUAGE plpgsql;