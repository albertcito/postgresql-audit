CREATE EXTENSION dblink;
CREATE TYPE example_enum AS ENUM('left', 'right');
CREATE TABLE "lang" (
	"id" varchar NOT NULL,
	"name" varchar NOT NULL,
	"localname" varchar NOT NULL,
	"active" boolean NOT NULL DEFAULT FALSE,
	"is_blocked" boolean NOT NULL DEFAULT FALSE,
	"created_by" integer,
	"updated_by" integer,
	"created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	"updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	"type" example_enum,
	CONSTRAINT "UQ_id_lang" UNIQUE ("id"),
	CONSTRAINT "PK_id_lang" PRIMARY KEY ("id")
);

/*
-- Copy Paste function in audit table
pg_dump -U db_user -Fc -s -f dump_test example_db
pg_restore -l dump_test | grep audit_get_table_columns > function_list
pg_restore -U db_user -d audit -L function_list dump_test
*/