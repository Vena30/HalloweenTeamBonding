-- Upgrade an EXISTING database from 10 to 20 rooms. Safe to run once; players and PINs are NOT touched.
-- Run this whole file in the Neon SQL Editor.
DO $$
DECLARE c record;
BEGIN
  FOR c IN
    SELECT conrelid::regclass AS tbl, conname FROM pg_constraint
    WHERE contype='c' AND conrelid IN ('game_state'::regclass,'room_answers'::regclass,'submissions'::regclass)
      AND pg_get_constraintdef(oid) LIKE '%room <= 9%'
  LOOP
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', c.tbl, c.conname);
  END LOOP;
END $$;
ALTER TABLE game_state ADD CONSTRAINT game_state_room_check CHECK (room BETWEEN 0 AND 19);
ALTER TABLE room_answers ADD CONSTRAINT room_answers_room_check CHECK (room BETWEEN 0 AND 19);
ALTER TABLE submissions ADD CONSTRAINT submissions_room_check CHECK (room BETWEEN 0 AND 19);
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
INSERT INTO room_answers(room,answer) VALUES(0,'OPEN THE SECRET BOOK') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(1,'THE GHOSTS GUARD THE KEY') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(2,'MIDNIGHT MOONFLOWER ELIXIR') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(3,'FOLLOW THE MIDNIGHT CLOCK CHIMES') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(4,'BEWARE THE SILENT SHADOWS') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(5,'THE PHANTOMS ARRIVE AT MIDNIGHT') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(6,'FOLLOW THE CANDLELIT STAIRCASE') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(7,'FIND THE HIDDEN SILVER STAR') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(8,'TAKE THE GOLDEN SKELETON KEY') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(9,'OPEN THE BLACKTHORN MANOR GATES') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(10,'THE LANTERN HIDES A LOCKET') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(11,'NINE LIVES LEFT') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(12,'TRUST NO REFLECTION') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(13,'SPIDER KEY') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(14,'PUMPKIN KING RETURNS') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(15,'CLOCK TOWEL COLD COMB') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(16,'NIGHTFALL') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(17,'THE GHOSTS SING AT DAWN') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(18,'RING THE BELL THREE TIMES') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
INSERT INTO room_answers(room,answer) VALUES(19,'BLACKTHORN MANOR SETS YOU FREE') ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;
SELECT count(*) AS answers_loaded FROM room_answers;
