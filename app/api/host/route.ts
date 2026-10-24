import {actor,db,bad,json} from '../../../lib/server';
export async function POST(req:Request){try{const a=await actor();if(a?.role!=='host')return bad('Host only',403);const {action,seconds}=await req.json();const sql=db();let rows;
 if(action==='start')rows=await sql`UPDATE game_state SET phase='ready',room=0,opened_at=NULL,expires_at=NULL,updated_at=NOW() WHERE id=1 AND phase='intro' RETURNING phase`;
 else if(action==='open')rows=await sql`UPDATE game_state SET phase='open',opened_at=clock_timestamp(),expires_at=clock_timestamp()+(round_seconds||' seconds')::interval,updated_at=NOW() WHERE id=1 AND phase='ready' RETURNING phase`;
 else if(action==='close')rows=await sql`UPDATE game_state SET phase='complete',updated_at=NOW() WHERE id=1 AND phase='open' RETURNING phase`;
 else if(action==='next')rows=await sql`UPDATE game_state SET room=room+1,phase='ready',opened_at=NULL,expires_at=NULL,updated_at=NOW() WHERE id=1 AND room<9 AND phase='complete' RETURNING phase`;
 else if(action==='end')rows=await sql`UPDATE game_state SET phase='ended',updated_at=NOW() WHERE id=1 AND room=9 AND phase='complete' RETURNING phase`;
 else if(action==='duration'){const n=Number(seconds);if(!Number.isInteger(n)||n<30||n>1200)return bad('Choose 30–1200 seconds');rows=await sql`UPDATE game_state SET round_seconds=${n},updated_at=NOW() WHERE id=1 AND phase IN ('intro','ready') RETURNING phase`}
 else if(action==='reset'){await sql`SELECT reset_blackthorn()`;return json({ok:true})}
 else return bad('Unknown action');if(!rows.length)return bad('Action not available in current phase. Refresh and try again.',409);return json({ok:true});
 }catch(e){return bad('Unable to update round',500)}}
