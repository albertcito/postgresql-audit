CREATE OR REPLACE FUNCTION test_audit(
	conn_data VARCHAR DEFAULT 'host=127.0.0.1 port=5432 dbname=audit user=db_user password=1234 options=-csearch_path='
)
	RETURNS VARCHAR
	AS $func$
	DECLARE total INT = 0;
	DECLARE query_verify VARCHAR;
	DECLARE record RECORD;
	DECLARE connname VARCHAR = upper(substr(md5(random()::text), 0, 20));
	DECLARE name_schema VARCHAR = 'public';
	DECLARE id VARCHAR = upper(substr(md5(random()::text), 0, 5));
	DECLARE id_add_column VARCHAR = upper(substr(md5(random()::text), 0, 5));
	DECLARE id_update_column VARCHAR = upper(substr(md5(random()::text), 0, 5));
BEGIN
	RAISE NOTICE 'dblink_connect %', (SELECT dblink_connect(connname, conn_data));
	RAISE NOTICE 'copy_fn_to_audit %', (SELECT copy_fn_to_audit(connname));

	RAISE NOTICE '----------------> verify audit_table <------------------------';
	RAISE NOTICE 'audit_table %', (SELECT audit_table(connname, conn_data, name_schema, 'lang'));
	INSERT INTO public.lang(id, name, localname, active, is_blocked, created_by, updated_by, type)
	VALUES (id, 'inEnglish', 'inOriginal', true, false, 1, 2, 'left');

	query_verify = FORMAT('SELECT COUNT(lang.id) as total FROM public.lang WHERE id = ''%s'';', id);
	RAISE NOTICE 'Verify query in audit %', query_verify;

	SELECT remote.total INTO total FROM dblink(connname, query_verify) AS remote(total int);

	if (total > 0) THEN
		RAISE INFO 'Verification success';
	ELSE
		RAISE EXCEPTION 'The id "%" does not exists in "%.%" table ', id, name_schema, name_table
		USING ERRCODE='AUTNF';
	END IF;

	RAISE NOTICE '----------------> verify new column <------------------------';
	ALTER TABLE public.lang ADD COLUMN IF NOT EXISTS new_column INT;
	RAISE NOTICE 'audit_table -> new column %', (SELECT audit_table(connname, conn_data, 'public', 'lang'));
	INSERT INTO
		public.lang(id, name, localname, active, is_blocked, created_by, updated_by, type, new_column)
		VALUES (id_add_column, 'inEnglish', 'inOriginal', true, false, 1, 2, 'left', 10);

	query_verify = FORMAT('SELECT COUNT(lang.new_column) as total FROM public.lang WHERE id = ''%s'';', id_add_column);
	RAISE NOTICE 'Verify query in audit %', query_verify;
	total = 0;
	SELECT remote2.total INTO total FROM dblink(connname, query_verify) AS remote2(total int);
	if (total > 0) THEN
		RAISE INFO 'Verification new columun success';
	ELSE
		RAISE EXCEPTION 'The id "%" does not exists in "%.%" table ', id, name_schema, name_table
		USING ERRCODE='AUTNF';
	END IF;

	RAISE NOTICE '----------------> verify alter columns <------------------------';
	ALTER TABLE public.lang
		ALTER COLUMN id TYPE text,
		ALTER COLUMN created_by TYPE int4,
		ALTER COLUMN type TYPE  VARCHAR;
	RAISE NOTICE 'audit_table -> new column %', (SELECT audit_table(connname, conn_data, 'public', 'lang'));
	INSERT INTO
		public.lang(id, name, localname, active, is_blocked, created_by, updated_by, type, new_column)
		VALUES (id_update_column, 'inEnglish', 'inOriginal', true, false, 1, 2, 'left', 10);
	query_verify = FORMAT('SELECT COUNT(lang.new_column) as total FROM public.lang WHERE id = ''%s'';', id_update_column);
	RAISE NOTICE 'Verify query in audit %', query_verify;
	total = 0;
	SELECT remote3.total INTO total FROM dblink(connname, query_verify) AS remote3(total int);
	if (total > 0) THEN
		RAISE INFO 'Verification new columun success';
	ELSE
		RAISE EXCEPTION 'The id "%" does not exists in "%.%" table ', id, name_schema, name_table
		USING ERRCODE='AUTNF';
	END IF;

	-- Disconnect
	RAISE NOTICE 'dblink_disconnect %',(SELECT dblink_disconnect(connname));
	RETURN 'Test passed';
END
$func$
LANGUAGE plpgsql;