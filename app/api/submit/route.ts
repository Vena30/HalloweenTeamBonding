import {actor,db,bad,json} from '../../../lib/server';
export async function POST(req:Request){try{const a=await actor();if(a?.role!=='player')return bad('Participant login required',403);const b=await req.json();const answer=String(b.answer||'').slice(0,200).trim();if(!answer)return bad('Enter an answer');const sql=db();const [result]=await sql`SELECT submit_blackthorn(${a.name},${answer}) AS result`;return json(result.result);
 }catch(e){return bad('Submission failed, please retry',500)}}
