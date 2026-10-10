import {useState} from 'react';
import {guardarComprobacion} from '../model/diagnosticoRepository';
const API=process.env.EXPO_PUBLIC_API_URL||'http://127.0.0.1:18080';
export function useEntornoViewModel(){
 const [estado,setEstado]=useState('Conexión sin comprobar'),[local,setLocal]=useState('Almacenamiento sin comprobar'),[busy,setBusy]=useState(false);
 async function comprobarApi(){setBusy(true);setEstado('Conectando…');const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),10000);try{const r=await fetch(`${API}/api/estado`,{signal:controller.signal});if(!r.ok)throw new Error();const d=await r.json();setEstado(`PostgreSQL conectado · ${d.tablas} tablas`);}catch{setEstado('Sin conexión. Revisa el backend y el enlace USB/emulador.');}finally{clearTimeout(timer);setBusy(false);}}
 async function comprobarLocal(){try{const total=await guardarComprobacion();setLocal(`SQLite: ${total} comprobaciones guardadas en este dispositivo`);}catch{setLocal('No se pudo escribir en SQLite');}}
 return {estado,local,busy,comprobarApi,comprobarLocal};
}
