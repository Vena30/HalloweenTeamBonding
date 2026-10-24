import {actor,db,bad,json} from '../../../lib/server';
import rooms from '../../../lib/rooms.json';
export const dynamic='force-dynamic';
export async function GET(){try{const a=await actor();if(!a)return bad('Please sign in',401);const sql=db();const [state]=await sql`SELECT room,phase,round_seconds,opened_at,expires_at FROM game_state WHERE id=1`;
 const scores=await sql`SELECT team, COALESCE(SUM(points),0)::int AS points FROM awards WHERE room IN (SELECT room FROM awards GROUP BY room HAVING COUNT(DISTINCT team)=2) GROUP BY team ORDER BY team`;
 const awards=await sql`SELECT room,team,name,points FROM awards ORDER BY room,awarded_at,submission_id`;
 const players=await sql`SELECT name,team FROM players ORDER BY team,name`;
 const submissions=a.role==='host'?await sql`SELECT room,name,team,answer,correct,submitted_at FROM submissions WHERE room=${Number(state.room)} ORDER BY id DESC LIMIT 60`:[];
 const room=rooms[Number(state.room)];const complete=state.phase==='complete';return json({role:a.role,name:a.name,serverNow:new Date().toISOString(),state,room:{name:room.name,tag:room.tag,setting:room.setting,story:room.story,puzzle:room.puzzle,points:room.points,hints: a.role==='host'?room.hints:[],solution:a.role==='host'&&complete?room.solution:undefined},scores:[1,2,3].map(team=>({team,points:Number(scores.find(s=>s.team===team)?.points||0)})),awards,players,submissions});
 }catch(e){return bad('Database is not initialized or temporarily unavailable',500)}}
