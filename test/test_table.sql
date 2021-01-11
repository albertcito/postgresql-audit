CREATE OR REPLACE FUNCTION test_table(
    conn_data VARCHAR DEFAULT 'host=127.0.0.1 port=5432 dbname=audit user=db_user password=1234 options=-csearch_path='
)
	RETURNS VARCHAR
	AS $func$
    DECLARE connname VARCHAR = upper(substr(md5(random()::text), 0, 20));
BEGIN
	RAISE NOTICE 'dblink_connect: %', (SELECT dblink_connect(connname, conn_data));
    -- Prepare Audit DB
    RAISE NOTICE '%', (SELECT copy_fn_to_audit(connname));
    RAISE NOTICE '%', (SELECT audit_table(connname, conn_data, 'public', 'lang'));

    RAISE NOTICE '-------------------------------------------------------------';
    RAISE NOTICE '                       test_audit_insert                    |';
    RAISE NOTICE '-------------------------------------------------------------';
    RAISE NOTICE '%', (SELECT test_audit_insert(connname, conn_data));

    RAISE NOTICE '-------------------------------------------------------------';
    RAISE NOTICE '|                       test_add_column                     |';
    RAISE NOTICE '-------------------------------------------------------------';
    RAISE NOTICE '%', (SELECT test_add_column(connname, conn_data));

    RAISE NOTICE '-------------------------------------------------------------';
    RAISE NOTICE '|                     test_alter_column                     |';
    RAISE NOTICE '-------------------------------------------------------------';
    RAISE NOTICE '%', (SELECT test_alter_column(connname, conn_data));

    RAISE NOTICE 'dblink_disconnect %',(SELECT dblink_disconnect(connname));
	RETURN 'Test passed';
END
$func$
LANGUAGE plpgsql;