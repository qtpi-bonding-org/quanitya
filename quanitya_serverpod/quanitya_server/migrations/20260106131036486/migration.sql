BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "encrypted_analysis_pipelines" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "encrypted_analysis_pipelines" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "accountId" bigint NOT NULL,
    "encryptedData" text NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "encrypted_analysis_pipeline_account_idx" ON "encrypted_analysis_pipelines" USING btree ("accountId");

--
-- ACTION DROP TABLE
--
DROP TABLE "encrypted_entries" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "encrypted_entries" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "accountId" bigint NOT NULL,
    "encryptedData" text NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "encrypted_entry_account_idx" ON "encrypted_entries" USING btree ("accountId");

--
-- ACTION DROP TABLE
--
DROP TABLE "encrypted_schedules" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "encrypted_schedules" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "accountId" bigint NOT NULL,
    "encryptedData" text NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "encrypted_schedule_account_idx" ON "encrypted_schedules" USING btree ("accountId");

--
-- ACTION DROP TABLE
--
DROP TABLE "encrypted_templates" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "encrypted_templates" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "accountId" bigint NOT NULL,
    "encryptedData" text NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "encrypted_template_account_idx" ON "encrypted_templates" USING btree ("accountId");

--
-- ACTION DROP TABLE
--
DROP TABLE "template_aesthetics" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "template_aesthetics" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "accountId" bigint NOT NULL,
    "templateId" text NOT NULL,
    "themeName" text,
    "icon" text,
    "emoji" text,
    "paletteJson" text,
    "fontConfigJson" text,
    "colorMappingsJson" text,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "template_aesthetics_account_idx" ON "template_aesthetics" USING btree ("accountId");
CREATE INDEX "template_aesthetics_template_idx" ON "template_aesthetics" USING btree ("templateId");


--
-- MIGRATION VERSION FOR quanitya
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('quanitya', '20260106131036486', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260106131036486', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20251208110420531-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110420531-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


COMMIT;
