
CREATE OR REPLACE FUNCTION audit_table_triggers(
    name_schema VARCHAR,
    name_table VARCHAR
)
	RETURNS VARCHAR
	AS $func$
	DECLARE record RECORD;
	DECLARE table_schema_name VARCHAR = CONCAT('"', name_schema, '"."', name_table, '2"');
	DECLARE function_name VARCHAR = CONCAT(
		name_schema, '.', 'audit_', name_schema, '_', name_table, '_trigger()'
	);
	DECLARE trigger VARCHAR = CONCAT(
		' CREATE TRIGGER audit_table',
		' AFTER INSERT OR UPDATE OR DELETE ON',
		' ', table_schema_name, ' ',
    	'FOR EACH ROW EXECUTE PROCEDURE',
		' ', function_name, ' '
	);
	DECLARE function_trigger VARCHAR;
BEGIN

	function_trigger = CONCAT(
		' CREATE OR REPLACE FUNCTION',
		' ', function_name, ' ',
        ' RETURNS trigger as $$ BEGIN'
	);
	function_trigger = CONCAT(
		function_trigger,
		' INSERT INTO',
		' ', table_schema_name, ' ('
	);
	FOR record IN (SELECT * FROM audit_get_table_columns(name_schema, name_table)) LOOP
		function_trigger = CONCAT(function_trigger, record.column_name, ', ');
	END LOOP;
	function_trigger = RTRIM(function_trigger, ', ');
	function_trigger = CONCAT(function_trigger, ') VALUES (');
	FOR record IN (SELECT * FROM audit_get_table_columns(name_schema, name_table)) LOOP
		function_trigger = CONCAT(function_trigger, 'NEW.', record.column_name, ', ');
	END LOOP;
	function_trigger = RTRIM(function_trigger, ', ');
	function_trigger = CONCAT(function_trigger, '); ');
	function_trigger = CONCAT(
		function_trigger,
		' RETURN NEW; ',
		' END; ',
		' $$ LANGUAGE plpgsql;'
	);
	RAISE NOTICE '%',  function_trigger;
	RETURN CONCAT(
		function_trigger,
		' --> was created if it does not existed <-- ',
		trigger
	);
END
$func$
LANGUAGE plpgsql;