CREATE TABLE "lang" (
	"id" varchar NOT NULL,
	"name" varchar NOT NULL,
	"localname" varchar NOT NULL,
	"active" boolean NOT NULL DEFAULT FALSE,
	"is_blocked" boolean NOT NULL DEFAULT FALSE,
	"created_by" integer,
	"updated_by" integer,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL,
	CONSTRAINT "UQ_id_lang" UNIQUE ("id"),
	CONSTRAINT "PK_id_lang" PRIMARY KEY ("id")
)