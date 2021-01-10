CREATE OR REPLACE FUNCTION copy_fn_to_audit(
    connname VARCHAR,
    fn_name VARCHAR DEFAULT 'audit_get_table_columns'
)
	RETURNS VARCHAR
	AS $func$
    DECLARE total INT = 0;
    DECLARE function_body VARCHAR;
BEGIN
	SELECT pg_get_functiondef(oid) INTO function_body
    FROM pg_proc WHERE proname = fn_name;

    RAISE NOTICE 'Audit -> Executing: %', function_body;
	RETURN (SELECT dblink_exec(connname, function_body));
END
$func$
LANGUAGE plpgsql;