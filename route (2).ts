import {NextRequest,NextResponse} from 'next/server';
import {db,bad,sign} from '../../../lib/server';
import {createHash,timingSafeEqual} from 'crypto';
export async function POST(req:NextRequest){try{const body=await req.json();if(!process.env.SESSION_SECRET||!process.env.HOST_PASSWORD)return bad('Server secrets not configured',500);let kind='';let name='';if(body.role==='host'){
 const a=Buffer.from(createHash('sha256').update(String(body.password||'')).digest('hex'));
 const b=Buffer.from(createHash('sha256').update(process.env.HOST_PASSWORD).digest('hex'));
 if(!timingSafeEqual(a,b))return bad('Incorrect host password',401);kind='host';name='Game Master';
 }else if(body.role==='player'){
 const sql=db(); const rows=await sql`SELECT name FROM players WHERE name=${String(body.name||'')} AND pin_hash=encode(digest(${String(body.pin||'')},'sha256'),'hex')`;
 if(!rows.length)return bad('Incorrect name or access PIN',401);kind='player';name=String(rows[0].name);
 }else return bad('Invalid role');
 const res=NextResponse.json({ok:true,role:kind,name});res.cookies.set('blackthorn_session',sign(kind,name),{httpOnly:true,secure:process.env.NODE_ENV==='production',sameSite:'lax',path:'/',maxAge:60*60*8});return res;
 }catch(e){return bad('Login failed: check database setup',500)}}
export async function DELETE(){const res=NextResponse.json({ok:true});res.cookies.delete('blackthorn_session');return res}
