import {neon} from '@neondatabase/serverless';
import {createHmac,timingSafeEqual} from 'node:crypto';
import {cookies} from 'next/headers';
export function db(){if(!process.env.DATABASE_URL)throw Error('DATABASE_URL missing');return neon(process.env.DATABASE_URL)}
export function sign(role:string,name:string){const msg=Buffer.from(JSON.stringify({role,name,exp:Date.now()+1000*60*60*8})).toString('base64url'); const sig=createHmac('sha256',process.env.SESSION_SECRET||'').update(msg).digest('base64url');return `${msg}.${sig}`;}
export function verify(token:string|undefined){try{if(!token||!process.env.SESSION_SECRET)return null;const [m,s]=token.split('.');const expected=createHmac('sha256',process.env.SESSION_SECRET).update(m).digest('base64url');if(!s||s.length!==expected.length||!timingSafeEqual(Buffer.from(s),Buffer.from(expected)))return null;const p=JSON.parse(Buffer.from(m,'base64url').toString());return p.exp>Date.now()&&['host','player'].includes(p.role)?p:null;}catch{return null}}
export async function actor(){return verify((await cookies()).get('blackthorn_session')?.value)}
export const bad=(message:string,status=400)=>Response.json({error:message},{status,headers:{'Cache-Control':'no-store'}});
export const json=(x:unknown)=>Response.json(x,{headers:{'Cache-Control':'no-store'}});
