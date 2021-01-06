CREATE OR REPLACE FUNCTION audit_table_triggers(
    name_schema VARCHAR,
    name_table VARCHAR
)
	RETURNS VARCHAR
	AS $func$
	DECLARE record RECORD;
	DECLARE table_schema_name VARCHAR = CONCAT('"', name_schema, '"."', name_table, '"');
	DECLARE function_name VARCHAR = CONCAT(
		name_schema, '.', 'audit_', name_schema, '_', name_table, '_trigger()'
	);
	DECLARE trigger VARCHAR = CONCAT(
		' DROP TRIGGER IF EXISTS audit_table ON', table_schema_name, ' ; ',
		' CREATE TRIGGER audit_table AFTER INSERT OR UPDATE OR DELETE ON',
		' ', table_schema_name, ' ',
    	'FOR EACH ROW EXECUTE PROCEDURE ', function_name, '; '
	);
	DECLARE columns_query VARCHAR = '';
	DECLARE values_new_query VARCHAR = '';
	DECLARE values_old_query VARCHAR = '';
	DECLARE function_trigger VARCHAR;
BEGIN

	function_trigger = CONCAT(
		' CREATE OR REPLACE FUNCTION',
		' ', function_name, ' ',
        ' RETURNS trigger as $$ ',
		' DECLARE connname VARCHAR = upper(substr(md5(random()::text), 0, 20));',
		' DECLARE query_insert VARCHAR;',
		'BEGIN'
	);

	FOR record IN (SELECT * FROM audit_get_table_columns(name_schema, name_table)) LOOP
		columns_query = CONCAT(columns_query, '"', record.column_name, '", ');
		values_new_query = CONCAT(values_new_query, 'NEW."', record.column_name, '", ');
		values_old_query = CONCAT(values_old_query, 'OLD."', record.column_name, '", ');
	END LOOP;

	function_trigger = CONCAT(
		function_trigger,
		' IF TG_OP = ''DELETE'' THEN ',
			'query_insert = ',
			''' INSERT INTO ', table_schema_name, ' (', columns_query, 'event_audit_) VALUES (', values_old_query, 'TG_OP); '';'
		' ELSE ',
			'query_insert = ',
			''' INSERT INTO ', table_schema_name, ' (', columns_query, 'event_audit_) VALUES (', values_new_query, 'TG_OP); '';',
		' END IF;'
	);

	function_trigger = CONCAT(
		function_trigger,
		'SELECT dblink_connect(',
			'connname,',
			'''host=127.0.0.1 port=5432 dbname=log user=albert options=-csearch_path=''',
		');',
		' SELECT dblink_exec(connname, query_insert);',
		' SELECT dblink_disconnect(connname); ',
		' RETURN NEW; ',
		' END; ',
		' $$ LANGUAGE plpgsql;'
	);
	EXECUTE function_trigger;
	RAISE NOTICE '%',  function_trigger;
	EXECUTE trigger;
	RAISE NOTICE '%',  trigger;
	RETURN 'Trigger created or updated';
END
$func$
LANGUAGE plpgsql;