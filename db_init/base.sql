CREATE TYPE example_enum AS ENUM('left', 'right');
CREATE TABLE "lang" (
	"id" varchar NOT NULL,
	"name" varchar NOT NULL,
	"localname" varchar NOT NULL,
	"active" boolean NOT NULL DEFAULT FALSE,
	"is_blocked" boolean NOT NULL DEFAULT FALSE,
	"created_by" integer,
	"updated_by" integer,
	"created_at" timestamp,
	"updated_at" timestamp,
	"type" example_enum,
	CONSTRAINT "UQ_id_lang" UNIQUE ("id"),
	CONSTRAINT "PK_id_lang" PRIMARY KEY ("id")
);

/*
CREATE EXTENSION dblink;
SELECT dblink_connect(
	'audit_db_connection',
	'host=127.0.0.1 port=5432 dbname=log user=albert password=1234 options=-csearch_path='
);
SELECT audit_table_copy('audit_db_connection', 'public', 'lang');
SELECT * FROM dblink_disconnect('audit_db');
*/