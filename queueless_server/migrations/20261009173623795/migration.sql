BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "queue_room" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- ACTION DATA BACKFILL FOR queue_ticket
--
-- 1. Insert default room
INSERT INTO "queue_room" (name, "createdAt") VALUES ('General', now());

-- 2. Add column as nullable
ALTER TABLE "queue_ticket" ADD COLUMN "roomId" bigint;

-- 3. Backfill data
UPDATE "queue_ticket" SET "roomId" = (SELECT id FROM "queue_room" WHERE name = 'General');

-- 4. Make column NOT NULL
ALTER TABLE "queue_ticket" ALTER COLUMN "roomId" SET NOT NULL;

-- Indexes
CREATE UNIQUE INDEX "room_ticket_idx" ON "queue_ticket" USING btree ("roomId", "ticketNumber");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "queue_ticket"
    ADD CONSTRAINT "queue_ticket_fk_0"
    FOREIGN KEY("roomId")
    REFERENCES "queue_room"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR queueless
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('queueless', '20261009173623795', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261009173623795', "timestamp" = now();

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
