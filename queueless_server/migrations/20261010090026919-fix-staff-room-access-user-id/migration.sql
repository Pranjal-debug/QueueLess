BEGIN;

--
-- ACTION ALTER COLUMN TYPE
--
ALTER TABLE "staff_room_access"
ALTER COLUMN "userId" TYPE text
USING "userId"::text;

--
-- MIGRATION VERSION FOR queueless
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('queueless', '20261010090026919-fix-staff-room-access-user-id', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261010090026919-fix-staff-room-access-user-id', "timestamp" = now();

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
