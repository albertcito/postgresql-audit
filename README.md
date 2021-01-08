## Install

- Run `docker-compose up -d`.

## Use

The functions create a new table in other DB to save the values inserted, updated or delete from the original table. In order to make it work you must run this script:

```sql
CREATE EXTENSION dblink;
SELECT dblink_connect(
	'audit_db_connection',
	'host=127.0.0.1 port=5432 dbname=audit user=albertcito password=1234 options=-csearch_path='
);
SELECT audit_table(
	'audit_db_connection',
	'host=127.0.0.1 port=5432 dbname=audit user=albertcito password=1234 options=-csearch_path=',
	'public',
	'lang'
);
SELECT dblink_disconnect('audit_db_connection');

INSERT INTO public.lang(id, name, localname, active, is_blocked, created_by, updated_by, type)
VALUES ('EN', 'English', 'English', true, false, 1, 2, 'left');
```

And review the `audit` table to see the inserted the same value.

## Functions

### audit_table

`audit_table(connname VARCHAR, conn_data VARCHAR, name_schema VARCHAR, name_table VARCHAR)`
- `connname`: Connection name from a dblink_connect.
- `conn_data`: The connection data to use in trigger. i.e: `host=127.0.0.1 port=5432 dbname=audit user=albert password=1234 options=-csearch_path=`.
- `name_schema`: Name schema to audit.
- `name_table`: Name table to audit.

This function create a new table in the `audit` data base (or the db name choose) in the same schema that is the table in the original. Also, it created a trigger in the original table that is executed on Insert, Update or Delete and create a new row in the `audit` table.

### audit_table_copy

`audit_table_copy(connname VARCHAR, name_schema VARCHAR, name_table VARCHAR)`
- `connname`: Connection name from a dblink_connect.
- `name_schema`: Name schema to audit.
- `name_table`: Name table to audit.

This function create a new table in the `audit` data base (or the db name choose) in the same schema that is the table in the original.

### audit_table_triggers

`audit_table_triggers(conn_data VARCHAR, name_schema VARCHAR, name_table VARCHAR )`
- `conn_data`: The connection data to use in trigger. i.e: `host=127.0.0.1 port=5432 dbname=audit user=albert password=1234 options=-csearch_path=`.
- `name_schema`: Name schema to audit.
- `name_table`: Name table to audit.

This function created a trigger in the original table that is executed on Insert, Update or Delete and create a new row in the `audit` table.

