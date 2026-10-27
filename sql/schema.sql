CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS game_state (
 id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id=1), room INTEGER NOT NULL DEFAULT 0 CHECK (room BETWEEN 0 AND 19),
 phase TEXT NOT NULL DEFAULT 'intro' CHECK (phase IN ('intro','ready','open','complete','ended')),
 opened_at TIMESTAMPTZ, expires_at TIMESTAMPTZ,
 round_seconds INTEGER NOT NULL DEFAULT 300 CHECK (round_seconds BETWEEN 30 AND 1200),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO game_state(id) VALUES(1) ON CONFLICT DO NOTHING;
CREATE TABLE IF NOT EXISTS players(name TEXT PRIMARY KEY, team INTEGER NOT NULL CHECK(team BETWEEN 1 AND 3),pin_hash TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS room_answers(room INTEGER PRIMARY KEY CHECK(room BETWEEN 0 AND 19), answer TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS submissions (
 id BIGSERIAL PRIMARY KEY, room INTEGER NOT NULL CHECK(room BETWEEN 0 AND 19), name TEXT NOT NULL REFERENCES players(name),
 team INTEGER NOT NULL, answer TEXT NOT NULL, correct BOOLEAN NOT NULL,
 submitted_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX IF NOT EXISTS submissions_room_idx ON submissions(room,id);
CREATE TABLE IF NOT EXISTS awards (room INTEGER NOT NULL,team INTEGER NOT NULL CHECK(team BETWEEN 1 AND 3),name TEXT NOT NULL, points INTEGER NOT NULL,
 submission_id BIGINT NOT NULL REFERENCES submissions(id), awarded_at TIMESTAMPTZ DEFAULT clock_timestamp(), PRIMARY KEY(room,team));
-- Atomic validation and award: row-level lock ensures exact ordering even with simultaneous responses.
CREATE OR REPLACE FUNCTION submit_blackthorn(p_name TEXT,p_answer TEXT) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE g game_state%ROWTYPE; p players%ROWTYPE; expected TEXT; is_correct BOOLEAN; row_id BIGINT; n INTEGER; prev_team INTEGER; pts INTEGER;
BEGIN
 SELECT * INTO g FROM game_state WHERE id=1 FOR UPDATE;
 IF g.phase <> 'open' THEN RETURN jsonb_build_object('ok',false,'message','Answers are not open. Wait for the host.'); END IF;
 IF clock_timestamp() >= g.expires_at THEN RETURN jsonb_build_object('ok',false,'message','Time is up. Wait for the host.'); END IF;
 SELECT * INTO p FROM players WHERE name=p_name;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'message','Unrecognized participant.'); END IF;
 IF EXISTS(SELECT 1 FROM submissions WHERE room=g.room AND name=p_name AND correct) THEN
   RETURN jsonb_build_object('ok',false,'message','You have already answered this room correctly.'); END IF;
 SELECT answer INTO expected FROM room_answers WHERE room=g.room;
 is_correct := upper(regexp_replace(coalesce(p_answer,''),'[^a-zA-Z0-9]','','g')) = upper(regexp_replace(expected,'[^a-zA-Z0-9]','','g'));
 INSERT INTO submissions(room,name,team,answer,correct) VALUES(g.room,p.name,p.team,left(p_answer,200),is_correct) RETURNING id INTO row_id;
 IF NOT is_correct THEN RETURN jsonb_build_object('ok',false,'message','Not quite. Try another answer.'); END IF;
 SELECT COUNT(*) INTO n FROM awards WHERE room=g.room;
 -- First correct distinct team gets a reserved slot; point award is simultaneous after second distinct team.
 IF NOT EXISTS (SELECT 1 FROM awards WHERE room=g.room AND team=p.team) THEN
   pts:=CASE WHEN g.room=19 THEN 10 ELSE 5 END;
   INSERT INTO awards(room,team,name,points,submission_id) VALUES(g.room,p.team,p.name,pts,row_id);
 END IF;
 SELECT COUNT(*) INTO n FROM awards WHERE room=g.room;
 IF n>=2 THEN UPDATE game_state SET phase='complete',updated_at=now() WHERE id=1;
   RETURN jsonb_build_object('ok',true,'message','Correct! Two different teams have qualified. Room complete!','complete',true);
 END IF;
 RETURN jsonb_build_object('ok',true,'message','Correct! Your team secured the first qualifying slot. Waiting for another team.','complete',false);
END $$;
CREATE OR REPLACE FUNCTION reset_blackthorn() RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  PERFORM 1 FROM game_state WHERE id=1 FOR UPDATE;
  DELETE FROM awards;
  DELETE FROM submissions;
  UPDATE game_state SET room=0,phase='intro',opened_at=NULL,expires_at=NULL,updated_at=NOW() WHERE id=1;
END $$;
