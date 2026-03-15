BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "encrypted_template_aesthetics" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "accountId" bigint NOT NULL,
    "encryptedData" text NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "encrypted_template_aesthetics_account_idx" ON "encrypted_template_aesthetics" USING btree ("accountId");


--
-- MIGRATION VERSION FOR quanitya
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('quanitya', '20260315114717616', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260315114717616', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
