export class ErrorCentral extends Error { constructor(message: string, public status: number) { super(message); } }
const API=(process.env.EXPO_PUBLIC_API_URL || 'http://127.0.0.1:18080').replace(/\/$/,'');
export async function central<T>(token: string, ruta: string, body?: unknown): Promise<T> {
  const controller=new AbortController(); const timer=setTimeout(()=>controller.abort(),15000);
  try {
    const res=await fetch(`${API}${ruta}`,{method:body===undefined?'GET':'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:controller.signal});
    if(!res.ok) throw new ErrorCentral(res.status===401?'Sesión vencida o revocada. Vuelve a iniciar sesión.':res.status===404?'No se encontró el registro en tu centro.':res.status===409?'No se pudo asignar: revisa la capacidad, disponibilidad o destino actual.':res.status===403?'No tienes permiso para esta operación.':'No se pudo completar la operación.',res.status);
    return await res.json();
  } catch(e) {
    if(e instanceof TypeError || (e instanceof Error && e.name==='AbortError')) throw new Error('No se confirmó la operación. Comprueba la conexión y consulta el estado antes de reintentar.');
    throw e;
  } finally {clearTimeout(timer);}
}
export type LoteCentral={idLote:string;idCentro:number;centro:string;proveedor:string;placa:string;operario:string;fechaHora:string;volumenLitros:number;temperaturaC:number;acidezDornic:number;densidadGml:number;estadoEvaluacion:string;motivo:string|null;versionReglas:string|null;codigoQr:string|null;idTanque:number|null;tanque:string|null;asignadoEn:string|null};
export type Tanque={id:number;codigo:string;estado:string;capacidadLitros:number;volumenAsignadoLitros:number;disponibleLitros:number};
export type PaginaCentral<T>={elementos:T[];total:number;pagina:number;tamano:number};
