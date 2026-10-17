import { useEffect, useRef, useState } from 'react';
import { central, type LoteCentral, type PaginaCentral, type Tanque } from '../services/centralService';
export function useCentralViewModel(token:string, modo:'calidad'|'tanque'|'trazabilidad') {
  const [lista,setLista]=useState<PaginaCentral<LoteCentral>|null>(null),[pagina,setPagina]=useState(0);
  const [detalle,setDetalle]=useState<LoteCentral|null>(null),[tanques,setTanques]=useState<PaginaCentral<Tanque>|null>(null);
  const [paginaTanque,setPaginaTanque]=useState(0),[error,setError]=useState(''),[busy,setBusy]=useState(false);
  const [codigo,setCodigo]=useState(''),[intento,setIntento]=useState(0);
  const secuencia=useRef(0), bloqueo=useRef(false);
  useEffect(()=>{let activo=true;setLista(null);setError('');setBusy(true);
    central<PaginaCentral<LoteCentral>>(token,`/api/lotes?pagina=${pagina}&tamano=25${modo==='tanque'?'&estado=APROBADO':''}`)
      .then(r=>{if(activo)setLista(r);}).catch(e=>{if(activo)setError(e.message);}).finally(()=>{if(activo)setBusy(false);});
    return()=>{activo=false;secuencia.current++;};
  },[token,modo,pagina,intento]);
  async function abrir(codigo:string) {
    if(bloqueo.current)return;
    const id=++secuencia.current;setBusy(true);setError('');setDetalle(null);setTanques(null);setPaginaTanque(0);
    try {
      const limpio=codigo.trim();
      if(!/^(ACOPIO:)?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(limpio))throw new Error('Ingresa un UUID válido o un QR ACOPIO.');
      const r=await central<LoteCentral>(token,limpio.startsWith('ACOPIO:')?`/api/lotes/por-qr?codigo=${encodeURIComponent(limpio)}`:`/api/lotes/${limpio}`);
      if(id===secuencia.current)setDetalle(r);
    }catch(e){if(id===secuencia.current)setError(e instanceof Error?e.message:'No se pudo consultar.');}
    finally{if(id===secuencia.current)setBusy(false);}
  }
  async function cargarTanques(pagina=0) {
    if(bloqueo.current)return;
    setBusy(true);setError('');setTanques(null);
    try{setTanques(await central<PaginaCentral<Tanque>>(token,`/api/tanques?disponibles=true&pagina=${pagina}&tamano=25`));setPaginaTanque(pagina);}
    catch(e){setError(e instanceof Error?e.message:'No se pudo cargar tanques.');}finally{setBusy(false);}
  }
  async function asignar(idTanque:number) {
    if(!detalle||bloqueo.current)return;
    bloqueo.current=true;setBusy(true);setError('');const id=detalle.idLote;setTanques(null);
    try{
      // Consulta previa obligatoria, también tras un resultado HTTP incierto.
      const actual=await central<LoteCentral>(token,`/api/lotes/${id}`);setDetalle(actual);
      if(!actual.idTanque){await central(token,`/api/lotes/${id}/asignacion-tanque`,{idTanque});setDetalle(await central<LoteCentral>(token,`/api/lotes/${id}`));}
    }catch(e){setDetalle(null);setCodigo(id);setError((e instanceof Error?e.message:'No se confirmó la asignación.')+' Consulta nuevamente el lote para conocer su destino.');}
    finally{bloqueo.current=false;setBusy(false);}
  }
  return {lista,pagina,setPagina,detalle,setDetalle,tanques,paginaTanque,error,busy,codigo,setCodigo,abrir,cargarTanques,asignar,recargar:()=>setIntento(n=>n+1)};
}
