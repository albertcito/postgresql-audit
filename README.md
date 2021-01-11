[![CircleCI (all branches)](https://img.shields.io/circleci/project/github/albertcito/postgresql-audit.svg)](https://circleci.com/gh/albertcito/postgresql-audit) ![Twitter URL](https://img.shields.io/twitter/url?style=social&url=https://twitter.com/intent/tweet?text=Cool%20Postgres%20DB%20Audit%20repository&url=https%3A%2F%2Fgithub.com%2Falbertcito%2Fpostgresql-audit%2F&hashtags=postgres)

## Install to dev

- Run `docker-compose up -d`.

### Review it in PgAdmin
- Run this query function to create a copy of the `public.lang` table in `audit` db
``` sql
SELECT test_audit()
```
- Insert data in lang table
```sql
INSERT INTO public.lang(id, name, localname, active, is_blocked, created_by, updated_by, type)
VALUES ('EN', 'English', 'English', true, false, 1, 2, 'left');
```

- Review the table `audit` DB to see the same value inserted.

### Run test in the terminal

- `docker exec -it postgresql-audit  bash`
Connect and test it
	- `psql -U db_user example_db`
	- `SELECT test_audit();`

## Use in prod

The functions create a new table in other DB to save the values inserted, updated or delete from the original table.

In order to make it work you must do:

1. Copy [audit_get_table_columns](db_init/audit_column_to_query.sql) to your `audit` DB.

2. Run this code
```sql
CREATE EXTENSION dblink;
SELECT dblink_connect(
	'audit_db_connection',
	'host=127.0.0.1 port=5432 dbname=audit user=root password=1234 options=-csearch_path='
);
SELECT audit_table(
	'audit_db_connection',
	'host=127.0.0.1 port=5432 dbname=audit user=root password=1234 options=-csearch_path=',
	'public',
	'lang'
);
SELECT dblink_disconnect('audit_db_connection');
```

## Functions

### audit_table

`audit_table(connname VARCHAR, conn_data VARCHAR, name_schema VARCHAR, name_table VARCHAR)`
- `connname`: Connection name from a dblink_connect.
- `conn_data`: The connection data to use in trigger. i.e: `host=127.0.0.1 port=5432 dbname=audit user=root password=1234 options=-csearch_path=`.
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
- `conn_data`: The connection data to use in trigger. i.e: `host=127.0.0.1 port=5432 dbname=audit user=root password=1234 options=-csearch_path=`.
- `name_schema`: Name schema to audit.
- `name_table`: Name table to audit.

This function created a trigger in the original table that is executed on Insert, Update or Delete and create a new row in the `audit` table.

### audit_get_table_columns
`audit_get_table_columns( name_schema varchar, name_table varchar)`
- `name_schema`: Name schema.
- `name_table`: Name table.

Function returns a table with the columns and type data of the table requested.

