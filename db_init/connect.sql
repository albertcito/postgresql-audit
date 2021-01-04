create extension dblink;
SELECT dblink_connect(
	'audit_db',
	'host=127.0.0.1 port=5432 dbname=log user=albert password=1234 options=-csearch_path='
);
