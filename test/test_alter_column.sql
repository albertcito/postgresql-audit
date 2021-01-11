CREATE OR REPLACE FUNCTION test_alter_column(
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
	RAISE NOTICE '----------------> verify alter columns <------------------------';
	ALTER TABLE public.lang
		ALTER COLUMN id TYPE text,
		ALTER COLUMN created_by TYPE int4,
		ALTER COLUMN type TYPE  VARCHAR;
	RAISE NOTICE 'audit_table -> new column %', (SELECT audit_table(connname, conn_data, 'public', 'lang'));
	INSERT INTO
		public.lang(id, name, localname, active, is_blocked, created_by, updated_by, type, new_column)
		VALUES (id, 'test_alter_column', 'test_alter_column', true, false, 1, 2, 'left', 10);
	query_verify = FORMAT('SELECT COUNT(lang.new_column) as total FROM public.lang WHERE id = ''%s'';', id);
	RAISE NOTICE 'Verify query in audit %', query_verify;
	total = 0;
	SELECT remote3.total INTO total FROM dblink(connname, query_verify) AS remote3(total int);
	if (total > 0) THEN
		RAISE INFO 'Verification new columun success';
	ELSE
		RAISE EXCEPTION 'The id "%" does not exists in "%.%" table ', id, name_schema, name_table
		USING ERRCODE='AUTNF';
	END IF;
	RETURN 'test_alter_column passed';
END
$func$
LANGUAGE plpgsql;