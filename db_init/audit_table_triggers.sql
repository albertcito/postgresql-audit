CREATE OR REPLACE FUNCTION audit_table_triggers(
	conn_data VARCHAR,
    name_schema VARCHAR,
    name_table VARCHAR
)
	RETURNS VARCHAR
	AS $func$
	DECLARE record RECORD;
	DECLARE table_schema_name VARCHAR = CONCAT('"', name_schema, '"."', name_table, '"');
	DECLARE function_name VARCHAR = CONCAT(
		name_schema, '.', '_audit_', name_schema, '_', name_table, '_trigger()'
	);
	DECLARE trigger VARCHAR = CONCAT(
		' DROP TRIGGER IF EXISTS _audit_table ON ', table_schema_name, ' ; ',
		' CREATE TRIGGER _audit_table AFTER INSERT OR UPDATE OR DELETE ON',
		' ', table_schema_name, ' ',
    	'FOR EACH ROW EXECUTE PROCEDURE ', function_name, '; '
	);
	DECLARE columns_query VARCHAR = '';
	DECLARE values_format VARCHAR = '';
	DECLARE values_new_query VARCHAR = '';
	DECLARE values_old_query VARCHAR = '';
	DECLARE function_trigger VARCHAR;
	DECLARE select_temp_value VARCHAR;
BEGIN

	function_trigger = CONCAT(
		' CREATE OR REPLACE FUNCTION',
		' ', function_name, ' ',
        ' RETURNS trigger as $$ ',
		' DECLARE connname VARCHAR = upper(substr(md5(random()::text), 0, 20));',
		' DECLARE conn_data VARCHAR = ''',conn_data,''';',
		' DECLARE query_format VARCHAR;',
		' DECLARE query_insert VARCHAR;',
		'BEGIN'
	);

	FOR record IN (SELECT * FROM audit_get_table_columns(name_schema, name_table)) LOOP
		columns_query = CONCAT(columns_query, '"', record.column_name, '", ');
		values_format = CONCAT(values_format, '%L, ');
		values_new_query =  CONCAT(values_new_query, 'NEW."', record.column_name, '", ');
		values_old_query = CONCAT(values_old_query, 'OLD."', record.column_name, '", ');
	END LOOP;

	function_trigger = CONCAT(
		function_trigger,
		' query_format = '' INSERT INTO ', table_schema_name, ' (', columns_query, '_audit_type) VALUES (', values_format, ' ''''%s''''); '';',
		' IF TG_OP = ''DELETE'' THEN ',
			'query_insert = FORMAT(query_format, ', values_old_query, ' TG_OP);',
		' ELSE ',
			'query_insert = FORMAT(query_format, ', values_new_query, ' TG_OP);',
		' END IF;'
	);

	function_trigger = CONCAT(
		function_trigger,
		' RAISE NOTICE ''Audit -> Connect: %'', (SELECT dblink_connect(connname, conn_data)); ',
		' RAISE NOTICE ''Audit -> Executing: %'', query_insert; ',
		' RAISE NOTICE ''Audit -> Executed: %'', (SELECT dblink_exec(connname, query_insert)); ',
		' RAISE NOTICE ''Audit -> Disconnect: %'', (SELECT dblink_disconnect(connname)); ',
		' RETURN NEW; ',
		' END; ',
		' $$ LANGUAGE plpgsql;'
	);
	RAISE NOTICE 'Executing: %',  function_trigger;
	EXECUTE function_trigger;
	RAISE NOTICE 'Executing: %',  trigger;
	EXECUTE trigger;
	RETURN 'audit_table_triggers done';
END
$func$
LANGUAGE plpgsql;