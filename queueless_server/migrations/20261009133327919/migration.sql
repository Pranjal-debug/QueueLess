BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "queue_ticket" (
    "id" bigserial PRIMARY KEY,
    "customerName" text NOT NULL,
    "ticketNumber" bigint NOT NULL,
    "status" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "calledAt" timestamp without time zone,
    "completedAt" timestamp without time zone
);


--
-- MIGRATION VERSION FOR queueless
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('queueless', '20261009133327919', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261009133327919', "timestamp" = now();

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
