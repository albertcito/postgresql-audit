CREATE OR REPLACE FUNCTION test_audit_insert(
	connname VARCHAR,
	conn_data VARCHAR DEFAULT 'host=127.0.0.1 port=5432 dbname=audit user=db_user password=1234 options=-csearch_path='
)
	RETURNS VARCHAR
	AS $func$
	DECLARE total INT = 0;
	DECLARE query_verify VARCHAR;
	DECLARE name_schema VARCHAR = 'public';
	DECLARE id VARCHAR = upper(substr(md5(random()::text), 0, 5));
BEGIN
	INSERT INTO public.lang(
		id, name, localname, active, is_blocked, created_by, updated_by, type
	) VALUES (
		id, 'test_audit_table', 'test_audit_table', true, false, 1, 2, 'left'
	);

	query_verify = FORMAT('SELECT COUNT(lang.id) as total FROM public.lang WHERE id = ''%s'';', id);
	RAISE NOTICE 'Verify query in audit %', query_verify;

	SELECT remote.total INTO total
	FROM dblink(connname, query_verify) AS remote(total int);

	if (total > 0) THEN
		RAISE INFO 'Verification success';
	ELSE
		RAISE EXCEPTION 'The id "%" does not exists in "%.%" table ', id, name_schema, name_table
		USING ERRCODE='AUTNF';
	END IF;

	RETURN 'audit_table passed';
END
$func$
LANGUAGE plpgsql;