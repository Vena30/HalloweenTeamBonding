import type {Metadata} from 'next';
import './style.css';
export const metadata:Metadata={title:'Blackthorn Manor | Live Halloween Escape Room',description:'Host-controlled multiplayer Halloween challenge'};
export default function Layout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
