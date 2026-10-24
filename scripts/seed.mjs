import {readFileSync,writeFileSync,mkdirSync} from 'fs';
import {randomInt} from 'crypto';
import path from 'path';
const root=process.cwd();const rooms=JSON.parse(readFileSync(path.join(root,'lib/rooms.json'),'utf8'));
const roster=[['Ms Ivy','Ericka','Ms Joyce','Skylar','Fayne','Ms Nat'],['Sir Lyndon','Gabe','Alliah','Yesenia','Rachel','Ms Jessel','Sir Joe'],['Ms Carissa','Ms Cassandra','Melvin','Annalyn','Lyka','Amber']];
const lit=s=>"'"+String(s).replaceAll("'","''")+"'";
let sql='-- Run AFTER sql/schema.sql. Keep the PIN roster private.\n';
for(let i=0;i<rooms.length;i++)sql+=`INSERT INTO room_answers(room,answer) VALUES(${i},${lit(rooms[i].word)}) ON CONFLICT(room) DO UPDATE SET answer=excluded.answer;\n`;
const pins=[];
for(let t=0;t<roster.length;t++)for(const name of roster[t]){const pin=String(randomInt(100000,999999));pins.push(`${name} | Team ${t+1} | PIN ${pin}`);sql+=`INSERT INTO players(name,team,pin_hash) VALUES(${lit(name)},${t+1},encode(digest(${lit(pin)},'sha256'),'hex')) ON CONFLICT(name) DO UPDATE SET team=excluded.team,pin_hash=excluded.pin_hash;\n`}
mkdirSync(path.join(root,'private'),{recursive:true});writeFileSync(path.join(root,'private/seed.sql'),sql);writeFileSync(path.join(root,'private/PARTICIPANT_PINS.txt'),pins.join('\n')+'\n');console.log('Generated private/seed.sql and private/PARTICIPANT_PINS.txt. Never commit or share them publicly.');
