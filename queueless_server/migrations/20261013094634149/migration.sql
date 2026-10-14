BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "queue_room" ADD COLUMN "deletedAt" timestamp without time zone;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "queue_session" (
    "id" bigserial PRIMARY KEY,
    "roomId" bigint NOT NULL,
    "businessDate" text NOT NULL,
    "sessionNumber" bigint NOT NULL,
    "status" text NOT NULL,
    "startedAt" timestamp without time zone NOT NULL,
    "closedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "room_session_status_idx" ON "queue_session" USING btree ("roomId", "status");

--
-- ACTION ALTER TABLE
--
DROP INDEX "room_ticket_idx";
ALTER TABLE "queue_ticket" ADD COLUMN "sessionId" bigint;
CREATE UNIQUE INDEX "session_ticket_idx" ON "queue_ticket" USING btree ("sessionId", "ticketNumber");
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "queue_session"
    ADD CONSTRAINT "queue_session_fk_0"
    FOREIGN KEY("roomId")
    REFERENCES "queue_room"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "queue_ticket"
    ADD CONSTRAINT "queue_ticket_fk_1"
    FOREIGN KEY("sessionId")
    REFERENCES "queue_session"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR queueless
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('queueless', '20261013094634149', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013094634149', "timestamp" = now();

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
