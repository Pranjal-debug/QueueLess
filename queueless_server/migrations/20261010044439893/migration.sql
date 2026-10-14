BEGIN;

--
-- ACTION ADD COLUMN accessCode
--
ALTER TABLE "queue_ticket" ADD COLUMN "accessCode" text;

--
-- ACTION BACKFILL accessCode
--
UPDATE "queue_ticket" 
SET "accessCode" = upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6)) 
WHERE "accessCode" IS NULL;

--
-- ACTION ENFORCE NOT NULL
--
ALTER TABLE "queue_ticket" ALTER COLUMN "accessCode" SET NOT NULL;


--
-- MIGRATION VERSION FOR queueless
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('queueless', '20261010044439893', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261010044439893', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
