BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_room_access" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "roomId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "user_room_idx" ON "staff_room_access" USING btree ("userId", "roomId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "staff_room_access"
    ADD CONSTRAINT "staff_room_access_fk_0"
    FOREIGN KEY("roomId")
    REFERENCES "queue_room"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR queueless
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('queueless', '20261010052244589', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261010052244589', "timestamp" = now();

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
