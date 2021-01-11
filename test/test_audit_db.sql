CREATE OR REPLACE FUNCTION test_audit_db(
    conn_data VARCHAR DEFAULT 'host=127.0.0.1 port=5432 dbname=audit user=db_user password=1234 options=-csearch_path='
)
	RETURNS VARCHAR
	AS $func$
    DECLARE connname VARCHAR = upper(substr(md5(random()::text), 0, 20));
BEGIN
	RAISE NOTICE 'dblink_connect: %', (SELECT dblink_connect(connname, conn_data));
    -- Prepare Audit DB
    RAISE NOTICE '%', (SELECT copy_fn_to_audit(connname));
    -- Run function
    RAISE NOTICE '%', (SELECT audit_db(connname, conn_data));

    RAISE NOTICE 'dblink_disconnect %',(SELECT dblink_disconnect(connname));
	RETURN 'Test test_audit_db passed';
END
$func$
LANGUAGE plpgsql;