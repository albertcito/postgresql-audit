[![CircleCI (all branches)](https://img.shields.io/circleci/project/github/albertcito/postgresql-audit.svg)](https://circleci.com/gh/albertcito/postgresql-audit) [![Twitter](https://img.shields.io/twitter/url?style=social)](https://twitter.com/intent/tweet?text=Cool%20Postgres%20DB%20Audit%20repository&url=https%3A%2F%2Fgithub.com%2Falbertcito%2Fpostgresql-audit%2F&hashtags=postgres)


## What is it

- It create the same schemas and tables in a audit DB.
- It add triggers in each of the tables to your DB to copy every INSERT, UPDATE or DELETE to the audit DB.

### How to start

1. Copy [audit_get_table_columns](db_init/audit_get_table_columns.sql) in the `public` schema of your `audit` DB.

2. It require dblink extension in order to work, so install it:
```sql
CREATE EXTENSION dblink;
```
3. Run this code
```sql
SELECT dblink_connect(
	'audit_db_connection',
	'host=127.0.0.1 port=5432 dbname=audit user=root password=1234 options=-csearch_path='
);
-- Copy all your schemas and tables to the audit DB
SELECT audit_db(
	'audit_db_connection',
	'host=127.0.0.1 port=5432 dbname=audit user=root password=1234 options=-csearch_path='
);
SELECT dblink_disconnect('audit_db_connection');
```
4. Review your audit DB you will have the same struct of your DB. Insert something in your DB and review it in the audit DB.

### What happens if I update a table or add a new column?

You just have to run this function
```sql
SELECT dblink_connect(
	'audit_db_connection',
	'host=127.0.0.1 port=5432 dbname=audit user=root password=1234 options=-csearch_path='
);
-- Update table triggers and audit table column
SELECT audit_table(
	'audit_db_connection',
	'host=127.0.0.1 port=5432 dbname=audit user=root password=1234 options=-csearch_path=',
	'my_schema',
	'my_table'
);
SELECT dblink_disconnect('audit_db_connection');
```

## Open a new issue

If you want to fix something or improve the code. These are the steps to install it in dev env.

- Run `git clone https://github.com/albertcito/postgresql-audit.git`
- Run `cd postgresql-audit`
- Run `docker-compose up -d`

### Review test it in PgAdmin
- Run this query function to create a copy of the `public.lang` table in `audit` db
``` sql
SELECT test_table()
```
- Insert data in lang table
```sql
INSERT INTO public.lang(id, name, localname, active, is_blocked, created_by, updated_by, type)
VALUES ('EN', 'English', 'English', true, false, 1, 2, 'left');
```

- Review the table `audit` DB to see the same value inserted.

### Run test in the terminal

- `docker exec -it postgresql-audit  bash`
- Connect and test it
	- `psql -U db_user example_db`
	- `SELECT test_table();`