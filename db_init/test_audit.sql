CREATE OR REPLACE FUNCTION test_audit()
	RETURNS VARCHAR
	AS $func$
	DECLARE total INT = 0;
	DECLARE query_verify VARCHAR;
	DECLARE record RECORD;
	DECLARE connname VARCHAR = upper(substr(md5(random()::text), 0, 20));
	DECLARE conn_data VARCHAR = 'host=127.0.0.1 port=5432 dbname=audit user=db_user password=1234 options=-csearch_path=';
	DECLARE id VARCHAR = upper(substr(md5(random()::text), 0, 5));
BEGIN
	RAISE NOTICE 'dblink_connect %', (SELECT dblink_connect(connname, conn_data));
	RAISE NOTICE 'audit_table %', (SELECT audit_table(connname, conn_data, 'public', 'lang'));

	INSERT INTO public.lang(id, name, localname, active, is_blocked, created_by, updated_by, type)
	VALUES (id, 'inEnglish', 'inOriginal', true, false, 1, 2, 'left');

	-- Verify the same value in `audit` table -> DB link
	query_verify = FORMAT('SELECT COUNT(lang.id) as total FROM public.lang WHERE id = ''%s'';', id);
	RAISE NOTICE 'Verify query in audit %', query_verify;
	SELECT remote.total INTO total FROM dblink(connname, query_verify) AS remote(total int);
	if (total > 0) THEN
		RAISE INFO 'Verification success';
	ELSE
		RAISE EXCEPTION 'The id "%" does not exists in "%.%" table ', id, name_schema, name_table
		USING ERRCODE='AUTNF';
	END IF;

	RAISE NOTICE 'dblink_disconnect %',(SELECT dblink_disconnect(connname));
	RETURN 'Test passed';
END
$func$
LANGUAGE plpgsql;