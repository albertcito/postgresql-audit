CREATE OR REPLACE FUNCTION test_add_column(
	connname VARCHAR,
	conn_data VARCHAR DEFAULT 'host=127.0.0.1 port=5432 dbname=audit user=db_user password=1234 options=-csearch_path='
)
	RETURNS VARCHAR
	AS $func$
	DECLARE total INT = 0;
	DECLARE query_verify VARCHAR;
	DECLARE name_schema VARCHAR = 'public';
	DECLARE name_table VARCHAR = 'lang';
	DECLARE id VARCHAR = upper(substr(md5(random()::text), 0, 5));
BEGIN
	ALTER TABLE public.lang ADD COLUMN IF NOT EXISTS new_column INT;
	RAISE NOTICE 'audit_table -> new column %', (SELECT audit_table(connname, conn_data, name_schema, name_table));
	INSERT INTO
		public.lang(id, name, localname, active, is_blocked, created_by, updated_by, type, new_column)
		VALUES (id, 'test_add_column', 'test_add_column', true, false, 1, 2, 'left', 10);

	query_verify = FORMAT('SELECT COUNT(lang.new_column) as total FROM public.lang WHERE id = ''%s'';', id);
	RAISE NOTICE 'Verify query in audit %', query_verify;
	total = 0;
	SELECT remote2.total INTO total FROM dblink(connname, query_verify) AS remote2(total int);
	if (total > 0) THEN
		RAISE INFO 'Verification new columun success';
	ELSE
		RAISE EXCEPTION 'The id "%" does not exists in "%.%" table ', id, name_schema, name_table
		USING ERRCODE='AUTNF';
	END IF;

	RETURN 'test_add_column passed';
END
$func$
LANGUAGE plpgsql;